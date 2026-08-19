"""计算字段公式引擎（白名单求值器，扁平规则列表）。

任务四（P2）：自动计算字段由公式驱动，前后端同一份公式，后端为提交权威值。

设计约束：
  - 白名单算子，纯函数 + dispatch 字典，**严禁 eval / exec / new Function**。
  - 非法 op / 未声明引用 → 该规则置空并记录告警，绝不抛异常中断整批。
  - 数值舍入用「四舍五入、远离零」（与前端 JS `Number.toFixed` 对齐，逐值一致是硬指标）。
  - 规则按依赖顺序求值（前置 calc 列可被后续规则引用）。

规则 JSON schema（每条对应一个计算列，`column_key` 即目标字段）：

  {"column_key": "mean", "op": "avg", "inputs": ["ra1","ra2","ra3"],
   "args": {"precision": 3}}
  {"column_key": "conclusion", "op": "abs_le", "inputs": ["mean","limit"],
   "args": {"precision": 3, "constant": 15, "true_value": "符合", "false_value": "不符合"}}

算子白名单：
  数值聚合/算术：avg sum min max add subtract multiply divide
  数值变换：     abs round
  比较（判定，输出字符串）：le ge lt gt eq ne abs_le abs_ge all_eq
  计数（输出数值）：count count_if
"""
from __future__ import annotations

import logging
from decimal import Decimal, ROUND_HALF_UP
from typing import Any

logger = logging.getLogger("calc_engine")

# ── 白名单 ──
_NUMERIC_OPS = {"avg", "sum", "min", "max", "add", "subtract", "multiply", "divide", "abs", "round"}
_VERDICT_OPS = {"le", "ge", "lt", "gt", "eq", "ne", "abs_le", "abs_ge", "all_eq"}
_SPECIAL_OPS = {"color_overall", "color_conclusion"}
_COUNT_OPS = {"count", "count_if"}
_ALLOWED_OPS = _NUMERIC_OPS | _VERDICT_OPS | _SPECIAL_OPS | _COUNT_OPS


# ── 数值辅助 ──

def _to_num(val: Any) -> float | None:
    """把输入转 float；None/空串/非数字 → None。"""
    if val is None or val == "":
        return None
    if isinstance(val, bool):
        return None
    try:
        return float(val)
    except (TypeError, ValueError):
        return None


def round_half_away(value: float, precision: int) -> float:
    """四舍五入、远离零（等价 JS Number.toFixed 的常规舍入）。

    Python 内建 round() 是银行家舍入（half-to-even），与 JS 不一致；
    Decimal.ROUND_HALF_UP 即「平局远离零」，正负皆如此，与 toFixed 对齐。
    """
    try:
        quant = Decimal(1).scaleb(-int(precision))
    except Exception:
        return float(value)
    return float(Decimal(str(value)).quantize(quant, rounding=ROUND_HALF_UP))


def _round(value: float | None, precision: int | None) -> float | None:
    if value is None:
        return None
    if precision is None:
        return value
    return round_half_away(value, precision)


def _resolve(value: Any) -> Any:
    """统一空值：None 与空串视为空。"""
    if value is None or value == "":
        return None
    return value


# ── 数值算子 ──

def _op_avg(nums: list[float | None], args: dict) -> float | None:
    if any(n is None for n in nums) or not nums:
        return None
    return sum(nums) / len(nums)


def _op_sum(nums: list[float | None], args: dict) -> float | None:
    if any(n is None for n in nums) or not nums:
        return None
    return sum(nums)


def _op_min(nums: list[float | None], args: dict) -> float | None:
    if any(n is None for n in nums) or not nums:
        return None
    return min(nums)


def _op_max(nums: list[float | None], args: dict) -> float | None:
    if any(n is None for n in nums) or not nums:
        return None
    return max(nums)


def _op_add(nums: list[float | None], args: dict) -> float | None:
    if any(n is None for n in nums) or not nums:
        return None
    return sum(nums) + float(args.get("constant", 0) or 0)


def _op_subtract(nums: list[float | None], args: dict) -> float | None:
    if len(nums) < 2 or any(n is None for n in nums[:2]):
        return None
    return nums[0] - nums[1]


def _op_multiply(nums: list[float | None], args: dict) -> float | None:
    if not nums or any(n is None for n in nums):
        return None
    out = 1.0
    for n in nums:
        out *= n
    c = args.get("constant")
    if c is not None and c != "":
        out *= float(c)
    return out


def _op_divide(nums: list[float | None], args: dict) -> float | None:
    if len(nums) < 2 or any(n is None for n in nums):
        return None
    out = float(args.get("constant", 1) if args.get("constant") not in (None, "") else 1)
    out *= nums[0]
    for n in nums[1:]:
        if n == 0:
            return None
        out /= n
    return out


def _op_abs(nums: list[float | None], args: dict) -> float | None:
    if not nums or nums[0] is None:
        return None
    return abs(nums[0])


def _op_round(nums: list[float | None], args: dict) -> float | None:
    if not nums or nums[0] is None:
        return None
    return _round(nums[0], args.get("precision"))


# ── 比较算子（输出判定字符串）──

def _cmp_rhs(inputs: list[Any], args: dict) -> Any:
    """取比较右值：优先 inputs[1]，缺失时回退 args.constant。"""
    if len(inputs) >= 2 and _resolve(inputs[1]) is not None:
        return inputs[1]
    return args.get("constant")


