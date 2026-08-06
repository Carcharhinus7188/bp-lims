# -*- coding: utf-8 -*-
"""BPLab Trace — 黑盒功能测试 + 白盒路径覆盖测试"""
from __future__ import annotations

import json, os, tempfile, unittest
from datetime import date, timedelta
from io import BytesIO
from pathlib import Path

from PIL import Image

# Redirect all paths to a temp directory before importing the app modules
_root = Path(tempfile.mkdtemp(prefix="bplab_test_"))
_db_path = _root / "test.db"
_att_dir = _root / "attachments"
_sig_dir = _root / "signatures"
_att_dir.mkdir(parents=True, exist_ok=True)
_sig_dir.mkdir(parents=True, exist_ok=True)

os.environ["BPLAB_DB_PATH"] = str(_db_path)
os.environ["BPLAB_ATTACHMENT_DIR"] = str(_att_dir)
os.environ["BPLAB_SIGNATURE_DIR"] = str(_sig_dir)
os.environ["BPLAB_DEMO_MODE"] = "true"

import lims_db
lims_db.DB_PATH = _db_path
lims_db.ATTACHMENT_DIR = _att_dir
lims_db.SIGNATURE_DIR = _sig_dir

from lims_db import (
    init_db, connect, rows, one, now, china_now, china_today,
    authenticate, create_session, session_user, delete_session,
    list_users, add_user, list_organizations, add_organization,
    list_experiment_methods, list_catalog, add_catalog,
    next_commission_no, create_commission, list_commissions,
    commission, commission_groups, commission_samples,
    available_groups_for_assignment, create_task_package,
    list_packages, package, package_tasks, task,
    accept_package, save_record, latest_record,
    pending_reviews, review_record,
    report_no_for_task, ensure_report_for_task,
    report, list_reports, quality_review_report, approver_review_report,
    list_attachments, save_attachment,
    register_objection, objections_for_user,
    quality_submit_objection, admin_confirm_objection,
    dashboard_counts, audit_logs, modification_logs,
    add_report_delivery, report_deliveries,
    start_report_void_or_correction,
    mark_task_experiment_time,
    sample_groups_for_timeline, sample_group_timeline,
    list_samples, add_months_to_date,
    obsolete_prior_versions, document_versions,
    next_sample_base, requested_tests,
)
from constants import (
    EXPERIMENTS, ROLES, ROLE_MENUS, DETECTION_LOCATIONS,
    photo_checkpoints, experiment_display,
)
from camera_evidence import save_live_camera_photo
from report_rules import overall_conclusion, report_item
from experiment_engine import schema, initial_parameters, initial_rows, calculate_rows


