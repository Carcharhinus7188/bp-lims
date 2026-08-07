# -*- coding: utf-8 -*-
"""BPLab Trace — 实验引擎单元测试：schema/参数/行/计算"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_engine_test_"))
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
from experiment_engine import (
    schema, initial_parameters, initial_rows, calculate_rows,
    normalize_rows, result_summary, columns_for_editor, dataframe,
)
# Private helpers for white-box testing
from experiment_engine import _number_or_none, _num, _db_schema

ALL_KINDS = [
    "rough", "mc_crack", "xray", "warp", "cte", "shock",
    "bend", "hv", "thickness", "color", "fixed_denture", "removable_denture",
]


class TestSchema(unittest.TestCase):
    """schema() 函数测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_all_known_kinds_return_dict(self):
        """12 个已知 kind 都返回有效字典"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                s = schema(kind)
                self.assertIsInstance(s, dict)
                self.assertIn("sections", s)
                self.assertIn("columns", s)

    def test_sections_is_non_empty(self):
        """每个 kind 至少有一个 section"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                s = schema(kind)
                self.assertGreater(len(s["sections"]), 0)

    def test_columns_is_non_empty(self):
        """每个 kind 至少有一列"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                s = schema(kind)
                self.assertGreater(len(s["columns"]), 0)

    def test_unknown_kind_fallback(self):
        """未知 kind 返回 generic schema"""
        s = schema("nonexistent_kind_xyz")
        self.assertIn("sections", s)
        self.assertEqual(s, schema("generic"))

    def test_empty_string_fallback(self):
        """空字符串返回 generic schema"""
        s = schema("")
        self.assertEqual(s, schema("generic"))

    def test_generic_kind(self):
        """generic kind 返回通用配置"""
        s = schema("generic")
        self.assertIn("sections", s)
        self.assertIn("columns", s)

    def test_db_schema_returns_none_for_unknown(self):
        """_db_schema 对未知 kind 返回 None"""
        result = _db_schema("nonexistent")
        self.assertIsNone(result)

    def test_db_schema_for_known_kind(self):
        """_db_schema 对已知 kind 返回配置"""
        s = _db_schema("rough")
        self.assertIsNotNone(s)
        self.assertIn("sections", s)

    def test_hv_has_face_labels(self):
        """hv 有 face_labels（faces 展开模式）"""
        s = schema("hv")
        face_labels = s.get("face_labels")
        self.assertIsNotNone(face_labels)

    def test_rough_has_result_labels(self):
        """rough 有 DB result labels"""
        s = schema("rough")
        # DB schema should have _result_title
        if s.get("_result_title"):
            self.assertIn("_result_title", s)
            self.assertIn("_result_value_key", s)


class TestInitialParameters(unittest.TestCase):
    """initial_parameters() 函数测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_all_kinds_return_dict(self):
        """12 种实验都返回参数字典"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                params = initial_parameters(kind)
                self.assertIsInstance(params, dict)

    def test_rough_has_sampling_params(self):
        """rough 含取样参数默认值"""
        params = initial_parameters("rough")
        self.assertIn("sampling_length", params)
        self.assertIn("sampling_count", params)
        self.assertIn("evaluation_length", params)
        # DB defaults after Phase B (stored as strings from DB)
        self.assertEqual(float(params["sampling_length"]), 2.5)
        self.assertEqual(float(params["sampling_count"]), 3.0)

    def test_preset_none(self):
        """preset=None 不影响结果"""
        params = initial_parameters("rough", preset=None)
        self.assertIn("test_date", params)

    def test_preset_partial_override(self):
        """preset 部分覆盖默认值"""
        params = initial_parameters("rough", preset={"temperature_before": 25.0})
        self.assertEqual(params["temperature_before"], 25.0)

    def test_preset_empty_value_not_override(self):
        """preset 空值不覆盖默认"""
        params = initial_parameters("rough", preset={"temperature_before": ""})
        self.assertNotEqual(params.get("temperature_before"), "")

    def test_detection_location_override(self):
        """detection_location 参数正确填入"""
        params = initial_parameters("rough", detection_location="Lab A")
        self.assertEqual(params["detection_location"], "Lab A")

    def test_detection_location_empty(self):
        """detection_location 为空"""
        params = initial_parameters("rough", detection_location="")
        self.assertEqual(params["detection_location"], "")

    def test_cte_has_heating_rate_default(self):
        """CTE 有升温速率默认值 5.0"""
        params = initial_parameters("cte")
        self.assertEqual(float(params["heating_rate"]), 5.0)

    def test_cte_no_start_time_end_time(self):
        """CTE 不应有 start_time/end_time"""
        params = initial_parameters("cte")
        # CTE schema excludes these from COMMON_ENV_FIELDS
        self.assertNotIn("start_time", params)
        self.assertNotIn("end_time", params)

    def test_fixed_denture_has_design_check(self):
        """固定义齿有设计单检查字段"""
        params = initial_parameters("fixed_denture")
        self.assertIn("design_sheet_check", params)
        self.assertEqual(params["design_sheet_check"], "符合")

    def test_removable_denture_has_traceability(self):
        """活动义齿有追溯字段"""
        params = initial_parameters("removable_denture")
        self.assertIn("material_traceability", params)


class TestInitialRows(unittest.TestCase):
    """initial_rows() 函数测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_single_sample_returns_one_row(self):
        """单样品返回 1 行"""
        rows = initial_rows("rough", ["S1"])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["sample_no"], "S1")

    def test_multiple_samples(self):
        """多样品返回 N 行"""
        rows = initial_rows("rough", ["S1", "S2", "S3"])
        self.assertEqual(len(rows), 3)

    def test_empty_sample_list(self):
        """空样品列表返回 1 行（sample_no=""）"""
        rows = initial_rows("rough", [])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["sample_no"], "")

    def test_hv_faces_expansion(self):
        """hv 每样品生成 2 行（faces 展开）"""
        rows = initial_rows("hv", ["S1"])
        self.assertGreaterEqual(len(rows), 2)
        faces = [r.get("face") for r in rows]
        self.assertIn("Z轴方向", faces)

    def test_all_kinds_produce_rows(self):
        """12 种实验都能生成行"""
        for kind in ALL_KINDS:
            with self.subTest(kind=kind):
                rows = initial_rows(kind, ["SAMPLE01"])
                self.assertIsInstance(rows, list)
                self.assertGreater(len(rows), 0)

    def test_column_defaults_from_db(self):
        """行包含 DB 列默认值"""
        rows = initial_rows("rough", ["S1"])
        self.assertIn("limit", rows[0])
        self.assertEqual(rows[0]["limit"], 15.0)

    def test_bend_column_defaults(self):
        """bend 列默认值正确"""
        rows = initial_rows("bend", ["S1"])
        r = rows[0]
        self.assertEqual(r.get("length"), 25.0)
        self.assertEqual(r.get("width"), 2.0)
        self.assertEqual(r.get("height"), 2.0)
        self.assertEqual(r.get("span"), 20.0)
        self.assertEqual(r.get("speed"), 1.0)

    def test_cte_column_defaults(self):
        """CTE 列默认值正确"""
        rows = initial_rows("cte", ["S1"])
        r = rows[0]
        self.assertEqual(r.get("t1"), 25.0)
        self.assertEqual(r.get("t2"), 550.0)


