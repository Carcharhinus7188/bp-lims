# -*- coding: utf-8 -*-
from __future__ import annotations

from io import BytesIO
import json
import re
from pathlib import Path
from typing import Any

import xlsxwriter


def _safe_sheet_name(name: str, used: set[str]) -> str:
    value = re.sub(r"[\\/*?:\[\]]", "_", str(name or "实验"))[:31]
    base = value or "实验"
    counter = 2
    while value in used:
        suffix = f"_{counter}"
        value = (base[:31-len(suffix)] + suffix)
        counter += 1
    used.add(value)
    return value


def _json_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(x) for x in value]
    try:
        return [str(x) for x in json.loads(value or "[]")]
    except Exception:
        return []


def build_internal_trace_workbook(commission_no: str) -> BytesIO:
    from lims_db import (
        commission, commission_groups, commission_tasks, latest_record,
        task_config_snapshot, list_attachments, rows, package, attachment_file,
    )

    c = commission(commission_no) or {}
    groups = {x["id"]: x for x in commission_groups(commission_no)}
    tasks = commission_tasks(commission_no)
    attachments = list_attachments(commission_no=commission_no)
    attachment_by_task: dict[str, list[dict[str, Any]]] = {}
    for item in attachments:
        attachment_by_task.setdefault(item.get("task_no", ""), []).append(item)

    output = BytesIO()
    wb = xlsxwriter.Workbook(output, {"in_memory": True})
    wb.set_properties({
        "title": f"{commission_no} 内部实验数据追溯工作簿",
        "subject": "实验数据、附件、修订和复核内部追溯",
        "company": "大连标普检测有限公司",
        "comments": "本工作簿不替代正式受控原始记录表。",
    })
    fmt_title = wb.add_format({"bold": True, "font_size": 16, "font_color": "#FFFFFF", "bg_color": "#12364A", "align": "center", "valign": "vcenter"})
    fmt_header = wb.add_format({"bold": True, "font_color": "#FFFFFF", "bg_color": "#176B87", "border": 1, "align": "center", "valign": "vcenter", "text_wrap": True})
    fmt_cell = wb.add_format({"border": 1, "valign": "top", "text_wrap": True})
    fmt_center = wb.add_format({"border": 1, "align": "center", "valign": "vcenter", "text_wrap": True})
    fmt_note = wb.add_format({"font_color": "#555555", "bg_color": "#F3F7F9", "border": 1, "text_wrap": True, "valign": "top"})
    fmt_link = wb.add_format({"font_color": "#0563C1", "underline": 1, "border": 1, "text_wrap": True})
    fmt_subtitle = wb.add_format({"bold": True, "font_color": "#12364A", "bg_color": "#DDEBF7", "border": 1})

    def title(ws, text, last_col):
        ws.merge_range(0, 0, 1, last_col, text, fmt_title)
        ws.set_row(0, 26)
        ws.freeze_panes(4, 0)

    used: set[str] = set()
    ws = wb.add_worksheet(_safe_sheet_name("00_使用说明", used))
    title(ws, "BPLab 内部实验数据与附件追溯工作簿", 7)
    ws.write(2, 0, "委托编号", fmt_header); ws.write(2, 1, commission_no, fmt_cell)
    ws.write(2, 2, "委托单位", fmt_header); ws.write(2, 3, c.get("client_name", ""), fmt_cell)
    ws.write(2, 4, "生产单位", fmt_header); ws.write(2, 5, c.get("production_org_name", ""), fmt_cell)
    ws.write(2, 6, "生成说明", fmt_header); ws.write(2, 7, "本工作簿用于内部附件、数据和审核追溯，不替代正式原始记录。", fmt_note)
    instructions = [
        ("正式原始记录", "以系统按受控Word模板直接填写并锁定的原始记录为准。"),
        ("附件", "原图和原始文件独立保存；Excel登记附件ID、相对路径和SHA-256。"),
        ("附件索引字段", "仅记录附件本身、关联任务、文件关系、时间、人员和校验信息。"),
        ("时间", "统一使用中国大陆时区 Asia/Shanghai（UTC+8）。"),
        ("图片", "图片粘贴区仅用于重要缩略图；原文件仍以附件索引和文件目录为准。"),
    ]
    ws.write_row(5, 0, ["项目", "填写与使用要求"], fmt_header)
    for i, row in enumerate(instructions, 6):
        ws.write(i, 0, row[0], fmt_cell); ws.write(i, 1, row[1], fmt_note)
    ws.set_column("A:A", 18); ws.set_column("B:B", 65); ws.set_column("C:H", 18)

    # Experiment ledger.
    ws = wb.add_worksheet(_safe_sheet_name("01_实验总台账", used))
    headers = ["任务编号","委托编号","样品组编号","实体样品编号","样品名称","规格型号","材料名称","实验名称","检测方法","检测地点","实验员","复核员","任务状态","记录版本","记录状态","配置版本","原始记录模板","附件数量","配置快照SHA-256","最后更新时间"]
    title(ws, "实验总台账与追溯状态", len(headers)-1)
    ws.write_row(3, 0, headers, fmt_header)
    for r, task in enumerate(tasks, 4):
        g = groups.get(task.get("group_id"), {})
        rec = latest_record(task["task_no"])
        snap = task_config_snapshot(task["task_no"])
        p = package(task.get("package_no", "")) or {}
        values = [
            task["task_no"], commission_no, task.get("group_no", ""), "、".join(task.get("sample_nos_list") or _json_list(task.get("sample_nos"))),
            g.get("sample_name", ""), g.get("model", ""), task.get("material_name", ""), task.get("experiment", ""), task.get("method_code", ""),
            p.get("detection_location", ""), task.get("assignee", ""), task.get("reviewer", ""), task.get("status", ""),
            (rec or {}).get("version", ""), (rec or {}).get("status", ""), snap.get("config_version", ""), snap.get("record_template_file", ""),
            len(attachment_by_task.get(task["task_no"], [])), snap.get("snapshot_hash", ""), (rec or {}).get("updated_at", task.get("updated_at", "")),
        ]
        ws.write_row(r, 0, values, fmt_cell)
    ws.autofilter(3, 0, max(3, 3+len(tasks)), len(headers)-1)
    ws.set_column(0, 0, 28); ws.set_column(1, 2, 20); ws.set_column(3, 3, 36); ws.set_column(4, 9, 20); ws.set_column(10, 17, 16); ws.set_column(18, 18, 68); ws.set_column(19, 19, 22)

    # Attachment and immutable photo-evidence index.
    ws = wb.add_worksheet(_safe_sheet_name("02_附件索引", used))
    headers = ["附件编号","委托编号","任务包编号","任务编号","样品编号","附件类型","拍摄节点","采集来源","证据状态","设备标识","原始文件名","相对路径","SHA-256","服务器拍摄时间","上传人","内容说明","是否原始文件","关联原附件编号","上传时间"]
    title(ws, "截图、照片、曲线和原始文件附件索引", len(headers)-1)
    ws.write_row(3, 0, headers, fmt_header)
    for r, item in enumerate(attachments, 4):
        values = [item.get("attachment_id",""),item.get("commission_no",""),item.get("package_no",""),item.get("task_no",""),item.get("sample_no",""),item.get("attachment_type",""),item.get("checkpoint_label",""),item.get("capture_source",""),item.get("evidence_status",""),item.get("device_id",""),item.get("original_name",""),item.get("relative_path",""),item.get("sha256",""),item.get("server_captured_at") or item.get("captured_at",""),item.get("uploader",""),item.get("description",""),"是" if item.get("is_original") else "否",item.get("parent_attachment_id",""),item.get("created_at","")]
        ws.write_row(r, 0, values, fmt_cell)
    ws.autofilter(3, 0, max(3, 3+len(attachments)), len(headers)-1)
    ws.set_column(0, 9, 20); ws.set_column(10, 11, 34); ws.set_column(12, 12, 68); ws.set_column(13, 14, 22); ws.set_column(15, 15, 38); ws.set_column(16, 18, 20)

    ws = wb.add_worksheet(_safe_sheet_name("03_图片粘贴区", used))
    title(ws, "实验现场照片留档", 7)
    ws.merge_range(2, 0, 2, 7, "照片由平板现场相机取得；本页展示服务器时间戳副本，原图和SHA-256见附件索引。", fmt_note)
    photo_items=[x for x in attachments if x.get("capture_source")=="live_camera" and not x.get("is_original")]
    if not photo_items:
        ws.merge_range(4,0,10,7,"暂无现场照片",fmt_center)
    for index,item in enumerate(photo_items):
        row=4+index*15
        ws.merge_range(row,0,row,7,f"{item.get('task_no','')}｜{item.get('checkpoint_label','')}｜{item.get('server_captured_at','')}｜{item.get('evidence_status','')}",fmt_subtitle)
        path=attachment_file(item)
        if path.exists() and path.suffix.lower() in (".jpg",".jpeg",".png",".webp"):
            ws.insert_image(row+1,0,str(path),{"x_scale":0.22,"y_scale":0.22,"object_position":1})
        ws.merge_range(row+1,5,row+12,7,
            f"附件编号：{item.get('attachment_id','')}\n样品：{item.get('sample_no','')}\n设备：{item.get('device_id','')}\nSHA-256：{item.get('sha256','')}\n原图：{item.get('parent_attachment_id','')}",
            fmt_note)
        for image_row in range(row+1,row+13):
            ws.set_row(image_row,24)
    ws.set_column(0,4,18);ws.set_column(5,7,22)

    audits = rows("SELECT * FROM audit_logs WHERE entity_type='record' AND entity_id IN (SELECT task_no FROM tasks WHERE commission_no=?) ORDER BY id", (commission_no,))
    ws = wb.add_worksheet(_safe_sheet_name("04_修改记录", used))
    headers = ["修改编号","实验编号","操作","字段","原值","修改后值","修改原因","修改人","角色","服务器时间","设备","前一日志哈希","本日志哈希"]
    title(ws, "实验数据修改前后追踪", len(headers)-1)
    ws.write_row(3,0,headers,fmt_header)
    for r,item in enumerate(audits,4):
        ws.write_row(r,0,[item.get("id",""),item.get("entity_id",""),item.get("action",""),item.get("field_name",""),item.get("old_value",""),item.get("new_value",""),item.get("reason",""),item.get("actor_name") or item.get("actor",""),item.get("actor_role",""),item.get("created_at",""),item.get("device_id",""),item.get("previous_hash",""),item.get("entry_hash","")],fmt_cell)
    ws.set_column(0,3,22); ws.set_column(4,6,38); ws.set_column(7,10,22);ws.set_column(11,12,68)

    timeline = rows(
        """SELECT created_at,actor,action,entity_type,entity_id,reason
           FROM audit_logs
           WHERE entity_id=? OR entity_id IN (SELECT task_no FROM tasks WHERE commission_no=?)
              OR entity_id IN (SELECT report_no FROM reports WHERE commission_no=?)
           ORDER BY created_at,id""",
        (commission_no,commission_no,commission_no),
    )
    ws=wb.add_worksheet(_safe_sheet_name("05_全过程时间轴",used))
    headers=["服务器时间","操作者","事件","对象类型","对象编号","说明"]
    title(ws,"委托、样品、实验、报告全过程时间轴",len(headers)-1)
    ws.write_row(3,0,headers,fmt_header)
    for r,item in enumerate(timeline,4):
        ws.write_row(r,0,[item.get("created_at",""),item.get("actor",""),item.get("action",""),item.get("entity_type",""),item.get("entity_id",""),item.get("reason","")],fmt_cell)
    ws.set_column(0,1,22);ws.set_column(2,4,28);ws.set_column(5,5,55)

    reviews = rows("SELECT r.* FROM reviews r JOIN tasks t ON t.task_no=r.record_no WHERE t.commission_no=? ORDER BY r.id", (commission_no,))
    ws = wb.add_worksheet(_safe_sheet_name("06_复核记录", used))
    headers = ["复核编号","实验编号","记录版本","复核人","决定","复核意见","复核时间"]
    title(ws, "原始记录复核追溯", len(headers)-1)
    ws.write_row(3,0,headers,fmt_header)
    for r,item in enumerate(reviews,4):
        ws.write_row(r,0,[item.get("id",""),item.get("record_no",""),item.get("version",""),item.get("reviewer",""),item.get("decision",""),item.get("comment",""),item.get("reviewed_at","")],fmt_cell)
    ws.set_column(0,4,22); ws.set_column(5,5,45); ws.set_column(6,6,22)

    # One concise worksheet per experiment in the selected commission.
    for index, task in enumerate(tasks, 1):
        name = _safe_sheet_name(f"实验{index:02d}_{task.get('experiment','实验')}", used)
        ws = wb.add_worksheet(name)
        title(ws, f"{task.get('experiment','')}｜{task.get('method_code','')}", 7)
        g = groups.get(task.get("group_id"), {})
        rec = latest_record(task["task_no"])
        snap = task_config_snapshot(task["task_no"])
        p = package(task.get("package_no", "")) or {}
        pairs = [
            ("任务编号",task["task_no"]),("委托编号",commission_no),("样品组编号",task.get("group_no","")),
            ("实体样品编号","、".join(task.get("sample_nos_list") or [])),("样品名称",g.get("sample_name","")),("规格型号",g.get("model","")),
            ("材料名称",task.get("material_name","")),("检测地点",p.get("detection_location","")),("实验员",task.get("assignee","")),
            ("复核员",task.get("reviewer","")),("任务状态",task.get("status","")),("记录版本",(rec or {}).get("version","")),
            ("记录状态",(rec or {}).get("status","")),("配置版本",snap.get("config_version","")),("受控原始记录模板",snap.get("record_template_file","")),
            ("配置快照SHA-256",snap.get("snapshot_hash","")),("附件数量",len(attachment_by_task.get(task["task_no"],[]))),
            ("报告结果摘要",((rec or {}).get("payload") or {}).get("report_summary","") if rec else ""),
            ("单项结论",((rec or {}).get("payload") or {}).get("report_conclusion","") if rec else ""),
        ]
        for r,(label,value) in enumerate(pairs,3):
            ws.write(r,0,label,fmt_header); ws.merge_range(r,1,r,7,str(value or ""),fmt_cell)
        attachment_header_row=len(pairs)+4
        ws.write(attachment_header_row,0,"附件编号",fmt_header); ws.write(attachment_header_row,1,"附件类型",fmt_header); ws.write(attachment_header_row,2,"样品编号",fmt_header); ws.write(attachment_header_row,3,"文件名",fmt_header); ws.write(attachment_header_row,4,"相对路径",fmt_header); ws.write(attachment_header_row,5,"SHA-256",fmt_header); ws.write(attachment_header_row,6,"时间",fmt_header); ws.write(attachment_header_row,7,"说明",fmt_header)
        task_attachments=attachment_by_task.get(task["task_no"],[])
        for j,item in enumerate(task_attachments,attachment_header_row+1):
            ws.write_row(j,0,[item.get("attachment_id",""),item.get("attachment_type",""),item.get("sample_no",""),item.get("original_name",""),item.get("relative_path",""),item.get("sha256",""),item.get("captured_at",""),item.get("description","")],fmt_cell)
        data_start=attachment_header_row+len(task_attachments)+3
        business=((rec or {}).get("payload") or {}).get("business_record",{}) if rec else {}
        ws.merge_range(data_start,0,data_start,7,"全部实验参数与原始数据",fmt_subtitle)
        data_row=data_start+1
        ws.write_row(data_row,0,["数据区","字段","值","","","","",""],fmt_header)
        data_row+=1
        for key,value in (business.get("parameters") or {}).items():
            ws.write(data_row,0,"参数",fmt_cell);ws.write(data_row,1,str(key),fmt_cell);ws.merge_range(data_row,2,data_row,7,str(value),fmt_cell);data_row+=1
        raw_rows=business.get("rows") or []
        raw_columns=list(dict.fromkeys(key for raw in raw_rows for key in raw.keys()))
        if raw_columns:
            ws.write(data_row,0,"原始数据",fmt_header)
            for col_index,column in enumerate(raw_columns[:7],1):
                ws.write(data_row,col_index,column,fmt_header)
            data_row+=1
            for raw in raw_rows:
                ws.write(data_row,0,"测量值",fmt_cell)
                for col_index,column in enumerate(raw_columns[:7],1):
                    ws.write(data_row,col_index,str(raw.get(column,"")),fmt_cell)
                data_row+=1
        ws.set_column(0,0,22); ws.set_column(1,3,24); ws.set_column(4,4,38); ws.set_column(5,5,68); ws.set_column(6,7,24)

    wb.close()
    output.seek(0)
    return output
