# -*- coding: utf-8 -*-
"""受控模板映射注册表 —— 坐标 / 阈值 / 设备号 数据化（任务二 P3）。

权威来源 = DB：
  - 常量（设备号/阈值/固定文本）→ `experiment_config_versions.extra_json.constants`。
  - 静态单元格坐标 → `template_field_mappings`（config_id → field_key → table/row/col/transform）。

本文件提供「硬编码兜底」：当 DB 未灌库（空表 / 无 extra_json.constants）时，
`CONSTANTS` 与 `FIELD_MAPPINGS` 保证行为与改造前逐格一致。种子脚本
`backend/scripts/seed_mappings.py` 据此灌库；运行期由异步调用方读 DB 后传入
`apply_controlled_mapping(..., registry=...)`，DB 值优先、硬编码兜底。

坐标约定：`table/row/col` 为 0 基下标，与 `record_word_engine.template_manifest`
返回的 `t{table}_r{row}_c{col}` 一致。仅「表/行/列全为字面常量」的静态单元格入 registry；
动态行/列（循环、`4 + roi`、`range(3,18,3)` 等）与判定逻辑保留在 mapper 代码内。
"""
from __future__ import annotations

import copy
from typing import Any

# ── 常量（硬编码兜底 = 改造前原值）────────────────────────────
CONSTANTS: dict[str, dict[str, Any]] = {
    "devices": {
        "fixture_no": "BPGL-B009",              # 金瓷结合试验夹具
        "parallel_block_no": "BGGL-B019",       # 平行块
        "roughness_instrument": "BPGL-B002",    # 表面粗糙度仪
        "tarnish_eq_a": "BPGL-A025",            # 抗晦暗溶液 A
        "tarnish_eq_b": "BPGL-C006",            # 抗晦暗溶液 B
        "d65_lightbox": "D65灯箱",               # 色稳定性标准光源
    },
    "thresholds": {
        "rough_limit_um": 15,                   # 表面粗糙度 Ra 判定上限 μm
        "crack_span_mm": 20,                    # 金瓷结合跨距 mm
        "crack_roller_mm": 1.0,                 # 金瓷结合滚轮半径 mm
        "crack_block_spec": "（30×6×5） mm",      # 平行块规格
        "thickness_tol_mm": 0.05,               # 厚度允差 mm
        "fixed_denture_ra_um": 0.025,           # 固定义齿粗糙度 Ra 上限 μm
        "density_tol_pct": 5,                   # 密度相对偏差允差 %
    },
    "fixed_text": {
        "tarnish_bath_volume_ml": 1000,         # 抗晦暗浸泡溶液体积 mL
    },
}