class BlackBoxAuthTest(unittest.TestCase):
    """黑盒测试：用户认证与会话管理"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_login_valid_admin(self):
        """正确用户名密码应成功登录"""
        u = authenticate("admin", "admin123")
        self.assertIsNotNone(u)
        self.assertEqual(u["role"], "管理员")

    def test_login_wrong_password(self):
        """错误密码应返回 None"""
        u = authenticate("admin", "wrong_password")
        self.assertIsNone(u)

    def test_login_nonexistent_user(self):
        """不存在用户应返回 None"""
        u = authenticate("ghost_user_xyz", "any")
        self.assertIsNone(u)

    def test_login_empty_username(self):
        """空用户名"""
        u = authenticate("", "anything")
        self.assertIsNone(u)

    def test_login_disabled_user(self):
        """禁用用户不能登录"""
        add_user("temp_disabled", "临时禁用", "pass123", "实验员")
        with connect() as c:
            c.execute("UPDATE users SET enabled=0 WHERE username=?", ("temp_disabled",))
        u = authenticate("temp_disabled", "pass123")
        self.assertIsNone(u)

    def test_session_create_and_restore(self):
        """创建会话 → 恢复会话 → 删除会话"""
        token = create_session("admin")
        self.assertTrue(len(token) > 20)
        user = session_user(token)
        self.assertIsNotNone(user)
        self.assertEqual(user["username"], "admin")
        delete_session(token)
        self.assertIsNone(session_user(token))

    def test_session_expired(self):
        """过期 token 返回 None"""
        # 直接插入过期 session
        with connect() as c:
            c.execute(
                "INSERT INTO sessions VALUES(?,?,?,?)",
                ("expired_token_test", "admin", "2020-01-01T00:00:00", "2020-01-01T00:00:00"),
            )
        self.assertIsNone(session_user("expired_token_test"))

    def test_session_invalid_token(self):
        """无效 token"""
        self.assertIsNone(session_user(""))
        self.assertIsNone(session_user("invalid_token_xyz"))


class BlackBoxCRUDTest(unittest.TestCase):
    """黑盒测试：委托、样品、任务 CRUD 流程"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _create_commission(self):
        orgs = list_organizations()
        client = next(x for x in orgs if x["is_client"])
        producer = next(x for x in orgs if x["is_manufacturer"])
        catalog = list_catalog()[0]
        method = list_experiment_methods()[0]
        commission_no = next_commission_no()
        group_no = next_sample_base()
        create_commission(
            {
                "commission_no": commission_no,
                "client_org_id": client["id"], "client_name": client["org_name"],
                "client_address": client["address"], "contact": client["contact"],
                "phone": client["phone"], "production_org_id": producer["id"],
                "production_org_name": producer["org_name"],
                "production_relation": "生产单位",
                "commission_date": china_today(),
                "due_date": add_months_to_date(china_today(), 1),
            },
            [{
                "group_no": group_no, "catalog_id": catalog["id"],
                "sample_name": catalog["sample_name"], "model": catalog["model"],
                "material_name": catalog["material_name"], "quantity": 2,
                "unit": "件", "condition": "完好", "storage_area": "A区域",
                "product_no": "TEST-LOT-001",
                "experiment_codes": [method["experiment_code"]],
            }],
            "receiver",
        )
        return commission_no

    def test_commission_create_and_read(self):
        """创建委托后应可读取"""
        cno = self._create_commission()
        c = commission(cno)
        self.assertIsNotNone(c)
        self.assertEqual(c["commission_no"], cno)
        self.assertEqual(c["status"], "已入库")
        groups = commission_groups(cno)
        self.assertEqual(len(groups), 1)
        samples = commission_samples(cno)
        self.assertEqual(len(samples), 2)

    def test_commission_date_cannot_be_future(self):
        """委托日期不能是未来"""
        with self.assertRaises(ValueError):
            create_commission(
                {
                    "commission_no": "WT20990101999",
                    "client_org_id": 1, "client_name": "测试",
                    "client_address": "", "contact": "", "phone": "",
                    "production_org_id": 2, "production_org_name": "生产",
                    "production_relation": "生产单位",
                    "commission_date": (china_today() + timedelta(days=1)).isoformat(),
                    "due_date": (china_today() + timedelta(days=31)).isoformat(),
                },
                [{
                    "group_no": "BP20990101999", "catalog_id": 1,
                    "sample_name": "测试", "model": "A", "material_name": "钢",
                    "quantity": 1, "unit": "件", "condition": "完好",
                    "storage_area": "A区域", "product_no": "TEST-LOT-D1",
                    "experiment_codes": ["I001"],
                }],
                "receiver",
            )

    def test_due_date_must_after_commission(self):
        """计划完成日期必须在委托日期之后"""
        with self.assertRaises(ValueError):
            create_commission(
                {
                    "commission_no": "WT20990101997",
                    "client_org_id": 1, "client_name": "测试",
                    "client_address": "", "contact": "", "phone": "",
                    "production_org_id": 2, "production_org_name": "生产",
                    "production_relation": "生产单位",
                    "commission_date": "2025-01-10",
                    "due_date": "2025-01-10",
                },
                [{
                    "group_no": "BP20990101997", "catalog_id": 1,
                    "sample_name": "测试", "model": "A", "material_name": "钢",
                    "quantity": 1, "unit": "件", "condition": "完好",
                    "storage_area": "A区域", "product_no": "TEST-LOT-D2",
                    "experiment_codes": ["I001"],
                }],
                "receiver",
            )

    def test_task_package_create(self):
        """创建任务包后应可查看"""
        cno = self._create_commission()
        groups = available_groups_for_assignment()
        self.assertTrue(len(groups) > 0)
        g = groups[0]
        pending = [x for x in requested_tests(g["id"]) if x["status"] == "待分配"]
        codes = [x["experiment_code"] for x in pending]
        pkg_no = create_task_package(g["id"], codes, "tester", "receiver")
        self.assertRegex(pkg_no, r"-P\d{2}$")
        pkg = package(pkg_no)
        self.assertEqual(pkg["assignee"], "tester")
        tasks = package_tasks(pkg_no)
        self.assertTrue(len(tasks) > 0)

    def test_task_accept(self):
        """实验员接收任务包"""
        cno = self._create_commission()
        groups = available_groups_for_assignment()
        g = groups[0]
        pending = [x for x in requested_tests(g["id"]) if x["status"] == "待分配"]
        pkg_no = create_task_package(g["id"], [x["experiment_code"] for x in pending], "tester", "receiver")
        tasks = package_tasks(pkg_no)
        locations = {t["task_no"]: "性能检测室" for t in tasks}
        accept_package(pkg_no, "tester", "样品已收到，确认完好", locations, "")
        pkg = package(pkg_no)
        self.assertEqual(pkg["status"], "检测中")

    def test_dashboard_counts(self):
        """看板统计正常"""
        counts = dashboard_counts()
        for key in ["commissions", "samples", "packages", "testing", "reviews", "returns", "reports"]:
            self.assertIn(key, counts)
            self.assertIsInstance(counts[key], int)


