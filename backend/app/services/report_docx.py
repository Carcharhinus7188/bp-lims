"""报告文档生成引擎 — 委托单/报告/发放登记/借出归还/危废处置/样品登记等 DOCX"""
from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path
from typing import Any

from docx import Document
from docx.shared import Inches, Pt, RGBColor

from app.core.evaluation_standards import EVALUATION_STANDARDS as _EVAL_STD

BLACK = RGBColor(0, 0, 0)

TEMPLATE_DIR = Path(__file__).parent.parent.parent.parent / "templates"
SIGNATURE_DIR = Path(__file__).parent.parent.parent.parent / "data" / "signatures"


def _standard_requirement(experiment_name: str) -> str:
    """按实验名称返回评价标准的「标准要求」句（回退用）。

    对齐 upstream report_rules.STANDARD_REQUIREMENTS，取 evaluation_standards
    中该实验的 limits 文本值（忽略数值限值字段）拼接为一句。
    """
    for entry in _EVAL_STD.values():
        if entry.get("experiment_name") == experiment_name:
            parts = [str(v) for v in entry.get("limits", {}).values() if isinstance(v, str)]
            if parts:
                return "；".join(parts)
            return entry.get("judgment", "")
    return ""


def _blacken(doc: Document) -> None:
    for p in doc.paragraphs:
        for r in p.runs:
            r.font.color.rgb = BLACK
    for t in doc.tables:
        for row in t.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    for r in p.runs:
                        r.font.color.rgb = BLACK


def _save(doc: Document) -> bytes:
    _blacken(doc)
    b = BytesIO()
    doc.save(b)
    b.seek(0)
    return b.read()


def _set_cell_text(cell, value: str) -> None:
    """Set cell text, preserving first paragraph."""
    paragraphs = list(cell.paragraphs)
    para = paragraphs[0] if paragraphs else cell.add_paragraph()
    runs = list(para.runs)
    if not runs:
        runs = [para.add_run("")]
    runs[0].text = "" if value is None else str(value)
    runs[0].font.color.rgb = BLACK
    for run in runs[1:]:
        run.text = ""
        run.font.color.rgb = BLACK
    for extra in paragraphs[1:]:
        for run in extra.runs:
            run.text = ""


def _set_para_text(para, value: str) -> None:
    """Replace a body paragraph's text with a single black run."""
    para.clear()
    run = para.add_run("" if value is None else str(value))
    run.font.color.rgb = BLACK


# ── Chinese label → data key mapping for template filling ──
# Each label maps to a list of possible keys (tried in order, first with data wins)
LABEL_MAP: dict[str, list[str]] = {
    "报告编号：": ["REPORT_NO"],
    "委托编号：": ["COMMISSION_NO"],
    "委托单号：": ["COMMISSION_NO"],
    "委托书编号：": ["COMMISSION_NO"],
    "委托单位：": ["CLIENT_NAME"],
    "委托方名称：": ["CLIENT_NAME"],
    "委托方地址：": ["CLIENT_ADDRESS"],
    "地址：": ["CLIENT_ADDRESS"],
    "样品名称：": ["SAMPLE_NAME"],
    "型号/规格：": ["MODEL"],
    "型号／规格：": ["MODEL"],
    "样品编号：": ["SAMPLE_NO"],
    "产品编号：": ["PRODUCT_NO"],
    "产品编号/批号：": ["PRODUCT_NO"],
    "生产单位：": ["PRODUCTION_UNIT"],
    "接收日期：": ["RECEIVE_DATE"],
    "委托日期：": ["COMMISSION_DATE"],
    "检验类别：": ["INSPECTION_CATEGORY"],
    "报告日期：": ["REPORT_DATE"],
    "签发日期：": ["REPORT_DATE"],
    "报告发布日期：": ["REPORT_DATE"],
    "检验日期：": ["TEST_DATE"],
    "检验日期 ：": ["TEST_DATE"],
    "检验结论：": ["CONCLUSION"],
    "结论：": ["CONCLUSION"],
    "本次检验技术依据及技术指标:": ["EXPERIMENT", "STANDARD"],
    "本次检验技术依据及技术指标：": ["EXPERIMENT", "STANDARD"],
    "照片和说明：": ["PHOTO_DESC"],
    "检验员：": ["TESTER"],
    "检测员：": ["TESTER"],
    "复核员：": ["VERIFIER"],
    "核验员：": ["VERIFIER"],
    "签发人：": ["APPROVER"],
    "批准人：": ["APPROVER"],
    "联系人：": ["CONTACT"],
    "联系电话：": ["PHONE"],
    "电话：": ["PHONE"],
    "约定完成日期：": ["DUE_DATE"],
    "生产单位与委托人关系：": ["PRODUCTION_RELATION"],
    "备注：": ["NOTES", "NOTE"],
    "报告形式：": ["REPORT_MEDIUM"],
    "符合性判定：": ["CONFORMITY_JUDGMENT"],
    "报告交付方式：": ["DELIVERY_METHOD"],
    "发放方式：": ["DELIVERY_METHOD"],
    "接样人：": ["RECEIVER"],
    "样品状态：": ["SAMPLE_CONDITION"],
    "接收状态：": ["SAMPLE_CONDITION"],
    "样品说明：": ["SAMPLE_STATEMENT"],
    "检测项目：": ["EXPERIMENT"],
    "处置编号：": ["DISPOSAL_NO"],
    "危废名称：": ["WASTE_NAME"],
    "废物类别：": ["WASTE_TYPE"],
    "数量：": ["QUANTITY"],
    "单位：": ["UNIT"],
    "处置人：": ["HANDLER"],
    "容器编号：": ["CONTAINER_NO"],
    "产生日期：": ["OCCURRED_AT"],
    "处置方式：": ["DISPOSAL_METHOD"],
    "危险特性：": ["HAZARD_CATEGORY"],
    "状态：": ["STATUS"],
    "接收人：": ["RECIPIENT"],
    "发放日期：": ["DELIVERY_DATE"],
    "检验地点、环境条件：": ["DETECTION_ENV"],
    "检验地点、环境条件:": ["DETECTION_ENV"],
    "需说明的情况:": ["NOTES", "NOTE"],
    "需说明的情况：": ["NOTES", "NOTE"],
    "样品情况说明：": ["SAMPLE_STATEMENT"],
    "样品情况说明:": ["SAMPLE_STATEMENT"],
}

