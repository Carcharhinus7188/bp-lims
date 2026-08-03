# -*- coding: utf-8 -*-
from __future__ import annotations

import json
from io import BytesIO

from PIL import Image, ImageDraw

from business_record_engine import (
    business_to_template_fields,
    calculate_business_record,
    fixed_and_manual_fields,
    initialize_business_record,
    visible_row_fields,
)
from experiment_engine import calculate_rows
from lims_db import (
    accept_package,
    approver_review_report,
    china_today,
    commission,
    commission_groups,
    commission_tasks,
    connect,
    create_notification,
    create_commission,
    create_task_package,
    ensure_report_for_task,
    freeze_document_version,
    group_samples,
    list_experiment_methods,
    list_attachments,
    list_organizations,
    now,
    package_tasks,
    quality_review_report,
    report,
    task_config_snapshot,
    add_report_delivery,
)
from camera_evidence import save_live_camera_photo
from constants import REPORT_DECISIVE_PHOTO_CODES, SAMPLE_LEVEL_PHOTO_CODES, photo_checkpoints


DEMO_COMMISSION_NO = "WT20990101001"
DEMO_GROUP_NO = "BP20990101001"
PENDING_DEMO_COMMISSION_NO = "WT20990101002"
PENDING_DEMO_GROUP_NO = "BP20990101002"


def _add_demo_result_photos(
    task_row: dict, sample_ids: list[str], all_required: bool = False,
    black: bool = False,
) -> None:
    """Create deterministic camera-style evidence so the document demo includes photos."""
    checkpoint_labels = {code: label for code, label, _required in photo_checkpoints(task_row["experiment"])}
    codes = (
        [code for code, _label, required in photo_checkpoints(task_row["experiment"]) if required]
        if all_required else REPORT_DECISIVE_PHOTO_CODES.get(task_row["experiment"], ["RESULT"])
    )
    existing={
        (item.get("checkpoint_code"),item.get("sample_no") or "")
        for item in list_attachments(task_no=task_row["task_no"])
        if item.get("capture_source")=="live_camera" and item.get("evidence_status")=="有效"
    }
    for code in codes:
        entities = sample_ids if code in SAMPLE_LEVEL_PHOTO_CODES else [""]
        for sample_no in entities:
            if (code,sample_no) in existing:
                continue
            image = Image.new("RGB", (1280, 800), (0, 0, 0) if black else (232, 242, 247))
            draw = ImageDraw.Draw(image)
            if not black:
                draw.rectangle((55, 55, 1225, 745), outline=(23, 107, 135), width=8)
                draw.text((95, 105), "BPLab DEMO RESULT EVIDENCE", fill=(18, 54, 74))
                draw.text((95, 180), task_row["task_no"], fill=(18, 54, 74))
                draw.text((95, 250), code, fill=(23, 107, 135))
                draw.text((95, 320), sample_no or "TASK LEVEL", fill=(23, 107, 135))
                draw.line((95, 520, 1160, 260), fill=(58, 166, 185), width=10)
            content = BytesIO()
            image.save(content, "JPEG", quality=92)
            save_live_camera_photo(
                {
                    "commission_no": task_row["commission_no"],
                    "package_no": task_row["package_no"],
                    "task_no": task_row["task_no"],
                    "sample_no": sample_no,
                    "checkpoint_code": code,
                    "checkpoint_label": checkpoint_labels.get(code, code),
                    "device_id": "DEMO-TABLET",
                },
                content.getvalue(), "tester", "实验员张工",
            )


