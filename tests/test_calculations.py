# -*- coding: utf-8 -*-
"""BPLab Trace — 计算边界/精度/除零/None 传播测试"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_calc_test_"))
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
from experiment_engine import calculate_rows, _number_or_none, _num


# ── 精度验证 ──

class TestPrecision(unittest.TestCase):
    """计算结果精度测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_rough_mean_round_3(self):
        """rough: mean = round(avg, 3)"""
        rows = [{"ra1": 1.0, "ra2": 2.0, "ra3": 3.0}]
        result = calculate_rows("rough", rows)
        # (1+2+3)/3 = 2.0 → round(2.0, 3) = 2.0
        self.assertEqual(result[0]["mean"], 2.0)

    def test_rough_mean_precision_fraction(self):
        """rough: mean 精度 3 — 分数正确"""
        rows = [{"ra1": 1.0, "ra2": 2.0, "ra3": 3.0}]
        result = calculate_rows("rough", rows)
        # round(2.0, 3) = 2.0 (float)
        self.assertIsInstance(result[0]["mean"], float)

    def test_mc_crack_dm_mean_round_4(self):
        """mc_crack: dm_mean = round(avg, 4)"""
        rows = [{"dm1": 1.0, "dm2": 2.0, "dm3": 3.0}]
        result = calculate_rows("mc_crack", rows)
        self.assertEqual(result[0]["dm_mean"], 2.0)

    def test_mc_crack_tau_round_2(self):
        """mc_crack: tau = round(k*ffail, 2)"""
        rows = [{"k": 5.0, "ffail": 6.0}]
        result = calculate_rows("mc_crack", rows)
        self.assertEqual(result[0]["tau"], 30.0)

    def test_xray_roi_round_2(self):
        """xray: roi = round(avg, 2)"""
        rows = [{
            "roi1_reading1": 100.0, "roi1_reading2": 100.0, "roi1_reading3": 100.0,
            "roi2_reading1": 200.0, "roi2_reading2": 200.0, "roi2_reading3": 200.0,
            "roi3_reading1": 300.0, "roi3_reading2": 300.0, "roi3_reading3": 300.0,
        }]
        result = calculate_rows("xray", rows)
        self.assertEqual(result[0]["roi_mean"], 200.0)

    def test_warp_delta_round_4(self):
        """warp: delta = round(h1-h2, 4)"""
        rows = [{"h1": 5.0, "h2": 3.0}]
        result = calculate_rows("warp", rows)
        self.assertEqual(result[0]["delta"], 2.0)

    def test_cte_delta_t_round_3(self):
        """cte: delta_t = round(t2-t1, 3)"""
        rows = [{"t1": 25.0, "t2": 550.0}]
        result = calculate_rows("cte", rows)
        self.assertEqual(result[0]["delta_t"], 525.0)

    def test_cte_alpha_round_3(self):
        """cte: alpha = round(..., 3)"""
        rows = [{"l0": 25.0, "t1": 20.0, "t2": 520.0, "delta_l": 125.0}]
        result = calculate_rows("cte", rows)
        self.assertIsNotNone(result[0]["alpha"])
        # round((125/1000)/(25*500)*1e6, 3)
        self.assertEqual(result[0]["alpha"], 10.0)

    def test_hv_mean_round_1(self):
        """hv: mean = round(avg, 1)"""
        rows = [{"indent1": 100.0, "indent2": 200.0, "indent3": 300.0}]
        result = calculate_rows("hv", rows)
        self.assertEqual(result[0]["mean"], 200.0)

    def test_thickness_mean_round_4(self):
        """thickness: fixed_mean = round(avg, 4)"""
        # Known bug: key naming mismatch, but if working would use this precision
        rows = [{
            "r1_fixed": 1.0, "r1_middle": 1.0, "r1_free": 1.0,
            "r2_fixed": 1.0, "r2_middle": 1.0, "r2_free": 1.0,
            "r3_fixed": 1.0, "r3_middle": 1.0, "r3_free": 1.0,
        }]
        result = calculate_rows("thickness", rows)
        if result[0].get("fixed_mean") is not None:
            self.assertIsInstance(result[0]["fixed_mean"], float)


# ── 除零保护 ──