# ── Colon-less labels: template has e.g. "批 准 人" without colon ──
# These are ONLY matched when they appear at the END of a paragraph (after
# stripping trailing whitespace); this prevents false matches inside
# sentences like "报告无批准人签字无效".
COLONLESS_LABELS: dict[str, list[str]] = {
    "批准人": ["APPROVER"],
    "签发人": ["APPROVER"],
    "检验员": ["TESTER"],
    "检测员": ["TESTER"],
    "复核员": ["VERIFIER"],
    "核验员": ["VERIFIER"],
}

# ── Labels that must be at END of paragraph (to avoid overwriting static content) ──
# e.g. "地址：" appears as both a client-address placeholder AND as static company
# address text "地址：辽宁省大连市...". We only fill it when nothing follows.
END_OF_PARA_LABELS: set[str] = {"地址："}


def _fill_labels(doc: Document, data: dict[str, str]) -> None:
    """Fill Chinese label + value into paragraphs that contain known labels.

    Scans ALL paragraphs (body + every table cell). For each known Chinese
    label (e.g. "报告编号："), appends the corresponding data value after it.
    Handles character-spacing in templates (e.g. "委 托 单 位：" → "委托单位：value").
    Also handles colon-less personnel labels (e.g. "批 准 人") that appear at
    the end of a paragraph, adding a colon before the value.
    """
    import re

    # Collect every paragraph in the document
    all_paragraphs: list = list(doc.paragraphs)
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                all_paragraphs.extend(cell.paragraphs)

    # Sort labels by length (longest first) so "检验结论：" matches before "结论："
    sorted_labels = sorted(LABEL_MAP.items(), key=lambda x: len(x[0]), reverse=True)
    sorted_colonless = sorted(COLONLESS_LABELS.items(), key=lambda x: len(x[0]), reverse=True)

    for para in all_paragraphs:
        text = para.text
        if not text.strip():
            continue

        modified = False
        matched_keys: set[str] = set()   # data keys already filled in this paragraph
        matched_labels: set[str] = set()  # normalized labels already matched
        for label, keys in sorted_labels:
            label_norm = label.replace(" ", "").replace("　", "")
            # Skip if all candidate keys for this label have already been filled
            if all(k in matched_keys for k in keys):
                continue
            # Skip if this label is a substring of an already-matched longer label
            if any(label_norm in prev and label_norm != prev for prev in matched_labels):
                continue

            # Build a flexible regex that matches the label with possible
            # spaces between characters (common in Chinese templates)
            if label in END_OF_PARA_LABELS:
                # Only match if nothing but whitespace follows (protects static content)
                label_re = r"\s*".join(re.escape(ch) for ch in label) + r"\s*$"
            else:
                label_re = r"\s*".join(re.escape(ch) for ch in label)
            if not re.search(label_re, text):
                continue

            # Find the value for this label
            val = ""
            matched_key = ""
            for key in keys:
                if key in data:
                    v = data[key]
                    if v is not None and str(v).strip():
                        val = str(v).strip()
                        matched_key = key
                        break
            if not val:
                continue

            # Replace the first occurrence of the label with "label + value"
            text, n = re.subn(label_re, lambda m: f"{label}{val}", text, count=1)
            if n > 0:
                modified = True
                matched_labels.add(label_norm)
                if matched_key:
                    matched_keys.add(matched_key)

        # ── Colon-less personnel labels (only at end of paragraph) ──
        for label, keys in sorted_colonless:
            label_norm = label.replace(" ", "").replace("　", "")
            if all(k in matched_keys for k in keys):
                continue
            if any(label_norm in prev and label_norm != prev for prev in matched_labels):
                continue

            # Only match if the label appears at the END of the paragraph text
            # (after stripping trailing whitespace). This prevents false matches
            # inside sentences like "5.报告无批准人签字无效。"
            label_re = r"\s*".join(re.escape(ch) for ch in label) + r"\s*$"
            if not re.search(label_re, text):
                continue

            val = ""
            matched_key = ""
            for key in keys:
                if key in data:
                    v = data[key]
                    if v is not None and str(v).strip():
                        val = str(v).strip()
                        matched_key = key
                        break
            if not val:
                continue

            # Replace with colon-added label + value
            text, n = re.subn(label_re, lambda m: f"{label}：{val}", text, count=1)
            if n > 0:
                modified = True
                matched_labels.add(label_norm)
                if matched_key:
                    matched_keys.add(matched_key)

        if modified:
            para.clear()
            run = para.add_run(text)
            run.font.color.rgb = BLACK


def _fill_placeholders(doc: Document, data: dict[str, str]) -> None:
    """Replace {{KEY}} placeholders in all paragraphs (body + table cells)."""
    all_paragraphs: list = list(doc.paragraphs)
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                all_paragraphs.extend(cell.paragraphs)

    for para in all_paragraphs:
        for run in para.runs:
            for key, val in data.items():
                placeholder = f"{{{{{key}}}}}"
                if placeholder in run.text:
                    run.text = run.text.replace(placeholder, str(val) if val is not None else "")


