"""规格型号（model）规范化工具。

历史数据里存在「标准」「-」「无」等占位符，这些并非真实规格型号。
入库/资料库阶段统一把它们视为「未填写」，强制录入真实值。
"""

# 视为「未填写」的占位符（匹配前统一 strip + lower）
# 注：「标准」暂不作为占位符，允许作为规格型号值使用。
_PLACEHOLDERS = {
    "", "-", "—", "－", "_", "无", "暂无", "不适用",
    "na", "n/a", "none", "null", "nil",
}


def normalize_model(value) -> str:
    """规格型号规范化：占位符视为空，返回 stripped 后的真实值或 ''。"""
    if value is None:
        return ""
    s = str(value).strip()
    key = s.lower()
    return "" if key in _PLACEHOLDERS else s


def is_real_model(value) -> bool:
    """是否为有效的真实规格型号（非空且非占位符）。"""
    return bool(normalize_model(value))
