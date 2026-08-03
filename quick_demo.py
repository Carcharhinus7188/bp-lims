# -*- coding: utf-8 -*-
from __future__ import annotations

import json

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
    list_organizations,
    now,
    package_tasks,
    quality_review_report,
    report,
    task_config_snapshot,
)


DEMO_COMMISSION_NO = "WT20990101001"
DEMO_GROUP_NO = "BP20990101001"
PENDING_DEMO_COMMISSION_NO = "WT20990101002"
PENDING_DEMO_GROUP_NO = "BP20990101002"


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
    if commission(PENDING_DEMO_COMMISSION_NO):
        tasks = commission_tasks(PENDING_DEMO_COMMISSION_NO)
        if tasks:
            return {
                "commission_no": PENDING_DEMO_COMMISSION_NO,
                "task_no": tasks[0]["task_no"],
            }

    organizations = list_organizations()
    client = next(item for item in organizations if item["org_code"] == "ORG-DEFAULT")
    producer = next(item for item in organizations if item["org_code"] == "ORG-TEST-MFR")
    method = next(
        item for item in list_experiment_methods()
        if item["experiment_name"] == "表面粗糙度试验"
    )
    create_commission(
        {
            "commission_no": PENDING_DEMO_COMMISSION_NO,
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
            "group_no": PENDING_DEMO_GROUP_NO,
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
    group_row = commission_groups(PENDING_DEMO_COMMISSION_NO)[0]
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
        "report_no": PENDING_DEMO_COMMISSION_NO,
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
        template_name, kind, context, equipment, business, [], {},
    )
    payload = {
        "common": {
            "record_no": task_row["task_no"], "task_no": task_row["task_no"],
            "commission_no": PENDING_DEMO_COMMISSION_NO,
            "report_no": PENDING_DEMO_COMMISSION_NO,
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
        "commission_no": PENDING_DEMO_COMMISSION_NO,
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