def _complete_business(kind: str, sample_ids: list[str], equipment: list[dict]):
    record = initialize_business_record(kind, sample_ids, "性能检测室", {})
    params = record["parameters"]
    params["test_date"] = str(china_today())
    params["start_time"] = f"{china_today()} 09:00:00"
    params["end_time"] = f"{china_today()} 10:00:00"
    for field in fixed_and_manual_fields(kind)[1]:
        key, field_type = field["key"], field.get("type", "text")
        if params.get(key) not in (None, ""):
            continue
        if field_type == "number":
            params[key] = 1.0
        elif field_type == "select":
            params[key] = (field.get("options") or ["正常"])[0]
        elif field_type == "multiselect":
            params[key] = field.get("default") or (field.get("options") or ["已确认"])[:1]
        else:
            params[key] = "演示数据已确认"
    rows = record["rows"]
    for index, row in enumerate(rows, 1):
        for key, _label, field_type in visible_row_fields(kind):
            if field_type == "calc":
                continue
            value = row.get(key)
            if value not in (None, "", 0, 0.0):
                continue
            if field_type == "number":
                row[key] = float(index + 1)
            elif field_type.startswith("select:"):
                row[key] = field_type.split(":", 1)[1].split("|")[0]
            elif key == "note":
                row[key] = ""
            else:
                row[key] = f"演示记录{index}"
    record["parameters"] = params
    record["rows"] = calculate_rows(kind, rows)
    record["equipment_checks"] = [
        {
            "management_no": item.get("management_no", ""),
            "equipment_name": item.get("equipment_name", ""),
            "model": item.get("model", ""),
            "measuring_range": item.get("measuring_range", ""),
            "calibration_certificate": item.get("calibration_certificate", ""),
            "calibration_due": item.get("calibration_due", ""),
            "status": "正常",
            "note": "完整演示数据",
            "required": bool(item.get("required")),
        }
        for item in equipment
    ]
    record["overall_status"] = "正常完成"
    record["deviation"] = "无"
    record["retest"] = "否"
    record = calculate_business_record(kind, record)
    record["report_summary"] = record.get("report_summary") or "演示实验完成，数据完整。"
    record["report_conclusion"] = record.get("report_conclusion") or "符合"
    return record