# ── 静态坐标（硬编码兜底 = 改造前字面坐标）────────────────────
# kind → { field_key: {table, row, col, transform} }
# transform ∈ {"text", "raw", "checkbox"}
FIELD_MAPPINGS: dict[str, dict[str, dict[str, Any]]] = {
    "rough": {
        # 表2 环境条件（_environment 抽象出的字段）
        "temperature_before": {"table": 2, "row": 1, "col": 2, "transform": "text"},
        "temperature_after": {"table": 2, "row": 1, "col": 3, "transform": "text"},
        "humidity_before": {"table": 2, "row": 2, "col": 2, "transform": "text"},
        "humidity_after": {"table": 2, "row": 2, "col": 3, "transform": "text"},
        "env_temp_ok": {"table": 2, "row": 1, "col": 4, "transform": "checkbox"},
        "env_humidity_ok": {"table": 2, "row": 2, "col": 4, "transform": "checkbox"},
        # 表2 干扰/清洁/浮尘
        "interference_col2": {"table": 2, "row": 3, "col": 2, "transform": "checkbox"},
        "interference_col3": {"table": 2, "row": 3, "col": 3, "transform": "checkbox"},
        "interference_ok": {"table": 2, "row": 3, "col": 4, "transform": "checkbox"},
        "clean_status": {"table": 2, "row": 4, "col": 2, "transform": "checkbox"},
        "clean_ok": {"table": 2, "row": 4, "col": 4, "transform": "checkbox"},
        "dust_status": {"table": 2, "row": 5, "col": 2, "transform": "checkbox"},
        "dust_ok": {"table": 2, "row": 5, "col": 4, "transform": "checkbox"},
        # 表4 核查记录
        "platform_record": {"table": 4, "row": 1, "col": 2, "transform": "checkbox"},
        "platform_conclusion": {"table": 4, "row": 1, "col": 3, "transform": "checkbox"},
        "fixture_record": {"table": 4, "row": 2, "col": 2, "transform": "checkbox"},
        "fixture_conclusion": {"table": 4, "row": 2, "col": 3, "transform": "checkbox"},
        "standard_block_record": {"table": 4, "row": 3, "col": 2, "transform": "raw"},
        "standard_block_conclusion": {"table": 4, "row": 3, "col": 3, "transform": "checkbox"},
        "repeat_record": {"table": 4, "row": 4, "col": 2, "transform": "raw"},
        "repeat_conclusion": {"table": 4, "row": 4, "col": 3, "transform": "checkbox"},
        "probe_record": {"table": 4, "row": 5, "col": 2, "transform": "checkbox"},
        "probe_conclusion": {"table": 4, "row": 5, "col": 3, "transform": "checkbox"},
        "overall_record": {"table": 4, "row": 6, "col": 2, "transform": "checkbox"},
        "overall_conclusion": {"table": 4, "row": 6, "col": 3, "transform": "checkbox"},
        # 表5 设定值
        "calculation_standard": {"table": 5, "row": 1, "col": 2, "transform": "raw"},
        "calculation_standard_ok": {"table": 5, "row": 1, "col": 3, "transform": "checkbox"},
        "lambda_s": {"table": 5, "row": 2, "col": 2, "transform": "raw"},
        "lambda_s_ok": {"table": 5, "row": 2, "col": 3, "transform": "checkbox"},
        "cutoff_filter": {"table": 5, "row": 3, "col": 2, "transform": "raw"},
        "cutoff_filter_ok": {"table": 5, "row": 3, "col": 3, "transform": "checkbox"},
        "shape_removal": {"table": 5, "row": 4, "col": 2, "transform": "raw"},
        "shape_removal_ok": {"table": 5, "row": 4, "col": 3, "transform": "checkbox"},
        "measurement_range": {"table": 5, "row": 5, "col": 2, "transform": "raw"},
        "measurement_range_ok": {"table": 5, "row": 5, "col": 3, "transform": "checkbox"},
        "sampling_length_select": {"table": 5, "row": 6, "col": 1, "transform": "checkbox"},
        "sampling_length_value": {"table": 5, "row": 6, "col": 2, "transform": "raw"},
        "sampling_length_ok": {"table": 5, "row": 6, "col": 3, "transform": "checkbox"},
        "evaluation_length_value": {"table": 5, "row": 7, "col": 2, "transform": "raw"},
        "evaluation_length_ok": {"table": 5, "row": 7, "col": 3, "transform": "checkbox"},
        "sampling_count_select": {"table": 5, "row": 8, "col": 1, "transform": "checkbox"},
        "sampling_count_value": {"table": 5, "row": 8, "col": 2, "transform": "raw"},
        "sampling_count_ok": {"table": 5, "row": 8, "col": 3, "transform": "checkbox"},
        "evaluation_length_value2": {"table": 5, "row": 9, "col": 2, "transform": "raw"},
        "evaluation_length_ok2": {"table": 5, "row": 9, "col": 3, "transform": "checkbox"},
        "measurement_direction": {"table": 5, "row": 10, "col": 2, "transform": "raw"},
        "measurement_direction_ok": {"table": 5, "row": 10, "col": 3, "transform": "checkbox"},
        # 表6 3L 适用性
        "three_length_applicable": {"table": 6, "row": 0, "col": 2, "transform": "checkbox"},
        "three_length_not_applicable": {"table": 6, "row": 0, "col": 1, "transform": "checkbox"},
        # 表8 统计/结论
        "statistics_minmax": {"table": 8, "row": 1, "col": 1, "transform": "raw"},
        "statistics_failed": {"table": 8, "row": 2, "col": 1, "transform": "checkbox"},
        "three_length_conclusion": {"table": 8, "row": 3, "col": 1, "transform": "checkbox"},
        "final_verdict": {"table": 8, "row": 5, "col": 1, "transform": "checkbox"},
        "final_conclusion": {"table": 8, "row": 6, "col": 1, "transform": "text"},
        # 表9 异常/偏离
        "deviation_record": {"table": 9, "row": 1, "col": 2, "transform": "raw"},
        "deviation_affects_result": {"table": 9, "row": 1, "col": 5, "transform": "checkbox"},
    },

    "mc_crack": {
        "temperature_before": {"table": 1, "row": 1, "col": 2, "transform": "text"},
        "temperature_after": {"table": 1, "row": 1, "col": 3, "transform": "text"},
        "humidity_before": {"table": 1, "row": 2, "col": 2, "transform": "text"},
        "humidity_after": {"table": 1, "row": 2, "col": 3, "transform": "text"},
        "env_temp_ok": {"table": 1, "row": 1, "col": 4, "transform": "checkbox"},
        "env_humidity_ok": {"table": 1, "row": 2, "col": 4, "transform": "checkbox"},
        "fixture_record": {"table": 3, "row": 1, "col": 2, "transform": "text"},
        "support_span_record": {"table": 3, "row": 2, "col": 2, "transform": "text"},
        "roller_radius_record": {"table": 3, "row": 3, "col": 2, "transform": "text"},
        "parallel_block_record": {"table": 3, "row": 6, "col": 2, "transform": "text"},
        "parallel_block_parallelism": {"table": 3, "row": 7, "col": 2, "transform": "text"},
        "parallel_check_record": {"table": 3, "row": 9, "col": 2, "transform": "text"},
        "sample_record": {"table": 4, "row": 1, "col": 1, "transform": "text"},
        "em_record": {"table": 4, "row": 2, "col": 1, "transform": "text"},
        "k_value_note": {"table": 4, "row": 3, "col": 1, "transform": "checkbox"},
        "count_conform": {"table": 7, "row": 1, "col": 1, "transform": "text"},
        "has_nonconform": {"table": 7, "row": 2, "col": 1, "transform": "checkbox"},
        "attachment_ref_t7": {"table": 7, "row": 4, "col": 1, "transform": "text"},
        "final_verdict": {"table": 7, "row": 5, "col": 1, "transform": "checkbox"},
    },

    "xray": {
        "start_time": {"table": 2, "row": 0, "col": 1, "transform": "text"},
        "end_time": {"table": 2, "row": 0, "col": 3, "transform": "text"},
        "operator_t2": {"table": 2, "row": 0, "col": 5, "transform": "text"},
        "temperature_before": {"table": 2, "row": 1, "col": 1, "transform": "text"},
        "temperature_ok": {"table": 2, "row": 1, "col": 5, "transform": "checkbox"},
        "humidity_before": {"table": 2, "row": 2, "col": 1, "transform": "text"},
        "humidity_ok": {"table": 2, "row": 2, "col": 5, "transform": "checkbox"},
        "density_mean": {"table": 4, "row": 1, "col": 5, "transform": "text"},
        "density_verdict": {"table": 4, "row": 1, "col": 7, "transform": "checkbox"},
        "sample_no_t7": {"table": 7, "row": 0, "col": 2, "transform": "text"},
        "image_no_t7": {"table": 7, "row": 0, "col": 6, "transform": "text"},
        "test_date": {"table": 7, "row": 0, "col": 10, "transform": "text"},
        "software": {"table": 7, "row": 1, "col": 2, "transform": "text"},
        "operator_t7": {"table": 7, "row": 1, "col": 6, "transform": "text"},
        "reviewer_t7": {"table": 7, "row": 1, "col": 10, "transform": "text"},
    },

    # 翘曲变形全为 per-row 循环（动态行），无静态单元格
    "warp": {},

    "cte": {
        "temperature_before": {"table": 1, "row": 1, "col": 2, "transform": "text"},
        "humidity_before": {"table": 1, "row": 2, "col": 2, "transform": "text"},
        "final_verdict": {"table": 8, "row": 0, "col": 1, "transform": "checkbox"},
        "alpha_mean": {"table": 8, "row": 1, "col": 1, "transform": "text"},
        "delta_l_max": {"table": 8, "row": 2, "col": 1, "transform": "text"},
        "temperature_range": {"table": 8, "row": 1, "col": 3, "transform": "raw"},
        "attachment_ref_t8": {"table": 8, "row": 2, "col": 3, "transform": "text"},
    },

    "shock": {
        "temperature_before": {"table": 1, "row": 1, "col": 2, "transform": "text"},
        "temperature_after": {"table": 1, "row": 1, "col": 3, "transform": "text"},
        "humidity_before": {"table": 1, "row": 2, "col": 2, "transform": "text"},
        "humidity_after": {"table": 1, "row": 2, "col": 3, "transform": "text"},
        "env_temp_ok": {"table": 1, "row": 1, "col": 4, "transform": "checkbox"},
        "env_humidity_ok": {"table": 1, "row": 2, "col": 4, "transform": "checkbox"},
        "illumination_col2": {"table": 1, "row": 3, "col": 2, "transform": "text"},
        "illumination_col3": {"table": 1, "row": 3, "col": 3, "transform": "text"},
        "illumination_ok": {"table": 1, "row": 3, "col": 4, "transform": "checkbox"},
        "appearance_check": {"table": 4, "row": 1, "col": 2, "transform": "checkbox"},
        "oven_temperature_record": {"table": 4, "row": 2, "col": 2, "transform": "text"},
        "first_heating_record": {"table": 4, "row": 3, "col": 2, "transform": "text"},
        "ice_bath_record": {"table": 4, "row": 4, "col": 2, "transform": "text"},
        "ice_water_record": {"table": 4, "row": 5, "col": 2, "transform": "text"},
        "transfer_time_record": {"table": 4, "row": 6, "col": 2, "transform": "text"},
        "ice_immersion_record": {"table": 4, "row": 7, "col": 2, "transform": "text"},
        "second_heating_record": {"table": 4, "row": 8, "col": 2, "transform": "text"},
        "container_no": {"table": 6, "row": 1, "col": 0, "transform": "text"},
        "sample_count": {"table": 6, "row": 1, "col": 1, "transform": "text"},
        "first_heating_interval": {"table": 6, "row": 1, "col": 2, "transform": "text"},
        "transfer_interval": {"table": 6, "row": 1, "col": 3, "transform": "text"},
        "immersion_interval": {"table": 6, "row": 1, "col": 4, "transform": "text"},
        "second_heating_interval": {"table": 6, "row": 1, "col": 5, "transform": "text"},
        "cooling_temp_record": {"table": 7, "row": 1, "col": 2, "transform": "text"},
        "surface_temp_record": {"table": 7, "row": 2, "col": 2, "transform": "text"},
        "cooling_record": {"table": 7, "row": 3, "col": 2, "transform": "text"},
        "illumination_record": {"table": 7, "row": 4, "col": 2, "transform": "text"},
        "inspector_record": {"table": 7, "row": 5, "col": 2, "transform": "text"},
        "total_count": {"table": 9, "row": 0, "col": 1, "transform": "text"},
        "total_count_2": {"table": 9, "row": 0, "col": 3, "transform": "text"},
        "crack_count": {"table": 9, "row": 1, "col": 1, "transform": "text"},
        "chipping_count": {"table": 9, "row": 1, "col": 3, "transform": "text"},
        "fracture_count": {"table": 9, "row": 2, "col": 1, "transform": "text"},
        "final_verdict": {"table": 9, "row": 3, "col": 3, "transform": "checkbox"},
        "final_conclusion": {"table": 9, "row": 4, "col": 1, "transform": "checkbox"},
    },

    "bend": {
        "overall_verdict": {"table": 4, "row": 7, "col": 0, "transform": "checkbox"},
        "attachment_ref_t7": {"table": 7, "row": 0, "col": 1, "transform": "text"},
        "has_attachment_a": {"table": 7, "row": 1, "col": 1, "transform": "checkbox"},
        "has_attachment_b": {"table": 7, "row": 1, "col": 3, "transform": "checkbox"},
    },

    "hv": {
        "standard_block_due": {"table": 2, "row": 1, "col": 5, "transform": "text"},
        "std_reading_1": {"table": 2, "row": 2, "col": 3, "transform": "text"},
        "std_reading_2": {"table": 2, "row": 2, "col": 5, "transform": "text"},
        "std_reading_3": {"table": 2, "row": 3, "col": 1, "transform": "text"},
        "std_reading_mean": {"table": 2, "row": 3, "col": 3, "transform": "text"},
        "std_result": {"table": 2, "row": 3, "col": 5, "transform": "checkbox"},
        "surface_verdict": {"table": 2, "row": 4, "col": 5, "transform": "checkbox"},
        "surface_condition": {"table": 2, "row": 5, "col": 1, "transform": "checkbox"},
        "perpendicularity": {"table": 2, "row": 5, "col": 5, "transform": "checkbox"},
        "indent_method": {"table": 3, "row": 1, "col": 1, "transform": "checkbox"},
        "report_exported": {"table": 3, "row": 2, "col": 3, "transform": "checkbox"},
        "report_exported_ok": {"table": 3, "row": 2, "col": 5, "transform": "checkbox"},
    },

    "thickness": {
        "sample_batch": {"table": 0, "row": 7, "col": 1, "transform": "text"},
        "production_date": {"table": 0, "row": 7, "col": 3, "transform": "text"},
        "design_file_no": {"table": 0, "row": 7, "col": 5, "transform": "text"},
        "magnification_record": {"table": 2, "row": 1, "col": 2, "transform": "text"},
        "preheat_record": {"table": 2, "row": 2, "col": 2, "transform": "text"},
        "calibration_record": {"table": 2, "row": 3, "col": 2, "transform": "text"},
    },

    "color": {
        "temperature_before": {"table": 1, "row": 0, "col": 1, "transform": "text"},
        "humidity_before": {"table": 1, "row": 0, "col": 5, "transform": "text"},
        "lightbox_type": {"table": 1, "row": 2, "col": 1, "transform": "checkbox"},
        "lightbox_clean": {"table": 1, "row": 2, "col": 5, "transform": "checkbox"},
        "lightbox_confirmed": {"table": 1, "row": 3, "col": 5, "transform": "checkbox"},
        "lamp_no": {"table": 4, "row": 0, "col": 1, "transform": "text"},
        "lamp_hours": {"table": 4, "row": 0, "col": 3, "transform": "text"},
        "filter_no": {"table": 4, "row": 1, "col": 1, "transform": "text"},
        "filter_hours": {"table": 4, "row": 1, "col": 3, "transform": "text"},
        "lamp_calibrated": {"table": 4, "row": 2, "col": 3, "transform": "checkbox"},
        "lamp_history": {"table": 4, "row": 3, "col": 3, "transform": "checkbox"},
        "source_type": {"table": 5, "row": 1, "col": 2, "transform": "checkbox"},
        "water_temp_record": {"table": 5, "row": 2, "col": 2, "transform": "text"},
        "sample_illuminance": {"table": 5, "row": 3, "col": 2, "transform": "text"},
        "water_distance": {"table": 5, "row": 4, "col": 2, "transform": "text"},
        "exposure_time_record": {"table": 5, "row": 5, "col": 2, "transform": "text"},
        "sample_placement": {"table": 5, "row": 6, "col": 2, "transform": "checkbox"},
        "device_status": {"table": 5, "row": 7, "col": 2, "transform": "checkbox"},
        "exposure_start": {"table": 7, "row": 0, "col": 1, "transform": "text"},
        "exposure_end": {"table": 7, "row": 0, "col": 3, "transform": "text"},
        "exposure_time": {"table": 7, "row": 1, "col": 1, "transform": "text"},
        "exposure_ok": {"table": 7, "row": 1, "col": 3, "transform": "checkbox"},
        "attachment_ref_t7": {"table": 7, "row": 2, "col": 1, "transform": "text"},
        "trace_ref": {"table": 7, "row": 2, "col": 3, "transform": "text"},
        "has_attachment_a": {"table": 7, "row": 3, "col": 1, "transform": "checkbox"},
        "has_attachment_b": {"table": 7, "row": 3, "col": 3, "transform": "checkbox"},
        "sample_handling": {"table": 9, "row": 0, "col": 1, "transform": "checkbox"},
        "handling_status": {"table": 9, "row": 0, "col": 3, "transform": "checkbox"},
        "lamp_box_ready": {"table": 9, "row": 1, "col": 1, "transform": "checkbox"},
        "d65_illuminance": {"table": 9, "row": 1, "col": 3, "transform": "text"},
        "background": {"table": 9, "row": 2, "col": 1, "transform": "checkbox"},
        "background_ok": {"table": 9, "row": 2, "col": 3, "transform": "checkbox"},
        "observation_distance": {"table": 9, "row": 3, "col": 1, "transform": "text"},
        "single_observation_time": {"table": 9, "row": 3, "col": 3, "transform": "text"},
        "observation_conditions": {"table": 9, "row": 4, "col": 1, "transform": "checkbox"},
        "observation_date": {"table": 9, "row": 4, "col": 3, "transform": "text"},
        "overall_verdict": {"table": 11, "row": 13, "col": 2, "transform": "checkbox"},
        "final_verdict": {"table": 11, "row": 13, "col": 7, "transform": "checkbox"},
    },

    "fixed_denture": {
        "porosity_result": {"table": 10, "row": 1, "col": 1, "transform": "checkbox"},
        "roughness_result": {"table": 10, "row": 4, "col": 1, "transform": "checkbox"},
        "final_verdict": {"table": 10, "row": 5, "col": 1, "transform": "checkbox"},
        "attachment_ref_t10": {"table": 10, "row": 6, "col": 1, "transform": "text"},
    },

    "removable_denture": {
        "attachment_ref_t9a": {"table": 9, "row": 2, "col": 1, "transform": "text"},
        "iqi_no": {"table": 9, "row": 3, "col": 1, "transform": "text"},
        "attachment_ref_t9b": {"table": 9, "row": 6, "col": 1, "transform": "text"},
        "xray_conclusion": {"table": 9, "row": 10, "col": 1, "transform": "checkbox"},
        "cutting_device_no": {"table": 10, "row": 1, "col": 2, "transform": "text"},
        "outer_angle": {"table": 10, "row": 2, "col": 3, "transform": "text"},
        "termination_outer": {"table": 10, "row": 2, "col": 4, "transform": "checkbox"},
        "inner_angle": {"table": 10, "row": 3, "col": 3, "transform": "text"},
        "termination_inner": {"table": 10, "row": 3, "col": 4, "transform": "checkbox"},
        "same_vertical": {"table": 10, "row": 4, "col": 3, "transform": "checkbox"},
        "termination_vertical": {"table": 10, "row": 4, "col": 4, "transform": "checkbox"},
        "upper_no_pore_faces": {"table": 11, "row": 1, "col": 7, "transform": "text"},
        "porosity_upper": {"table": 11, "row": 1, "col": 8, "transform": "checkbox"},
        "lower_no_pore_faces": {"table": 11, "row": 2, "col": 7, "transform": "text"},
        "porosity_lower": {"table": 11, "row": 2, "col": 8, "transform": "checkbox"},
        "final_conclusion": {"table": 15, "row": 1, "col": 1, "transform": "checkbox"},
        "final_no": {"table": 15, "row": 4, "col": 1, "transform": "checkbox"},
    },

    "density": {
        "balance_calibration": {"table": 2, "row": 0, "col": 7, "transform": "checkbox"},
        "system_check": {"table": 3, "row": 6, "col": 6, "transform": "checkbox"},
        "auto_calc_check": {"table": 4, "row": 4, "col": 5, "transform": "checkbox"},
        "overall_mean": {"table": 7, "row": 7, "col": 3, "transform": "text"},
        "overall_mean_1dp": {"table": 7, "row": 7, "col": 8, "transform": "text"},
        "overall_verdict": {"table": 7, "row": 7, "col": 10, "transform": "checkbox"},
        "declared_source": {"table": 10, "row": 1, "col": 1, "transform": "text"},
        "declared_density": {"table": 10, "row": 1, "col": 3, "transform": "text"},
        "density_verdict": {"table": 10, "row": 3, "col": 1, "transform": "checkbox"},
        "attachment_ref_t10": {"table": 10, "row": 4, "col": 1, "transform": "text"},
    },

    "tarnish": {
        "bath_volume": {"table": 5, "row": 1, "col": 2, "transform": "text"},
        "bath_temperature": {"table": 5, "row": 2, "col": 2, "transform": "text"},
        "cycle_immersion_seconds": {"table": 5, "row": 3, "col": 2, "transform": "text"},
        "solution_change_24h": {"table": 5, "row": 5, "col": 2, "transform": "text"},
        "solution_change_48h": {"table": 5, "row": 6, "col": 2, "transform": "text"},
        "total_duration": {"table": 5, "row": 7, "col": 2, "transform": "text"},
        "bath_status": {"table": 5, "row": 8, "col": 2, "transform": "checkbox"},
        "observation_illuminance": {"table": 7, "row": 2, "col": 3, "transform": "text"},
        "observation_distance": {"table": 7, "row": 3, "col": 3, "transform": "text"},
        "immersed_color_change": {"table": 7, "row": 5, "col": 1, "transform": "text"},
        "control_color_change": {"table": 7, "row": 5, "col": 2, "transform": "text"},
        "reflectance_change": {"table": 7, "row": 6, "col": 1, "transform": "text"},
        "tarnish_product": {"table": 7, "row": 7, "col": 1, "transform": "text"},
        "immersed_sample_no": {"table": 8, "row": 1, "col": 0, "transform": "text"},
        "removal_ease": {"table": 8, "row": 1, "col": 3, "transform": "checkbox"},
        "color_change_verdict": {"table": 9, "row": 1, "col": 1, "transform": "checkbox"},
        "removal_ease_verdict": {"table": 9, "row": 2, "col": 1, "transform": "checkbox"},
        "reflectance_verdict": {"table": 9, "row": 3, "col": 1, "transform": "text"},
        "tarnish_verdict": {"table": 9, "row": 4, "col": 1, "transform": "checkbox"},
        "result_valid": {"table": 12, "row": 1, "col": 1, "transform": "checkbox"},
        "final_conclusion": {"table": 12, "row": 2, "col": 1, "transform": "checkbox"},
        "attachment_ref_t12": {"table": 12, "row": 4, "col": 3, "transform": "text"},
    },
}


