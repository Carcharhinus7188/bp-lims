# -*- coding: utf-8 -*-
from __future__ import annotations

from io import BytesIO
import json
import re
from typing import Any

import xlsxwriter

from constants import REPORT_DECISIVE_PHOTO_CODES
from experiment_engine import schema


def _json_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(x) for x in value]
    try:
        return [str(x) for x in json.loads(value or "[]")]
    except Exception:
        return []


def _text(value: Any) -> str:
    if isinstance(value, list):
        return "、".join(str(x) for x in value)
    if isinstance(value, dict):
        return json.dumps(value, ensure_ascii=False, default=str)
    return "" if value is None else str(value)


def _field_labels(kind: str) -> dict[str, str]:
    definition = schema(kind)
    labels: dict[str, str] = {}
    for section in definition.get("sections", []):
        for field in section.get("fields", []):
            labels[field["key"]] = field.get("label") or field["key"]
    for key, label, _typ in definition.get("columns", []):
        labels[key] = label
    labels.update({
        "report_summary": "报告结果摘要", "report_conclusion": "单项结论",
        "overall_status": "实验完成状态", "deviation": "异常/偏离及处理",
        "retest": "是否复测", "precheck_note": "实验前检查说明",
    })
    return labels


def build_internal_trace_workbook(commission_no: str) -> BytesIO:
    """Quality-investigation workbook: evidence first, technical detail second."""
    from lims_db import (
        commission, commission_groups, commission_tasks, latest_record,
        task_config_snapshot, list_attachments, attachment_file, rows,
        modification_logs,
    )

    c = commission(commission_no) or {}
    groups = {x["id"]: x for x in commission_groups(commission_no)}
    tasks = commission_tasks(commission_no)
    attachments = list_attachments(commission_no=commission_no)
    attachments_by_task: dict[str, list[dict[str, Any]]] = {}
    for item in attachments:
        attachments_by_task.setdefault(item.get("task_no", ""), []).append(item)
    objections = rows("SELECT * FROM objections WHERE commission_no=? ORDER BY created_at", (commission_no,))

    output = BytesIO()
    wb = xlsxwriter.Workbook(output, {"in_memory": True})
    wb.set_properties({
        "title": f"{commission_no} 异议调查追溯表",
        "subject": "供质量负责人调查客户异议使用",
        "company": "大连标普检测有限公司",
    })
    title_fmt = wb.add_format({"bold": True, "font_size": 16, "font_color": "#FFFFFF", "bg_color": "#12364A", "align": "center", "valign": "vcenter"})
    header_fmt = wb.add_format({"bold": True, "font_color": "#FFFFFF", "bg_color": "#176B87", "border": 1, "align": "center", "valign": "vcenter", "text_wrap": True})
    cell_fmt = wb.add_format({"border": 1, "valign": "top", "text_wrap": True})
    center_fmt = wb.add_format({"border": 1, "align": "center", "valign": "vcenter", "text_wrap": True})
    note_fmt = wb.add_format({"border": 1, "bg_color": "#F3F7F9", "font_color": "#475569", "valign": "top", "text_wrap": True})
    alert_fmt = wb.add_format({"border": 1, "bg_color": "#FFF2CC", "font_color": "#9C5700", "bold": True, "text_wrap": True})
    good_fmt = wb.add_format({"border": 1, "bg_color": "#E2F0D9", "font_color": "#375623", "bold": True, "text_wrap": True})

    def setup(ws, title: str, last_col: int) -> None:
        ws.hide_gridlines(2)
        ws.merge_range(0, 0, 1, last_col, title, title_fmt)
        ws.set_row(0, 26)
        ws.freeze_panes(4, 0)

    # 1. Investigation overview.
    ws = wb.add_worksheet("调查总览")
    setup(ws, "客户异议调查总览", 7)
    overview = [
        ("委托编号", commission_no), ("委托单位", c.get("client_name", "")),
        ("委托联系人", c.get("contact", "")), ("联系电话", c.get("phone", "")),
        ("生产单位", c.get("production_org_name", "")), ("任务数量", len(tasks)),
        ("现场照片数量", len([x for x in attachments if x.get("capture_source") == "live_camera" and not x.get("is_original")])),
        ("追溯表用途", "质量负责人调查客户异议；正式结论仍应在系统异议流程中签发。"),
    ]
    for index, (label, value) in enumerate(overview):
        row = 2 + index // 2
        col = (index % 2) * 4
        ws.write(row, col, label, header_fmt)
        ws.merge_range(row, col + 1, row, col + 3, _text(value), cell_fmt)
    start = 7
    ws.write_row(start, 0, ["异议编号", "报告编号", "异议内容", "调查路径", "调查结论", "质量负责人", "状态", "更新时间"], header_fmt)
    if objections:
        for offset, item in enumerate(objections, start + 1):
            ws.write_row(offset, 0, [
                item.get("objection_no", ""), item.get("report_no", ""), item.get("description", ""),
                item.get("pathway", ""), item.get("trace_conclusion", ""), item.get("quality_inspector", ""),
                item.get("status", ""), item.get("updated_at", ""),
            ], cell_fmt)
    else:
        ws.merge_range(start + 1, 0, start + 2, 7, "尚未登记客户异议。本表仍可用于预调查和内部追溯。", note_fmt)
    ws.set_column("A:B", 22); ws.set_column("C:E", 34); ws.set_column("F:H", 20)

    # 2. Data-photo correspondence - the main investigation sheet.
    ws = wb.add_worksheet("数据与照片对应")
    headers = ["任务编号", "实验项目", "样品编号", "原始数据（中文字段）", "计算结果/结论", "决定性照片节点", "照片附件编号与时间", "证据状态", "照片缩略图"]
    setup(ws, "数据与决定性照片对应表", len(headers) - 1)
    ws.write_row(3, 0, headers, header_fmt)
    row_index = 4
    for task in tasks:
        rec = latest_record(task["task_no"]) or {}
        payload = rec.get("payload") or {}
        business = payload.get("business_record") or {}
        kind = (task_config_snapshot(task["task_no"]) or {}).get("kind") or "generic"
        labels = _field_labels(kind)
        raw_rows = business.get("rows") or [{"sample_no": sample_no} for sample_no in task.get("sample_nos_list") or _json_list(task.get("sample_nos"))]
        decisive_codes = REPORT_DECISIVE_PHOTO_CODES.get(task.get("experiment", ""), [])
        task_photos = [
            item for item in attachments_by_task.get(task["task_no"], [])
            if item.get("capture_source") == "live_camera"
            and not item.get("is_original")
            and item.get("evidence_status") == "有效"
            and item.get("checkpoint_code") in decisive_codes
        ]
        for raw in raw_rows:
            sample_no = raw.get("sample_no", "")
            photo_rows = [x for x in task_photos if x.get("sample_no") in ("", sample_no)]
            values = [
                f"{labels[key]}：{_text(value)}"
                for key, value in raw.items()
                if key in labels and key not in ("sample_no", "note")
                and not key.startswith("_") and value not in (None, "")
            ]
            conclusion = "；".join(filter(None, [
                f"{labels.get('report_summary')}：{business.get('report_summary','')}",
                f"{labels.get('report_conclusion')}：{business.get('report_conclusion','')}",
                f"单样判定：{raw.get('conclusion','')}" if raw.get("conclusion") else "",
            ]))
            node_text = "、".join(dict.fromkeys(x.get("checkpoint_label", "") for x in photo_rows))
            photo_text = "\n".join(
                f"{x.get('attachment_id','')}｜{x.get('server_captured_at','')}｜{x.get('sample_no') or '任务整体'}"
                for x in photo_rows
            )
            status = "证据完整" if photo_rows else "缺少决定性照片"
            ws.write_row(row_index, 0, [
                task["task_no"], task.get("experiment", ""), sample_no,
                "\n".join(values), conclusion, node_text, photo_text, status, "",
            ], cell_fmt)
            ws.write(row_index, 7, status, good_fmt if photo_rows else alert_fmt)
            ws.set_row(row_index, 105)
            if photo_rows:
                path = attachment_file(photo_rows[0])
                if path.exists() and path.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp"):
                    ws.insert_image(row_index, 8, str(path), {
                        "x_scale": 0.15, "y_scale": 0.15, "x_offset": 4, "y_offset": 4,
                        "object_position": 1, "description": node_text or "决定性结果照片",
                    })
            row_index += 1
    ws.autofilter(3, 0, max(3, row_index - 1), len(headers) - 1)
    ws.set_column(0, 0, 27); ws.set_column(1, 2, 22); ws.set_column(3, 4, 50)
    ws.set_column(5, 7, 28); ws.set_column(8, 8, 24)

    # 3. Key timeline.
    ws = wb.add_worksheet("关键时间轴")
    headers = ["服务器时间", "任务/单据", "关键事件", "操作者", "角色", "说明"]
    setup(ws, "样品、实验、照片、报告与异议关键时间轴", len(headers) - 1)
    ws.write_row(3, 0, headers, header_fmt)
    timeline_terms = ("收样", "入库", "派发", "接收", "领用", "开始实验", "实验开始", "实验结束", "拍照", "提交复核", "复核", "签发", "发放", "异议")
    timeline = rows(
        """SELECT * FROM audit_logs
           WHERE entity_id=? OR entity_id IN (SELECT task_no FROM tasks WHERE commission_no=?)
              OR entity_id IN (SELECT report_no FROM reports WHERE commission_no=?)
              OR entity_id IN (SELECT objection_no FROM objections WHERE commission_no=?)
           ORDER BY created_at,id""",
        (commission_no, commission_no, commission_no, commission_no),
    )
    timeline = [x for x in timeline if any(term in str(x.get("action", "")) for term in timeline_terms)]
    for offset, item in enumerate(timeline, 4):
        ws.write_row(offset, 0, [
            item.get("created_at", ""), item.get("entity_id", ""), item.get("action", ""),
            item.get("actor_name") or item.get("actor", ""), item.get("actor_role", ""),
            item.get("reason") or item.get("new_value", ""),
        ], cell_fmt)
    ws.autofilter(3, 0, max(3, 3 + len(timeline)), len(headers) - 1)
    ws.set_column(0, 1, 24); ws.set_column(2, 4, 22); ws.set_column(5, 5, 55)

    # 4. Modification and version records.
    ws = wb.add_worksheet("修改与版本")
    headers = ["修改编号", "对象", "修改位置", "动作", "修改前", "修改后", "原因", "操作者/角色", "服务器时间"]
    setup(ws, "与本委托有关的修改、作废和更正记录", len(headers) - 1)
    ws.write_row(3, 0, headers, header_fmt)
    task_nos = {x["task_no"] for x in tasks}
    report_nos = {x["report_no"] for x in rows("SELECT report_no FROM reports WHERE commission_no=?", (commission_no,))}
    objection_nos = {x.get("objection_no") for x in objections}
    related = {commission_no} | task_nos | report_nos | objection_nos
    changes = [x for x in modification_logs() if x.get("entity_id") in related]
    for offset, item in enumerate(changes, 4):
        ws.write_row(offset, 0, [
            item.get("id", ""), f"{item.get('entity_type','')} / {item.get('entity_id','')}",
            item.get("field_label", ""), item.get("action", ""), item.get("old_value", ""),
            item.get("new_value", ""), item.get("reason", ""),
            f"{item.get('actor_name') or item.get('actor','')} / {item.get('actor_role','')}",
            item.get("created_at", ""),
        ], cell_fmt)
    ws.autofilter(3, 0, max(3, 3 + len(changes)), len(headers) - 1)
    ws.set_column(0, 1, 24); ws.set_column(2, 6, 40); ws.set_column(7, 8, 24)

    # 5. Complete normalized raw data; no first-seven-column truncation.
    ws = wb.add_worksheet("完整原始数据")
    headers = ["任务编号", "实验项目", "样品编号", "数据区域", "中文字段", "记录值", "记录版本", "记录状态"]
    setup(ws, "完整原始数据（逐字段展开）", len(headers) - 1)
    ws.write_row(3, 0, headers, header_fmt)
    out_row = 4
    for task in tasks:
        rec = latest_record(task["task_no"]) or {}
        business = (rec.get("payload") or {}).get("business_record") or {}
        kind = (task_config_snapshot(task["task_no"]) or {}).get("kind") or "generic"
        labels = _field_labels(kind)
        for key, value in (business.get("parameters") or {}).items():
            if key not in labels:
                continue
            ws.write_row(out_row, 0, [
                task["task_no"], task.get("experiment", ""), "", "环境/参数",
                labels[key], _text(value), rec.get("version", ""), rec.get("status", ""),
            ], cell_fmt); out_row += 1
        for raw in business.get("rows") or []:
            for key, value in raw.items():
                if key.startswith("_") or key not in labels:
                    continue
                ws.write_row(out_row, 0, [
                    task["task_no"], task.get("experiment", ""), raw.get("sample_no", ""), "原始测量",
                    labels[key], _text(value), rec.get("version", ""), rec.get("status", ""),
                ], cell_fmt); out_row += 1
    ws.autofilter(3, 0, max(3, out_row - 1), len(headers) - 1)
    ws.set_column(0, 2, 24); ws.set_column(3, 4, 26); ws.set_column(5, 5, 48); ws.set_column(6, 7, 18)

    # 6. Human-readable evidence directory. Internal paths, hashes and IDs stay in the database.
    ws = wb.add_worksheet("照片证据目录")
    headers = ["照片编号", "任务编号", "样品编号", "拍摄节点", "证据状态", "文件名称", "拍摄时间", "拍摄人"]
    setup(ws, "照片证据目录", len(headers) - 1)
    ws.write_row(3, 0, headers, header_fmt)
    for offset, item in enumerate(attachments, 4):
        ws.write_row(offset, 0, [
            item.get("attachment_id", ""), item.get("task_no", ""), item.get("sample_no", ""),
            item.get("checkpoint_label", ""), item.get("evidence_status", ""),
            item.get("original_name", ""),
            item.get("server_captured_at") or item.get("captured_at", ""), item.get("uploader", ""),
        ], cell_fmt)
    ws.autofilter(3, 0, max(3, 3 + len(attachments)), len(headers) - 1)
    ws.set_column(0, 4, 24); ws.set_column(5, 5, 42); ws.set_column(6, 7, 24)

    wb.close()
    output.seek(0)
    return output