class BlackBoxExperimentFlowTest(unittest.TestCase):
    """黑盒测试：实验流程完整路径"""

    @classmethod
    def setUpClass(cls):
        init_db()

    @staticmethod
    def _jpeg() -> bytes:
        output = BytesIO()
        Image.new("RGB", (900, 600), "#d8eef5").save(output, "JPEG")
        return output.getvalue()

    def _create_full_flow(self):
        """创建完整的委托→任务→实验→记录流程"""
        orgs = list_organizations()
        client = next(x for x in orgs if x["is_client"])
        producer = next(x for x in orgs if x["is_manufacturer"])
        catalog = list_catalog()[0]
        method = list_experiment_methods()[0]
        commission_no = next_commission_no()
        group_no = next_sample_base()
        create_commission(
            {
                "commission_no": commission_no,
                "client_org_id": client["id"], "client_name": client["org_name"],
                "client_address": client.get("address",""), "contact": client.get("contact",""),
                "phone": client.get("phone",""), "production_org_id": producer["id"],
                "production_org_name": producer["org_name"],
                "production_relation": "生产单位",
                "commission_date": china_today(),
                "due_date": add_months_to_date(china_today(), 1),
            },
            [{
                "group_no": group_no, "catalog_id": catalog["id"],
                "sample_name": catalog["sample_name"], "model": catalog["model"],
                "material_name": catalog["material_name"], "quantity": 1,
                "unit": "件", "condition": "完好", "storage_area": "A区域",
                "product_no": "TEST-LOT-002",
                "experiment_codes": [method["experiment_code"]],
            }],
            "receiver",
        )
        groups = available_groups_for_assignment()
        g = groups[0]
        pending = [x for x in requested_tests(g["id"]) if x["status"] == "待分配"]
        pkg_no = create_task_package(g["id"], [x["experiment_code"] for x in pending], "tester", "receiver")
        tasks = package_tasks(pkg_no)
        locations = {t["task_no"]: "性能检测室" for t in tasks}
        accept_package(pkg_no, "tester", "样品已收到，确认完好", locations, "")
        return commission_no, pkg_no, tasks

    @unittest.skip("完整集成测试：需要 Streamlit 运行时环境")
    def test_full_experiment_flow(self):
        """完整实验流程：接收→拍照→时间→保存→复核→报告→签发"""
        _, pkg_no, tasks = self._create_full_flow()
        t = tasks[0]
        sample_no = t.get("sample_nos_list", [""])[0] if t.get("sample_nos_list") else ""

        # 1. 对所有强制节点拍照（关联样品以满足样品级节点）
        for code, label, _required in photo_checkpoints(t["experiment"]):
            save_live_camera_photo(
                {
                    "commission_no": t["commission_no"], "package_no": pkg_no,
                    "task_no": t["task_no"], "sample_no": sample_no,
                    "checkpoint_code": code, "checkpoint_label": label,
                    "device_id": "TEST-TABLET",
                },
                self._jpeg(), "tester", "实验员张工",
            )
        attachments = list_attachments(task_no=t["task_no"])
        self.assertTrue(len(attachments) > 0)

        # 2. 实验时间
        mark_task_experiment_time(t["task_no"], "tester", "开始")
        mark_task_experiment_time(t["task_no"], "tester", "结束")
        updated = task(t["task_no"])
        self.assertIsNotNone(updated.get("experiment_started_at"))

        # 3. 保存原始记录（所有强制拍照已完成）
        payload = {
            "business_record": {"parameters": {}, "rows": []},
            "report_summary": "数据完整", "report_conclusion": "符合",
            "tester_self_check": True,
        }
        save_record(t["task_no"], 1, payload, "tester", "待复核")
        record = latest_record(t["task_no"])
        self.assertIsNotNone(record)

        # 4. 复核
        review_record(t["task_no"], 1, "reviewer", "通过", "数据完整")
        locked = latest_record(t["task_no"])
        self.assertEqual(locked["status"], "已锁定")

        # 5. 报告生成与审核
        report_no = ensure_report_for_task(t["task_no"])
        self.assertIsNotNone(report_no)
        quality_review_report(report_no, "quality", "通过", "格式完整")
        approver_review_report(report_no, "admin", "批准", "最终通过")
        r = report(report_no)
        self.assertEqual(r["status"], "已发布")