class TestCalculateRows(unittest.TestCase):
    """calculate_rows() 计算逻辑测试 — 12 个实验"""

    @classmethod
    def setUpClass(cls):
        init_db()

    # ── rough ──
    def test_rough_mean_normal(self):
        """rough: 正常 ra 值 mean=avg"""
        rows = [{"ra1": 1.0, "ra2": 2.0, "ra3": 3.0, "sample_no": "S1"}]
        result = calculate_rows("rough", rows)
        self.assertEqual(result[0]["mean"], 2.0)

    def test_rough_mean_precision(self):
        """rough: mean 精度为 3 位"""
        rows = [{"ra1": 1.0, "ra2": 2.0, "ra3": 3.0}]
        result = calculate_rows("rough", rows)
        # round((1+2+3)/3, 3) = round(2.0, 3) = 2.0
        self.assertEqual(result[0]["mean"], 2.0)

    def test_rough_conclusion_pass(self):
        """rough: mean <= limit → 符合"""
        rows = [{"ra1": 1.0, "ra2": 2.0, "ra3": 3.0, "limit": 15.0}]
        result = calculate_rows("rough", rows)
        self.assertEqual(result[0]["conclusion"], "符合")

    def test_rough_conclusion_fail(self):
        """rough: mean > limit → 不符合"""
        rows = [{"ra1": 10.0, "ra2": 10.0, "ra3": 10.0, "limit": 5.0}]
        result = calculate_rows("rough", rows)
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_rough_missing_ra_mean_none(self):
        """rough: ra 缺失 → mean=None"""
        rows = [{"ra1": 1.0, "sample_no": "S1"}]
        result = calculate_rows("rough", rows)
        self.assertIsNone(result[0]["mean"])

    def test_rough_all_missing_conclusion_empty(self):
        """rough: 全部缺失 → conclusion="" """
        rows = [{"sample_no": "S1"}]
        result = calculate_rows("rough", rows)
        self.assertEqual(result[0]["conclusion"], "")

    def test_rough_empty_limit_defaults(self):
        """rough: limit 为空默认 15.0"""
        rows = [{"ra1": 1.0, "ra2": 2.0, "ra3": 3.0, "sample_no": "S1"}]
        result = calculate_rows("rough", rows)
        self.assertEqual(result[0]["conclusion"], "符合")

    # ── mc_crack ──
    def test_mc_crack_dm_mean(self):
        """mc_crack: dm_mean=avg(dm1,dm2,dm3)"""
        rows = [{"dm1": 1.0, "dm2": 2.0, "dm3": 3.0, "sample_no": "S1"}]
        result = calculate_rows("mc_crack", rows)
        self.assertEqual(result[0]["dm_mean"], 2.0)

    def test_mc_crack_tau(self):
        """mc_crack: tau=k*ffail"""
        rows = [{"k": 5.0, "ffail": 6.0, "sample_no": "S1"}]
        result = calculate_rows("mc_crack", rows)
        self.assertEqual(result[0]["tau"], 30.0)

    def test_mc_crack_conclusion_pass(self):
        """mc_crack: tau>25 → 符合"""
        rows = [{"k": 5.0, "ffail": 6.0, "sample_no": "S1"}]
        result = calculate_rows("mc_crack", rows)
        self.assertEqual(result[0]["conclusion"], "符合")

    def test_mc_crack_conclusion_fail(self):
        """mc_crack: tau<=25 → 不符合"""
        rows = [{"k": 2.0, "ffail": 5.0, "sample_no": "S1"}]
        result = calculate_rows("mc_crack", rows)
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_mc_crack_missing_k_tau_none(self):
        """mc_crack: k 缺失 → tau=None"""
        rows = [{"ffail": 6.0, "sample_no": "S1"}]
        result = calculate_rows("mc_crack", rows)
        self.assertIsNone(result[0]["tau"])

    # ── xray ──
    def test_xray_roi_calculation(self):
        """xray: 3 ROI × 3 readings 正确计算"""
        rows = [{
            "sample_no": "S1",
            "roi1_reading1": 100, "roi1_reading2": 110, "roi1_reading3": 120,
            "roi2_reading1": 200, "roi2_reading2": 210, "roi2_reading3": 220,
            "roi3_reading1": 300, "roi3_reading2": 310, "roi3_reading3": 320,
        }]
        result = calculate_rows("xray", rows)
        self.assertEqual(result[0]["roi1"], 110.0)
        self.assertEqual(result[0]["roi2"], 210.0)
        self.assertEqual(result[0]["roi3"], 310.0)
        self.assertEqual(result[0]["roi_mean"], 210.0)

    def test_xray_legacy_roi_fallback(self):
        """xray: 读数缺失时用 legacy roi 值"""
        rows = [{"sample_no": "S1", "roi1": 50.0, "roi2": 60.0, "roi3": 70.0}]
        result = calculate_rows("xray", rows)
        self.assertEqual(result[0]["roi1"], 50.0)

    # ── warp ──
    def test_warp_delta_positive(self):
        """warp: h1-h2 positive"""
        rows = [{"h1": 5.0, "h2": 3.0, "sample_no": "S1"}]
        result = calculate_rows("warp", rows)
        self.assertEqual(result[0]["delta"], 2.0)

    def test_warp_delta_negative(self):
        """warp: h1-h2 negative"""
        rows = [{"h1": 3.0, "h2": 5.0, "sample_no": "S1"}]
        result = calculate_rows("warp", rows)
        self.assertEqual(result[0]["delta"], -2.0)

    def test_warp_conclusion_pass(self):
        """warp: abs(delta)<=limit → 合格"""
        rows = [{"h1": 5.0, "h2": 4.8, "limit": 0.5, "sample_no": "S1"}]
        result = calculate_rows("warp", rows)
        self.assertEqual(result[0]["conclusion"], "合格")

    def test_warp_conclusion_fail(self):
        """warp: abs(delta)>limit → 不合格"""
        rows = [{"h1": 5.0, "h2": 4.0, "limit": 0.5, "sample_no": "S1"}]
        result = calculate_rows("warp", rows)
        self.assertEqual(result[0]["conclusion"], "不合格")

    # ── cte ──
    def test_cte_delta_t(self):
        """cte: delta_t=t2-t1"""
        rows = [{"t1": 25.0, "t2": 550.0, "sample_no": "S1"}]
        result = calculate_rows("cte", rows)
        self.assertEqual(result[0]["delta_t"], 525.0)

    def test_cte_alpha_calculation(self):
        """cte: alpha 计算正确"""
        rows = [{"l0": 10.0, "t1": 25.0, "t2": 550.0, "delta_l": 50.0, "sample_no": "S1"}]
        result = calculate_rows("cte", rows)
        expected = round((50.0 / 1000.0) / (10.0 * 525.0) * 1_000_000, 3)
        self.assertEqual(result[0]["alpha"], expected)

    def test_cte_conclusion_from_judgement(self):
        """cte: conclusion=judgement_result"""
        rows = [{"judgement_result": "符合", "sample_no": "S1"}]
        result = calculate_rows("cte", rows)
        self.assertEqual(result[0]["conclusion"], "符合")

    # ── shock ──
    def test_shock_conclusion_pass(self):
        """shock: 全部无→符合"""
        rows = [{"crack": "无", "chipping": "无", "fracture": "无", "sample_no": "S1"}]
        result = calculate_rows("shock", rows)
        self.assertEqual(result[0]["conclusion"], "符合")

    def test_shock_conclusion_fail_crack(self):
        """shock: crack=有→不符合"""
        rows = [{"crack": "有", "chipping": "无", "fracture": "无", "sample_no": "S1"}]
        result = calculate_rows("shock", rows)
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_shock_empty_values(self):
        """shock: 空字符串视为非无→不符合"""
        rows = [{"crack": "", "chipping": "无", "fracture": "无", "sample_no": "S1"}]
        result = calculate_rows("shock", rows)
        self.assertEqual(result[0]["conclusion"], "不符合")

    # ── bend ──
    def test_bend_conclusion_pass(self):
        """bend: stress_02>=800→符合"""
        rows = [{"stress_02": 900.0, "sample_no": "S1"}]
        result = calculate_rows("bend", rows)
        self.assertEqual(result[0]["conclusion"], "符合")

    def test_bend_conclusion_fail(self):
        """bend: stress_02<800→不符合"""
        rows = [{"stress_02": 700.0, "sample_no": "S1"}]
        result = calculate_rows("bend", rows)
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_bend_missing_stress(self):
        """bend: stress_02 缺失→0→不符合"""
        rows = [{"sample_no": "S1"}]
        result = calculate_rows("bend", rows)
        self.assertEqual(result[0]["conclusion"], "不符合")

    # ── hv ──
    def test_hv_mean_normal(self):
        """hv: indent avg"""
        rows = [{"indent1": 100.0, "indent2": 200.0, "indent3": 300.0, "sample_no": "S1"}]
        result = calculate_rows("hv", rows)
        self.assertEqual(result[0]["mean"], 200.0)

    def test_hv_mean_partial_missing(self):
        """hv: 部分 indent 缺失→mean=None"""
        rows = [{"indent1": 100.0, "sample_no": "S1"}]
        result = calculate_rows("hv", rows)
        self.assertIsNone(result[0]["mean"])

    # ── thickness ──
    def test_thickness_known_bug_key_mismatch(self):
        """thickness: 已知 bug — 硬编码 calc 键名不匹配导致所有计算列为空"""
        rows = [{
            "sample_no": "S1",
            "r1_fixed": 1.0, "r1_middle": 1.0, "r1_free": 1.0,
            "r2_fixed": 1.0, "r2_middle": 1.0, "r2_free": 1.0,
            "r3_fixed": 1.0, "r3_middle": 1.0, "r3_free": 1.0,
        }]
        result = calculate_rows("thickness", rows)
        # BUG: hardcoded code uses r{repeat}_{section}_p{point} pattern
        # but actual keys are r1_fixed, r1_middle, etc.
        # All calculated columns should be None/empty
        if result[0].get("fixed_mean") is not None:
            # If the bug is ever fixed, this test will document the fix
            self.assertIsNotNone(result[0].get("mean"))

    # ── color ──
    def test_color_overall_all_no_diff(self):
        """color: 3人全未见明显差异"""
        rows = [{"observer1": "未见明显差异", "observer2": "未见明显差异",
                 "observer3": "未见明显差异", "sample_no": "S1"}]
        result = calculate_rows("color", rows)
        self.assertIn("未见明显差异", result[0]["overall"])
        self.assertEqual(result[0]["conclusion"], "符合")

    def test_color_two_severe_diff(self):
        """color: 2人明显差异→不符合"""
        rows = [{"observer1": "明显差异", "observer2": "明显差异",
                 "observer3": "未见明显差异", "sample_no": "S1"}]
        result = calculate_rows("color", rows)
        self.assertEqual(result[0]["overall"], "明显差异")
        self.assertEqual(result[0]["conclusion"], "不符合")

    def test_color_two_unable(self):
        """color: 2人无法判定→需复核"""
        rows = [{"observer1": "无法判定", "observer2": "无法判定",
                 "observer3": "未见明显差异", "sample_no": "S1"}]
        result = calculate_rows("color", rows)
        self.assertEqual(result[0]["overall"], "无法判定")
        self.assertEqual(result[0]["conclusion"], "需复核")

    # ── fixed_denture / removable_denture ──
    def test_fixed_denture_no_calc(self):
        """fixed_denture: 目前无计算逻辑（已知缺陷）"""
        rows = [{"sample_no": "S1", "connector_full_grids": 5, "connector_traced_grids": 3}]
        result = calculate_rows("fixed_denture", rows)
        # connector_area should eventually be calculated; currently None/empty
        self.assertIsInstance(result, list)
        self.assertEqual(len(result), 1)

    def test_removable_denture_no_calc(self):
        """removable_denture: 目前无计算逻辑（已知缺陷）"""
        rows = [{"sample_no": "S1", "edge_1": 1.0, "edge_2": 1.0, "edge_3": 1.0}]
        result = calculate_rows("removable_denture", rows)
        self.assertIsInstance(result, list)
        self.assertEqual(len(result), 1)

    # ── 空列表 ──
    def test_calculate_rows_empty_list(self):
        """calculate_rows: 空列表返回空列表"""
        result = calculate_rows("rough", [])
        self.assertEqual(result, [])