def create_pending_review_demo() -> dict[str, str]:
    """Create one completed roughness experiment awaiting reviewer approval."""
    sequence = 2
    while True:
        commission_no = f"WT20990101{sequence:03d}"
        group_no = f"BP20990101{sequence:03d}"
        existing = commission(commission_no)
        if not existing:
            break
        tasks = commission_tasks(commission_no)
        pending = next(
            (item for item in tasks if item.get("status") in ("待复核","更正待复核")),
            None,
        )
        if pending:
            group_row = commission_groups(commission_no)[0]
            sample_ids = [item["sample_no"] for item in group_samples(group_row["id"])]
            _add_demo_result_photos(pending, sample_ids, all_required=True, black=True)
            return {
                "commission_no": commission_no,
                "task_no": pending["task_no"],
            }
        sequence += 1

    organizations = list_organizations()
    client = next(item for item in organizations if item["org_code"] == "ORG-DEFAULT")
    producer = next(item for item in organizations if item["org_code"] == "ORG-TEST-MFR")
    method = next(
        item for item in list_experiment_methods()
        if item["experiment_name"] == "表面粗糙度试验"
    )
    create_commission(
        {
            "commission_no": commission_no,
            "client_org_id": client["id"],
            "client_name": client["org_name"],
            "client_address": client["address"],
            "contact": client["contact"],
            "phone": client["phone"],
            "production_org_id": producer["id"],
            "production_org_name": producer["org_name"],
            "production_relation": "生产单位",
            "commission_date": str(china_today()),
            "due_date": str(china_today()),
            "subcontract_allowed": "否",
            "report_medium": "电子档",
            "conformity_judgment": "是",
            "uncertainty": "否",
            "delivery_method": "演示",
            "cnas_mark": "否",
            "capability": "完全满足",
            "notes": "待复核实验临时Demo",
        },
        [{
            "group_no": group_no,
            "catalog_id": None,
            "sample_name": "表面粗糙度待复核演示样品",
            "model": "DEMO-25 mm×2 mm×2 mm",
            "material_name": "钴铬合金",
            "product_no": "DEMO-PENDING-BATCH-001",
            "quantity": 2,
            "unit": "件",
            "condition": "完好",
            "condition_note": "",
            "storage_area": "A区域",
            "notes": "实验已完成，等待复核员",
            "experiment_codes": [method["experiment_code"]],
        }],
        "receiver",
    )
    group_row = commission_groups(commission_no)[0]
    package_no = create_task_package(
        group_row["id"], [method["experiment_code"]],
        "tester", "receiver", "reviewer",
    )
    task_row = package_tasks(package_no)[0]
    snapshot = task_config_snapshot(task_row["task_no"])
    accept_package(
        package_no, "tester", "样品已收到，确认完好",
        {
            task_row["task_no"]:
                snapshot.get("default_location") or "性能检测室",
        },
        "待复核Demo自动接收",
    )
    task_row = package_tasks(package_no)[0]
    sample_ids = [item["sample_no"] for item in group_samples(group_row["id"])]
    equipment = snapshot.get("equipment") or []
    kind = snapshot.get("kind") or "rough"
    business = _complete_business(kind, sample_ids, equipment)
    _add_demo_result_photos(task_row, sample_ids, all_required=True, black=True)
    demo_attachments = list_attachments(task_no=task_row["task_no"])
    context = {
        "client_name": client["org_name"],
        "client_address": client["address"],
        "production_unit": producer["org_name"],
        "product_no": "DEMO-PENDING-BATCH-001",
        "sample_name": "表面粗糙度待复核演示样品",
        "model": "DEMO-25 mm×2 mm×2 mm",
        "material": "钴铬合金",
        "sample_nos": sample_ids,
        "sample_quantity": len(sample_ids),
        "received_date": str(china_today()),
        "report_no": commission_no,
        "task_no": task_row["task_no"],
        "test_date": str(china_today()),
        "detection_location": task_row.get("detection_location") or "性能检测室",
        "standard": snapshot.get("standard", ""),
        "method_code": snapshot.get("method_code", ""),
        "operator": "实验员张工",
        "reviewer": "复核员李工",
    }
    template_name = snapshot.get("record_template_file", "")
    template_fields = business_to_template_fields(
        template_name, kind, context, equipment, business, demo_attachments, {},
    )
    payload = {
        "common": {
            "record_no": task_row["task_no"], "task_no": task_row["task_no"],
            "commission_no": commission_no,
            "report_no": commission_no,
            "client": client["org_name"], "sample_name": context["sample_name"],
            "sample_no": "、".join(sample_ids), "model": context["model"],
            "material": context["material"], "method_code": context["method_code"],
            "standard": context["standard"], "test_date": context["test_date"],
            "operator": context["operator"], "reviewer": context["reviewer"],
        },
        "business_record": business,
        "template_name": template_name,
        "template_fields": template_fields,
        "equipment_snapshot": equipment,
        "deviation": "无", "retest": "否",
        "report_summary": business["report_summary"],
        "report_conclusion": business["report_conclusion"],
        "configuration_snapshot": snapshot,
        "tester_self_check": True,
        "photo_attachment_ids": [
            item["attachment_id"] for item in demo_attachments
            if item.get("capture_source") == "live_camera"
            and item.get("evidence_status") == "有效"
        ],
    }
    timestamp = now()
    with connect() as connection:
        connection.execute(
            """UPDATE tasks SET status='待复核',experiment_started_at=?,
               experiment_ended_at=?,updated_at=? WHERE task_no=?""",
            (timestamp, timestamp, timestamp, task_row["task_no"]),
        )
        connection.execute(
            """UPDATE task_packages SET status='待复核',updated_at=?
               WHERE package_no=?""",
            (timestamp, package_no),
        )
        connection.execute(
            """UPDATE sample_groups SET status='实验完成待复核',updated_at=?
               WHERE id=?""",
            (timestamp, group_row["id"]),
        )
        connection.execute(
            """UPDATE samples SET status='实验完成待复核',updated_at=?
               WHERE group_id=?""",
            (timestamp, group_row["id"]),
        )
        connection.execute(
            """INSERT INTO records(
               record_no,task_no,version,experiment,owner,status,payload,
               template_version,sop_version,change_reason,tester_signed_at,
               created_at,updated_at
               ) VALUES(?,?,?,?,?,'待复核',?,?,?,?,?,?,?)""",
            (
                task_row["task_no"], task_row["task_no"], 1,
                task_row["experiment"], "tester",
                json.dumps(payload, ensure_ascii=False, default=str),
                snapshot.get("record_template_version") or "A/0",
                snapshot.get("sop_version") or "A/0",
                "待复核Demo自动生成", timestamp, timestamp, timestamp,
            ),
        )
    create_notification(
        "reviewer", "Demo原始记录待复核",
        f"{task_row['task_no']} 已完成实验并提交，请直接查看DOCX预览。",
        "record", task_row["task_no"],
    )
    return {
        "commission_no": commission_no,
        "task_no": task_row["task_no"],
    }


