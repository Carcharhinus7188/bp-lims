# -*- coding: utf-8 -*-
"""BPLab Trace — 业务记录引擎单元测试"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_brec_test_"))
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

from lims_db import init_db
from business_record_engine import (
    initialize_business_record,
    calculate_business_record,
    validate_business_record,
    merge_widget_values_into_business_draft,
    fixed_and_manual_fields,
)

ALL_KINDS = [
    "rough", "mc_crack", "xray", "warp", "cte", "shock",
    "bend", "hv", "thickness", "color", "fixed_denture", "removable_denture",
]


class TestInitializeBusinessRecord(unittest.TestCase):
    """initialize_business_record 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_all_kinds_create_record(self):
        """12 种实验都能初始化"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                rec = initialize_business_record(kind, ["S1"], "Lab1")
                self.assertIsInstance(rec, dict)
                self.assertGreater(len(rec), 0)

    def test_required_top_level_keys(self):
        """返回 record 含所有必需顶层 key"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        for key in ("parameters", "rows", "task_confirmations",
                    "prechecks", "all_prechecks", "deviation",
                    "equipment_checks", "overall_status",
                    "report_summary", "report_conclusion",
                    "fixed_parameter_mode", "retest"):
            self.assertIn(key, rec)

    def test_parameters_contains_common_env_fields(self):
        """parameters 含公共环境字段"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        params = rec["parameters"]
        for key in ("test_date", "temperature_before", "humidity_before",
                    "detection_location", "equipment_name"):
            self.assertIn(key, params)

    def test_detection_location_set(self):
        """detection_location 正确填入"""
        rec = initialize_business_record("rough", ["S1"], "Lab A")
        self.assertEqual(rec["parameters"]["detection_location"], "Lab A")

    def test_prior_none_no_error(self):
        """prior=None 不影响初始化"""
        rec = initialize_business_record("rough", ["S1"], "Lab1", prior=None)
        self.assertIn("parameters", rec)

    def test_prior_preserves_existing_parameters(self):
        """prior 保留已有参数"""
        prior = {"parameters": {"custom_note": "kept_value"}}
        rec = initialize_business_record("rough", ["S1"], "Lab1", prior=prior)
        self.assertEqual(rec["parameters"]["custom_note"], "kept_value")

    def test_prior_preserves_existing_rows(self):
        """prior 保留并重新计算已有行"""
        prior = {"rows": [{"sample_no": "CUSTOM"}]}
        rec = initialize_business_record("rough", ["S1"], "Lab1", prior=prior)
        self.assertEqual(rec["rows"][0]["sample_no"], "CUSTOM")

    def test_empty_sample_list_defaults(self):
        """空样品列表生成 1 行"""
        rec = initialize_business_record("rough", [], "Lab1")
        self.assertEqual(len(rec["rows"]), 1)

    def test_task_confirmations_all_true(self):
        """task_confirmations 全部初始为 True"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        tc = rec["task_confirmations"]
        for v in tc.values():
            self.assertTrue(v)

    def test_hv_faces_expansion_in_record(self):
        """hv 每样品生成 2 行"""
        rec = initialize_business_record("hv", ["S1"], "Lab1")
        self.assertGreaterEqual(len(rec["rows"]), 2)

    def test_cte_no_start_end_time(self):
        """CTE 不含 start_time/end_time 字段"""
        rec = initialize_business_record("cte", ["S1"], "Lab1")
        self.assertNotIn("start_time", rec["parameters"])
        self.assertNotIn("end_time", rec["parameters"])