def _fill_table_data(table, data: list[list], header_rows: int = 1) -> None:
    """Fill table rows with data starting from header_rows."""
    while len(table.rows) < header_rows + len(data):
        table.add_row()
    for i, vals in enumerate(data, start=header_rows):
        for j, v in enumerate(vals):
            if j < len(table.rows[i].cells):
                table.rows[i].cells[j].text = "" if v is None else str(v)
    # Clear remaining rows
    for i in range(header_rows + len(data), len(table.rows)):
        for cell in table.rows[i].cells:
            cell.text = ""


def _signature_path(username: str) -> Path | None:
    """Look up a signature image file for a username."""
    if not username:
        return None
    for ext in (".png", ".jpg", ".jpeg"):
        p = SIGNATURE_DIR / f"{username}{ext}"
        if p.exists():
            return p
    return None


def _set_signature_cell(cell, username: str, date_text: str = "", width: float = 0.92) -> None:
    """Insert signature image into a table cell."""
    paragraphs = list(cell.paragraphs)
    para = paragraphs[0] if paragraphs else cell.add_paragraph()
    para.clear()
    sig = _signature_path(username)
    if sig:
        try:
            para.add_run().add_picture(str(sig), width=Inches(width))
        except Exception:
            para.add_run("【签名图片读取失败】")
    else:
        para.add_run(f"【{username or '待签名'}】")
    if date_text:
        para.add_run(f"  {str(date_text)[:10]}")
    for extra in paragraphs[1:]:
        for run in extra.runs:
            run.text = ""


def _checked(template: str, label: str) -> str:
    """把模板文本中的某选项勾选（☑），其余保持 □。与 upstream form_engine.checked 一致。"""
    value = str(template or "").replace("☑", "□")
    return value.replace("□" + label, "☑" + label, 1)


def _option_line(text: str, label: str) -> str:
    """把「□ label」勾选为「☑ label」（□ 后可为普通空格 / 全角空格）。与 upstream option_line 一致。"""
    import re
    value = str(text or "").replace("☑", "□")
    pattern = re.compile(r"□\s*" + re.escape(label))
    return pattern.sub(lambda m: "☑" + m.group(0)[1:], value, count=1)


# ═══════════════════════════════════════════════════════════════
# Report DOCX
# ═══════════════════════════════════════════════════════════════