def create_full_document_demo() -> str:
    """Create one idempotent, fully approved ten-experiment document set."""
    if commission(DEMO_COMMISSION_NO):
        return DEMO_COMMISSION_NO

    organizations = list_organizations()
    client = next(item for item in organizations if item["org_code"] == "ORG-DEFAULT")
    producer = next(item for item in organizations if item["org_code"] == "ORG-TEST-MFR")
    methods = list_experiment_methods()
    experiment_codes = [item["experiment_code"] for item in methods]
    create_commission(
        {
            "commission_no": DEMO_COMMISSION_NO,
            "client_org_id": client["id"],
            "client_name": client["org_name"],
            "client_address": client["address"],
            "contact": client["contact"],
            "phone": client["phone"],
            "production_org_id": producer["id"],
            "production_org_name": producer["org_name"],
            "production_relation": "生产单位",
            "commission_date": str(china_today()),
            "due_date": str(china_today()),
            "subcontract_allowed": "否",
            "report_medium": "电子档",
            "conformity_judgment": "是",
            "uncertainty": "否",
            "delivery_method": "演示",
            "cnas_mark": "否",
            "capability": "完全满足",
            "notes": "临时完整单据演示，可直接查看全部原始记录和报告",
        },
        [{
            "group_no": DEMO_GROUP_NO,
            "catalog_id": None,
            "sample_name": "全实验单据演示样品",
            "model": "DEMO-25 mm×2 mm×2 mm",
            "material_name": "钴铬合金/牙科材料演示",
            "product_no": "DEMO-BATCH-001",
            "quantity": 2,
            "unit": "件",
            "condition": "完好",
            "condition_note": "",
            "storage_area": "A区域",
            "notes": "临时演示数据",
            "experiment_codes": experiment_codes,
        }],
        "receiver",
    )
    group_row = commission_groups(DEMO_COMMISSION_NO)[0]
    package_no = create_task_package(
        group_row["id"], experiment_codes, "tester", "receiver", "reviewer",
    )
    task_rows = package_tasks(package_no)
    accept_package(
        package_no,
        "tester",
        "样品已收到，确认完好",
        {
            item["task_no"]: (
                task_config_snapshot(item["task_no"]).get("default_location")
                or "性能检测室"
            )
            for item in task_rows
        },
        "完整演示自动接收",
    )
    sample_ids = [item["sample_no"] for item in group_samples(group_row["id"])]
    timestamp = now()
    for task_row in package_tasks(package_no):
        task_no = task_row["task_no"]
        snapshot = task_config_snapshot(task_no)
        equipment = snapshot.get("equipment") or []
        kind = snapshot.get("kind") or "generic"
        business = _complete_business(kind, sample_ids, equipment)
        context = {
            "client_name": client["org_name"],
            "client_address": client["address"],
            "production_unit": producer["org_name"],
            "product_no": "DEMO-BATCH-001",
            "sample_name": "全实验单据演示样品",
            "model": "DEMO-25 mm×2 mm×2 mm",
            "material": "钴铬合金/牙科材料演示",
            "sample_nos": sample_ids,
            "sample_quantity": len(sample_ids),
            "received_date": str(china_today()),
            "report_no": DEMO_COMMISSION_NO,
            "task_no": task_no,
            "test_date": str(china_today()),
            "detection_location": task_row.get("detection_location") or "性能检测室",
            "standard": snapshot.get("standard", ""),
            "method_code": snapshot.get("method_code", ""),
            "operator": "实验员张工",
            "reviewer": "复核员李工",
        }
        template_name = snapshot.get("record_template_file", "")
        template_fields = business_to_template_fields(
            template_name, kind, context, equipment, business, [], {},
        )
        payload = {
            "common": {
                "record_no": task_no, "task_no": task_no,
                "commission_no": DEMO_COMMISSION_NO,
                "report_no": DEMO_COMMISSION_NO,
                "client": client["org_name"],
                "sample_name": context["sample_name"],
                "sample_no": "、".join(sample_ids),
                "model": context["model"], "material": context["material"],
                "method_code": context["method_code"], "standard": context["standard"],
                "test_date": context["test_date"],
                "operator": context["operator"], "reviewer": context["reviewer"],
            },
            "business_record": business,
            "template_name": template_name,
            "template_fields": template_fields,
            "equipment_snapshot": equipment,
            "deviation": "无",
            "retest": "否",
            "report_summary": business["report_summary"],
            "report_conclusion": business["report_conclusion"],
            "configuration_snapshot": snapshot,
            "tester_self_check": True,
        }
        with connect() as connection:
            connection.execute(
                """UPDATE tasks SET status='已复核',experiment_started_at=?,
                   experiment_ended_at=?,updated_at=? WHERE task_no=?""",
                (timestamp, timestamp, timestamp, task_no),
            )
            connection.execute(
                """INSERT INTO records(
                   record_no,task_no,version,experiment,owner,status,payload,
                   template_version,sop_version,change_reason,tester_signed_at,
                   reviewer_signed_at,created_at,updated_at
                   ) VALUES(?,?,?,?,?, '已锁定',?,?,?,?,?,?,?,?)""",
                (
                    task_no, task_no, 1, task_row["experiment"], "tester",
                    json.dumps(payload, ensure_ascii=False, default=str),
                    snapshot.get("record_template_version") or "A/0",
                    snapshot.get("sop_version") or "A/0",
                    "完整单据演示自动生成", timestamp, timestamp, timestamp, timestamp,
                ),
            )
        _add_demo_result_photos(task_row, sample_ids)
        freeze_document_version(
            "record", task_no, 1, "完整演示锁定", payload, "reviewer",
        )
        report_no = ensure_report_for_task(task_no)
        report_row = report(report_no)
        quality_review_report(
            report_no, report_row["quality_inspector"], "通过", "完整演示自动通过",
        )
        report_row = report(report_no)
        approver_review_report(
            report_no, report_row["approver"], "批准", "完整演示自动签发",
        )
        add_report_delivery({
            "report_no": report_no,
            "client_name": client["org_name"],
            "delivery_method": "电子邮件",
            "recipient": client.get("contact", ""),
            "recipient_contact": client.get("phone", ""),
            "delivered_at": now(),
            "receipt_status": "已发送待确认",
            "receipt_note": "完整Demo自动登记；信息来自委托单",
        }, "receiver")
    with connect() as connection:
        connection.execute(
            "UPDATE task_packages SET status='已回库',updated_at=? WHERE package_no=?",
            (now(), package_no),
        )
        connection.execute(
            "UPDATE sample_groups SET status='留样保存',updated_at=? WHERE id=?",
            (now(), group_row["id"]),
        )
        connection.execute(
            """UPDATE samples SET status='留样保存',current_location='A区域',
               current_holder='receiver',updated_at=? WHERE group_id=?""",
            (now(), group_row["id"]),
        )
    return DEMO_COMMISSION_NO


def create_objection_application_demo() -> dict[str, str]:
    """Prepare an already-issued report for manual objection-application testing."""
    commission_no=create_full_document_demo()
    with connect() as connection:
        item=connection.execute(
            """SELECT report_no FROM reports
               WHERE commission_no=? AND status='已发布'
               ORDER BY publish_date,report_no LIMIT 1""",
            (commission_no,),
        ).fetchone()
    if not item:
        raise ValueError("异议Demo未找到已签发报告")
    return {"commission_no":commission_no,"report_no":item["report_no"]}
