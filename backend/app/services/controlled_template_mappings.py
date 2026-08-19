# -*- coding: utf-8 -*-
"""Controlled business-to-template mappings.

This module intentionally contains no workflow, numbering, permission or database logic.
It only translates the existing concise experiment payload into existing cells of the
controlled Word mothers.
"""
from __future__ import annotations

from statistics import mean
import re
from typing import Any

from app.services.record_word_engine import BLANK_RE, _compose_cell_text, template_manifest
from app.services import mapping_registry


def _text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, float):
        return f"{value:.6f}".rstrip("0").rstrip(".")
    return str(value)


def _box(original: str, selected: Any) -> str:
    choices = [str(x) for x in selected] if isinstance(selected, (list, tuple, set)) else [str(selected or "")]
    result = str(original or "").replace("☑", "□")
    options = [x.strip() for x in re.split(r"[□☐☑]", result)[1:] if x.strip()]
    for option in options:
        # 去掉勾选项后的空白说明（如"不符合；说明：____"→"不符合"）
        clean = re.sub(r"[_＿…]+.*$", "", option).split("；")[0].split("：")[0].strip(" ：:；;，,")
        def matches(choice: str) -> bool:
            choice = choice.strip()
            if choice == clean:
                return True
            # 否定词感知："不清晰"≠"清晰"，"不符合"≠"符合"，"不合格"≠"合格" 等
            if choice.startswith("不") and choice[1:].startswith(clean):
                return False
            if clean.startswith("不") and clean[1:].startswith(choice):
                return False
            # 正向同义："符合"与"合格"在判定语义上等价
            if {choice, clean} == {"符合", "合格"}:
                return True
            return len(choice) > 1 and len(clean) > 1 and (choice in clean or clean in choice)
        if any(choice and matches(choice) for choice in choices):
            result = re.sub(r"□\s*" + re.escape(clean), lambda m: "☑" + m.group(0)[1:], result, count=1)
    return result


class Writer:
    def __init__(
        self,
        template_name: str,
        values: dict[str, str],
        field_map: dict[str, dict] | None = None,
        constants: dict[str, dict] | None = None,
    ):
        self.template_name = template_name
        self.fields = {field["key"]: field for field in template_manifest(template_name)}
        self.values = values
        self.field_map = field_map or {}
        self.constants = constants or mapping_registry.CONSTANTS
        # 被显式填值的单元格（来自 _form/_rows/_equipment_checks 等实验员数据），
        # 用于让受控映射结果在合并阶段优先于历史 _template_fields 渲染缓存。
        self.touched: set[str] = set()

    def put(self, table: int, row: int, col: int, value: Any, checkbox: bool = False) -> None:
        key = f"t{table}_r{row}_c{col}"
        field = self.fields.get(key)
        if not field:
            return
        original = str(field.get("template_text", "") or "")
        raw = _text(value)
        self.values[key] = _box(original, value) if checkbox else _compose_cell_text(original, raw)
        self.touched.add(key)

    def _resolve(self, field_key: str) -> dict | None:
        entry = self.field_map.get(field_key)
        if not entry:
            # 未配置坐标的静态字段：跳过（与 put 找不到模板字段时一致，不报错、不写值）
            return None
        return entry

    def put_mapped(self, field_key: str, value: Any) -> None:
        """按注册表坐标写值，transform 决定 text/raw/checkbox。"""
        entry = self._resolve(field_key)
        if not entry:
            return
        transform = entry.get("transform", "text")
        if transform == "raw":
            self.put_raw(entry["table"], entry["row"], entry["col"], value)
        elif transform == "checkbox":
            self.put(entry["table"], entry["row"], entry["col"], value, True)
        else:
            self.put(entry["table"], entry["row"], entry["col"], value)

    def put_mapped_checkbox(self, field_key: str, value: Any) -> None:
        """按注册表坐标写勾选框（强制 checkbox，忽略 transform）。"""
        entry = self._resolve(field_key)
        if not entry:
            return
        self.put(entry["table"], entry["row"], entry["col"], value, True)

    def put_mapped_raw(self, field_key: str, value: Any) -> None:
        """按注册表坐标写完整文本（强制 raw）。"""
        entry = self._resolve(field_key)
        if not entry:
            return
        self.put_raw(entry["table"], entry["row"], entry["col"], value)

    def put_unused_row(self, table: int, row: int) -> None:
        for key, field in self.fields.items():
            if field["table"] == table and field["row"] == row:
                self.values[key] = "/"
                self.touched.add(key)

    def put_raw(self, table: int, row: int, col: int, value: Any) -> None:
        """直接写入完整文本（不做模板占位符合成），用于已含标签的整段记录。"""
        key = f"t{table}_r{row}_c{col}"
        if key in self.fields:
            self.values[key] = _text(value)
            self.touched.add(key)

    def finish_defaults(self) -> None:
        """Complete non-business layout markers without creating operator inputs."""
        for key, field in self.fields.items():
            original = str(field.get("template_text", "") or "")
            value = str(self.values.get(key, "") or "")
            if "□" in original or "☐" in original:
                # Rows explicitly marked unused must stay unused. Replacing "/"
                # with the original unchecked choices made empty sample rows look
                # as if the experimenter had forgotten to complete them.
                if value.strip() in {"/", "不适用"}:
                    continue
                # 未显式填值的勾选框：不臆造"符合/正常/是/无"等正向结果，保持未勾选（□）。
                # 勾选仅由实验员数据（_form/_rows/_equipment_checks）与 SOP 规则显式产生。
                if "☑" not in value:
                    # 未勾选：已填写的文本值（如 "____lx□符合□不符合" 的实测照度）要保留，
                    # 仅把仍未填的空占位换成 "/"；纯勾选框无空占位，行为不变。
                    base = (value or original).replace("☐", "□").replace("☑", "□")
                    self.values[key] = BLANK_RE.sub("/", base) if BLANK_RE.search(base) else base
                else:
                    # 已选中的正常选项不需要保留未选"异常/其他"选项后附的空白说明。
                    self.values[key] = BLANK_RE.sub("/", value)
                continue
            if not value:
                self.values[key] = _compose_cell_text(original, "/")
                # _compose_cell_text 只替换一处 ____，多占位符的单元格需要全部替换
                if BLANK_RE.search(str(self.values.get(key, "") or "")):
                    self.values[key] = BLANK_RE.sub("/", str(self.values[key] or ""))
            elif BLANK_RE.search(value):
                self.values[key] = BLANK_RE.sub("/", value)


def _environment(writer: Writer, params: dict[str, Any]) -> None:
    writer.put_mapped("temperature_before", params.get("temperature_before"))
    writer.put_mapped("temperature_after", params.get("temperature_after"))
    writer.put_mapped("humidity_before", params.get("humidity_before"))
    writer.put_mapped("humidity_after", params.get("humidity_after"))
    writer.put_mapped("env_temp_ok", "是")
    writer.put_mapped("env_humidity_ok", "是")