def get_constants(extra_json: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    """DB extra_json.constants 优先，硬编码 CONSTANTS 兜底（浅合并一层）。"""
    result = copy.deepcopy(CONSTANTS)
    extra = (extra_json or {}).get("constants") or {}
    if isinstance(extra, dict):
        for section in ("devices", "thresholds", "fixed_text"):
            db_section = extra.get(section)
            if isinstance(db_section, dict):
                result.setdefault(section, {}).update(db_section)
    return result


def get_field_map(kind: str, db_mappings: list[dict[str, Any]] | None = None) -> dict[str, dict[str, Any]]:
    """DB template_field_mappings 优先，硬编码 FIELD_MAPPINGS[kind] 兜底。

    db_mappings: template_field_mappings 行（含 field_key/table_index/row_index/col_index/transform）。
    """
    result = copy.deepcopy(FIELD_MAPPINGS.get(kind, {}))
    for row in (db_mappings or []):
        if not isinstance(row, dict):
            continue
        key = row.get("field_key")
        if not key:
            continue
        result[key] = {
            "table": int(row.get("table_index", 0)),
            "row": int(row.get("row_index", 0)),
            "col": int(row.get("col_index", 0)),
            "transform": row.get("transform") or "text",
        }
    return result


def kind_field_mappings(kind: str) -> dict[str, dict[str, Any]]:
    """返回某 kind 的静态坐标兜底（种子脚本据此灌库）。"""
    return copy.deepcopy(FIELD_MAPPINGS.get(kind, {}))