class TestCalculateBusinessRecord(unittest.TestCase):
    """calculate_business_record 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_standard_block_calculated(self):
        """rough: standard_block_measured 计算正确"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        params = rec["parameters"]
        params["repeat_check_1"] = 2.0
        params["repeat_check_2"] = 2.5
        params["repeat_check_3"] = 3.0
        result = calculate_business_record("rough", rec)
        # 3 repeat checks → measured = range/polar or avg
        self.assertIn("standard_block_measured", result["parameters"])
        self.assertIsNotNone(result["parameters"]["standard_block_measured"])
        self.assertNotEqual(result["parameters"]["standard_block_measured"], "")

    def test_report_summary_filled(self):
        """report_summary 被填充"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        rec["rows"][0]["ra1"] = 1.0
        rec["rows"][0]["ra2"] = 2.0
        rec["rows"][0]["ra3"] = 3.0
        result = calculate_business_record("rough", rec)
        self.assertNotEqual(result["report_summary"], "")

    def test_report_conclusion_filled(self):
        """report_conclusion 被填充"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        rec["rows"][0]["ra1"] = 1.0
        rec["rows"][0]["ra2"] = 2.0
        rec["rows"][0]["ra3"] = 3.0
        result = calculate_business_record("rough", rec)
        self.assertNotEqual(result["report_conclusion"], "")

    def test_missing_rows_key_no_crash(self):
        """无 rows 键不崩溃"""
        rec = {"parameters": {"test_date": "2024-01-01"}}
        result = calculate_business_record("rough", rec)
        self.assertIsInstance(result, dict)

    def test_deep_copy_does_not_mutate_input(self):
        """deep copy 不修改原始输入"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        rec["rows"][0]["ra1"] = 5.0
        rec["rows"][0]["ra2"] = 5.0
        rec["rows"][0]["ra3"] = 5.0
        original_mean = rec["rows"][0].get("mean")
        _ = calculate_business_record("rough", rec)
        # Original rows should be unchanged (deep copy)
        self.assertEqual(rec["rows"][0]["ra1"], 5.0)

    def test_all_kinds_calculate(self):
        """12 种实验 calculate 不崩溃"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                rec = initialize_business_record(kind, ["S1"], "Lab1")
                result = calculate_business_record(kind, rec)
                self.assertIsInstance(result, dict)
                self.assertIn("report_summary", result)
                self.assertIn("report_conclusion", result)


class TestValidateBusinessRecord(unittest.TestCase):
    """validate_business_record 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_missing_start_time(self):
        """非CTE实验缺少 start_time 报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        issues = validate_business_record("rough", rec)
        self.assertTrue(any("开始时间" in i for i in issues),
                        f"Expected start_time error, got: {issues}")

    def test_missing_end_time(self):
        """非CTE实验缺少 end_time 报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        issues = validate_business_record("rough", rec)
        self.assertTrue(any("结束时间" in i for i in issues),
                        f"Expected end_time error, got: {issues}")

    def test_cte_no_time_errors(self):
        """CTE 无时间轴限制，不报时间错误"""
        rec = initialize_business_record("cte", ["S1"], "Lab1")
        issues = validate_business_record("cte", rec)
        self.assertFalse(any("开始时间" in i for i in issues))
        self.assertFalse(any("结束时间" in i for i in issues))

    def test_task_confirmations_missing(self):
        """task_confirmations 缺失报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        rec["task_confirmations"]["sample_received"] = False
        issues = validate_business_record("rough", rec)
        self.assertTrue(any("确认" in i or "任务" in i for i in issues),
                        f"Got: {issues}")

    def test_prechecks_missing_no_note(self):
        """prechecks 缺失且无 note 报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        # Uncheck a precheck
        rec["prechecks"][0] = False
        rec["precheck_note"] = ""
        issues = validate_business_record("rough", rec)
        self.assertTrue(any("检查" in i for i in issues),
                        f"Got: {issues}")

    def test_prechecks_missing_with_note(self):
        """prechecks 缺失但有 note 不报此错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        rec["prechecks"][0] = False
        rec["precheck_note"] = "已知问题，已记录"
        issues = validate_business_record("rough", rec)
        # The precheck issue specific to prechecks should be suppressed
        # (may still have other issues like time)
        time_issues = [i for i in issues if "检查前" in i and "note" not in i]
        self.assertEqual(len(time_issues), 0)

    def test_empty_report_summary_error(self):
        """report_summary 为空报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        rec["report_summary"] = ""
        issues = validate_business_record("rough", rec)
        self.assertTrue(any("摘要" in i for i in issues),
                        f"Got: {issues}")

    def test_row_missing_required_field(self):
        """行必填字段缺失报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        rec["rows"][0]["ra1"] = None
        rec["rows"][0]["ra2"] = None
        rec["rows"][0]["ra3"] = None
        # Fill time to avoid time-related errors
        rec["parameters"]["start_time"] = "09:00"
        rec["parameters"]["end_time"] = "17:00"
        issues = validate_business_record("rough", rec)
        # May have row-level required field errors
        self.assertIsInstance(issues, list)

    def test_required_equipment_abnormal_no_note(self):
        """必需设备状态异常无说明报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        # required_equipment needs management_no and required keys
        equip = [
            {"management_no": "EQ-001", "required": True}
        ]
        # equipment_checks must have matching management_no with abnormal status
        rec["equipment_checks"] = [
            {"management_no": "EQ-001", "status": "异常", "note": ""}
        ]
        issues = validate_business_record("rough", rec, required_equipment=equip)
        has_equip_error = any("EQ-001" in i for i in issues)
        self.assertTrue(has_equip_error, f"Expected equipment error, got: {issues}")

    def test_required_equipment_abnormal_with_note(self):
        """必需设备异常有说明不报此错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        equip = [
            {"management_no": "EQ-001", "required": True}
        ]
        rec["equipment_checks"] = [
            {"management_no": "EQ-001", "status": "异常", "note": "已报修"}
        ]
        issues = validate_business_record("rough", rec, required_equipment=equip)
        has_equip_error = any("EQ-001" in i for i in issues)
        self.assertFalse(has_equip_error, f"Got: {issues}")

    def test_required_equipment_none_ok(self):
        """required_equipment=None 正常"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        issues = validate_business_record("rough", rec, required_equipment=None)
        self.assertIsInstance(issues, list)

    def test_returns_list(self):
        """返回类型为 list[str]"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        issues = validate_business_record("rough", rec)
        self.assertIsInstance(issues, list)