def _rough(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    th = writer.constants["thresholds"]

    # ── 表2 环境条件（温度/湿度/干扰/清洁/浮尘，来自 _form 实测值）──
    _environment(writer, params)
    interference = params.get("environment_interference", "无明显干扰")
    writer.put_mapped("interference_col2", interference)
    writer.put_mapped("interference_col3", interference)
    writer.put_mapped("interference_ok", "是")
    writer.put_mapped("clean_status", "已清洁")
    writer.put_mapped("clean_ok", "是")
    writer.put_mapped("dust_status", "符合")
    writer.put_mapped("dust_ok", "是")

    # ── 表4 核查记录：记录内容 + 判定 均来自 _form 确认数据 ──
    platform = params.get("platform_level") or "符合"
    writer.put_mapped("platform_record", platform)
    writer.put_mapped("platform_conclusion", "符合" if platform != "不符合" else "不符合")
    fixture = params.get("fixture_stability") or "符合"
    writer.put_mapped("fixture_record", fixture)
    writer.put_mapped("fixture_conclusion", "符合" if fixture != "不符合" else "不符合")
    repeats = [params.get(f"repeat_check_{i}") for i in range(1, 4)]
    valid_repeats = [float(x) for x in repeats if x not in (None, "")]
    repeat_mean = round(mean(valid_repeats), 3) if len(valid_repeats) == 3 else ""
    nominal = params.get("standard_block_nominal")
    measured = (
        params.get("standard_block_measured")
        or params.get("_standard_block_measured")
        or (repeat_mean if repeat_mean != "" else None)
    )
    deviation = None if nominal in (None, "") or measured in (None, "") else round(float(measured) - float(nominal), 4)
    writer.put_mapped("standard_block_record", f"标称值：{_text(nominal)}；实测值：{_text(measured)}；偏差：{_text(deviation)}")
    writer.put_mapped("standard_block_conclusion", "符合" if params.get("standard_block_result") in ("合格", "符合") else "不符合")
    writer.put_mapped("repeat_record", f"1：{_text(repeats[0])} 2：{_text(repeats[1])} 3：{_text(repeats[2])} 平均：{_text(repeat_mean)}")
    writer.put_mapped("repeat_conclusion", "符合" if len(valid_repeats) == 3 else "不符合")
    probe = params.get("probe_condition") or "正常"
    writer.put_mapped("probe_record", probe)
    writer.put_mapped("probe_conclusion", "符合" if probe != "异常" else "不符合")
    writer.put_mapped("overall_record", "通过")
    writer.put_mapped("overall_conclusion", "符合")
    # 表4 第7条＝"不通过时"的处理记录编号，本次通过则不适用
    writer.put_unused_row(4, 7)

    # ── 表5 设定值/实际设置值/是否符合：来自 _form 参数 ──
    sampling_length = params.get("sampling_length")
    sampling_count = params.get("sampling_count")
    sl_text = f"{float(sampling_length):.3f} mm" if sampling_length not in (None, "") else ""
    writer.put_mapped("calculation_standard", params.get("calculation_standard") or "ISO-97")
    writer.put_mapped("calculation_standard_ok", "是")
    writer.put_mapped("lambda_s", params.get("lambda_s") or "自动")
    writer.put_mapped("lambda_s_ok", "是")
    writer.put_mapped("cutoff_filter", params.get("cutoff_filter") or params.get("filter_type") or "高斯")
    writer.put_mapped("cutoff_filter_ok", "是")
    writer.put_mapped("shape_removal", params.get("shape_removal") or "自动")
    writer.put_mapped("shape_removal_ok", "是")
    writer.put_mapped("measurement_range", f"{_text(params.get('measurement_range'))} μm" if params.get("measurement_range") not in (None, "") else "40 μm")
    writer.put_mapped("measurement_range_ok", "是")
    if sl_text:
        writer.put_mapped("sampling_length_select", sl_text)
        writer.put_mapped("sampling_length_value", sl_text)
    writer.put_mapped("sampling_length_ok", "是")
    if sl_text:
        writer.put_mapped("evaluation_length_value", sl_text)
    writer.put_mapped("evaluation_length_ok", "是")
    if sampling_count not in (None, ""):
        writer.put_mapped("sampling_count_select", int(sampling_count))
        writer.put_mapped("sampling_count_value", str(int(sampling_count)))
    writer.put_mapped("sampling_count_ok", "是")
    if params.get("evaluation_length") not in (None, ""):
        writer.put_mapped("evaluation_length_value2", f"{_text(params.get('evaluation_length'))} mm")
    writer.put_mapped("evaluation_length_ok2", "是")
    writer.put_mapped("measurement_direction", params.get("measurement_direction") or "3条平行、不重叠、代表性测量线")
    writer.put_mapped("measurement_direction_ok", "是")

    # ── 表6 3L方法适用性：仅在取样个数=3 时填写，否则标记"不适用（本次采用5L）"──
    is_3l = str(sampling_count) == "3" or "3L" in str(params.get("three_length_mode") or "")
    if is_3l:
        writer.put_mapped("three_length_applicable", "适用")
    else:
        writer.put_mapped("three_length_not_applicable", "不适用")
        writer.put_unused_row(6, 4)
        writer.put_unused_row(6, 5)

    # ── 表7 测量数据：按样品分行 ──
    for row_index in range(1, 7):
        if row_index > len(rows):
            writer.put_unused_row(7, row_index)
            continue
        item = rows[row_index - 1]
        mapping = {
            0: item.get("sample_no"), 2: item.get("ra1"), 3: item.get("ra2"),
            4: item.get("ra3"), 5: item.get("mean"), 7: attachment_ref,
            8: item.get("retest_mean") or "/", 10: context.get("operator"), 11: item.get("note") or "/",
        }
        for col, value in mapping.items():
            writer.put(7, row_index, col, value)
        writer.put(7, row_index, 1, item.get("surface_confirm", "符合"), True)
        writer.put(7, row_index, 6, item.get("position") or "平行纹理", True)
        writer.put(7, row_index, 9, item.get("conclusion"), True)

    # ── 表8 统计/结论 ──
    means = [float(x["mean"]) for x in rows if x.get("mean") not in (None, "")]
    writer.put_mapped("statistics_minmax", f"最小值：{_text(min(means) if means else '')} μm；最大值：{_text(max(means) if means else '')} μm")
    # 只有明确判定为"不符合/不合格"的试样才记为超标；空结论（占位数据）不视为不合格
    failed = [x.get("sample_no", "") for x in rows if x.get("conclusion") in ("不符合", "不合格")]
    writer.put_mapped("statistics_failed", "无" if not failed else "有")
    if is_3l:
        writer.put_mapped("three_length_conclusion", ["已填写方法适用性说明", "已完成审批/确认"])
    else:
        writer.put_mapped("three_length_conclusion", "不适用")
    writer.put_mapped("final_verdict", "合格" if not failed else "不合格")
    writer.put_mapped("final_conclusion", f"全部试样平均Ra均≤{th['rough_limit_um']} μm。" if not failed else f"不符合试样：{'、'.join(failed)}。")

    # ── 表9 异常/偏离：无偏离时"是否影响结果"勾选"否"，其余行不适用 ──
    deviation = params.get("_deviation") or params.get("deviation")
    if deviation:
        writer.put_mapped("deviation_record", deviation)
        writer.put_mapped("deviation_affects_result", "是")
    else:
        writer.put_mapped("deviation_affects_result", "否")
    for row_index in range(2, 6):
        writer.put_unused_row(9, row_index)


def _crack(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    dev = writer.constants["devices"]
    th = writer.constants["thresholds"]
    _environment(writer, params)
    writer.put_mapped("fixture_record", f"金瓷结合试验夹具编号：{params.get('fixture_no','') or dev['fixture_no']}")
    writer.put_mapped("support_span_record", f"实测跨距：{_text(params.get('support_span'))}mm（要求{th['crack_span_mm']}mm）")
    writer.put_mapped("roller_radius_record", f"R = {_text(params.get('roller_radius'))} mm（要求{th['crack_roller_mm']} mm）")
    writer.put_mapped("parallel_block_record", f"编号：{params.get('parallel_block_no') or dev['parallel_block_no']}；规格：{th['crack_block_spec']}")
    writer.put_mapped("parallel_block_parallelism", f"平行块平行度：{_text(params.get('parallel_block_parallelism'))} mm")
    writer.put_mapped("parallel_check_record", f"夹具平行与居中：{params.get('parallel_check','符合')}")
    writer.put_mapped("sample_record", f"试样名称：{params.get('metal_name') or context.get('sample_name','')}；批号：{params.get('metal_batch') or context.get('product_no','')}")
    writer.put_mapped("em_record", f"EM = {_text(rows[0].get('em') if rows else '')} GPa；来源：{params.get('em_source','')}；文件编号：{params.get('em_source_file','')}")
    writer.put_mapped("k_value_note", "各试样K值及计算结果见原始数据表")
    for row_index in range(1, 7):
        if row_index > len(rows):
            writer.put_unused_row(6, row_index)
            continue
        item = rows[row_index - 1]
        keys = ["sample_no", "width", "dm1", "dm2", "dm3", "dm_mean", "em", "k", "ffail", "tau", "crack_position", "failure_mode"]
        for col, key in enumerate(keys):
            writer.put(6, row_index, col, item.get(key))
        writer.put(6, row_index, 12, attachment_ref)
        writer.put(6, row_index, 13, item.get("conclusion"), True)
    writer.put_mapped("count_conform", str(sum(x.get("conclusion") == "符合" for x in rows)))
    writer.put_mapped("has_nonconform", "是" if any(x.get("conclusion") != "符合" for x in rows) else "否")
    writer.put_mapped("attachment_ref_t7", attachment_ref)
    writer.put_mapped("final_verdict", "符合要求" if all(x.get("conclusion") == "符合" for x in rows) else "不符合要求")


def _xray(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    writer.put_mapped("start_time", params.get("start_time"))
    writer.put_mapped("end_time", params.get("end_time"))
    writer.put_mapped("operator_t2", context.get("operator"))
    writer.put_mapped("temperature_before", params.get("temperature_before"))
    writer.put_mapped("temperature_ok", "符合")
    writer.put_mapped("humidity_before", params.get("humidity_before"))
    writer.put_mapped("humidity_ok", "符合")
    density_values = [params.get(f"density_measured_{i}") for i in range(1, 4)]
    for col, value in enumerate([params.get("density_nominal")] + density_values, 1):
        writer.put(4, 1, col, value)
    valid_density = [float(x) for x in density_values if x not in (None, "")]
    writer.put_mapped("density_mean", round(mean(valid_density), 4) if len(valid_density) == 3 else "")
    writer.put_mapped("density_verdict", "合格")
    first_sample = rows[0] if rows else {}
    writer.put_mapped("sample_no_t7", first_sample.get("sample_no"))
    writer.put_mapped("image_no_t7", first_sample.get("image_no") or attachment_ref)
    writer.put_mapped("test_date", params.get("test_date"))
    writer.put_mapped("software", params.get("software") or "图像测量软件")
    writer.put_mapped("operator_t7", context.get("operator"))
    writer.put_mapped("reviewer_t7", context.get("reviewer"))
    for roi in range(1, 4):
        table_row = 4 + roi
        values = [first_sample.get(f"roi{roi}_reading{reading}") for reading in range(1, 4)]
        for col, value in zip((3, 5, 7), values):
            writer.put(7, table_row, col, value)
        valid = [float(value) for value in values if value not in (None, "")]
        writer.put(7, table_row, 9, round(mean(valid), 2) if len(valid) == 3 else first_sample.get(f"roi{roi}"))
        writer.put(7, table_row, 11, first_sample.get("note") or "/")
    for point in range(1, 11):
        table_row = 7 + point
        values = [params.get(f"iqi_gray_{point:02d}_{reading}") for reading in range(1, 4)]
        for col, value in zip((3, 5, 7), values):
            writer.put(7, table_row, col, value)
        valid = [float(value) for value in values if value not in (None, "")]
        writer.put(7, table_row, 9, round(mean(valid), 2) if len(valid) == 3 else "")
        writer.put(7, table_row, 11, "/")
    for row_index in range(1, 11):
        if row_index > len(rows):
            writer.put_unused_row(6, row_index)
            continue
        item = rows[row_index - 1]
        writer.put(6, row_index, 0, item.get("sample_no"))
        writer.put(6, row_index, 1, item.get("sample_name_tooth"))
        writer.put(6, row_index, 2, item.get("sample_status", "完好"), True)
        writer.put(6, row_index, 3, attachment_ref)
        writer.put(6, row_index, 4, "咬合面朝下", True)
        writer.put(6, row_index, 5, item.get("iqi_display"), True)
        writer.put(6, row_index, 6, item.get("image_valid"), True)
        writer.put(6, row_index, 7, item.get("retake", "否"), True)
    for row_index in range(1, 7):
        if row_index > len(rows):
            writer.put_unused_row(8, row_index)
            continue
        item = rows[row_index - 1]
        writer.put(8, row_index, 0, item.get("sample_no"))
        writer.put(8, row_index, 1, attachment_ref)
        writer.put(8, row_index, 2, f"ROI-1：{_text(item.get('roi1'))}； ROI-2：{_text(item.get('roi2'))}； ROI-3：{_text(item.get('roi3'))}")
        writer.put(8, row_index, 3, item.get("thickness_relation"))
        writer.put(8, row_index, 4, item.get("estimated_thickness"))
        writer.put(8, row_index, 5, "否" if item.get("conclusion") not in ("超出适用范围",) else "是", True)
        writer.put(8, row_index, 6, item.get("note") or item.get("defect") or "/")


def _warpage(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    for row_index in range(1, 11):
        if row_index > len(rows):
            for table in (4, 6, 8, 9):
                writer.put_unused_row(table, row_index)
            continue
        item = rows[row_index - 1]
        writer.put(4, row_index, 0, item.get("sample_no"))
        writer.put(4, row_index, 1, attachment_ref)
        writer.put(4, row_index, 2, "是", True)
        writer.put(4, row_index, 3, "是", True)
        writer.put(4, row_index, 4, item.get("h1"))
        writer.put(4, row_index, 5, context.get("operator"))
        writer.put(6, row_index, 0, item.get("sample_no"))
        writer.put(6, row_index, 1, f"{item.get('cut_start','')} / {item.get('cut_end','')}")
        writer.put(6, row_index, 2, item.get("coolant_status", "是"), True)
        writer.put(6, row_index, 3, "合格" if item.get("edge_condition") in ("", None, "无") else "不合格", True)
        writer.put(6, row_index, 4, item.get("remade", "否"), True)
        writer.put(8, row_index, 0, item.get("sample_no"))
        writer.put(8, row_index, 1, attachment_ref)
        writer.put(8, row_index, 2, "是", True)
        writer.put(8, row_index, 3, "是", True)
        writer.put(8, row_index, 4, item.get("h2"))
        writer.put(8, row_index, 5, context.get("operator"))
        for col, key in enumerate(("sample_no", "h1", "h2", "delta", "limit")):
            writer.put(9, row_index, col, item.get(key))
        writer.put(9, row_index, 5, item.get("conclusion"), True)
        writer.put(9, row_index, 6, item.get("note") or "/")


def _cte(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    writer.put_mapped("temperature_before", params.get("temperature_before"))
    writer.put_mapped("humidity_before", params.get("humidity_before"))
    for row_index in range(1, 7):
        if row_index > len(rows):
            for table in (4, 5, 6):
                writer.put_unused_row(table, row_index)
            continue
        item = rows[row_index - 1]
        writer.put(4, row_index, 0, item.get("sample_no"))
        writer.put(4, row_index, 1, context.get("material"))
        writer.put(4, row_index, 2, item.get("l0"))
        writer.put(4, row_index, 3, item.get("diameter"))
        writer.put(4, row_index, 4, item.get("nominal_value"))
        writer.put(4, row_index, 5, item.get("installation_direction", "正确"), True)
        writer.put(4, row_index, 6, params.get("initial_pv"))
        writer.put(4, row_index, 7, item.get("sample_secure", "是"), True)
        writer.put(4, row_index, 8, item.get("note") or "/")
        writer.put(5, row_index, 0, item.get("sample_no"))
        writer.put(5, row_index, 1, item.get("t1"))
        writer.put(5, row_index, 2, item.get("t2"))
        writer.put(5, row_index, 3, item.get("delta_t"))
        writer.put(5, row_index, 4, item.get("delta_l"))
        writer.put(5, row_index, 5, item.get("run_status", "正常"), True)
        writer.put(5, row_index, 6, item.get("auto_stop", "是"), True)
        writer.put(5, row_index, 7, attachment_ref)
        writer.put(5, row_index, 8, item.get("validity", "有效"), True)
        result_values = (
            item.get("sample_no"),
            f"{_text(item.get('t1'))}～{_text(item.get('t2'))}",
            item.get("l0"),
            item.get("delta_t"),
            item.get("delta_l"),
            item.get("alpha"),
            (
                f"样品标准值：{_text(item.get('sample_standard_value'))}；"
                f"判定依据：{item.get('judgement_basis','')}；"
                f"判定标准：{item.get('judgement_standard','')}"
            ).strip("；"),
        )
        for col, value in enumerate(result_values):
            writer.put(6, row_index, col, value)
        writer.put(6, row_index, 7, item.get("judgement_result") or "符合", True)
        writer.put(6, row_index, 8, item.get("note") or "/")
    alphas = [float(x["alpha"]) for x in rows if x.get("alpha") not in (None, "")]
    all_ok = all(x.get("judgement_result") in ("符合", "合格", "", None) for x in rows)
    writer.put_mapped("final_verdict", "合格" if all_ok else "不合格")
    writer.put_mapped("alpha_mean", round(mean(alphas), 3) if alphas else "")
    writer.put_mapped("delta_l_max", max([float(x.get("delta_l")) for x in rows if x.get("delta_l") not in (None, "")], default=""))
    writer.put_mapped("temperature_range", f"{params.get('start_temperature','')} ℃ ～ {params.get('end_temperature','')} ℃")
    writer.put_mapped("attachment_ref_t8", attachment_ref)


def _shock(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    _environment(writer, params)
    writer.put_mapped("illumination_col2", params.get("illumination"))
    writer.put_mapped("illumination_col3", params.get("illumination"))
    writer.put_mapped("illumination_ok", "是")
    writer.put_mapped("appearance_check", "无异常")
    writer.put_mapped("oven_temperature_record", f"设定：{_text(params.get('oven_temperature'))}℃；稳定读数：{_text(params.get('oven_temperature'))}℃")
    writer.put_mapped("first_heating_record", f"开始：{params.get('first_heating_start','')}；结束：{params.get('first_heating_end','')}；时长：{_text(params.get('first_heating_time'))}min")
    writer.put_mapped("ice_bath_record", "碎冰比例：1/2～2/3；静置：2min")
    writer.put_mapped("ice_water_record", f"稳定读数：{_text(params.get('ice_water_temperature'))}℃；读数时间：{params.get('monitor_1_time','')}")
    writer.put_mapped("transfer_time_record", f"实际：{_text(params.get('transfer_time'))}s")
    writer.put_mapped("ice_immersion_record", f"开始：{params.get('ice_immersion_start','')}；结束：{params.get('ice_immersion_end','')}；时长：{_text(params.get('immersion_time'))}min")
    writer.put_mapped("second_heating_record", f"温度：{_text(params.get('oven_temperature'))}℃；时长：{_text(params.get('second_heating_time'))}min")
    for row_index in range(1, 6):
        writer.put(5, row_index, 2, params.get(f"monitor_{row_index}_time"))
        writer.put(5, row_index, 3, params.get(f"monitor_{row_index}_temperature"))
        writer.put(5, row_index, 4, params.get(f"monitor_{row_index}_stable", "是"), True)
        status = params.get(f"monitor_{row_index}_status", "符合")
        note = params.get(f"monitor_{row_index}_note") or ""
        writer.put(5, row_index, 5, f"{status}" + (f"；{note}" if note else ""), True)
        writer.put(5, row_index, 6, context.get("operator"))
    writer.put_mapped("container_no", params.get("container_no") or "/")
    writer.put_mapped("sample_count", len(rows))
    writer.put_mapped("first_heating_interval", f"{params.get('first_heating_start','')}-{params.get('first_heating_end','')}")
    writer.put_mapped("transfer_interval", f"{params.get('ice_immersion_start','')} / {_text(params.get('transfer_time'))}s")
    writer.put_mapped("immersion_interval", f"{params.get('ice_immersion_start','')}-{params.get('ice_immersion_end','')}")
    writer.put_mapped("second_heating_interval", f"{params.get('second_heating_start','')}-{params.get('second_heating_end','')}")
    writer.put_mapped("cooling_temp_record", f"环境温度：{_text(params.get('cooling_temperature'))}℃；☑无直吹风 ☑无阳光直射")
    writer.put_mapped("surface_temp_record", f"读数：{_text(params.get('surface_temperature'))}℃；稳定时间：30s")
    writer.put_mapped("cooling_record", f"冷却开始：{params.get('cooling_start','')}；完成：{params.get('cooling_end','')}")
    writer.put_mapped("illumination_record", f"照度：{_text(params.get('illumination'))}lx；放大镜：☑{_text(params.get('magnification'))}×")
    writer.put_mapped("inspector_record", f"检查人员：{context.get('operator','')}")
    for row_index in range(1, 29):
        if row_index > len(rows):
            writer.put_unused_row(8, row_index)
            continue
        item = rows[row_index - 1]
        writer.put(8, row_index, 0, item.get("sample_no"))
        writer.put(8, row_index, 1, item.get("initial_appearance", "无异常"), True)
        writer.put(8, row_index, 2, item.get("crack"), True)
        writer.put(8, row_index, 3, item.get("chipping"), True)
        writer.put(8, row_index, 4, item.get("fracture"), True)
        writer.put(8, row_index, 5, item.get("conclusion"), True)
        writer.put(8, row_index, 6, item.get("note") or attachment_ref)
    writer.put_mapped("total_count", len(rows))
    writer.put_mapped("total_count_2", len(rows))
    writer.put_mapped("crack_count", sum(x.get("crack") == "有" for x in rows))
    writer.put_mapped("chipping_count", sum(x.get("chipping") == "有" for x in rows))
    writer.put_mapped("fracture_count", sum(x.get("fracture") == "有" for x in rows))
    failed = [x for x in rows if x.get("conclusion") != "符合"]
    writer.put_mapped("final_verdict", "合格" if not failed else "不合格")
    writer.put_mapped("final_conclusion", "经耐急冷急热试验后，样品未见裂纹、崩瓷、破裂，判定合格。" if not failed else "试验后存在裂纹、崩瓷或破裂，判定不合格。")


def _bending(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    for row_index in range(1, 7):
        if row_index > len(rows):
            writer.put_unused_row(4, row_index)
            continue
        item = rows[row_index - 1]
        mapping = ("sample_no", "length", "width", "height", "span", "speed", "fmax", "stress_02")
        for col, key in enumerate(mapping):
            writer.put(4, row_index, col, item.get(key))
        writer.put(4, row_index, 8, item.get("sample_state"), True)
        writer.put(4, row_index, 9, item.get("conclusion"), True)
        writer.put(4, row_index, 10, item.get("note") or "/")
    overall = "全部符合" if all(x.get("conclusion") == "符合" for x in rows) else "存在不符合"
    writer.put_mapped("overall_verdict", overall)
    writer.put_mapped("attachment_ref_t7", attachment_ref)
    writer.put_mapped("has_attachment_a", "有" if attachment_ref else "无")
    writer.put_mapped("has_attachment_b", "有" if attachment_ref else "无")


def _vickers(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    writer.put_mapped("standard_block_due", params.get("standard_block_due"))
    writer.put_mapped("std_reading_1", params.get("standard_block_reading_1"))
    writer.put_mapped("std_reading_2", params.get("standard_block_reading_2"))
    writer.put_mapped("std_reading_3", params.get("standard_block_reading_3"))
    values = [params.get(f"standard_block_reading_{i}") for i in range(1, 4)]
    valid = [float(x) for x in values if x not in (None, "")]
    writer.put_mapped("std_reading_mean", round(mean(valid), 1) if len(valid) == 3 else "")
    writer.put_mapped("std_result", params.get("standard_block_result"))
    writer.put_mapped("surface_verdict", "符合" if params.get("surface_condition") == "平整清洁" else "不符合")
    writer.put_mapped("surface_condition", params.get("surface_condition"))
    writer.put_mapped("perpendicularity", params.get("perpendicularity"))
    writer.put_mapped("indent_method", params.get("indent_measurement_method", "切线测量"))
    writer.put_mapped("report_exported", "已导出" if params.get("report_exported") == "是" else "未导出")
    writer.put_mapped("report_exported_ok", "是")
    for row_index in range(1, 13):
        if row_index > len(rows):
            writer.put_unused_row(5, row_index)
            continue
        item = rows[row_index - 1]
        mapping = ("sample_no", "face", "indent1", "indent2", "indent3", "mean")
        for col, key in enumerate(mapping):
            writer.put(5, row_index, col, item.get(key))
        writer.put(5, row_index, 6, item.get("indent_quality", "有效"), True)
        writer.put(5, row_index, 7, params.get("test_force"))
        writer.put(5, row_index, 8, params.get("dwell_time"))
    grouped: dict[str, list[dict[str, Any]]] = {}
    for item in rows:
        grouped.setdefault(str(item.get("sample_no", "")), []).append(item)
    for row_index, (sample_no, items) in enumerate(grouped.items(), 1):
        if row_index > 6:
            break
        writer.put(6, row_index, 0, sample_no)
        writer.put(6, row_index, 1, items[0].get("mean") if items else "")
        writer.put(6, row_index, 2, items[1].get("mean") if len(items) > 1 else "")
        writer.put(6, row_index, 3, items[0].get("limit") or "按委托/技术要求")
        writer.put(6, row_index, 4, "不判定", True)
        writer.put(6, row_index, 5, attachment_ref)


def _thickness(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    th = writer.constants["thresholds"]
    writer.put_mapped("sample_batch", f"样品批号：{params.get('sample_production_date') or context.get('product_no','')}")
    writer.put_mapped("production_date", f"生产日期：{params.get('production_date') or context.get('production_date','')}")
    writer.put_mapped("design_file_no", f"设计文件编号：{params.get('design_file_no','')}")
    writer.put_mapped("magnification_record", f"测试放大倍数：{params.get('magnification') or '33倍'}")
    writer.put_mapped("preheat_record", f"开始：{params.get('preheat_start','')} 结束：{params.get('preheat_end','')}")
    nominal, measured = params.get("calibration_nominal"), params.get("calibration_measured")
    error = None if nominal in (None, "") or measured in (None, "") else round(float(measured) - float(nominal), 4)
    writer.put_mapped("calibration_record", f"标准量块标称值：{_text(nominal)} mm 实测值：{_text(measured)} mm 误差：{_text(error)} mm")
    data_rows = list(range(3, 18, 3))
    for sample_index, start_row in enumerate(data_rows):
        if sample_index >= len(rows):
            for row_index in range(start_row, min(start_row + 3, 18)):
                writer.put_unused_row(4, row_index)
            continue
        item = rows[sample_index]
        for repeat_offset in range(3):
            row_index = start_row + repeat_offset
            writer.put(4, row_index, 0, item.get("sample_no"))
            writer.put(4, row_index, 1, repeat_offset + 1)
            values = [item.get(f"r{repeat_offset + 1}_{section}") for section in ("fixed", "middle", "free")]
            for col, value in enumerate(values, 2):
                writer.put(4, row_index, col, value)
            writer.put(4, row_index, 5, item.get(f"r{repeat_offset + 1}_mean"))
            writer.put(4, row_index, 6, item.get("image_no") or attachment_ref)
            writer.put(4, row_index, 7, item.get("data_file_no") or attachment_ref)
            writer.put(4, row_index, 8, item.get("note") or "/")
    for row_index in range(1, 6):
        if row_index > len(rows):
            writer.put_unused_row(5, row_index)
            continue
        item = rows[row_index - 1]
        values = [
            item.get("sample_no"), params.get("design_thickness"), item.get("fixed_mean"),
            item.get("middle_mean"), item.get("free_mean"), item.get("mean"),
            item.get("deviation"), f"±{th['thickness_tol_mm']} mm",
        ]
        for col, value in enumerate(values):
            writer.put(5, row_index, col, value)
        writer.put(5, row_index, 8, item.get("conclusion"), True)
        writer.put(5, row_index, 9, item.get("note") or "/")


def _color(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    dev = writer.constants["devices"]
    writer.put_mapped("temperature_before", params.get("temperature_before"))
    writer.put_mapped("humidity_before", params.get("humidity_before"))
    writer.put_mapped("lightbox_type", dev["d65_lightbox"])
    writer.put_mapped("lightbox_clean", "清洁")
    writer.put_mapped("lightbox_confirmed", "已确认")
    observer_names = [params.get(f"observer_{index}") or f"观察者{index}" for index in range(1, 4)]
    for table_row, observer in enumerate(observer_names, 5):
        writer.put(1, table_row, 1, observer)
        writer.put(1, table_row, 2, params.get("observer_qualification"))
        writer.put(1, table_row, 4, "否", True)
        writer.put(1, table_row, 5, "合格", True)
        writer.put(1, table_row, 6, observer)
    writer.put_mapped("lamp_no", params.get("lamp_no"))
    writer.put_mapped("lamp_hours", params.get("lamp_hours"))
    writer.put_mapped("filter_no", params.get("filter_no"))
    writer.put_mapped("filter_hours", params.get("filter_hours"))
    writer.put_mapped("lamp_calibrated", "是")
    writer.put_mapped("lamp_history", "历史记录")
    writer.put_mapped("source_type", params.get("source_type"))
    writer.put_mapped("water_temp_record", f"设定：{_text(params.get('water_temperature'))}℃；实测：{_text(params.get('color_monitor_1_water_temperature'))}℃")
    writer.put_mapped("sample_illuminance", params.get("sample_illuminance"))
    writer.put_mapped("water_distance", params.get("water_distance"))
    writer.put_mapped("exposure_time_record", f"设定：{_text(params.get('exposure_time'))} h")
    writer.put_mapped("sample_placement", "平行；无阴影")
    writer.put_mapped("device_status", "正常")
    for table_row in range(1, 8):
        writer.put(5, table_row, 3, "是", True)
        writer.put(5, table_row, 4, context.get("operator"))
    writer.put_mapped("exposure_start", params.get("exposure_start"))
    writer.put_mapped("exposure_end", params.get("exposure_end"))
    writer.put_mapped("exposure_time", params.get("exposure_time"))
    writer.put_mapped("exposure_ok", "是")
    writer.put_mapped("attachment_ref_t7", attachment_ref)
    writer.put_mapped("trace_ref", "详见内部实验数据追溯Excel")
    writer.put_mapped("has_attachment_a", "有" if attachment_ref else "无")
    writer.put_mapped("has_attachment_b", "有" if attachment_ref else "无")
    for table_row in range(1, 7):
        writer.put(8, table_row, 1, params.get(f"color_monitor_{table_row}_datetime"))
        writer.put(8, table_row, 2, params.get(f"color_monitor_{table_row}_runtime"))
        writer.put(8, table_row, 3, params.get(f"color_monitor_{table_row}_water_temperature"))
        writer.put(8, table_row, 4, params.get(f"color_monitor_{table_row}_illuminance"))
        writer.put(8, table_row, 5, params.get(f"color_monitor_{table_row}_distance"))
        writer.put(8, table_row, 6, params.get(f"color_monitor_{table_row}_device_status", "正常"), True)
        writer.put(8, table_row, 7, params.get(f"color_monitor_{table_row}_sample_status", "正常"), True)
        writer.put(8, table_row, 8, context.get("operator"))
        writer.put(8, table_row, 9, params.get(f"color_monitor_{table_row}_note") or "/")
    writer.put_mapped("sample_handling", ["去除遮盖", "吸除表面水分", "未擦伤/污染试样"])
    writer.put_mapped("handling_status", "正常")
    writer.put_mapped("lamp_box_ready", params.get("lamp_box_ready"))
    writer.put_mapped("d65_illuminance", params.get("d65_illuminance"))
    writer.put_mapped("background", params.get("background"))
    writer.put_mapped("background_ok", "合格")
    writer.put_mapped("observation_distance", params.get("observation_distance"))
    writer.put_mapped("single_observation_time", params.get("single_observation_time"))
    writer.put_mapped("observation_conditions", ["无明显颜色反射", "光源无闪烁", "区域清洁"])
    writer.put_mapped("observation_date", params.get("observation_date"))
    for row_index in range(1, 13):
        if row_index > len(rows):
            writer.put_unused_row(6, row_index)
            continue
        item = rows[row_index - 1]
        writer.put(6, row_index, 0, item.get("sample_no"))
        writer.put(6, row_index, 1, item.get("control_no") or "/")
        writer.put(6, row_index, 2, item.get("shape"), True)
        writer.put(6, row_index, 4, item.get("cover_method"), True)
        writer.put(6, row_index, 5, item.get("cover_direction"))
        writer.put(6, row_index, 6, item.get("cover_secure"), True)
        writer.put(6, row_index, 8, "是" if attachment_ref else "否", True)
        writer.put(6, row_index, 9, item.get("note") or "/")
        for observer_index, observer_name in enumerate(observer_names, 1):
            detail_row = (row_index - 1) * 3 + observer_index
            if detail_row >= 19:
                break
            result = item.get(f"observer{observer_index}")
            writer.put(10, detail_row, 0, item.get("sample_no"))
            writer.put(10, detail_row, 1, observer_name)
            writer.put(10, detail_row, 2, "合格", True)
            writer.put(10, detail_row, 3, result)
            writer.put(10, detail_row, 4, result)
            writer.put(10, detail_row, 5, result, True)
            writer.put(10, detail_row, 6, observer_name)
            writer.put(10, detail_row, 7, params.get("observation_date"))
    for row_index in range(1, 13):
        if row_index > len(rows):
            writer.put_unused_row(11, row_index)
            continue
        item = rows[row_index - 1]
        writer.put(11, row_index, 0, item.get("sample_no"))
        writer.put(11, row_index, 1, item.get("observer1"), True)
        writer.put(11, row_index, 2, item.get("observer2"), True)
        writer.put(11, row_index, 3, item.get("observer3"), True)
        writer.put(11, row_index, 4, item.get("overall"), True)
        writer.put(11, row_index, 5, "是", True)
        writer.put(11, row_index, 6, item.get("conclusion"), True)
        writer.put(11, row_index, 7, item.get("note") or "/")
    overall = "未见明显色泽差异" if all(x.get("conclusion") == "符合" for x in rows) else "可见明显色泽差异"
    writer.put_mapped("overall_verdict", overall)
    writer.put_mapped("final_verdict", "合格" if all(x.get("conclusion") == "符合" for x in rows) else "不合格")


def _fixed_denture(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    dev = writer.constants["devices"]
    th = writer.constants["thresholds"]
    for index in range(1, 7):
        if index > len(rows):
            writer.put_unused_row(4, index)
            writer.put_unused_row(6, index)
            continue
        item = rows[index - 1]
        writer.put(4, index, 0, item.get("sample_no"))
        for col in range(1, 5):
            writer.put(4, index, col, item.get("common_check"), True)
        for col, key in ((5, "junction_thickness"), (6, "base_thickness"), (7, "connector_area")):
            writer.put(4, index, col, item.get(key))
        writer.put(4, index, 8, item.get("conclusion"), True)
        writer.put(4, index, 9, item.get("note") or "/")
        writer.put(6, index, 0, item.get("sample_no"))
        for col in range(1, 8):
            writer.put(6, index, col, item.get("finished_check"), True)
        writer.put(6, index, 8, item.get("conclusion"), True)
        writer.put(6, index, 9, item.get("note") or "/")
    for index in range(1, 5):
        if index > len(rows):
            for table in (5, 7, 8):
                writer.put_unused_row(table, index)
            continue
        item = rows[index - 1]
        writer.put(5, index, 0, item.get("sample_no"))
        writer.put(5, index, 1, params.get("material_category"), True)
        writer.put(5, index, 3, item.get("connector_n"))
        writer.put(5, index, 4, item.get("connector_m"))
        writer.put(5, index, 6, item.get("connector_area"))
        writer.put(5, index, 7, f"≥{_text(item.get('connector_limit'))} mm²")
        writer.put(5, index, 8, item.get("conclusion") if params.get("connector_applicable") == "适用" else "不适用", True)
        writer.put(7, index, 0, item.get("sample_no"))
        writer.put(7, index, 1, "是" if params.get("roughness_applicable") == "适用" else "否", True)
        writer.put(7, index, 2, dev["roughness_instrument"])
        writer.put(7, index, 6, f"Ra≤{th['fixed_denture_ra_um']} μm")
        rough_ok = item.get("roughness") not in (None, "") and float(item.get("roughness")) <= th["fixed_denture_ra_um"]
        writer.put(7, index, 7, ("符合" if rough_ok else "不符合") if params.get("roughness_applicable") == "适用" else "不适用", True)
        writer.put(7, index, 8, item.get("note") or "/")
        writer.put(8, index, 0, item.get("sample_no"))
        writer.put(8, index, 2, attachment_ref)
        writer.put(8, index, 3, item.get("pores_over30"))
        writer.put(8, index, 4, item.get("pores_40_150"))
        writer.put(8, index, 5, item.get("pore_over150"), True)
        writer.put(8, index, 7, item.get("conclusion") if params.get("porosity_applicable") == "适用" else "不适用", True)
    overall = "合格" if rows and all(row.get("conclusion") == "符合" for row in rows) else "不合格"
    writer.put_mapped("porosity_result", "是")
    writer.put_mapped("roughness_result", "否")
    writer.put_mapped("final_verdict", overall)
    writer.put_mapped("attachment_ref_t10", attachment_ref)


def _removable_denture(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    item = rows[0] if rows else {}
    for row_index in range(1, 11):
        writer.put(6, row_index, 3, item.get("common_check"), True)
        writer.put(6, row_index, 4, item.get("common_check"), True)
    selected_rows = (1, 2) if params.get("denture_type") == "全口义齿" else (3, 4)
    for row_index in range(1, 5):
        if row_index not in selected_rows or not rows:
            writer.put(7, row_index, 7, "不适用", True)
            continue
        edge = row_index in (1, 3)
        keys = ("edge1", "edge2", "edge3", "edge_mean") if edge else ("middle1", "middle2", "middle3", "middle_mean")
        for col, key in enumerate(keys, 3):
            writer.put(7, row_index, col, item.get(key))
        writer.put(7, row_index, 7, item.get("thickness_conclusion"), True)
    writer.put_mapped("attachment_ref_t9a", attachment_ref)
    writer.put_mapped("iqi_no", params.get("iqi_no"))
    writer.put_mapped("attachment_ref_t9b", attachment_ref)
    writer.put_mapped("xray_conclusion", item.get("xray_conclusion") if params.get("xray_applicable") == "适用" else "不适用")
    writer.put_mapped("cutting_device_no", params.get("cutting_device_no"))
    writer.put_mapped("outer_angle", item.get("outer_angle"))
    writer.put_mapped("termination_outer", item.get("termination_conclusion") if params.get("termination_applicable") == "适用" else "不适用")
    writer.put_mapped("inner_angle", item.get("inner_angle"))
    writer.put_mapped("termination_inner", item.get("termination_conclusion") if params.get("termination_applicable") == "适用" else "不适用")
    writer.put_mapped("same_vertical", item.get("same_vertical"))
    writer.put_mapped("termination_vertical", item.get("termination_conclusion") if params.get("termination_applicable") == "适用" else "不适用")
    writer.put_mapped("upper_no_pore_faces", item.get("upper_no_pore_faces"))
    writer.put_mapped("porosity_upper", item.get("porosity_conclusion") if params.get("porosity_applicable") == "适用" else "不适用")
    writer.put_mapped("lower_no_pore_faces", item.get("lower_no_pore_faces"))
    writer.put_mapped("porosity_lower", item.get("porosity_conclusion") if params.get("porosity_applicable") == "适用" else "不适用")
    # SOP-015 is the controlled deletion version: color stability is never
    # performed inside this integrated task; independent color work uses R012.
    for table in (13, 14):
        for row_index in range(1, 8):
            writer.put_unused_row(table, row_index)
    writer.put_mapped("final_conclusion", item.get("conclusion"))
    writer.put_mapped("final_no", "否")


def _density(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    th = writer.constants["thresholds"]
    writer.put_mapped("balance_calibration", params.get("balance_internal_calibration"))
    writer.put_mapped("system_check", params.get("system_check_result"))
    writer.put_mapped("auto_calc_check", params.get("auto_calc_check"))
    for sample_index in range(6):
        if sample_index >= len(rows):
            writer.put_unused_row(7, sample_index + 1)
            continue
        item = rows[sample_index]
        for repeat in range(1, 4):
            table_row = sample_index * 3 + repeat
            writer.put(6, table_row, 0, item.get("sample_no"))
            writer.put(6, table_row, 1, repeat)
            for col, key in ((2, f"a{repeat}"), (3, f"b{repeat}"), (4, f"water_temp{repeat}"), (5, f"water_density{repeat}"), (6, f"auto_density{repeat}")):
                writer.put(6, table_row, col, item.get(key))
            valid = item.get(f"density{repeat}") not in (None, "")
            writer.put(6, table_row, 7, "有" if valid else "无", True)
            writer.put(6, table_row, 8, "是" if valid else "否", True)
            writer.put(6, table_row, 9, "符合" if valid else "不符合", True)
            writer.put(6, table_row, 10, item.get("data_file_no") or attachment_ref)
            writer.put(6, table_row, 11, "有效" if valid else "无效", True)
            writer.put(6, table_row, 12, item.get("note") or "/")
        table_row = sample_index + 1
        values = [item.get("sample_no"), item.get("density1"), item.get("density2"), item.get("density3"), item.get("density_difference"), item.get("mean"), round(item.get("mean"), 1) if item.get("mean") is not None else "", params.get("declared_density"), item.get("relative_deviation"), f"±{th['density_tol_pct']}%"]
        for col, value in enumerate(values):
            writer.put(7, table_row, col, value)
        conclusion = "不判定" if item.get("conclusion") == "仅报告结果" else item.get("conclusion")
        writer.put(7, table_row, 10, conclusion, True)
        writer.put(7, table_row, 11, item.get("note") or "/")
    means = [float(row["mean"]) for row in rows if row.get("mean") is not None]
    overall_mean = round(sum(means) / len(means), 4) if len(means) == 6 else ""
    writer.put_mapped("overall_mean", overall_mean)
    writer.put_mapped("overall_mean_1dp", round(overall_mean, 1) if overall_mean != "" else "")
    writer.put_mapped("overall_verdict", "全部符合" if rows and all(row.get("conclusion") == "符合" for row in rows) else "仅报告结果" if rows and all(row.get("conclusion") == "仅报告结果" for row in rows) else "存在不符合")
    writer.put_mapped("declared_source", params.get("declared_density_source"))
    writer.put_mapped("declared_density", params.get("declared_density"))
    writer.put_mapped("density_verdict", "符合" if rows and all(row.get("conclusion") == "符合" for row in rows) else "仅报告实测结果不作判定" if rows and all(row.get("conclusion") == "仅报告结果" for row in rows) else "不符合")
    writer.put_mapped("attachment_ref_t10", attachment_ref)


def _tarnish(writer: Writer, rows: list[dict[str, Any]], params: dict[str, Any], context: dict[str, Any], attachment_ref: str) -> None:
    dev = writer.constants["devices"]
    ft = writer.constants["fixed_text"]
    for row_index in range(1, 3):
        if row_index > len(rows):
            writer.put_unused_row(3, row_index)
            continue
        item = rows[row_index - 1]
        for col, key in enumerate(("sample_no", "specimen_role", "diameter", "thickness")):
            writer.put(3, row_index, col, item.get(key), key == "specimen_role")
        writer.put(3, row_index, 5, item.get("surface_prep"), True)
        writer.put(3, row_index, 6, "符合" if item.get("conclusion") != "不符合" else "不符合", True)
    for row_index, key in enumerate(("solution_mass_initial", "solution_mass_24h", "solution_mass_48h"), 1):
        writer.put(4, row_index, 2, params.get(key))
        writer.put(4, row_index, 3, dev["tarnish_eq_a"])
        writer.put(4, row_index, 4, dev["tarnish_eq_b"])
    writer.put_mapped("bath_volume", ft["tarnish_bath_volume_ml"])
    writer.put_mapped("bath_temperature", f"{_text(params.get('bath_temperature'))} ℃")
    writer.put_mapped("cycle_immersion_seconds", params.get("cycle_immersion_seconds"))
    writer.put_mapped("solution_change_24h", params.get("solution_change_24h"))
    writer.put_mapped("solution_change_48h", params.get("solution_change_48h"))
    writer.put_mapped("total_duration", params.get("total_duration"))
    writer.put_mapped("bath_status", "正常")
    immersed = next((row for row in rows if row.get("specimen_role") == "浸泡试样"), rows[0] if rows else {})
    control = next((row for row in rows if row.get("specimen_role") == "未浸泡对照"), {})
    writer.put_mapped("observation_illuminance", params.get("observation_illuminance"))
    writer.put_mapped("observation_distance", _text(params.get("observation_distance")))
    writer.put_mapped("immersed_color_change", immersed.get("color_change"))
    writer.put_mapped("control_color_change", control.get("color_change"))
    writer.put_mapped("reflectance_change", immersed.get("reflectance_change"))
    writer.put_mapped("tarnish_product", immersed.get("tarnish_product"))
    writer.put_mapped("immersed_sample_no", immersed.get("sample_no"))
    writer.put_mapped("removal_ease", immersed.get("removal_ease"))
    writer.put_mapped("color_change_verdict", immersed.get("color_change"))
    writer.put_mapped("removal_ease_verdict", immersed.get("removal_ease"))
    writer.put_mapped("reflectance_verdict", immersed.get("reflectance_change"))
    writer.put_mapped("tarnish_verdict", "符合抗晦暗要求" if immersed.get("conclusion") == "符合" else "不符合抗晦暗要求")
    writer.put_mapped("result_valid", "是")
    writer.put_mapped("final_conclusion", immersed.get("conclusion"))
    writer.put_mapped("attachment_ref_t12", attachment_ref)


MAPPERS = {
    "rough": _rough,
    "mc_crack": _crack,
    "xray": _xray,
    "warp": _warpage,
    "cte": _cte,
    "shock": _shock,
    "bend": _bending,
    "hv": _vickers,
    "thickness": _thickness,
    "color": _color,
    "fixed_denture": _fixed_denture,
    "removable_denture": _removable_denture,
    "density": _density,
    "tarnish": _tarnish,
}


def _cte_env_value(field: dict[str, Any], ok: dict[str, bool]) -> str | None:
    """热膨胀(cte)模板"环境条件与试验安全确认"逐条勾选（数据驱动）。

    是否符合列 → 是/否；实测/记录列 → 无/有、正常/异常、已确认。
    每条对应实验员 _form 中的实际确认字段（温度/湿度/干扰/工作区域符合性）；
    加热区安全、禁止触碰等无独立字段的条目，以"操作与受控方法一致"为准。
    """
    row = field.get("row")
    col_header = str(field.get("col_header") or "")
    if col_header == "是否符合":
        row_ok = {
            1: ok["temperature_ok"], 2: ok["humidity_ok"], 3: ok["interfere_ok"],
            4: ok["work_ok"], 5: ok["method_ok"], 6: ok["method_ok"],
        }
        return "是" if row_ok.get(row, True) else "否"
    if col_header == "实测/记录":
        if row == 3:
            return "无" if ok["interfere_ok"] else "有"
        if row == 4:
            return "正常" if ok["work_ok"] else "异常"
        if row == 5:
            return "正常" if ok["method_ok"] else "异常"
        if row == 6:
            return "已确认" if ok["method_ok"] else ""
    return None


def _fill_dynamic_fields(
    writer: "Writer",
    db_mappings: list[dict[str, Any]] | None,
    kind: str,
    business_record: dict[str, Any],
) -> None:
    """把「配置新增」的字段/列写入受控模板对应坐标（数据对应）。

    硬编码兜底 `mapping_registry.FIELD_MAPPINGS[kind]` 已由 per-kind mapper 显式处理；
    这里只补 DB `template_field_mappings` 中「新增」（不在硬编码兜底内）的 field_key，
    取值按「静态字段 → parameters、测量/计算列 → 首行 rows」顺序解析，仅写非空值，
    保证不臆造、不与硬编码 mapper 冲突。
    """
    if not db_mappings:
        return
    params = business_record.get("parameters") or {}
    rows = business_record.get("rows") or []
    first_row = rows[0] if rows else {}
    hardcoded = mapping_registry.FIELD_MAPPINGS.get(kind, {})
    for m in db_mappings:
        if not isinstance(m, dict):
            continue
        fk = str(m.get("field_key") or "").strip()
        if not fk or fk in hardcoded:
            continue
        value = params.get(fk)
        if value in (None, ""):
            value = first_row.get(fk)
        if value in (None, ""):
            continue
        writer.put_mapped(fk, value)


def apply_controlled_mapping(
    template_name: str,
    kind: str,
    values: dict[str, str],
    context: dict[str, Any],
    business_record: dict[str, Any],
    attachment_ref: str,
    registry: dict[str, Any] | None = None,
    finalize: bool = True,
) -> dict[str, str]:
    # registry 可选结构（异步调用方从 DB 读取后传入，DB 值优先、硬编码兜底）：
    #   {"db_mappings": [template_field_mappings 行…], "extra_json": {experiment_config_versions.extra_json}}
    db_mappings = (registry or {}).get("db_mappings")
    extra_json = (registry or {}).get("extra_json")
    field_map = mapping_registry.get_field_map(kind, db_mappings)
    constants = mapping_registry.get_constants(extra_json)
    writer = Writer(template_name, values, field_map=field_map, constants=constants)
    params = business_record.get("parameters") or {}
    mapper = MAPPERS.get(kind)
    if mapper:
        mapper(
            writer,
            business_record.get("rows") or [],
            business_record.get("parameters") or {},
            context,
            attachment_ref,
        )
    # 数据对应：补写配置新增（DB template_field_mappings）的字段/列，硬编码兜底已由 mapper 处理
    _fill_dynamic_fields(writer, db_mappings, kind, business_record)
    if kind == "cte":
        # 勾选框一律由实验员 _form 确认数据 + SOP 规则显式生成，不臆造正向。
        all_conform = all(
            item.get("judgement_result") in ("符合", "合格", "", None)
            for item in (business_record.get("rows") or [])
        )
        work_area = params.get("work_area_condition")
        if work_area is None:
            work_area = params.get("work_area_status")
        # 工作区域无记录时按 SOP 默认"正常"；显式清空(空列表)才视为异常。
        ok = {
            "temperature_ok": str(params.get("temperature_compliance", "符合")) in ("符合", "是"),
            "humidity_ok": str(params.get("humidity_compliance", "符合")) in ("符合", "是"),
            "interfere_ok": str(params.get("interference_compliance", "符合")) in ("符合", "是"),
            "work_ok": work_area is None or bool(work_area),
            "method_ok": str(params.get("method_execution_confirmation", "一致")) in ("一致", "符合", "是"),
            "baseline_ok": str(params.get("baseline_stability_actual", "稳定")) in ("稳定", "符合", "是"),
        }
        # 试验前准备清单：方法执行一致且启动前基线稳定 → 全部"是"，否则"否"。
        precheck_ok = ok["method_ok"] and ok["baseline_ok"]
        for field in template_manifest(template_name):
            original = str(field.get("template_text") or "")
            if "□" not in original and "☐" not in original:
                continue
            combined = " ".join([
                str(field.get("section") or ""),
                str(field.get("label") or ""),
                str(field.get("row_label") or ""),
                str(field.get("col_header") or ""),
            ])
            key = field["key"]
            if "制样/处理状态" in combined:
                writer.values[key] = _box(
                    original, params.get("sample_processing_state", "原始状态")
                )
                writer.touched.add(key)
            elif "环境条件与试验安全确认" in combined:
                sel = _cte_env_value(field, ok)
                if sel is not None:
                    writer.values[key] = _box(original, sel)
                    writer.touched.add(key)
            elif "试验前准备与关键参数确认" in combined:
                writer.values[key] = _box(original, "是" if precheck_ok else "否")
                writer.touched.add(key)
            elif "是否符合委托要求" in combined:
                writer.values[key] = _box(original, "是" if all_conform else "否")
                writer.touched.add(key)
            elif "复核意见" in combined:
                writer.values[key] = "/"
                writer.touched.add(key)

    # 设备表"使用前状态"勾选：来自 _equipment_checks.status（实验员实际核验数据），
    # 全部设备核验为"正常"时勾选"正常"；否则按首个异常状态勾选。
    equipment_checks = business_record.get("_equipment_checks") or []
    if isinstance(equipment_checks, list) and equipment_checks:
        statuses = [str(c.get("status") or "") for c in equipment_checks if isinstance(c, dict)]
        if statuses:
            default_status = (
                "正常" if all(s == "正常" for s in statuses)
                else next((s for s in statuses if s and s != "正常"), "正常")
            )
            for field in template_manifest(template_name):
                key = field["key"]
                if key in writer.values and str(writer.values[key] or "").strip():
                    continue
                original = str(field.get("template_text") or "")
                combined = " ".join([
                    str(field.get("section") or ""),
                    str(field.get("label") or ""),
                    str(field.get("row_label") or ""),
                    str(field.get("col_header") or ""),
                ])
                if "使用前状态" in combined and ("□" in original or "☐" in original):
                    writer.values[key] = _box(original, default_status)
                    writer.touched.add(key)

    # 填充确认人/操作人/记录人/复核人等人员文本（来自任务上下文）
    operator = context.get("operator") or context.get("tester") or ""
    reviewer = context.get("reviewer") or ""
    for field in template_manifest(template_name):
        key = field["key"]
        if key in writer.values and str(writer.values[key] or "").strip():
            continue
        combined = " ".join([
            str(field.get("section") or ""),
            str(field.get("label") or ""),
            str(field.get("row_label") or ""),
            str(field.get("col_header") or ""),
        ])
        if "确认人" in combined and "复核" not in combined:
            if operator:
                writer.values[key] = operator
                writer.touched.add(key)
        elif any(w in combined for w in ("复核人", "核验人", "复核人员")):
            if reviewer:
                writer.values[key] = reviewer
                writer.touched.add(key)
        elif any(w in combined for w in ("操作人", "检测人", "记录人", "试验人")):
            if operator:
                writer.values[key] = operator
                writer.touched.add(key)

    # finalize=False 时保留空白标记/未勾选框，供「⑤母版过程确认」检测仍需实验员补充的字段
    if finalize:
        writer.finish_defaults()
    return writer.values, writer.touched