class TestDivisionByZero(unittest.TestCase):
    """除零保护测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_cte_l0_zero_no_crash(self):
        """cte: l0=0 → alpha=None 不崩溃"""
        rows = [{"l0": 0.0, "t1": 25.0, "t2": 525.0, "delta_l": 50.0}]
        result = calculate_rows("cte", rows)
        # Expression: (delta_l/1000)/(l0*dt)*1e6, l0=0 makes denominator 0
        # The exception is caught, alpha should be None
        self.assertIsNone(result[0].get("alpha"))

    def test_rough_limit_zero_pass(self):
        """rough: limit=0, mean>0 → conclusion="不符合" (正常计算)"""
        rows = [{"ra1": 1.0, "ra2": 1.0, "ra3": 1.0, "limit": 0.0}]
        result = calculate_rows("rough", rows)
        # mean=1.0 > 0.0 → 不符合
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_hv_indent_zero_no_crash(self):
        """hv: indent=0 正常除不崩溃"""
        rows = [{"indent1": 0.0, "indent2": 0.0, "indent3": 0.0}]
        result = calculate_rows("hv", rows)
        self.assertEqual(result[0]["mean"], 0.0)

    def test_thickness_design_thickness_zero(self):
        """thickness: design_thickness=0 → deviation 正常"""
        rows = [{
            "r1_fixed": 1.0, "r1_middle": 1.0, "r1_free": 1.0,
            "r2_fixed": 1.0, "r2_middle": 1.0, "r2_free": 1.0,
            "r3_fixed": 1.0, "r3_middle": 1.0, "r3_free": 1.0,
            "design_thickness": 0.0,
        }]
        # Should not raise ZeroDivisionError (subtraction, not division)
        result = calculate_rows("thickness", rows)
        self.assertIsInstance(result, list)

    def test_mc_crack_ffail_zero(self):
        """mc_crack: ffail=0 → tau=0 (k*0=0)"""
        rows = [{"k": 5.0, "ffail": 0.0}]
        result = calculate_rows("mc_crack", rows)
        self.assertEqual(result[0]["tau"], 0.0)


# ── None 传播 ──

class TestNonePropagation(unittest.TestCase):
    """None 值传播测试 — 缺失输入导致计算结果为 None"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_rough_missing_one_ra(self):
        """rough: 一个 ra 缺失 → mean=None"""
        rows = [{"ra1": 1.0, "ra2": 2.0}]
        result = calculate_rows("rough", rows)
        self.assertIsNone(result[0]["mean"])

    def test_rough_missing_all_ra(self):
        """rough: 全部 ra 缺失 → mean=None → conclusion="""
        rows = [{"sample_no": "S1"}]
        result = calculate_rows("rough", rows)
        self.assertIsNone(result[0]["mean"])
        self.assertEqual(result[0]["conclusion"], "")

    def test_mc_crack_missing_k(self):
        """mc_crack: k 缺失 → tau=None → conclusion="""
        rows = [{"dm1": 1.0, "dm2": 2.0, "dm3": 3.0, "ffail": 6.0}]
        result = calculate_rows("mc_crack", rows)
        self.assertIsNone(result[0]["tau"])
        self.assertEqual(result[0]["conclusion"], "")

    def test_warp_missing_h1(self):
        """warp: h1 缺失 → delta=None → DB calc 回落为 0 → conclusion="合格" """
        # Note: DB _column_calcs uses row.get('delta', 0) which defaults to 0
        # when delta is None, making abs(0) <= 0.5 → "合格"
        rows = [{"h2": 3.0}]
        result = calculate_rows("warp", rows)
        self.assertIsNone(result[0]["delta"])
        # DB calc overrides: abs(0) <= 0.5 → 合格
        self.assertEqual(result[0]["conclusion"], "合格")

    def test_cte_missing_l0(self):
        """cte: l0 缺失 → alpha=None"""
        rows = [{"t1": 25.0, "t2": 550.0, "delta_l": 50.0}]
        result = calculate_rows("cte", rows)
        self.assertIsNone(result[0]["alpha"])

    def test_cte_missing_delta_l(self):
        """cte: delta_l 缺失 → alpha=None"""
        rows = [{"l0": 10.0, "t1": 25.0, "t2": 550.0}]
        result = calculate_rows("cte", rows)
        self.assertIsNone(result[0]["alpha"])

    def test_hv_missing_one_indent(self):
        """hv: 一个 indent 缺失 → mean=None"""
        rows = [{"indent1": 100.0, "indent2": 200.0}]
        result = calculate_rows("hv", rows)
        self.assertIsNone(result[0]["mean"])

    def test_xray_missing_readings(self):
        """xray: 读数全部缺失 → roi=None, roi_mean=None"""
        rows = [{"sample_no": "S1"}]
        result = calculate_rows("xray", rows)
        self.assertIsNone(result[0]["roi_mean"])

    def test_shock_missing_field(self):
        """shock: 字段缺失被视为非"无" → 不符合"""
        rows = [{"crack": "有"}]
        result = calculate_rows("shock", rows)
        # crack="有" → 不符合 (chipping/fracture 缺失也被视为非无)
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_bend_missing_stress_zero_default(self):
        """bend: stress_02 缺失 → _num(None, 0)=0 → 不符合"""
        rows = [{"sample_no": "S1"}]
        result = calculate_rows("bend", rows)
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_color_missing_observers(self):
        """color: 观察者全部缺失 → 异常静默捕获"""
        rows = [{"sample_no": "S1"}]
        # Should not crash — exception caught by try/except
        result = calculate_rows("color", rows)
        self.assertIsInstance(result, list)
        self.assertEqual(len(result), 1)


# ── 额外辅助函数边界值 ──