def generate_report_docx(
    commission: dict | None,
    groups: list[dict],
    tasks: list[dict],
    records: dict[str, dict],
    report: dict,
    user_names: dict[str, str],
    photos: list[str] | None = None,
) -> bytes:
    """Fill FORM_REPORT.docx with all data from a completed task group.

    photos: optional list of image file paths to embed in the report appendix.
    """
    template = TEMPLATE_DIR / "FORM_REPORT.docx"
    if not template.exists():
        raise FileNotFoundError(f"报告模板不存在: {template}")
    doc = Document(str(template))

    c = commission or {}
    names = "、".join(dict.fromkeys(g.get("sample_name", "") for g in groups if g.get("sample_name")))
    models = "、".join(dict.fromkeys(g.get("model", "") for g in groups if g.get("model")))
    product_nos = "、".join(dict.fromkeys(g.get("product_no", "") or g.get("batch_no", "") for g in groups if g.get("product_no") or g.get("batch_no")))

    # Collect sample numbers from tasks (e.g. "BP20260811001-S01, BP20260811001-S02")
    all_sample_nos: list[str] = []
    for t in tasks:
        sn = t.get("sample_nos", "")
        if sn:
            all_sample_nos.append(str(sn))
    sample_nos_str = "；".join(dict.fromkeys(all_sample_nos))  # unique, preserve order

    # Convert usernames to display names
    tester_username = report.get("tester", "")
    verifier_username = report.get("verifier", "")
    approver_username = report.get("approver", "")
    tester_display = user_names.get(tester_username, tester_username) if tester_username else ""
    verifier_display = user_names.get(verifier_username, verifier_username) if verifier_username else ""
    approver_display = user_names.get(approver_username, approver_username) if approver_username else ""

    # Format commission date
    comm_date = c.get("commission_date", "")
    if comm_date:
        comm_date = str(comm_date)[:10]

    # Fallback for sample_statement: group condition_note → sample condition_note → auto-generated
    sample_statement = report.get("sample_statement", "")
    if not sample_statement:
        cond_notes = [g.get("condition_note", "") for g in groups if g.get("condition_note")]
        if cond_notes:
            sample_statement = "；".join(cond_notes)
    if not sample_statement:
        # Auto-generate from sample names + models if available
        parts = [f"{g.get('sample_name','')}（{g.get('model','')}）×{g.get('quantity',1)}" for g in groups if g.get('sample_name')]
        if parts:
            sample_statement = "样品：" + "；".join(parts) + "，状态完好"

    # Helper: convert None → "" for template filling
    def _s(v):
        return "" if v is None else str(v)

    # 接收状态（样品外观）由样品组 condition 派生，非硬编码「完好」
    bad_cond = [
        g for g in groups
        if str(g.get("condition", "") or "").strip() and str(g.get("condition", "") or "").strip() != "完好"
    ]
    sample_condition = "异常" if bad_cond else "完好"

    # 结论回退：报告结论为空时，由原始记录逐行结论汇总
    report_conclusion = _s(report.get("conclusion")).strip()
    if not report_conclusion:
        row_conclusions: list[str] = []
        for t in tasks:
            rec = records.get(t.get("task_no", ""), {})
            payload = rec.get("payload", {}) if isinstance(rec.get("payload"), dict) else {}
            for row in payload.get("_rows", []) or payload.get("measurements", []) or []:
                if isinstance(row, dict):
                    rc = str(row.get("conclusion", "") or "").strip()
                    if rc:
                        row_conclusions.append(rc)
        if row_conclusions:
            bad = {"不符合", "不合格", "不通过", "异常", "×", "✗"}
            good = {"符合", "合格", "通过", "正常", "√", "☑"}
            if any(c in bad for c in row_conclusions):
                report_conclusion = "不符合"
            elif all(c in good for c in row_conclusions):
                report_conclusion = "符合"

    fill_data = {
        "REPORT_NO": _s(report.get("report_no")),
        "COMMISSION_NO": _s(report.get("commission_no")),
        "CLIENT_NAME": _s(c.get("client_name")),
        "CLIENT_ADDRESS": _s(c.get("client_address")),
        "SAMPLE_NAME": _s(names),
        "MODEL": _s(models),
        "SAMPLE_NO": _s(sample_nos_str),
        "PRODUCT_NO": _s(product_nos or c.get("product_no")),
        "PRODUCTION_UNIT": _s(c.get("production_org_name")),
        "RECEIVE_DATE": _s(comm_date),
        "SAMPLE_CONDITION": sample_condition,
        "INSPECTION_CATEGORY": "委托检验",
        "REPORT_DATE": _s(str(report.get("publish_date", "") or ""))[:10],
        "TEST_DATE": "",
        "NOTES": _s(report.get("notes")),
        "SAMPLE_STATEMENT": _s(sample_statement),
        "CONCLUSION": report_conclusion,
        "TESTER": _s(tester_display),
        "VERIFIER": _s(verifier_display),
        "APPROVER": _s(approver_display),
        "EXPERIMENT": "",
        "STANDARD": "",
        "PHOTO_DESC": "",
    }

    # Gather experiments, test dates, environment, and measurement data from tasks
    experiments = []
    test_dates = []
    all_locations: list[str] = []
    env_conditions: list[dict] = []
    measurement_data: list[dict] = []
    for t in tasks:
        exp = t.get("experiment", "")
        if exp and exp not in experiments:
            experiments.append(exp)
        loc = t.get("detection_location", "")
        if loc and loc not in all_locations:
            all_locations.append(loc)
        rec = records.get(t.get("task_no", ""), {})
        payload = rec.get("payload", {}) if isinstance(rec.get("payload"), dict) else {}
        params = payload.get("_form", {}) or payload.get("parameters", {})
        if params.get("test_date"):
            test_dates.append(str(params["test_date"]))
        # Environment conditions from record
        temp = params.get("temperature_before") or params.get("temperature") or ""
        humidity = params.get("humidity_before") or params.get("humidity") or ""
        if loc or temp or humidity:
            env_conditions.append({
                "location": loc,
                "temperature": str(temp) if temp else "",
                "humidity": str(humidity) if humidity else "",
            })
        # Measurement rows from record
        rows = payload.get("_rows", []) or payload.get("measurements", [])
        for row in rows:
            if isinstance(row, dict) and row.get("sample_no"):
                measurement_data.append(row)

    fill_data["EXPERIMENT"] = "、".join(experiments)
    if test_dates:
        test_dates_sorted = sorted(set(test_dates))
        fill_data["TEST_DATE"] = test_dates_sorted[0] if len(test_dates_sorted) == 1 else f"{test_dates_sorted[0]}至{test_dates_sorted[-1]}"

    # Collect standards from tasks
    standards = []
    for t in tasks:
        std = t.get("standard", "")
        if std and std not in standards:
            standards.append(std)
    fill_data["STANDARD"] = "；".join(standards)

    # Photo description — check records + pass-through for appendix
    photo_notes = []
    for t in tasks:
        rec = records.get(t.get("task_no", ""), {})
        payload = rec.get("payload", {}) if isinstance(rec.get("payload"), dict) else {}
        payload_photos = payload.get("_photos", []) or payload.get("_images", []) or payload.get("images", [])
        if payload_photos:
            photo_notes.append(f"{t.get('experiment','')}附{len(payload_photos)}张照片")
    if photos:
        total = len(photos)
        if photo_notes:
            fill_data["PHOTO_DESC"] = "；".join(photo_notes) + f"（详见照片附件，共{total}张）"
        else:
            fill_data["PHOTO_DESC"] = f"详见照片附件（共{total}张）"
    else:
        fill_data["PHOTO_DESC"] = "；".join(photo_notes) if photo_notes else ""

    # Detection environment: location + temp/humidity summary
    env_parts = []
    if all_locations:
        env_parts.append("地点：" + "、".join(all_locations))
    if env_conditions:
        temps = [e["temperature"] for e in env_conditions if e["temperature"]]
        hums = [e["humidity"] for e in env_conditions if e["humidity"]]
        if temps:
            env_parts.append("温度：" + "～".join(sorted(set(temps))) + "℃" if len(set(temps)) > 1 else "温度：" + temps[0] + "℃")
        if hums:
            env_parts.append("相对湿度：" + "～".join(sorted(set(hums))) + "%" if len(set(hums)) > 1 else "相对湿度：" + hums[0] + "%")
    fill_data["DETECTION_ENV"] = "；".join(env_parts)

    _fill_placeholders(doc, fill_data)
    _fill_labels(doc, fill_data)

    # Equipment table (table 0 if exists)
    equipment_set = {}
    for t in tasks:
        rec = records.get(t.get("task_no", ""), {})
        payload = rec.get("payload", {}) if isinstance(rec.get("payload"), dict) else {}
        eq_checks = payload.get("_equipment_checks", [])
        for eq in eq_checks:
            key = eq.get("management_no", "")
            if key and key not in equipment_set:
                equipment_set[key] = eq

    eq_list = list(equipment_set.values())[:10]  # Show more equipment (up to 10)
    if eq_list and doc.tables:
        eq_table = doc.tables[0]
        eq_data = []
        for eq in eq_list:
            # Build 型号/规格 from model + management_no
            model_spec = eq.get("model", "") or ""
            mgmt_no = eq.get("management_no", "") or ""
            if mgmt_no:
                model_spec = f"{model_spec}（{mgmt_no}）" if model_spec else mgmt_no
            # Template columns: 设备名称 | 型号/规格 | 不确定度/准确度等级/最大允许误差 | 证书编号 | 溯源机构 | 有效期至
            cal_time = eq.get("calibration_time", "")
            if cal_time and str(cal_time).strip():
                cal_time = str(cal_time)[:10]
            else:
                cal_time = ""
            eq_data.append([
                eq.get("equipment_name", ""),
                model_spec,
                eq.get("measuring_range", ""),
                eq.get("calibration_certificate", eq.get("certificate_no", "")),
                eq.get("calibration_source", eq.get("manufacturer", "")),
                cal_time,
            ])
        _fill_table_data(eq_table, eq_data)

    # Environment conditions table (table 1 if exists, 4 columns: 地点/温度/湿度/备注)
    if len(doc.tables) >= 2 and env_conditions:
        env_table = doc.tables[1]
        env_data = []
        for ec in env_conditions:
            env_data.append([
                ec.get("location", ""), ec.get("temperature", ""),
                ec.get("humidity", ""), "",
            ])
        _fill_table_data(env_table, env_data)

    # Test results table (table 2 if exists, 6 columns: 序号/检验项目/标准要求/检验结果/单项结论/备注)
    if len(doc.tables) >= 3:
        results_table = doc.tables[2]
        results_data = []
        if measurement_data:
            for i, row in enumerate(measurement_data[:20], 1):
                sample_no = row.get("sample_no", "")
                # Use check_item from data, or experiment name from task as fallback
                check_item = row.get("check_item", "")
                if not check_item:
                    for t in tasks:
                        if t.get("sample_nos") and sample_no in str(t.get("sample_nos", "")):
                            check_item = t.get("experiment", "")
                            break
                if not check_item:
                    check_item = sample_no  # Last resort

                # Build 检验项目: experiment_name (sample_no)
                if check_item != sample_no:
                    item_label = f"{check_item}（{sample_no}）"
                else:
                    item_label = sample_no

                # Separate standard/limit fields from actual result fields
                std_fields = []
                res_fields = []
                # Actual data keys: sample_no, check_item, result, conclusion, note, _showNote
                skip_keys = {"sample_no", "check_item", "_showNote", "_note", "conclusion", "note", "experiment"}
                for k, v in row.items():
                    if k in skip_keys or k.startswith("_"):
                        continue
                    if v is None or str(v).strip() == "":
                        continue
                    val_str = str(v).strip()
                    # Simple result field → clean display
                    if k.lower() == "result":
                        res_fields.append(val_str)
                    elif any(w in k.lower() for w in ("limit", "spec", "upper", "lower", "max", "min", "限", "标准", "要求", "规定")):
                        std_fields.append(f"{k}={val_str}")
                    else:
                        res_fields.append(f"{k}={val_str}")
                conclusion = row.get("conclusion", "")
                note = row.get("note", "")
                std_text = "；".join(std_fields) if std_fields else (_standard_requirement(check_item) or "—")
                results_data.append([
                    i, item_label,
                    std_text,
                    "；".join(res_fields) if res_fields else "见原始记录",
                    str(conclusion) if conclusion else "—",
                    str(note) if note else "",
                ])
        else:
            # Fill with experiment names and standards if no measurement data
            for i, t in enumerate(tasks, 1):
                std_text = t.get("standard", "") or _standard_requirement(t.get("experiment", "")) or "按委托/产品技术要求"
                results_data.append([
                    i, t.get("experiment", ""), std_text, "见原始记录", "—", "",
                ])
        if results_data:
            _fill_table_data(results_table, results_data)

    # ── Photo appendix ──
    if photos:
        doc.add_page_break()
        doc.add_heading("照片附件", level=2)
        for i, img_path in enumerate(photos, 1):
            if img_path and Path(img_path).exists():
                try:
                    para = doc.add_paragraph()
                    run = para.add_run(f"照片{i}：{Path(img_path).name}")
                    run.font.size = Pt(9)
                    para2 = doc.add_paragraph()
                    para2.add_run().add_picture(img_path, width=Inches(5.5))
                    doc.add_paragraph()  # spacer
                except Exception:
                    doc.add_paragraph(f"照片{i}：{Path(img_path).name}（无法加载）")

    return _save(doc)