def _compare(op: str, a: Any, b: Any) -> bool | None:
    """数值优先比较，否则字符串比较。任一侧不可比 → None。"""
    na, nb = _to_num(a), _to_num(b)
    if na is not None and nb is not None:
        if op == "le":
            return na <= nb
        if op == "ge":
            return na >= nb
        if op == "lt":
            return na < nb
        if op == "gt":
            return na > nb
        if op == "eq":
            return na == nb
        if op == "ne":
            return na != nb
        if op == "abs_le":
            return abs(na) <= nb
        if op == "abs_ge":
            return abs(na) >= nb
    # 字符串比较
    sa = "" if _resolve(a) is None else str(a)
    sb = "" if _resolve(b) is None else str(b)
    if op == "eq":
        return sa == sb
    if op == "ne":
        return sa != sb
    if op == "le":
        return sa <= sb
    if op == "ge":
        return sa >= sb
    if op == "lt":
        return sa < sb
    if op == "gt":
        return sa > sb
    return None


def _verdict(res: bool | None, args: dict) -> str:
    if res is None:
        return ""
    return str(args.get("true_value", "符合")) if res else str(args.get("false_value", "不符合"))


def _op_compare(op: str, inputs: list[Any], args: dict) -> str:
    if not inputs or _resolve(inputs[0]) is None:
        return ""
    rhs = _cmp_rhs(inputs, args)
    if _resolve(rhs) is None:
        return ""
    return _verdict(_compare(op, inputs[0], rhs), args)


def _op_all_eq(inputs: list[Any], args: dict) -> str:
    if not inputs:
        return ""
    resolved = [_resolve(v) for v in inputs]
    if any(v is None for v in resolved):
        return ""
    match = args.get("match")
    if match is not None:
        return _verdict(all(str(v) == str(match) for v in resolved), args)
    return _verdict(all(v == resolved[0] for v in resolved), args)


# ── 色稳定性三态判定（专属算子，前后端镜像实现，保证逐值一致）──

def _color_counts(inputs: list[Any]) -> tuple[int, int]:
    resolved = [_resolve(v) for v in inputs]
    severe = sum(1 for v in resolved if str(v) == "明显差异")
    unable = sum(1 for v in resolved if str(v) == "无法判定")
    return severe, unable


def _op_color_overall(inputs: list[Any], args: dict) -> str:
    severe, unable = _color_counts(inputs)
    if unable >= 2:
        return "无法判定"
    if severe >= 2:
        return "明显差异"
    return "未见明显差异/轻微差异"


def _op_color_conclusion(inputs: list[Any], args: dict) -> str:
    severe, unable = _color_counts(inputs)
    if severe >= 2:
        return "不符合"
    if unable >= 2:
        return "需复核"
    return "符合"


# ── 计数算子 ──

def _op_count(inputs: list[Any], args: dict) -> int:
    return sum(1 for v in inputs if _resolve(v) is not None)


def _op_count_if(inputs: list[Any], args: dict) -> int:
    match = str(args.get("match", ""))
    return sum(1 for v in inputs if _resolve(v) is not None and str(v) == match)


# ── dispatch ──

def _eval_rule(rule: dict, row: dict[str, Any]) -> Any:
    op = rule.get("op")
    args = rule.get("args") or {}
    if not isinstance(args, dict):
        args = {}
    inputs = [_resolve(row.get(name)) for name in (rule.get("inputs") or [])]
    precision = args.get("precision")

    if op not in _ALLOWED_OPS:
        logger.warning("calc_engine: 未知算子 %r 已跳过", op)
        return None

    if op in _NUMERIC_OPS:
        nums = [_to_num(v) for v in inputs]
        if op == "avg":
            result = _op_avg(nums, args)
        elif op == "sum":
            result = _op_sum(nums, args)
        elif op == "min":
            result = _op_min(nums, args)
        elif op == "max":
            result = _op_max(nums, args)
        elif op == "add":
            result = _op_add(nums, args)
        elif op == "subtract":
            result = _op_subtract(nums, args)
        elif op == "multiply":
            result = _op_multiply(nums, args)
        elif op == "divide":
            result = _op_divide(nums, args)
        elif op == "abs":
            result = _op_abs(nums, args)
        elif op == "round":
            result = _op_round(nums, args)
        else:  # pragma: no cover - 已在白名单内
            result = None
        return _round(result, precision)

    if op in _VERDICT_OPS:
        if op == "all_eq":
            return _op_all_eq(inputs, args)
        return _op_compare(op, inputs, args)

    if op == "color_overall":
        return _op_color_overall(inputs, args)
    if op == "color_conclusion":
        return _op_color_conclusion(inputs, args)

    if op == "count":
        return _op_count(inputs, args)
    if op == "count_if":
        return _op_count_if(inputs, args)

    return None


def evaluate_rules(rules: list[dict], rows: list[dict]) -> list[dict]:
    """按给定顺序对每行求值规则，返回补齐计算列后的行列表（不修改入参）。

    rules: [{column_key, op, inputs, args}, ...]，必须已按依赖顺序排列。
    rows:  原始测量行。
    """
    out_rows: list[dict] = []
    for raw in rows:
        row = dict(raw)
        for rule in rules or []:
            if not isinstance(rule, dict):
                continue
            key = rule.get("column_key")
            if not key:
                continue
            row[key] = _eval_rule(rule, row)
        out_rows.append(row)
    return out_rows


def evaluate(rules: list[dict], row: dict[str, Any]) -> dict[str, Any]:
    """单行求值（便捷封装）。"""
    return evaluate_rules(rules, [row])[0]