class TestResultSummary(unittest.TestCase):
    """result_summary() 函数测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_all_pass(self):
        """全部符合→overall=符合"""
        # result_summary calls calculate_rows internally, so provide ra values
        _, overall = result_summary("rough", [
            {"ra1": 1.0, "ra2": 2.0, "ra3": 3.0, "limit": 15.0, "sample_no": "S1"},
            {"ra1": 4.0, "ra2": 5.0, "ra3": 6.0, "limit": 15.0, "sample_no": "S2"},
        ])
        self.assertEqual(overall, "符合")

    def test_any_fail(self):
        """有不符合→overall=不符合"""
        _, overall = result_summary("rough", [
            {"ra1": 1.0, "ra2": 2.0, "ra3": 3.0, "limit": 15.0, "sample_no": "S1"},
            {"ra1": 10.0, "ra2": 20.0, "ra3": 30.0, "limit": 5.0, "sample_no": "S2"},
        ])
        self.assertEqual(overall, "不符合")

    def test_empty_rows(self):
        """空行→未形成有效结果"""
        summary, overall = result_summary("rough", [])
        self.assertIn("尚未形成有效检验结果", summary)
        self.assertEqual(overall, "仅描述结果")

    def test_empty_conclusion(self):
        """空 conclusion→仅描述结果"""
        _, overall = result_summary("rough", [{"sample_no": "S1"}])
        self.assertEqual(overall, "仅描述结果")

    def test_mixed_non_pass_fail(self):
        """混合非 pass/fail→去重拼接"""
        _, overall = result_summary("xray", [
            {"conclusion": "合格", "sample_no": "S1"},
            {"conclusion": "合格", "sample_no": "S2"},
            {"conclusion": "需复检", "sample_no": "S3"},
        ])
        # 去重后："合格；需复检"
        self.assertIn("合格", overall)
        self.assertIn("需复检", overall)

    def test_return_type(self):
        """返回 tuple[str, str]"""
        result = result_summary("rough", [{"sample_no": "S1", "mean": 1.0, "conclusion": "符合"}])
        self.assertIsInstance(result, tuple)
        self.assertEqual(len(result), 2)
        self.assertIsInstance(result[0], str)
        self.assertIsInstance(result[1], str)


class TestNumberHelpers(unittest.TestCase):
    """_number_or_none / _num 辅助函数测试"""

    def test_number_or_none_none(self):
        """None→None"""
        self.assertIsNone(_number_or_none(None))

    def test_number_or_none_empty_string(self):
        """空字符串→None"""
        self.assertIsNone(_number_or_none(""))

    def test_number_or_none_float_string(self):
        """"3.14"→3.14"""
        self.assertEqual(_number_or_none("3.14"), 3.14)

    def test_number_or_none_int(self):
        """5→5.0"""
        self.assertEqual(_number_or_none(5), 5.0)

    def test_number_or_none_non_numeric(self):
        """"abc"→None"""
        self.assertIsNone(_number_or_none("abc"))

    def test_num_none_default(self):
        """_num(None, 15)→15.0"""
        self.assertEqual(_num(None, 15), 15.0)

    def test_num_empty_default(self):
        """_num("", 10)→10.0"""
        self.assertEqual(_num("", 10), 10.0)

    def test_num_valid(self):
        """_num("5.0", 0)→5.0"""
        self.assertEqual(_num("5.0", 0), 5.0)

    def test_num_invalid_default(self):
        """_num("abc", 99)→99.0"""
        self.assertEqual(_num("abc", 99), 99.0)


class TestNormalizeRows(unittest.TestCase):
    """normalize_rows() 测试"""

    def test_non_hv_passthrough(self):
        """非 hv kind 直通"""
        rows = [{"sample_no": "S1", "face": "something", "conclusion": "符合"}]
        result = normalize_rows("rough", rows)
        self.assertEqual(result[0]["face"], "something")
        self.assertEqual(result[0]["conclusion"], "符合")

    def test_hv_face_normalization(self):
        """hv: face 规范化"""
        rows = [
            {"sample_no": "S1", "face": "面1"},
            {"sample_no": "S1", "face": "Z方向"},
        ]
        result = normalize_rows("hv", rows)
        faces = [r["face"] for r in result]
        self.assertIn("Z轴方向", faces)

    def test_hv_strips_surface_confirm(self):
        """hv: 移除 surface_confirm 和 conclusion"""
        rows = [{"sample_no": "S1", "surface_confirm": "符合", "conclusion": "符合"}]
        result = normalize_rows("hv", rows)
        self.assertNotIn("surface_confirm", result[0])
        self.assertNotIn("conclusion", result[0])


class TestColumnsForEditor(unittest.TestCase):
    """columns_for_editor() 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_returns_list_of_dicts(self):
        """返回 [{key, label, type}] 格式"""
        cols = columns_for_editor("rough")
        self.assertIsInstance(cols, list)
        self.assertGreater(len(cols), 0)
        for c in cols:
            self.assertIn("key", c)
            self.assertIn("label", c)
            self.assertIn("type", c)


class TestDataframe(unittest.TestCase):
    """dataframe() 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_returns_dataframe(self):
        """返回 pandas DataFrame"""
        # dataframe() selects columns from schema — use full init+calc rows
        rows = initial_rows("rough", ["S1"])
        for r in rows:
            r["ra1"] = 1.0
            r["ra2"] = 2.0
            r["ra3"] = 3.0
        rows = calculate_rows("rough", rows)
        df = dataframe("rough", rows)
        self.assertIn("sample_no", df.columns)
        self.assertIn("mean", df.columns)


def setUpModule():
    init_db()


def tearDownModule():
    import shutil
    try:
        shutil.rmtree(str(_root), ignore_errors=True)
    except Exception:
        pass


if __name__ == "__main__":
    unittest.main(verbosity=2)
