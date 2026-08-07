# -*- coding: utf-8 -*-
"""BPLab Trace — DB 驱动模板字段映射测试"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_tmpl_test_"))
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
    init_db, connect, one, rows as db_rows, now,
    list_template_mappings, save_template_mappings,
    list_experiment_configs_for_experimenter,
)


def _get_draft_config_id():
    """获取一个草稿配置的 ID"""
    cfg = one(
        "SELECT id FROM experiment_config_versions WHERE status='草稿' ORDER BY id DESC LIMIT 1"
    )
    return cfg["id"] if cfg else None


def _create_test_mapping(**overrides):
    """创建标准测试映射"""
    base = {
        "field_source": "params",
        "field_key": "test_date",
        "template_name": "test_template.docx",
        "table_index": 0,
        "row_index": 0,
        "col_index": 0,
        "transform": "text",
        "checkbox_selection": "",
    }
    base.update(overrides)
    return base


class TestFieldSourceVariants(unittest.TestCase):
    """不同 field_source 类型测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _with_draft(self):
        draft_id = _get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        return draft_id

    def test_field_source_params(self):
        """field_source='params'"""
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(field_source="params", field_key="test_date")]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["field_source"], "params")
        self.assertEqual(saved[0]["field_key"], "test_date")

    def test_field_source_rows(self):
        """field_source='rows'"""
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(field_source="rows", field_key="ra1",
                                         row_index=0)]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["field_source"], "rows")
        self.assertEqual(saved[0]["field_key"], "ra1")

    def test_field_source_context(self):
        """field_source='context'"""
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(field_source="context", field_key="report_date")]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["field_source"], "context")


class TestTransformVariants(unittest.TestCase):
    """不同 transform 类型测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _with_draft(self):
        draft_id = _get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        return draft_id

    def test_transform_text(self):
        """transform='text'"""
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(transform="text")]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["transform"], "text")

    def test_transform_checkbox(self):
        """transform='checkbox'"""
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(transform="checkbox",
                                         checkbox_selection="符合")]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["transform"], "checkbox")
        self.assertEqual(saved[0]["checkbox_selection"], "符合")

    def test_transform_image(self):
        """transform='image'"""
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(transform="image",
                                         field_key="photo_1")]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["transform"], "image")


class TestMappingPositionVariants(unittest.TestCase):
    """不同位置参数测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _with_draft(self):
        draft_id = _get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        return draft_id

    def test_table_0(self):
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(table_index=0, row_index=0, col_index=0)]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["table_index"], 0)

    def test_table_5_row_10_col_3(self):
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(table_index=5, row_index=10, col_index=3)]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["table_index"], 5)
        self.assertEqual(saved[0]["row_index"], 10)
        self.assertEqual(saved[0]["col_index"], 3)

    def test_large_indices(self):
        draft_id = self._with_draft()
        mappings = [_create_test_mapping(table_index=99, row_index=99, col_index=99)]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["table_index"], 99)


class TestMultipleMappings(unittest.TestCase):
    """多条映射测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _with_draft(self):
        draft_id = _get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        return draft_id

    def test_bulk_save_50_mappings(self):
        """批量保存 50 条映射"""
        draft_id = self._with_draft()
        mappings = [
            _create_test_mapping(
                field_key=f"field_{i}",
                row_index=i,
                col_index=i % 5,
            )
            for i in range(50)
        ]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        self.assertEqual(len(saved), 50)
        # Verify sort_order is sequential
        for i, m in enumerate(saved, 1):
            self.assertEqual(m["sort_order"], i)

    def test_different_templates(self):
        """不同模板的映射"""
        draft_id = self._with_draft()
        mappings = [
            _create_test_mapping(template_name="template_a.docx", field_key="a1"),
            _create_test_mapping(template_name="template_b.docx", field_key="b1"),
            _create_test_mapping(template_name="template_a.docx", field_key="a2"),
        ]
        save_template_mappings(draft_id, mappings, "tester")
        saved = list_template_mappings(draft_id)
        templates = {m["template_name"] for m in saved}
        self.assertEqual(templates, {"template_a.docx", "template_b.docx"})


class TestMappingErrorCases(unittest.TestCase):
    """映射错误边界"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_save_to_nonexistent_raises(self):
        """保存到不存在配置抛出 ValueError"""
        with self.assertRaises(ValueError):
            save_template_mappings(99999, [], "tester")

    def test_save_to_zero_raises(self):
        """config_id=0 抛出 ValueError"""
        with self.assertRaises(ValueError):
            save_template_mappings(0, [], "tester")

    def test_empty_actor_still_works(self):
        """空 actor 也保存"""
        draft_id = _get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        mappings = [_create_test_mapping(field_key="empty_actor_test")]
        save_template_mappings(draft_id, mappings, "")
        saved = list_template_mappings(draft_id)
        self.assertEqual(len(saved), 1)


class TestMappingRoundTrip(unittest.TestCase):
    """映射往返测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _with_draft(self):
        draft_id = _get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        return draft_id

    def test_full_round_trip(self):
        """完整往返：保存→读取→验证"""
        draft_id = self._with_draft()
        mappings = [
            _create_test_mapping(field_source="params", field_key="temperature_before",
                                 template_name="r.docx", table_index=0, row_index=1,
                                 col_index=2, transform="text"),
            _create_test_mapping(field_source="rows", field_key="ra1",
                                 template_name="r.docx", table_index=1, row_index=0,
                                 col_index=3, transform="text"),
            _create_test_mapping(field_source="context", field_key="report_date",
                                 template_name="r.docx", table_index=0, row_index=0,
                                 col_index=0, transform="text"),
        ]
        save_template_mappings(draft_id, mappings, "round_trip_tester")

        saved = list_template_mappings(draft_id)
        self.assertEqual(len(saved), 3)
        self.assertEqual(saved[0]["field_source"], "params")
        self.assertEqual(saved[1]["field_source"], "rows")
        self.assertEqual(saved[2]["field_source"], "context")


def setUpModule():
    init_db()
    # Ensure a draft config exists for tests
    from lims_db import one, now
    existing = one("SELECT id FROM experiment_config_versions WHERE status='草稿' LIMIT 1")
    if not existing:
        # Clone the first current config as a draft
        src = one("SELECT * FROM experiment_config_versions WHERE status='现行' ORDER BY id LIMIT 1")
        if src:
            with connect() as c:
                cols = [col[1] for col in c.execute("PRAGMA table_info(experiment_config_versions)").fetchall()
                        if col[1] != 'id']
                vals = {k: src[k] for k in cols}
                vals['status'] = '草稿'
                # Version is like "V1.0" — bump minor
                import re as _re
                _m = _re.match(r'V(\d+)\.(\d+)', src['version'])
                _major, _minor = int(_m.group(1)), int(_m.group(2)) if _m else (1, 0)
                vals['version'] = f'V{_major}.{_minor + 1}'
                vals['created_by'] = 'test_setup'
                vals['created_at'] = now()
                vals['effective_date'] = None
                vals['approved_by'] = None
                vals['approved_at'] = None
                placeholders = ','.join(['?'] * len(vals))
                c.execute(
                    f"INSERT INTO experiment_config_versions({','.join(vals.keys())}) VALUES({placeholders})",
                    list(vals.values()),
                )


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
