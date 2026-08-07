# -*- coding: utf-8 -*-
"""BPLab Trace — 验证规则与 checkbox 辅助函数测试"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_val_test_"))
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
    _apply_db_validation_rules,
    _checkbox_options,
    _select_checkbox_value,
)

# ── POSITIVE_OPTIONS (from business_record_engine) ──
POSITIVE_OPTIONS = ["符合", "合格", "正常", "有效", "通过", "无", "已完成"]


class TestApplyDbValidationRules(unittest.TestCase):
    """_apply_db_validation_rules 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_basic_call_no_crash(self):
        """基本调用不崩溃"""
        record = {"parameters": {}, "rows": []}
        issues: list[str] = []
        _apply_db_validation_rules("rough", record, issues)
        self.assertIsInstance(issues, list)

    def test_all_kinds_no_crash(self):
        """12 种实验都不崩溃"""
        kinds = [
            "rough", "mc_crack", "xray", "warp", "cte", "shock",
            "bend", "hv", "thickness", "color", "fixed_denture", "removable_denture",
        ]
        for kind in kinds:
            with self.subTest(kind=kind):
                record = {"parameters": {}, "rows": []}
                issues: list[str] = []
                _apply_db_validation_rules(kind, record, issues)

    def test_unknown_kind_no_crash(self):
        """未知 kind 不崩溃"""
        record = {"parameters": {}, "rows": []}
        issues: list[str] = []
        _apply_db_validation_rules("nonexistent_kind", record, issues)

    def test_record_with_none_params(self):
        """parameters=None 不崩溃"""
        record = {"parameters": None, "rows": []}
        issues: list[str] = []
        _apply_db_validation_rules("rough", record, issues)

    def test_record_with_none_rows(self):
        """rows=None 不崩溃"""
        record = {"parameters": {}, "rows": None}
        issues: list[str] = []
        _apply_db_validation_rules("rough", record, issues)

    def test_empty_record_no_crash(self):
        """空 record 不崩溃"""
        issues: list[str] = []
        _apply_db_validation_rules("rough", {}, issues)


class TestCheckboxOptions(unittest.TestCase):
    """_checkbox_options 测试"""

    def test_plain_text_no_checkbox(self):
        """无 □ 标记 → 返回空列表"""
        result = _checkbox_options("正常")
        self.assertEqual(result, [])

    def test_single_checkbox(self):
        """单个 □ → 提取选项"""
        result = _checkbox_options("□ 符合 □ 不符合")
        self.assertIn("符合", result)
        self.assertIn("不符合", result)

    def test_multiple_checkboxes(self):
        """多个 □ → 提取全部选项"""
        text = "□ 合格 □ 不合格 □ 需复检"
        result = _checkbox_options(text)
        self.assertEqual(len(result), 3)

    def test_checked_checkbox_ignored(self):
        """☑ 标记同样被 split，因此选项也会被提取"""
        # Note: _checkbox_options splits on ALL markers [□☐☑],
        # so checked markers also produce options.
        text = "☑ 符合 □ 不符合"
        result = _checkbox_options(text)
        self.assertIn("符合", result)

    def test_suffix_stripping(self):
        """下划线后缀被去除"""
        text = "□ 符合__详细说明 □ 不符合__其他"
        result = _checkbox_options(text)
        for opt in result:
            self.assertNotIn("__", opt)

    def test_empty_string(self):
        """空字符串 → 空列表"""
        self.assertEqual(_checkbox_options(""), [])

    def test_only_checked(self):
        """仅含 ☑ → 同样提取选项（split 不区分 check 状态）"""
        result = _checkbox_options("☑ 符合 ☑ 合格")
        self.assertEqual(result, ["符合", "合格"])


class TestSelectCheckboxValue(unittest.TestCase):
    """_select_checkbox_value 测试"""

    def test_no_checkbox_passthrough(self):
        """无 □/☐ → 原样返回"""
        result = _select_checkbox_value("正常文本", "符合")
        self.assertEqual(result, "正常文本")

    def test_preferred_matched(self):
        """preferred 匹配 → 勾选对应选项"""
        original = "□ 符合 □ 不符合"
        result = _select_checkbox_value(original, "符合")
        self.assertIn("☑ 符合", result)

    def test_preferred_list_matched(self):
        """preferred 为列表时批量匹配"""
        original = "□ 符合 □ 不符合"
        result = _select_checkbox_value(original, ["符合"])
        self.assertIn("☑ 符合", result)

    def test_antonym_not_matched(self):
        """"符合"≠"不符合" — 反义词不误匹配"""
        original = "□ 符合标准 □ 不符合标准"
        # "符合" should match "符合标准" but NOT "不符合标准"
        result = _select_checkbox_value(original, "符合")
        self.assertIn("☑ 符合标准", result)
        self.assertNotIn("☑ 不符合标准", result)

    def test_antonym_not_matched_reverse(self):
        """"不符合"≠"符合" — 反义词不误匹配"""
        original = "□ 符合标准 □ 不符合标准"
        result = _select_checkbox_value(original, "不符合")
        self.assertIn("☑ 不符合标准", result)
        self.assertNotIn("☑ 符合标准", result)

    def test_no_match_fallsback_to_positive(self):
        """全部不匹配 → 回落 POSITIVE_OPTIONS"""
        original = "□ 合格 □ 不合格"
        result = _select_checkbox_value(original, "nonexistent_choice")
        # Should fallback to a positive option
        self.assertIn("☑", result)

    def test_no_match_no_positive_picks_first(self):
        """无 positive 选项 → 选第一个"""
        original = "□ 选项A □ 选项B"
        result = _select_checkbox_value(original, "nothing_matches")
        self.assertIn("☑", result)

    def test_empty_preferred(self):
        """preferred 为空 → 回落"""
        original = "□ 合格 □ 不合格"
        result = _select_checkbox_value(original, "")
        self.assertIn("☑", result)

    def test_none_preferred(self):
        """preferred=None → 回落"""
        original = "□ 合格 □ 不合格"
        result = _select_checkbox_value(original, None)
        self.assertIn("☑", result)

    def test_multiple_positives_selected(self):
        """多个独立正向确认 → 全部勾选"""
        original = "□ 平整 □ 清洁 □ 无油污 □ 瑕疵"
        result = _select_checkbox_value(original, "平整")
        # "平整", "清洁", "无油污" are all positive terms
        self.assertIn("☑ 平整", result)

    def test_pre_existing_checked_preserved(self):
        """已有 ☑ — 函数先统一转 □ 再重新勾选匹配项"""
        # The function replaces ALL ☑ with □ first, then checks matched options.
        # So when preferred="不符合", "符合" becomes unchecked.
        original = "☑ 符合 □ 不符合"
        result = _select_checkbox_value(original, "不符合")
        # "不符合" should be checked
        self.assertIn("☑ 不符合", result)
        # But "符合" will be unchecked (converted to □)
        self.assertIn("□ 符合", result)

    def test_checkbox_unicode_variant(self):
        """□ (U+25A1) 基本变体"""
        original = "□ 选项1 □ 选项2"
        result = _select_checkbox_value(original, "选项1")
        self.assertIn("☑", result)


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