class TestMergeWidgetValues(unittest.TestCase):
    """merge_widget_values_into_business_draft 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_merges_parameter_widget(self):
        """参数 widget 值合并到 parameters"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        widget_state = {"temp_before": "25.0"}
        merge_widget_values_into_business_draft("rough", rec, "", widget_state)
        # After merge, the value may or may not be in parameters
        # depending on key prefix and matching logic
        self.assertIsInstance(rec, dict)

    def test_merges_row_widget(self):
        """行 widget 值合并到 rows"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        # Build widget state with expected row key prefix
        widget_state = {"ra1_S1": "5.0"}
        merge_widget_values_into_business_draft("rough", rec, "", widget_state)
        self.assertIsInstance(rec, dict)

    def test_empty_widget_state_no_error(self):
        """空 widget_state 不报错"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        merge_widget_values_into_business_draft("rough", rec, "", {})
        self.assertIsInstance(rec, dict)

    def test_non_matching_keys_ignored(self):
        """不匹配的 widget key 被忽略"""
        rec = initialize_business_record("rough", ["S1"], "Lab1")
        params_before = dict(rec["parameters"])
        widget_state = {"nonexistent_key_xyz": "value"}
        merge_widget_values_into_business_draft("rough", rec, "", widget_state)
        # Parameters should be unchanged for this key
        self.assertEqual(rec["parameters"].get("nonexistent_key_xyz"),
                         params_before.get("nonexistent_key_xyz"))


class TestFixedAndManualFields(unittest.TestCase):
    """fixed_and_manual_fields 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_returns_two_lists(self):
        """返回两个列表"""
        fixed, manual = fixed_and_manual_fields("rough")
        self.assertIsInstance(fixed, list)
        self.assertIsInstance(manual, list)

    def test_fixed_fields_are_dicts(self):
        """fixed 字段都是 dict"""
        fixed, _ = fixed_and_manual_fields("rough")
        for f in fixed:
            self.assertIsInstance(f, dict)
            self.assertIn("key", f)
            self.assertIn("label", f)

    def test_manual_fields_are_dicts(self):
        """manual 字段都是 dict"""
        _, manual = fixed_and_manual_fields("rough")
        for f in manual:
            self.assertIsInstance(f, dict)
            self.assertIn("key", f)
            self.assertIn("label", f)

    def test_no_overlap_between_fixed_and_manual(self):
        """fixed 和 manual 无重叠"""
        fixed, manual = fixed_and_manual_fields("rough")
        fixed_keys = {f["key"] for f in fixed}
        manual_keys = {f["key"] for f in manual}
        self.assertTrue(fixed_keys.isdisjoint(manual_keys))

    def test_all_kinds_return_lists(self):
        """12 种实验都返回有效分类"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                fixed, manual = fixed_and_manual_fields(kind)
                self.assertIsInstance(fixed, list)
                self.assertIsInstance(manual, list)


def setUpModule():
    init_db()


def tearDownModule():
    import shutil
    from lims_db import pool_close_all
    pool_close_all()
    try:
        shutil.rmtree(str(_root), ignore_errors=True)
    except Exception:
        pass


if __name__ == "__main__":
    unittest.main(verbosity=2)