# ═══════════════════════════════════════════════════════════════
# Commission DOCX
# ═══════════════════════════════════════════════════════════════

def generate_commission_docx(
    commission: dict,
    groups: list[dict],
    tests: list[dict],
    receiver_name: str = "",
) -> bytes:
    """Fill FORM_COMMISSION.docx."""
    template = TEMPLATE_DIR / "FORM_COMMISSION.docx"
    if not template.exists():
        raise FileNotFoundError(f"委托单模板不存在: {template}")
    doc = Document(str(template))

    c = commission
    fill_data = {
        "CLIENT_NAME": c.get("client_name", ""),
        "CLIENT_ADDRESS": c.get("client_address", ""),
        "CONTACT": c.get("contact", ""),
        "PHONE": c.get("phone", ""),
        "COMMISSION_DATE": str(c.get("commission_date", "")),
        "DUE_DATE": str(c.get("due_date", "")),
        "PRODUCTION_UNIT": c.get("production_org_name", ""),
        "PRODUCTION_RELATION": c.get("production_relation", ""),
        "NOTES": c.get("notes", ""),
        "REPORT_MEDIUM": c.get("report_medium", "电子"),
        "CONFORMITY_JUDGMENT": c.get("conformity_judgment", ""),
        "DELIVERY_METHOD": c.get("delivery_method", ""),
    }
    _fill_placeholders(doc, fill_data)
    _fill_labels(doc, fill_data)

    # Fill sample groups table
    if groups and doc.tables:
        data = []
        for i, g in enumerate(groups, 1):
            group_tests = [t.get("experiment", "") for t in tests if t.get("group_no") == g.get("group_no")]
            data.append([
                i,
                f"{g.get('sample_name', '')}（{g.get('model', '')}）",
                g.get("group_no", ""),
                c.get("production_org_name", ""),
                "、".join(group_tests),
                g.get("quantity", 1),
                g.get("notes", "") or g.get("condition_note", ""),
            ])
        _fill_table_data(doc.tables[0], data)

    # 勾选框匹配（段落级；模板未勾选标记为 ¨，勾选写入 ☑）
    _fill_commission_checkboxes(doc, c, groups)

    return _save(doc)


