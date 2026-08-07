# -*- coding: utf-8 -*-
"""BPLab Trace — 集成流程测试：完整生命周期"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_int_test_"))
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
    init_db, pool_close_all,
)
from business_record_engine import (
    initialize_business_record,
    calculate_business_record,
    validate_business_record,
)
from experiment_engine import result_summary

ALL_KINDS = [
    "rough", "mc_crack", "xray", "warp", "cte", "shock",
    "bend", "hv", "thickness", "color", "fixed_denture", "removable_denture",
]


class TestFullBusinessFlow(unittest.TestCase):
    """完整业务记录流程：init→calc→validate→result_summary"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_rough_full_flow(self):
        """rough: init→calc→validate 完整路径"""
        rec = initialize_business_record("rough", ["FLOW-S1"], "FlowLab")
        self.assertIn("parameters", rec)

        rec["parameters"]["start_time"] = "09:00"
        rec["parameters"]["end_time"] = "17:00"
        rec["rows"][0]["ra1"] = 1.0
        rec["rows"][0]["ra2"] = 2.0
        rec["rows"][0]["ra3"] = 3.0
        rec["task_confirmations"] = {"sample_received": True, "number_match": True, "sample_condition": True}

        result = calculate_business_record("rough", rec)
        self.assertNotEqual(result["report_summary"], "")
        self.assertNotEqual(result["report_conclusion"], "")

        issues = validate_business_record("rough", result)
        self.assertIsInstance(issues, list)

        summary, overall = result_summary("rough", result["rows"])
        self.assertIsInstance(summary, str)
        self.assertIsInstance(overall, str)

    def test_all_kinds_init_calc_no_crash(self):
        """12 种实验 init→calc 完整链不崩溃"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                rec = initialize_business_record(kind, ["ALL-S1"], "AllLab")
                result = calculate_business_record(kind, rec)
                self.assertIsInstance(result, dict)
                issues = validate_business_record(kind, result)
                self.assertIsInstance(issues, list)

    def test_all_kinds_result_summary(self):
        """12 种实验 result_summary 可执行"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                rec = initialize_business_record(kind, ["RS-S1"], "RSLab")
                result = calculate_business_record(kind, rec)
                summary, overall = result_summary(kind, result["rows"])
                self.assertIsInstance(summary, str)
                self.assertIsInstance(overall, str)


class TestEmptyVsPartialFill(unittest.TestCase):
    """全空 vs 部分填写 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_rough_empty_has_issues(self):
        """rough: 全空记录验证产生错误"""
        rec = initialize_business_record("rough", ["EMPTY-S1"], "")
        rec["parameters"]["start_time"] = ""
        rec["parameters"]["end_time"] = ""
        rec["report_summary"] = ""
        rec["rows"][0]["ra1"] = None
        rec["rows"][0]["ra2"] = None
        rec["rows"][0]["ra3"] = None
        issues = validate_business_record("rough", rec)
        self.assertGreater(len(issues), 0, "全空记录应有验证错误")

    def test_rough_partial_has_no_time_issues(self):
        """rough: 仅填必填字段后无时间问题"""
        rec = initialize_business_record("rough", ["PART-S1"], "PartialLab")
        rec["parameters"]["start_time"] = "09:00"
        rec["parameters"]["end_time"] = "17:00"
        rec["task_confirmations"] = {"sample_received": True, "number_match": True, "sample_condition": True}
        rec["rows"][0]["ra1"] = 1.0
        rec["rows"][0]["ra2"] = 2.0
        rec["rows"][0]["ra3"] = 3.0
        result = calculate_business_record("rough", rec)
        issues = validate_business_record("rough", result)
        self.assertFalse(any("开始时间" in i for i in issues))
        self.assertFalse(any("结束时间" in i for i in issues))

    def test_cte_partial_fill(self):
        """cte: 部分填写"""
        rec = initialize_business_record("cte", ["CTE-S1"], "CTELab")
        rec["rows"][0]["l0"] = 25.0
        rec["rows"][0]["t1"] = 25.0
        rec["rows"][0]["t2"] = 550.0
        rec["rows"][0]["delta_l"] = 125.0
        rec["rows"][0]["judgement_result"] = "符合"
        result = calculate_business_record("cte", rec)
        issues = validate_business_record("cte", result)
        self.assertIsInstance(issues, list)

    def test_shock_partial_fill(self):
        """shock: 部分填写"""
        rec = initialize_business_record("shock", ["SH-S1"], "ShockLab")
        rec["rows"][0]["crack"] = "无"
        rec["rows"][0]["chipping"] = "无"
        rec["rows"][0]["fracture"] = "无"
        result = calculate_business_record("shock", rec)
        self.assertEqual(result["rows"][0]["conclusion"], "符合")


class TestEquipmentIntegration(unittest.TestCase):
    """设备集成测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_supplementary_equipment_storage(self):
        """补充设备存储到 equipment_checks"""
        rec = initialize_business_record("rough", ["EQ-S1"], "EQLab")
        self.assertIn("equipment_checks", rec)
        self.assertIsInstance(rec["equipment_checks"], list)

    def test_validate_empty_equipment_list(self):
        """空设备列表验证不崩溃"""
        rec = initialize_business_record("rough", ["EQ-S1"], "EQLab")
        issues = validate_business_record("rough", rec, required_equipment=[])
        self.assertIsInstance(issues, list)

    def test_validate_none_equipment(self):
        """None 设备列表验证不崩溃"""
        rec = initialize_business_record("rough", ["EQ-S1"], "EQLab")
        issues = validate_business_record("rough", rec, required_equipment=None)
        self.assertIsInstance(issues, list)


class TestConfigSnapshotIntegration(unittest.TestCase):
    """版本快照集成测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_snapshot_from_current_version(self):
        """当前版本快照含 kind"""
        from lims_db import (
            list_experiment_configs_for_experimenter,
            build_partial_config_snapshot_from_version,
        )
        configs = list_experiment_configs_for_experimenter("I001")
        self.assertGreater(len(configs), 0)
        snap = build_partial_config_snapshot_from_version(configs[0]["id"])
        self.assertIn("kind", snap)

    def test_snapshots_from_different_versions(self):
        """不同版本快照均为有效 dict"""
        from lims_db import (
            list_experiment_configs_for_experimenter,
            build_partial_config_snapshot_from_version,
        )
        configs = list_experiment_configs_for_experimenter("I001")
        for cfg in configs[:3]:  # Test up to 3 versions
            snap = build_partial_config_snapshot_from_version(cfg["id"])
            self.assertIsInstance(snap, dict)
            self.assertIn("experiment_code", snap)


def setUpModule():
    init_db()


def tearDownModule():
    pool_close_all()
    import shutil
    try:
        shutil.rmtree(str(_root), ignore_errors=True)
    except Exception:
        pass


if __name__ == "__main__":
    unittest.main(verbosity=2)
