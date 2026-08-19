"""计算字段公式库（扁平规则列表）—— 任务四 P2。

每个 kind 对应一份「按依赖顺序排列」的规则列表，规则 JSON schema：

    {"column_key": "mean", "op": "avg", "inputs": ["ra1","ra2","ra3"], "args": {"precision": 3}}

- `column_key`：目标计算列（即 experiment_config_columns.column_key）。
- `op`：白名单算子（见 calc_engine.py）。
- `inputs`：本行内引用的列键（含前置 calc 列）；常量走 `args.constant`。
- `args`：`precision`（舍入）、`constant`（比较/算术常量）、`true_value`/`false_value`
  或 `match`（all_eq / count_if 命中值）。

本文件是「公式的权威来源」：seed/backfill 脚本据此写入 DB 的
experiment_config_columns.calc_expression；前端 ExperimentRun.vue 与后端 calc_engine.py
共用同一份语义（前端 JS 镜像见 frontend/src/utils/calcEngine.js），后端为提交权威值。

数值舍入全部「四舍五入、远离零」，与前端逐值对齐（见 calc_engine.round_half_away）。

注意：density / tarnish / fixed_denture / removable_denture 四类实验在前端（Vue 移植版）中
**没有** 计算实现（calc 列当前为空/手工填写），故不在此配方化，calc_expression 保持空，
后端权威计算对它们不介入（不臆造行为，保证与改造前逐格一致）。
"""
from __future__ import annotations

from typing import Any

import json


# ── thickness：固定端/中点/自由端 各 3 点（单次测量 × 3 点）与 9 点全集 ──
# 已删除第 2/3 次重复测量（r2_*/r3_*），仅保留第 1 次（r1_*）三点。
def _thickness_inputs(section: str) -> list[str]:
    return [f"r1_{section}_p{p}" for p in range(1, 4)]


_THICKNESS_SECTIONS = ("fixed", "middle", "free")
# 与旧前端累加顺序一致：先固定端 → 中点 → 自由端（sec 主序），保证求和浮点序逐位一致
_THICKNESS_ALL = [f"r1_{sec}_p{p}" for sec in _THICKNESS_SECTIONS for p in range(1, 4)]