def _fill_commission_checkboxes(doc: Document, c: dict, groups: list[dict]) -> None:
    """委托单段落级勾选：样品外观检查、检测能力满足度。"""
    import re

    bad = [g for g in groups if str(g.get("condition", "")).strip() and str(g.get("condition", "")).strip() != "完好"]
    bad_note = "；".join(
        f"{g.get('group_no', '')}:{g.get('condition_note', '') or g.get('condition', '')}" for g in bad
    )

    def _toggle(label: str, selected: bool) -> None:
        glyph = "☑" if selected else "¨"
        pattern = re.compile(r"[¨☑](?=\s*" + re.escape(label) + r")")
        for p in doc.paragraphs:
            if label not in p.text:
                continue
            text = pattern.sub(glyph, p.text, count=1)
            _set_para_text(p, text)
            return

    # 样品外观检查（同一段内两个选项，逐项勾选）
    _toggle("样品外观检查良好", not bad)
    _toggle("样品外观异常", bool(bad))

    # 检测能力满足度
    cap = str(c.get("capability", ""))
    _toggle("完全满足", cap == "完全满足")
    _toggle("部分满足", cap == "部分满足")
    _toggle("不满足", cap == "不满足")


# ═══════════════════════════════════════════════════════════════
# Delivery DOCX
# ═══════════════════════════════════════════════════════════════

def generate_delivery_docx(
    report: dict,
    commission: dict | None,
    groups: list[dict],
    deliveries: list[dict],
    report_actions: list[dict] | None = None,
) -> bytes:
    """Fill FORM_REPORT_DELIVERY.docx（含发放类型/介质/方式等勾选框与变更处理）。"""
    template = TEMPLATE_DIR / "FORM_REPORT_DELIVERY.docx"
    if not template.exists():
        raise FileNotFoundError(f"报告发放模板不存在: {template}")
    doc = Document(str(template))
    table = doc.tables[0]

    c = commission or {}
    sample_text = "；".join(
        f"{g.get('sample_name', '')}/{g.get('model', '')}" for g in groups if g.get("sample_name") or g.get("model")
    )

    ordered = sorted(deliveries, key=lambda x: str(x.get("delivered_at", "")))[:7]
    for offset in range(7):
        row = table.rows[offset + 1]
        if offset >= len(ordered):
            for index in (1, 2, 4, 5, 6, 7, 9, 10, 11, 13, 14):
                _set_cell_text(row.cells[index], "")
            continue
        item = ordered[offset]
        note = str(item.get("receipt_note") or "")
        delivery_type = "作废替换" if "作废替换" in note else ("更正" if "更正" in note else ("补发" if "补发" in note else "首次"))
        medium = str(c.get("report_medium") or "电子")
        medium_label = "纸质" if "纸" in medium else "电子"
        method = str(item.get("delivery_method") or "")
        method_label = "现场" if method in ("自取", "现场领取", "现场") else ("快递" if "快递" in method else ("邮件" if "邮件" in method else "系统"))
        values = {
            0: offset + 1,
            1: report.get("report_no", ""),
            2: item.get("client_name") or c.get("client_name", ""),
            4: sample_text,
            5: _checked("□首次 □补发/□更正 □作废替换", delivery_type),
            6: _checked("□纸质 □电子", medium_label) + "/份数：1",
            7: str(item.get("delivered_at", "")),
            9: _checked("□现场 □快递/□邮件 □系统", method_label),
            10: f"{item.get('recipient', '')} / {item.get('recipient_contact', '')}",
            11: f"{item.get('receipt_status', '')}；{note}".strip("；"),
            13: "",
            14: note,
        }
        for index, value in values.items():
            _set_cell_text(row.cells[index], value)

    # 发放前核对（表内第 9 行）：全部勾选通过项
    _set_cell_text(table.rows[8].cells[4], "☑审批签字完整  ☑报告编号一致  ☑页码完整  ☑专用章/电子章完整")
    _set_cell_text(table.rows[8].cells[9], "☑附表齐全  ☑照片/附件齐全  ☑电子文件可正常打开")
    _set_cell_text(table.rows[8].cells[16], "☑委托单位一致  ☑接收人信息正确  ☑交付方式符合约定")

    # 异常/退回 + 变更处理（第 10 行）
    actions = [
        x for x in (report_actions or [])
        if "作废" in str(x.get("action", "")) or "更正" in str(x.get("action", ""))
    ]
    latest_action = actions[-1] if actions else {}
    action_comment = str(latest_action.get("comment", ""))
    changed = bool(latest_action)
    _set_cell_text(table.rows[9].cells[4], f"{'□无  ☑有' if changed else '☑无  □有'}，说明：{action_comment if changed else ''}")
    _set_cell_text(
        table.rows[9].cells[9],
        f"申请/批准记录编号：{report.get('report_no', '')}-CHG-{latest_action.get('id', '')}" if changed else "申请/批准记录编号：不适用",
    )
    if "已收回" in action_comment:
        handling = "☑收回  □作废  □无法收回已书面告知  □仅电子替换  □不适用"
    elif "无法收回" in action_comment:
        handling = "□收回  ☑作废  ☑无法收回已书面告知  □仅电子替换  □不适用"
    elif "电子报告" in action_comment:
        handling = "□收回  ☑作废  □无法收回已书面告知  ☑仅电子替换  □不适用"
    elif changed:
        handling = "□收回  ☑作废  □无法收回已书面告知  □仅电子替换  □不适用"
    else:
        handling = "□收回  □作废  □无法收回已书面告知  □仅电子替换  ☑不适用"
    _set_cell_text(table.rows[9].cells[16], handling)

    # 签名区与归档位置（第 11-12 行，占位；签名图片由 _set_signature_cell 处理）
    latest = ordered[-1] if ordered else {}
    date_text = str(latest.get("delivered_at", ""))[:10]
    _set_cell_text(table.rows[10].cells[16], f"电子路径：系统单据中心/{report.get('report_no', '')}")
    _set_cell_text(table.rows[11].cells[4], date_text)
    if report.get("publish_date"):
        _set_cell_text(table.rows[11].cells[9], str(report.get("publish_date"))[:10])

    return _save(doc)