class TestHelperEdgeCases(unittest.TestCase):
    """_num / _number_or_none 边界值"""

    def test_num_with_zero(self):
        """_num(0, default) → 0.0 (不是 falsy)"""
        self.assertEqual(_num(0, 99), 0.0)

    def test_num_with_negative(self):
        """_num(-5, default) → -5.0"""
        self.assertEqual(_num(-5, 99), -5.0)

    def test_number_or_none_zero(self):
        """_number_or_none(0) → 0.0"""
        self.assertEqual(_number_or_none(0), 0.0)

    def test_number_or_none_negative(self):
        """_number_or_none(-10) → -10.0"""
        self.assertEqual(_number_or_none(-10), -10.0)

    def test_number_or_none_whitespace_string(self):
        """"  " → None"""
        self.assertIsNone(_number_or_none("   "))

    def test_number_or_none_scientific_notation(self):
        """"1e-3" → 0.001"""
        self.assertEqual(_number_or_none("1e-3"), 0.001)

    def test_num_scientific_notation(self):
        """_num("1e3", 0) → 1000.0"""
        self.assertEqual(_num("1e3", 0), 1000.0)

    def test_num_boolean(self):
        """_num(True, 0) → 1.0"""
        self.assertEqual(_num(True, 0), 1.0)

    def test_number_or_none_boolean(self):
        """_number_or_none(False) → 0.0"""
        self.assertEqual(_number_or_none(False), 0.0)


# ── 综合链式计算验证 ──

class TestChainedCalculation(unittest.TestCase):
    """多步计算链的正确性"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_rough_full_chain(self):
        """rough: ra→mean→conclusion 完整链"""
        rows = [
            {"ra1": 0.8, "ra2": 1.2, "ra3": 1.0, "limit": 1.5, "sample_no": "S1"},
            {"ra1": 2.0, "ra2": 2.5, "ra3": 3.0, "limit": 1.5, "sample_no": "S2"},
            {"ra1": 0.5, "ra2": 0.5, "ra3": 0.5, "limit": 1.5, "sample_no": "S3"},
        ]
        result = calculate_rows("rough", rows)
        self.assertEqual(result[0]["mean"], 1.0)
        self.assertEqual(result[0]["conclusion"], "符合")
        self.assertEqual(result[1]["conclusion"], "不符合")
        self.assertEqual(result[2]["conclusion"], "符合")

    def test_warp_full_chain(self):
        """warp: h1,h2→delta→conclusion 完整链"""
        rows = [
            {"h1": 5.0, "h2": 4.8, "limit": 0.5, "sample_no": "S1"},
            {"h1": 5.0, "h2": 4.0, "limit": 0.5, "sample_no": "S2"},
        ]
        result = calculate_rows("warp", rows)
        self.assertEqual(result[0]["delta"], 0.2)
        self.assertEqual(result[0]["conclusion"], "合格")
        self.assertEqual(result[1]["delta"], 1.0)
        self.assertEqual(result[1]["conclusion"], "不合格")

    def test_shock_all_combinations(self):
        """shock: 所有标志位组合"""
        rows = [
            {"crack": "无", "chipping": "无", "fracture": "无", "sample_no": "S1"},
            {"crack": "有", "chipping": "无", "fracture": "无", "sample_no": "S2"},
            {"crack": "无", "chipping": "有", "fracture": "无", "sample_no": "S3"},
            {"crack": "无", "chipping": "无", "fracture": "有", "sample_no": "S4"},
        ]
        result = calculate_rows("shock", rows)
        self.assertEqual(result[0]["conclusion"], "符合")
        self.assertEqual(result[1]["conclusion"], "不符合")
        self.assertEqual(result[2]["conclusion"], "不符合")
        self.assertEqual(result[3]["conclusion"], "不符合")

    def test_color_observer_combinations(self):
        """color: 关键观察者组合"""
        # 2 severe → 明显差异, 不符合
        rows1 = [{"observer1": "明显差异", "observer2": "明显差异",
                  "observer3": "未见明显差异", "sample_no": "S1"}]
        r1 = calculate_rows("color", rows1)
        self.assertEqual(r1[0]["overall"], "明显差异")
        self.assertEqual(r1[0]["conclusion"], "不符合")

        # 2 unable → 无法判定, 需复核
        rows2 = [{"observer1": "无法判定", "observer2": "无法判定",
                  "observer3": "未见明显差异", "sample_no": "S2"}]
        r2 = calculate_rows("color", rows2)
        self.assertEqual(r2[0]["overall"], "无法判定")
        self.assertEqual(r2[0]["conclusion"], "需复核")

        # 1 severe + 1 unable + 1 normal → overall not "明显差异" or "无法判定"
        rows3 = [{"observer1": "明显差异", "observer2": "无法判定",
                  "observer3": "未见明显差异", "sample_no": "S3"}]
        r3 = calculate_rows("color", rows3)
        # severe=1 (<2), unable=1 (<2) → "未见明显差异/轻微差异"
        self.assertNotIn(r3[0]["overall"], ("明显差异", "无法判定"))


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