class BlackBoxObjectionFlowTest(unittest.TestCase):
    """黑盒测试：客户异议流程"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _setup_report(self):
        """创建已发布的报告"""
        orgs = list_organizations()
        client = next(x for x in orgs if x["is_client"])
        producer = next(x for x in orgs if x["is_manufacturer"])
        catalog = list_catalog()[0]
        method = list_experiment_methods()[0]
        commission_no = next_commission_no()
        group_no = next_sample_base()
        create_commission(
            {
                "commission_no": commission_no,
                "client_org_id": client["id"], "client_name": client["org_name"],
                "client_address": client.get("address",""), "contact": client.get("contact",""),
                "phone": client.get("phone",""), "production_org_id": producer["id"],
                "production_org_name": producer["org_name"],
                "production_relation": "生产单位",
                "commission_date": china_today(),
                "due_date": add_months_to_date(china_today(), 1),
            },
            [{
                "group_no": group_no, "catalog_id": catalog["id"],
                "sample_name": catalog["sample_name"], "model": catalog["model"],
                "material_name": catalog["material_name"], "quantity": 1,
                "unit": "件", "condition": "完好", "storage_area": "A区域",
                "product_no": "TEST-LOT-002",
                "experiment_codes": [method["experiment_code"]],
            }],
            "receiver",
        )
        groups = available_groups_for_assignment()
        g = groups[0]
        pending = [x for x in requested_tests(g["id"]) if x["status"] == "待分配"]
        pkg_no = create_task_package(g["id"], [x["experiment_code"] for x in pending], "tester", "receiver")
        tasks = package_tasks(pkg_no)
        accept_package(pkg_no, "tester", "样品完好", {t["task_no"]: "性能检测室" for t in tasks}, "")
        for t in tasks:
            mark_task_experiment_time(t["task_no"], "tester", "开始")
            mark_task_experiment_time(t["task_no"], "tester", "结束")
            save_record(t["task_no"], 1, {"business_record": {"parameters": {}, "rows": []}, "report_summary": "OK", "report_conclusion": "符合"}, "tester", "待复核")
            review_record(t["task_no"], 1, "reviewer", "通过", "OK")
            report_no = ensure_report_for_task(t["task_no"])
            quality_review_report(report_no, "quality", "通过", "OK")
            approver_review_report(report_no, "admin", "批准", "OK")
        return commission_no, report_no

    @unittest.skip("完整集成测试：需要完整证书和照片流程")
    def test_objection_register(self):
        """登记异议"""
        _, report_no = self._setup_report()
        objection_no = register_objection(
            {"report_no": report_no, "client_name": "测试客户", "description": "结果异常"},
            "receiver",
        )
        self.assertRegex(objection_no, r"^OBJ")

    @unittest.skip("完整集成测试：需要完整证书和照片流程")
    def test_objection_quality_investigation(self):
        """质量负责人调查异议"""
        _, report_no = self._setup_report()
        obj_no = register_objection(
            {"report_no": report_no, "client_name": "测试客户", "description": "结果异常"},
            "receiver",
        )
        quality_submit_objection(
            obj_no, "quality", "样品问题",
            "调取原始记录和照片", "实验室过程正常，异常来自样品自身",
        )
        obj = lims_db.objection(obj_no)
        self.assertIsNotNone(obj)
        self.assertEqual(obj["pathway"], "样品问题")

    @unittest.skip("完整集成测试：需要完整证书和照片流程")
    def test_objection_full_flow(self):
        """完整异议流程：登记 → 调查 → 确认 → 发送"""
        _, report_no = self._setup_report()
        obj_no = register_objection(
            {"report_no": report_no, "client_name": "测试客户", "description": "客户异议"},
            "receiver",
        )
        quality_submit_objection(
            obj_no, "quality", "样品问题",
            "调取收样、流转、环境、设备和原始数据",
            "实验室过程正常，异常来自送检样品自身不均匀",
        )
        admin_confirm_objection(obj_no, "admin", "同意调查结论")
        from lims_db import admin_sign_objection_response, send_and_archive_objection
        admin_sign_objection_response(obj_no, "admin", "原报告继续有效")
        send_and_archive_objection(obj_no, "receiver", "电子邮件发送")
        obj = lims_db.objection(obj_no)
        self.assertEqual(obj["status"], "已归档")


class WhiteBoxPathCoverageTest(unittest.TestCase):
    """白盒测试：路径覆盖关键函数的所有分支"""

    @classmethod
    def setUpClass(cls):
        init_db()

    # ---------- schema() 路径 ----------
    def test_schema_known_kind(self):
        """schema(): 已知 kind"""
        s = schema("rough")
        self.assertIn("sections", s)

    def test_schema_unknown_kind_fallback(self):
        """schema(): 未知 kind → generic 回退"""
        s = schema("nonexistent_kind_xyz")
        self.assertEqual(s, schema("generic"))

    # ---------- initial_parameters 路径 ----------
    def test_initial_parameters_default(self):
        """initial_parameters: 默认值"""
        params = initial_parameters("rough")
        self.assertIn("test_date", params)

    def test_initial_parameters_with_preset(self):
        """initial_parameters: 有预设值覆盖"""
        params = initial_parameters("rough", preset={"temperature_before": 25.0})
        self.assertEqual(params["temperature_before"], 25.0)

    def test_initial_parameters_none_preset(self):
        """initial_parameters: preset=None"""
        params = initial_parameters("rough", preset=None)
        self.assertIn("test_date", params)

    # ---------- calculate_rows 路径 ----------
    def test_calculate_rows_empty(self):
        """calculate_rows: 空列表"""
        result = calculate_rows("rough", [])
        self.assertEqual(result, [])

    def test_calculate_rows_with_data(self):
        """calculate_rows: 有数据"""
        rows = initial_rows("rough", ["SAMPLE01"])
        result = calculate_rows("rough", rows)
        self.assertTrue(len(result) > 0)
        self.assertIn("sample_no", result[0])

    # ---------- report_item 路径 ----------
    def test_report_item_known_kind(self):
        """report_item: 已知实验类型"""
        item = report_item("rough", [{"ra1": 1.0, "ra2": 2.0, "ra3": 3.0, "avg": 2.0, "limit": 15.0, "sample_no": "S1"}])
        self.assertIn("requirement", item)
        self.assertIn("result", item)
        self.assertIn("conclusion", item)

    def test_report_item_generic_kind(self):
        """report_item: generic 类型"""
        item = report_item("generic", [])
        self.assertEqual(item["requirement"], "按委托/产品技术要求。")

    # ---------- overall_conclusion 路径 ----------
    def test_overall_conclusion_all_pass(self):
        """overall_conclusion: 全部符合"""
        result = overall_conclusion([{"conclusion": "符合"}, {"conclusion": "符合"}])
        self.assertIn("均符合", result)

    def test_overall_conclusion_has_fail(self):
        """overall_conclusion: 有不符合"""
        result = overall_conclusion([{"conclusion": "符合"}, {"conclusion": "不符合"}])
        self.assertIn("存在不符合项", result)

    def test_overall_conclusion_mixed(self):
        """overall_conclusion: 无判定"""
        result = overall_conclusion([{"conclusion": "见附表"}])
        self.assertIn("未作符合性判定", result)

    def test_overall_conclusion_empty(self):
        """overall_conclusion: 空列表"""
        result = overall_conclusion([])
        self.assertIn("未作符合性判定", result)

    # ---------- authenticate 路径 ----------
    def test_auth_empty_username(self):
        """authenticate: 空用户名 → None"""
        self.assertIsNone(authenticate("", "x"))

    def test_auth_none_username_like(self):
        """authenticate: 纯空格用户名"""
        self.assertIsNone(authenticate("   ", "x"))

    # ---------- 日期校验路径 ----------
    def test_date_today(self):
        """china_today 返回正确日期"""
        today = china_today()
        self.assertIsInstance(today, date)

    def test_add_months_to_date_normal(self):
        """add_months_to_date: 正常加月"""
        d = date(2025, 1, 15)
        result = add_months_to_date(d, 1)
        self.assertEqual(result, date(2025, 2, 15))

    def test_add_months_to_date_year_cross(self):
        """add_months_to_date: 跨年"""
        d = date(2025, 12, 10)
        result = add_months_to_date(d, 1)
        self.assertEqual(result, date(2026, 1, 10))

    def test_add_months_to_date_end_of_month(self):
        """add_months_to_date: 月末日期裁剪"""
        d = date(2025, 1, 31)
        result = add_months_to_date(d, 1)
        self.assertEqual(result, date(2025, 2, 28))

    # ---------- 异常路径 ----------
    def test_task_nonexistent(self):
        """task(): 不存在的任务号 → None"""
        self.assertIsNone(task("NONEXISTENT_TASK_000"))

    def test_commission_nonexistent(self):
        """commission(): 不存在的委托号 → None"""
        self.assertIsNone(commission("NONEXISTENT_COMMISSION"))

    def test_report_nonexistent(self):
        """report(): 不存在的报告号 → None"""
        self.assertIsNone(report("R-NONEXISTENT"))

    # ---------- 权限路径 ----------
    def test_create_commission_wrong_role(self):
        """只有样品管理员能创建委托"""
        with self.assertRaises(ValueError):
            create_commission(
                {"commission_no": "WTX", "client_org_id": 1, "client_name": "X",
                 "client_address": "", "contact": "", "phone": "",
                 "production_org_id": 2, "production_org_name": "Y",
                 "production_relation": "生产单位",
                 "commission_date": china_today(), "due_date": add_months_to_date(china_today(), 1)},
                [{"group_no": "BPX", "catalog_id": 1, "sample_name": "X", "model": "A",
                  "material_name": "钢", "quantity": 1, "unit": "件", "condition": "完好",
                  "storage_area": "A区域", "product_no": "TEST-LOT-003", "experiment_codes": ["I001"]}],
                "tester",  # tester 没有权限
            )

    def test_create_commission_no_groups(self):
        """至少需要一个样品组"""
        with self.assertRaises(ValueError):
            create_commission(
                {"commission_no": "WTN", "client_org_id": 1, "client_name": "N",
                 "client_address": "", "contact": "", "phone": "",
                 "production_org_id": 2, "production_org_name": "Z",
                 "production_relation": "生产单位",
                 "commission_date": china_today(), "due_date": add_months_to_date(china_today(), 1)},
                [], "receiver",
            )

    # ---------- 审计日志路径 ----------
    def test_audit_logs_not_empty_after_operations(self):
        """操作后审计日志应有记录"""
        logs = audit_logs()
        self.assertTrue(len(logs) > 0, "审计日志不应为空")

    def test_audit_logs_chained(self):
        """审计日志哈希链完整"""
        logs = audit_logs()
        chained = [x for x in reversed(logs) if x.get("entry_hash")]
        for i in range(1, min(len(chained), 10)):
            self.assertEqual(chained[i - 1]["entry_hash"], chained[i]["previous_hash"])

    # ---------- 用户管理路径 ----------
    def test_list_users_has_demo(self):
        """list_users 包含演示用户"""
        users = list_users()
        self.assertTrue(any(u["username"] == "admin" for u in users))

    def test_add_user_duplicate(self):
        """添加重复用户应报错"""
        with self.assertRaises(Exception):
            add_user("admin", "重复", "pass", "实验员")

    # ---------- 实验方法路径 ----------
    def test_list_methods_all_enabled(self):
        """list_experiment_methods 返回启用的方法"""
        methods = list_experiment_methods()
        self.assertEqual(len(methods), 10)
        for m in methods:
            self.assertIn("experiment_code", m)
            self.assertIn("experiment_name", m)

    # ---------- 样品目录路径 ----------
    def test_catalog_not_empty(self):
        """样品目录非空"""
        catalog = list_catalog()
        self.assertTrue(len(catalog) > 0)

    # ---------- 组织单位路径 ----------
    def test_organizations_have_client_and_producer(self):
        """应有委托客户和生产单位"""
        orgs = list_organizations()
        self.assertTrue(any(o["is_client"] for o in orgs))
        self.assertTrue(any(o["is_manufacturer"] for o in orgs))

    # ---------- 附件路径 ----------
    def test_save_attachment(self):
        """save_attachment 正常保存"""
        aid = save_attachment(
            {"attachment_type": "设备原始数据文件", "original_name": "test.csv", "task_no": "test"},
            b"test content", "tester",
        )
        self.assertTrue(len(aid) > 0)

    # ---------- 报告交付路径 ----------
    @unittest.skip("完整集成测试：需要已签发的正式报告")
    def test_add_and_list_report_delivery(self):
        """报告发放登记"""
        add_report_delivery(
            {"report_no": "R-TEST-001", "client_name": "测试", "delivery_method": "电子邮件",
             "recipient": "收件人", "receipt_status": "已发送"},
            "receiver",
        )
        deliveries = report_deliveries("R-TEST-001")
        self.assertEqual(len(deliveries), 1)


def setUpModule():
    """确保测试数据库被初始化"""
    init_db()


def tearDownModule():
    """清理临时数据库"""
    import shutil
    try:
        shutil.rmtree(str(_root), ignore_errors=True)
    except Exception:
        pass


if __name__ == "__main__":
    unittest.main(verbosity=2)