# ═══════════════════════════════════════════════════════════════
# Sample Register DOCX
# ═══════════════════════════════════════════════════════════════

def generate_sample_register_docx(
    commission: dict,
    groups: list[dict],
    samples: list[dict],
    tests: list[dict],
    receiver_name: str = "",
) -> bytes:
    """Fill FORM_SAMPLE_REGISTER.docx."""
    template = TEMPLATE_DIR / "FORM_SAMPLE_REGISTER.docx"
    if not template.exists():
        raise FileNotFoundError(f"样品登记模板不存在: {template}")
    doc = Document(str(template))

    c = commission
    fill_data = {
        "COMMISSION_NO": c.get("commission_no", ""),
        "CLIENT_NAME": c.get("client_name", ""),
        "COMMISSION_DATE": str(c.get("commission_date", "")),
        "RECEIVER": receiver_name,
    }
    _fill_placeholders(doc, fill_data)
    _fill_labels(doc, fill_data)

    gm = {g["group_no"]: g for g in groups}
    tm: dict[str, list[str]] = {}
    for t in tests:
        tm.setdefault(t["group_no"], []).append(t.get("experiment", ""))

    production_unit = c.get("production_org_name", "")
    # 生产单位为受委托生产企业时，附注关系后缀（合同制造/外协）
    if str(c.get("production_relation", "") or "") in ("合同制造", "外协"):
        production_unit = f"{production_unit}（受委托生产企业）"

    if samples and doc.tables:
        data = []
        for s in samples:
            g = gm.get(s.get("group_no", ""), {})
            data.append([
                s.get("sample_no", ""),
                c.get("client_name", ""),
                s.get("sample_name", ""),
                s.get("model", ""),
                production_unit,
                g.get("product_no", ""),
                "、".join(tm.get(s.get("group_no", ""), [])),
                1,
                receiver_name,
                str(c.get("commission_date", "")),
                s.get("condition_note", "") or g.get("notes", ""),
            ])
        _fill_table_data(doc.tables[0], data)

    return _save(doc)


# ═══════════════════════════════════════════════════════════════
# Sample Loan/Return DOCX
# ═══════════════════════════════════════════════════════════════

def generate_loan_return_docx(
    loans: list[dict],
    user_names: dict[str, str] | None = None,
) -> bytes:
    """Fill FORM_SAMPLE_LOAN_RETURN.docx."""
    template = TEMPLATE_DIR / "FORM_SAMPLE_LOAN_RETURN.docx"
    if not template.exists():
        raise FileNotFoundError(f"借出归还模板不存在: {template}")
    doc = Document(str(template))

    names = user_names or {}

    if loans and doc.tables:
        data = []
        for i, x in enumerate(loans, 1):
            purpose = x.get("purpose") or "、".join(json.loads(x.get("experiments", "[]")))
            data.append([
                i,
                x.get("sample_no", ""),
                names.get(x.get("borrower", ""), x.get("borrower", "")),
                str(x.get("borrowed_at", "")),
                purpose,
                str(x.get("returned_at", "")),
                names.get(x.get("returned_by", ""), x.get("returned_by", "")),
                x.get("return_note", "") or x.get("issue_note", ""),
            ])
        _fill_table_data(doc.tables[0], data)

    return _save(doc)


# ═══════════════════════════════════════════════════════════════
# Hazardous Waste DOCX
# ═══════════════════════════════════════════════════════════════

