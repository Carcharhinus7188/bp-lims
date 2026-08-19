# -*- coding: utf-8 -*-
"""中文标签 → 业务 field_key 同义词字典（任务三 P4 模板自动匹配向导）。

权威词库复用前端 `ExperimentRun.vue` 的 `PARAM_ALIASES` / `ROW_ALIASES`（模板标签
→ 表单字段 key / 测量行列 key），后端 `match_field_key` 据此把模板里抽出的标签
（如「检测前温度/℃」「平均值Ra」）归一化后命中到业务 field_key，未命中项由调用方
标 `matched:false` 并给 `field_N` 兜底，交给管理员一次性确认。

说明：这是「辅助匹配」而非强制映射——匹配错误比不匹配更糟，因此只做确定性高的
精确/包含匹配，不做拼音/语义猜测；结果最终由管理员在向导里确认后再写入。
"""
from __future__ import annotations

import re

# ── 合并 PARAM_ALIASES + ROW_ALIASES（与前端 ExperimentRun.vue 保持同步）────────
# 中文标签 → 业务 field_key
LABEL_ALIASES: dict[str, str] = {
    # —— 委托 / 样品信息（PARAM_ALIASES）——
    "委托单位": "client_name", "委托方": "client_name", "委托方名称": "client_name",
    "委托方地址": "client_address", "委托单位地址": "client_address",
    "生产单位": "production_unit", "生产厂家": "production_unit",
    "样品名称": "sample_name", "试样名称": "sample_name",
    "规格型号": "model", "型号规格": "model", "样品规格": "model",
    "材料名称": "material_name", "材料工艺": "material_name",
    "产品编号": "batch_no", "批号": "batch_no", "样品批号": "batch_no",
    "样品编号": "sample_nos", "试样编号": "sample_nos", "实验室样品编号": "sample_nos",
    "检测依据": "standard", "检测方法": "method_code",
    "检测地点": "detection_location", "检测场所": "detection_location",
    "接收日期": "received_date", "收样日期": "received_date",
    "检测日期": "test_date", "实验日期": "test_date", "试验日期": "test_date",
    "检验日期": "test_date", "测量日期": "test_date",
    "检测人员": "operator", "实验员": "operator", "操作人": "operator", "记录人": "operator",
    "核验人员": "reviewer", "复核人": "reviewer",
    "报告编号": "report_no",
    "样品数量": "sample_quantity", "试样数量": "sample_quantity",
    # —— 环境 ——
    "温度": "temperature_before", "环境温度": "temperature_before",
    "湿度": "humidity_before", "环境湿度": "humidity_before",
    "实验前温度": "temperature_before", "实验后温度": "temperature_after",
    "实验前湿度": "humidity_before", "实验后湿度": "humidity_after",
    "试验温度": "temperature_before", "试验湿度": "humidity_before",
    "开始时间": "start_time", "结束时间": "end_time",
    # —— 各实验参数 ——
    "升温速率": "heating_rate", "保温时间": "hold_time",
    "载荷": "load", "试验力": "load",
    "硬度标尺": "hardness_scale", "试验力值": "test_force",
    "压头类型": "indenter_type", "保载时间": "dwell_time",
    "放大倍数": "magnification", "物镜": "objective",
    "评定长度": "evaluation_length", "截止波长": "cutoff_filter",
    "测量方向": "measurement_direction",
    "材料牌号": "metal_name", "金属牌号": "metal_name", "金属批号": "metal_batch",
    "陶瓷牌号": "ceramic_name", "烤瓷程序": "porcelain_program",
    "K值": "k", "跨距": "span",
    "X射线管电压": "tube_voltage", "管电压": "tube_voltage",
    "X射线管电流": "tube_current", "管电流": "tube_current",
    "曝光时间": "exposure_time", "焦距": "focal_distance",
    "源类型": "source_type", "辐照度": "irradiance",
    "水温": "water_medium", "浸泡时间": "exposure_duration",
    "观察者1": "observer1", "观察者2": "observer2", "观察者3": "observer3",
    "标准试样": "standard_sample", "标准号": "standard_no",
    "压痕测量方式": "indent_measurement_method",
    "设备名称": "equipment_name", "设备型号": "equipment_model",
    "管理编号": "management_no", "设备编号": "equipment_no",
    "校准证书": "calibration_certificate", "校准有效期": "calibration_due",
    "测量范围": "measuring_range", "溯源机构": "traceability_agency",
    # —— 测量行 / 列值（ROW_ALIASES）——
    "Ra1": "ra1", "Ra2": "ra2", "Ra3": "ra3", "平均值Ra": "mean", "粗糙度平均值": "mean",
    "dm1": "dm1", "dm2": "dm2", "dm3": "dm3", "dm平均": "dm_mean",
    "Ffail": "ffail", "τb": "tau", "结合强度": "tau",
    "ROI1": "roi1", "ROI2": "roi2", "ROI3": "roi3", "ROI平均": "roi_mean",
    "H1": "h1", "H2": "h2", "ΔH": "delta",
    "T1": "t1", "T2": "t2", "ΔT": "delta_t", "α": "alpha",
    "裂纹": "crack", "崩瓷": "chipping", "断裂": "fracture",
    "0.2%弯曲应力": "stress_02", "Fmax": "fmax",
    "压痕1": "indent1", "压痕2": "indent2", "压痕3": "indent3", "HV平均": "mean",
    "厚度平均": "mean", "偏差": "deviation",
}

# 去掉标签末尾的单位（"/μm"、"／℃"）与括号说明（"（…）"、"（mm）"）
_UNIT_SUFFIX = re.compile(r"[/／][^\s／/]{0,12}$")
_PAREN_SUFFIX = re.compile(r"[（(][^）)]*[）)]\s*$")


def normalize_label(label: str) -> str:
    """归一化标签：去首尾空白、去末尾单位/括号说明、去分隔符。"""
    s = (label or "").strip()
    s = _PAREN_SUFFIX.sub("", s)
    s = _UNIT_SUFFIX.sub("", s)
    s = s.strip(" ：:；;，,。")
    return s


def match_field_key(label: str) -> str | None:
    """返回命中的业务 field_key；未命中返回 None（调用方给 field_N 兜底）。"""
    key = normalize_label(label)
    if not key:
        return None
    # 1) 精确命中（含「值本身就是 field_key」的情形，如 "test_date"）
    if key in LABEL_ALIASES:
        return LABEL_ALIASES[key]
    if key in _ALIAS_VALUES:
        return key
    # 2) 包含匹配（标签与同义词键互为子串）
    for alias, fk in LABEL_ALIASES.items():
        if alias and (alias in key or key in alias):
            return fk
    return None


_ALIAS_VALUES = set(LABEL_ALIASES.values())