CALC_FORMULAS: dict[str, list[dict[str, Any]]] = {
    # ── I001 表面粗糙度 ──
    "rough": [
        {"column_key": "mean", "op": "avg", "inputs": ["ra1", "ra2", "ra3"], "args": {"precision": 3}},
        {"column_key": "conclusion", "op": "le", "inputs": ["mean", "limit"],
         "args": {"constant": 15, "true_value": "符合", "false_value": "不符合"}},
    ],

    # ── I002 金属-陶瓷结合裂纹萌生 ──
    "mc_crack": [
        {"column_key": "dm_mean", "op": "avg", "inputs": ["dm1", "dm2", "dm3"], "args": {"precision": 4}},
        {"column_key": "tau", "op": "multiply", "inputs": ["k", "ffail"], "args": {"precision": 2}},
        {"column_key": "conclusion", "op": "gt", "inputs": ["tau"],
         "args": {"constant": 25, "true_value": "符合", "false_value": "不符合"}},
    ],

    # ── I003 X射线灰度（conclusion 为 select，仅 ROI 均值参与计算）──
    "xray": [
        {"column_key": "roi1", "op": "avg",
         "inputs": ["roi1_reading1", "roi1_reading2", "roi1_reading3"], "args": {"precision": 2}},
        {"column_key": "roi2", "op": "avg",
         "inputs": ["roi2_reading1", "roi2_reading2", "roi2_reading3"], "args": {"precision": 2}},
        {"column_key": "roi3", "op": "avg",
         "inputs": ["roi3_reading1", "roi3_reading2", "roi3_reading3"], "args": {"precision": 2}},
        {"column_key": "roi_mean", "op": "avg", "inputs": ["roi1", "roi2", "roi3"], "args": {"precision": 2}},
    ],

    # ── I004 翘曲变形（判定词 合格/不合格）──
    "warp": [
        {"column_key": "delta", "op": "subtract", "inputs": ["h1", "h2"], "args": {"precision": 4}},
        {"column_key": "conclusion", "op": "abs_le", "inputs": ["delta", "limit"],
         "args": {"constant": 0.5, "true_value": "合格", "false_value": "不合格"}},
    ],

    # ── I005 热膨胀系数（alpha = ΔL(μm)/1000 / (L0·ΔT) ×10⁶）──
    "cte": [
        {"column_key": "delta_t", "op": "subtract", "inputs": ["t2", "t1"], "args": {"precision": 3}},
        {"column_key": "alpha", "op": "divide", "inputs": ["delta_l", "l0", "delta_t"],
         "args": {"constant": 1000, "precision": 3}},
    ],

    # ── I006 耐急冷急热（无裂纹/崩瓷/破裂 → 符合）──
    "shock": [
        {"column_key": "conclusion", "op": "all_eq", "inputs": ["crack", "chipping", "fracture"],
         "args": {"match": "无", "true_value": "符合", "false_value": "不符合"}},
    ],

    # ── I007 弯曲性能 ──
    "bend": [
        {"column_key": "conclusion", "op": "ge", "inputs": ["stress_02"],
         "args": {"constant": 800, "true_value": "符合", "false_value": "不符合"}},
    ],

    # ── I008 维氏硬度 ──
    "hv": [
        {"column_key": "mean", "op": "avg", "inputs": ["indent1", "indent2", "indent3"], "args": {"precision": 1}},
    ],

    # ── I009 厚度（deviation/conclusion 依赖 design_thickness 表单字段，当前前端未接入，暂不配方）──
    "thickness": [
        {"column_key": "fixed_mean", "op": "avg", "inputs": _thickness_inputs("fixed"), "args": {"precision": 4}},
        {"column_key": "middle_mean", "op": "avg", "inputs": _thickness_inputs("middle"), "args": {"precision": 4}},
        {"column_key": "free_mean", "op": "avg", "inputs": _thickness_inputs("free"), "args": {"precision": 4}},
        {"column_key": "mean", "op": "avg", "inputs": _THICKNESS_ALL, "args": {"precision": 4}},
    ],

    # ── I010 色稳定性（三态判定，专属算子 color_overall / color_conclusion）──
    "color": [
        {"column_key": "overall", "op": "color_overall", "inputs": ["observer1", "observer2", "observer3"], "args": {}},
        {"column_key": "conclusion", "op": "color_conclusion", "inputs": ["observer1", "observer2", "observer3"], "args": {}},
    ],
}


def rules_for_kind(kind: str) -> list[dict[str, Any]]:
    """返回某实验的公式规则列表（无配方返回空列表）。"""
    return CALC_FORMULAS.get(kind, [])


def rules_by_column(rules: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    """把规则列表按 column_key 建立索引，便于按列写回 calc_expression。"""
    return {r["column_key"]: r for r in rules if isinstance(r, dict) and r.get("column_key")}


def parse_expression(raw: Any) -> dict[str, Any] | None:
    """把 calc_expression（TEXT/JSONB 或已解析对象）解析为单条规则 dict；空/非法 → None。"""
    if raw is None or raw == "":
        return None
    if isinstance(raw, dict):
        return raw
    s = str(raw).strip()
    try:
        obj = json.loads(s)
    except (json.JSONDecodeError, TypeError):
        return None
    return obj if isinstance(obj, dict) else None


def rules_from_columns(columns: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """从（已规范化或 DB 原始）列列表构建按 sort_order 顺序的规则列表。

    仅收集 column_type=='calc' 且 calc_expression 为合法单规则 JSON 的列；
    规则若缺 column_key，则用列自身的 column_key 补齐（兼容旧格式）。
    """
    ordered = sorted(columns, key=lambda c: (c.get("sort_order", 0),))
    rules: list[dict[str, Any]] = []
    for c in ordered:
        ct = str(c.get("column_type", "") or "")
        if ct != "calc":
            continue
        expr = parse_expression(c.get("calc_expression"))
        if not expr or not expr.get("op"):
            continue
        rule = dict(expr)
        rule.setdefault("column_key", c.get("column_key", ""))
        if rule.get("column_key"):
            rules.append(rule)
    return rules