def generate_hazardous_waste_docx(item: dict) -> bytes:
    """Fill FORM_HAZARDOUS_WASTE.docx."""
    template = TEMPLATE_DIR / "FORM_HAZARDOUS_WASTE.docx"
    if not template.exists():
        raise FileNotFoundError(f"危废处置模板不存在: {template}")
    doc = Document(str(template))

    fill_data = {
        "DISPOSAL_NO": item.get("disposal_no", ""),
        "COMMISSION_NO": item.get("commission_no", ""),
        "WASTE_NAME": item.get("waste_name", ""),
        "WASTE_TYPE": item.get("waste_type", ""),
        "QUANTITY": str(item.get("quantity", "")),
        "UNIT": item.get("unit", ""),
        "HANDLER": item.get("handler", ""),
        "CONTAINER_NO": item.get("container_no", ""),
        "OCCURRED_AT": str(item.get("occurred_at", "")),
        "DISPOSAL_METHOD": item.get("disposal_method", ""),
        "HAZARD_CATEGORY": item.get("hazard_category", ""),
        "NOTE": item.get("note", ""),
        "STATUS": item.get("status", ""),
    }
    _fill_placeholders(doc, fill_data)
    _fill_labels(doc, fill_data)

    # 勾选框匹配（数据驱动）：来源类型 / 物理形态 / 废物类别
    waste_type = str(item.get("waste_type", ""))
    hazard_category = str(item.get("hazard_category", ""))

    def _toggle(cell, label):
        _set_cell_text(cell, _option_line(cell.text, label))

    if len(doc.tables) > 2:
        # T2 来源类型：□ 检测实验 □ 样品制备
        _toggle(doc.tables[2].cell(0, 0), "检测实验")
    if len(doc.tables) > 4:
        cls = doc.tables[4]
        # R0 分类结论 → 一般实验废物
        _toggle(cls.rows[0].cells[1], "一般实验废物")
        # R1 物理形态 → 液体/固体
        _toggle(cls.rows[1].cells[1], "液体" if "液" in waste_type else "固体")
        # R2 废物类别 → 实验废液 / 残余试剂
        if "液" in waste_type or "废液" in waste_type:
            _toggle(cls.rows[2].cells[1], "实验废液")
        elif "试剂" in waste_type:
            _toggle(cls.rows[2].cells[1], "残余试剂/标准溶液")
        else:
            _toggle(cls.rows[2].cells[1], "废弃样品/制样残余物")
        # R3 危害特性
        if "毒性" in hazard_category:
            _toggle(cls.rows[3].cells[1], "毒性")
        elif "易燃" in hazard_category:
            _toggle(cls.rows[3].cells[1], "易燃性")
        elif "腐蚀" in hazard_category:
            _toggle(cls.rows[3].cells[1], "腐蚀性")
        else:
            _toggle(cls.rows[3].cells[1], "无明显危害")
    if len(doc.tables) > 7:
        # T7 处置方式 → 已完成分类包装 + 处置方式
        disposal = doc.tables[7]
        if "中和" in str(item.get("disposal_method", "")):
            _toggle(disposal.rows[3].cells[1], "中和/预处理（经批准）")
        elif "破坏" in str(item.get("disposal_method", "")):
            _toggle(disposal.rows[3].cells[1], "破坏")

    return _save(doc)


# ═══════════════════════════════════════════════════════════════
# SOP: 标准操作规程文档生成
# ═══════════════════════════════════════════════════════════════

def generate_sop_docx(
    experiment_code: str = "",
    experiment_name: str = "",
    method_standard: str = "",
    sop_version: str = "A/0",
    effective_date: str = "",
    sop_file: str = "",
    equipment_list: list | None = None,
) -> bytes:
    """生成 SOP 文档 — 填入实验方法元数据"""
    from io import BytesIO
    from pathlib import Path
    from app.config import settings

    from docx import Document

    tmpl_dir = Path(settings.TEMPLATE_DIR)

    # 查找 SOP 模板文件
    sop_path = None

    # 1) If sop_file is specified and exists, use it directly
    if sop_file:
        direct = tmpl_dir / sop_file
        if direct.exists():
            sop_path = direct

    # 2) Derive from experiment_code (e.g. R015 → SOP-015_*.docx)
    if not sop_path and experiment_code:
        sop_code = experiment_code.replace("R", "SOP-")
        if not sop_code.startswith("SOP-"):
            sop_code = f"SOP-{sop_code}"
        for f in tmpl_dir.glob(f"{sop_code}_*.docx"):
            sop_path = f
            break
        if not sop_path:
            for f in tmpl_dir.glob(f"SOP-*_{experiment_code}*.docx"):
                sop_path = f
                break

    # 3) Fallback: first SOP template
    if not sop_path:
        for f in sorted(tmpl_dir.glob("SOP-*.docx")):
            sop_path = f
            break

    if not sop_path or not sop_path.exists():
        # 无模板时生成简易 SOP
        doc = Document()
        doc.styles['Normal'].font.name = 'SimSun'
        doc.styles['Normal'].element.rPr.rFonts.set('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}eastAsia', 'SimSun')
        if experiment_name:
            doc.add_heading(f"标准操作规程 — {experiment_name}", level=1)
        else:
            doc.add_heading("标准操作规程 (SOP)", level=1)
        doc.add_paragraph(f"实验方法: {experiment_name or '—'}")
        doc.add_paragraph(f"标准依据: {method_standard or '—'}")
        doc.add_paragraph(f"版本号: {sop_version}")
        if effective_date:
            doc.add_paragraph(f"生效日期: {effective_date}")
        return _save(doc)

    doc = Document(str(sop_path))

    # 替换占位符
    placeholders = {
        "EXPERIMENT_NAME": experiment_name or "",
        "METHOD_STANDARD": method_standard or "",
        "SOP_VERSION": sop_version or "A/0",
        "EFFECTIVE_DATE": effective_date or "",
        "TODAY": effective_date or "",
    }
    _fill_placeholders(doc, placeholders)
    _fill_labels(doc, placeholders)

    # 替换设备表格
    if equipment_list:
        equipment_table_data = [
            {
                "NO": str(i + 1),
                "NAME": eq.get("equipment_name", ""),
                "MODEL": eq.get("model", ""),
                "MANAGEMENT_NO": eq.get("management_no", ""),
                "RANGE": eq.get("measuring_range", ""),
                "ROLE": eq.get("binding_role", ""),
            }
            for i, eq in enumerate(equipment_list)
        ]
        _fill_table_data(doc, equipment_table_data)

    return _save(doc)


# ═══════════════════════════════════════════════════════════════
# Generic: DOCX → HTML preview helper
# ═══════════════════════════════════════════════════════════════

def docx_to_html(content: bytes, title: str = "文档预览") -> str:
    """Convert DOCX bytes to self-contained HTML for iframe preview."""
    try:
        from app.services.docx_preview import docx_review_html
        return docx_review_html(content, title)
    except ImportError:
        return f"<html><body><h2>{title}</h2><p>预览服务暂不可用</p></body></html>"
