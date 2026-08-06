from __future__ import annotations

from io import BytesIO
from pathlib import Path
import tempfile
import unittest

from PIL import Image

import lims_db
from camera_evidence import save_live_camera_photo
from constants import EXPERIMENTS, photo_checkpoints
from record_word_engine import export_record
from trace_excel_engine import build_internal_trace_workbook


class V60WorkflowTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bplab-v60-")
        root = Path(self.temp.name)
        lims_db.DB_PATH = root / "test.db"
        lims_db.ATTACHMENT_DIR = root / "attachments"
        lims_db.SIGNATURE_DIR = root / "signatures"
        lims_db.init_db()

    def tearDown(self):
        self.temp.cleanup()

    @staticmethod
    def _jpeg() -> bytes:
        output = BytesIO()
        Image.new("RGB", (900, 600), "#d8eef5").save(output, "JPEG")
        return output.getvalue()

    def _commission_and_task(self):
        organizations = lims_db.list_organizations()
        client = next(x for x in organizations if x["is_client"])
        producer = next(x for x in organizations if x["is_manufacturer"])
        catalog = lims_db.list_catalog()[0]
        method = lims_db.list_experiment_methods()[0]
        commission_no = lims_db.next_commission_no()
        group_no = lims_db.next_sample_base()
        lims_db.create_commission(
            {
                "commission_no": commission_no,
                "client_org_id": client["id"], "client_name": client["org_name"],
                "client_address": client["address"], "contact": client["contact"],
                "phone": client["phone"], "production_org_id": producer["id"],
                "production_org_name": producer["org_name"],
                "production_relation": "生产单位", "commission_date": lims_db.china_today(),
                "due_date": lims_db.add_months_to_date(lims_db.china_today(), 1),
            },
            [{
                "group_no": group_no, "catalog_id": catalog["id"],
                "sample_name": catalog["sample_name"], "model": catalog["model"],
                "material_name": catalog["material_name"], "quantity": 1,
                "unit": "件", "condition": "完好", "storage_area": "A区域",
                "product_no": "TEST-LOT-V60",
                "experiment_codes": [method["experiment_code"]],
            }],
            "receiver",
        )
        group = lims_db.commission_groups(commission_no)[0]
        package_no = lims_db.create_task_package(
            group["id"], [method["experiment_code"]], "tester", "receiver"
        )
        task = lims_db.package_tasks(package_no)[0]
        return commission_no, group, package_no, task

    def test_roles_numbering_camera_report_delivery_and_objection(self):
        self.assertEqual("SOP_R006_WARPAGE.docx", EXPERIMENTS["翘曲变形试验"]["sop"])
        self.assertEqual("SOP_R007_CTE.docx", EXPERIMENTS["热膨胀系数试验"]["sop"])
        self.assertEqual("SOP_R010_BENDING.docx", EXPERIMENTS["弯曲性能试验"]["sop"])
        commission_no, group, package_no, task = self._commission_and_task()
        self.assertRegex(commission_no, r"^WT\d{11}$")
        sample = lims_db.group_samples(group["id"])[0]
        self.assertRegex(sample["sample_no"], r"^BP\d{11}-S\d{2}$")
        self.assertRegex(task["task_no"], r"^BP\d{11}-T\d{2}$")
        self.assertEqual("reviewer", task["reviewer"])
        self.assertEqual("quality", task["quality_inspector"])

        lims_db.accept_package(
            package_no, "tester", "样品已收到，确认完好",
            {task["task_no"]: "性能检测室"}, "",
        )
        task = lims_db.task(task["task_no"])
        lims_db.mark_task_experiment_time(task["task_no"], "tester", "开始")
        for code, label, _required in photo_checkpoints(task["experiment"]):
            save_live_camera_photo(
                {
                    "commission_no": commission_no, "package_no": package_no,
                    "task_no": task["task_no"], "sample_no": sample["sample_no"],
                    "checkpoint_code": code, "checkpoint_label": label,
                    "device_id": "TEST-TABLET",
                },
                self._jpeg(), "tester", "实验员张工",
            )
        lims_db.mark_task_experiment_time(task["task_no"], "tester", "结束")
        payload = {
            "business_record": {"parameters": {"temperature": 23.5}, "rows": [{"value": 1.23}]},
            "report_summary": "测试数据完整", "report_conclusion": "符合",
            "tester_self_check": True,
        }
        lims_db.save_record(task["task_no"], 1, payload, "tester", "待复核")
        lims_db.review_record(task["task_no"], 1, "reviewer", "通过", "数据、计算和过程符合")
        locked_record = lims_db.record(task["task_no"], 1)
        record_docx = export_record(
            locked_record,
            EXPERIMENTS[task["experiment"]]["template"],
            lims_db.audit_logs(task["task_no"]),
        )
        self.assertGreater(len(record_docx.getvalue()), 1000)

        trace_book = build_internal_trace_workbook(commission_no)
        self.assertGreater(len(trace_book.getvalue()), 1000)

        reports = lims_db.rows("SELECT * FROM reports")
        self.assertEqual(1, len(reports))
        report_no = reports[0]["report_no"]
        self.assertRegex(report_no, r"^R\d{11}-T\d{2}$")
        self.assertEqual("待质量审核", reports[0]["status"])
        lims_db.quality_review_report(report_no, "quality", "通过", "格式、标识和信息完整")
        lims_db.approver_review_report(report_no, "admin", "批准", "最终审核通过")
        self.assertEqual("已发布", lims_db.report(report_no)["status"])

        lims_db.add_report_delivery(
            {
                "report_no": report_no, "client_name": "测试客户",
                "delivery_method": "电子邮件", "recipient": "客户代表",
                "receipt_status": "已发送待确认",
            },
            "receiver",
        )
        self.assertEqual(1, len(lims_db.report_deliveries(report_no)))

        objection_no = lims_db.register_objection(
            {
                "report_no": report_no, "client_name": "测试客户",
                "description": "客户认为检测结果异常",
            },
            "receiver",
        )
        lims_db.quality_submit_objection(
            objection_no, "quality", "样品自身问题",
            "调取收样、流转、环境、设备和原始数据",
            "实验室过程正常，异常来自送检样品自身不均匀",
        )
        lims_db.admin_confirm_objection(objection_no, "admin", "同意调查结论")
        lims_db.admin_sign_objection_response(objection_no, "admin", "原报告继续有效")
        lims_db.send_and_archive_objection(objection_no, "receiver", "电子邮件发送")
        self.assertEqual("已归档", lims_db.objection(objection_no)["status"])
        self.assertEqual("有效", lims_db.report(report_no)["validity_status"])

        method_objection_no = lims_db.register_objection(
            {
                "report_no": report_no, "client_name": "测试客户",
                "description": "客户再次提出方法实施异议",
            },
            "receiver",
        )
        lims_db.quality_submit_objection(
            method_objection_no, "quality", "检测方法或实验室实施问题",
            "调取方法版本、设备参数、原始记录和现场照片",
            "确认本次检测方法实施存在偏差",
        )
        lims_db.admin_confirm_objection(method_objection_no, "admin", "同意，原报告作废")
        self.assertEqual("已作废", lims_db.report(report_no)["validity_status"])
        lims_db.record_customer_retest_decision(
            method_objection_no, "receiver", "需要重测", "客户同意使用留样重测",
        )
        retest_task_no = lims_db.dispatch_retained_sample_retest(
            method_objection_no, "tester", "receiver",
        )
        self.assertRegex(retest_task_no, r"^BP\d{11}-T\d{2}$")
        retest_task = lims_db.task(retest_task_no)
        self.assertEqual("reviewer", retest_task["reviewer"])
        self.assertEqual("quality", retest_task["quality_inspector"])
        self.assertEqual("重测任务已下发", lims_db.objection(method_objection_no)["status"])

        audit_rows = lims_db.audit_logs()
        chained = [x for x in reversed(audit_rows) if x.get("entry_hash")]
        self.assertTrue(chained)
        for index in range(1, len(chained)):
            self.assertEqual(chained[index - 1]["entry_hash"], chained[index]["previous_hash"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
