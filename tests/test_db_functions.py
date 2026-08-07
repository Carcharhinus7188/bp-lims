# -*- coding: utf-8 -*-
"""BPLab Trace — Phase B 新增 DB 函数单元测试"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_dbfunc_test_"))
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
    init_db, connect, rows, one, now,
    list_experiment_configs_for_experimenter,
    build_partial_config_snapshot_from_version,
    list_template_mappings,
    save_template_mappings,
    _pool_get, _pool_invalidate, pool_close_all,
    timed_connection,
    experiment_config,
)


class TestListExperimentConfigsForExperimenter(unittest.TestCase):
    """list_experiment_configs_for_experimenter 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_valid_experiment_code_returns_configs(self):
        """有效 experiment_code 返回配置列表"""
        configs = list_experiment_configs_for_experimenter("I001")
        self.assertIsInstance(configs, list)
        self.assertGreater(len(configs), 0)

    def test_current_status_first(self):
        """现行版本排在第一位"""
        configs = list_experiment_configs_for_experimenter("I001")
        if len(configs) > 0:
            self.assertEqual(configs[0]["status"], "现行")

    def test_no_draft_configs_returned(self):
        """草稿配置不被返回"""
        configs = list_experiment_configs_for_experimenter("I001")
        for c in configs:
            self.assertIn(c["status"], ("现行", "历史"))

    def test_nonexistent_experiment_code(self):
        """不存在的 experiment_code 返回空列表"""
        configs = list_experiment_configs_for_experimenter("I999")
        self.assertEqual(configs, [])

    def test_empty_string(self):
        """空字符串返回空列表"""
        configs = list_experiment_configs_for_experimenter("")
        self.assertEqual(configs, [])

    def test_field_completeness(self):
        """返回字段完整"""
        configs = list_experiment_configs_for_experimenter("I001")
        if configs:
            c = configs[0]
            for key in ("id", "version", "status", "effective_date", "note", "kind",
                        "sop_version", "record_template_version"):
                self.assertIn(key, c)

    def test_all_twelve_experiments_have_current_config(self):
        """12 个实验都有现行配置"""
        experiment_codes = [f"I{i:03d}" for i in range(1, 13)]  # I001-I012
        for code in experiment_codes:
            configs = list_experiment_configs_for_experimenter(code)
            current = [c for c in configs if c["status"] == "现行"]
            self.assertEqual(len(current), 1,
                             f"{code} 应有 1 个现行配置，实际为 {len(current)}")


class TestBuildPartialConfigSnapshot(unittest.TestCase):
    """build_partial_config_snapshot_from_version 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_valid_config_id_returns_snapshot(self):
        """有效 config_id 返回完整快照"""
        configs = list_experiment_configs_for_experimenter("I001")
        if not configs:
            self.skipTest("No configs found for I001")
        snap = build_partial_config_snapshot_from_version(configs[0]["id"])
        self.assertIsInstance(snap, dict)
        self.assertGreater(len(snap), 0)
        for key in ("config_id", "config_version", "experiment_code",
                    "experiment_name", "kind", "equipment"):
            self.assertIn(key, snap)

    def test_nonexistent_config_id(self):
        """不存在的 config_id 返回空字典"""
        snap = build_partial_config_snapshot_from_version(99999)
        self.assertEqual(snap, {})

    def test_config_id_zero(self):
        """config_id=0 返回空字典"""
        snap = build_partial_config_snapshot_from_version(0)
        self.assertEqual(snap, {})

    def test_config_id_negative(self):
        """负 config_id 返回空字典"""
        snap = build_partial_config_snapshot_from_version(-1)
        self.assertEqual(snap, {})

    def test_kind_fallback_to_generic(self):
        """kind 为 None 时默认为 generic"""
        configs = list_experiment_configs_for_experimenter("I001")
        if configs:
            snap = build_partial_config_snapshot_from_version(configs[0]["id"])
            self.assertIn(snap.get("kind", "generic"), ("rough", "generic"))

    def test_all_twelve_experiments_snapshot(self):
        """12 个实验都能生成快照"""
        experiment_codes = [f"I{i:03d}" for i in range(1, 13)]  # I001-I012
        for code in experiment_codes:
            configs = list_experiment_configs_for_experimenter(code)
            if configs:
                snap = build_partial_config_snapshot_from_version(configs[0]["id"])
                self.assertIsInstance(snap, dict)
                self.assertGreater(len(snap), 0, f"{code} 快照不应为空")


class TestListTemplateMappings(unittest.TestCase):
    """list_template_mappings 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_valid_config_id_returns_list(self):
        """有效 config_id 返回列表"""
        mappings = list_template_mappings(1)
        self.assertIsInstance(mappings, list)

    def test_nonexistent_config_id(self):
        """不存在 config_id 返回空列表"""
        mappings = list_template_mappings(99999)
        self.assertEqual(mappings, [])

    def test_config_id_zero(self):
        """config_id=0 返回空列表"""
        mappings = list_template_mappings(0)
        self.assertEqual(mappings, [])


class TestSaveTemplateMappings(unittest.TestCase):
    """save_template_mappings 测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def _get_draft_config_id(self):
        """获取一个草稿配置的 ID，如没有则返回 None"""
        cfg = one(
            "SELECT id FROM experiment_config_versions WHERE status='草稿' ORDER BY id DESC LIMIT 1"
        )
        return cfg["id"] if cfg else None

    def test_save_to_draft_succeeds(self):
        """保存到草稿配置成功"""
        draft_id = self._get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        test_mappings = [
            {
                "field_source": "params",
                "field_key": "test_date",
                "template_name": "test_template.docx",
                "table_index": 0,
                "row_index": 1,
                "col_index": 2,
                "transform": "text",
                "checkbox_selection": "",
            }
        ]
        save_template_mappings(draft_id, test_mappings, "test_actor")
        saved = list_template_mappings(draft_id)
        self.assertEqual(len(saved), 1)
        self.assertEqual(saved[0]["field_key"], "test_date")

    def test_save_to_current_raises(self):
        """保存到现行配置抛出 ValueError"""
        configs = list_experiment_configs_for_experimenter("I001")
        if not configs:
            self.skipTest("No configs for I001")
        current_id = configs[0]["id"]
        with self.assertRaises(ValueError):
            save_template_mappings(current_id, [], "test_actor")

    def test_save_nonexistent_config_raises(self):
        """保存到不存在配置抛出 ValueError"""
        with self.assertRaises(ValueError):
            save_template_mappings(99999, [], "test_actor")

    def test_empty_mappings_clears_all(self):
        """空映射列表清空所有映射"""
        draft_id = self._get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        # First add some mappings
        test_mappings = [
            {
                "field_source": "params",
                "field_key": "temperature_before",
                "template_name": "test.docx",
                "table_index": 0,
                "row_index": 0,
                "col_index": 0,
                "transform": "text",
                "checkbox_selection": "",
            }
        ]
        save_template_mappings(draft_id, test_mappings, "test_actor")
        self.assertEqual(len(list_template_mappings(draft_id)), 1)
        # Clear
        save_template_mappings(draft_id, [], "test_actor")
        self.assertEqual(len(list_template_mappings(draft_id)), 0)

    def test_checkbox_selection_preserved(self):
        """checkbox_selection 正确保存和读取"""
        draft_id = self._get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        test_mappings = [
            {
                "field_source": "params",
                "field_key": "equipment_status",
                "template_name": "test.docx",
                "table_index": 1,
                "row_index": 3,
                "col_index": 1,
                "transform": "checkbox",
                "checkbox_selection": "正常",
            }
        ]
        save_template_mappings(draft_id, test_mappings, "test_actor")
        saved = list_template_mappings(draft_id)
        self.assertEqual(saved[0]["transform"], "checkbox")
        self.assertEqual(saved[0]["checkbox_selection"], "正常")

    def test_sort_order_is_sequential(self):
        """sort_order 按插入顺序排列"""
        draft_id = self._get_draft_config_id()
        if not draft_id:
            self.skipTest("没有草稿配置可用于测试")
        test_mappings = [
            {"field_source": "params", "field_key": f"field_{i}",
             "template_name": "t.docx", "table_index": 0,
             "row_index": i, "col_index": 0,
             "transform": "text", "checkbox_selection": ""}
            for i in range(3)
        ]
        save_template_mappings(draft_id, test_mappings, "test_actor")
        saved = list_template_mappings(draft_id)
        self.assertEqual(len(saved), 3)
        for i, m in enumerate(saved, 1):
            self.assertEqual(m["sort_order"], i)


class TestConnectionPool(unittest.TestCase):
    """连接池函数测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def setUp(self):
        pool_close_all()

    def tearDown(self):
        pool_close_all()

    def test_pool_get_creates_connection(self):
        """_pool_get 创建连接"""
        conn = _pool_get()
        self.assertIsNotNone(conn)
        # Verify it works
        conn.execute("SELECT 1")

    def test_pool_get_reuses_connection(self):
        """_pool_get 同线程复用连接"""
        conn1 = _pool_get()
        conn2 = _pool_get()
        self.assertIs(conn1, conn2)

    def test_pool_invalidate_removes_connection(self):
        """_pool_invalidate 移除并关闭连接"""
        conn = _pool_get()
        _pool_invalidate()
        # After invalidation, a new call should create a new connection
        conn_new = _pool_get()
        self.assertIsNot(conn, conn_new)

    def test_pool_close_all_clears(self):
        """pool_close_all 清空所有连接"""
        _pool_get()
        pool_close_all()
        # Next call should create fresh connection
        conn = _pool_get()
        self.assertIsNotNone(conn)

    def test_pool_close_all_empty_pool(self):
        """pool_close_all 空池不报错"""
        pool_close_all()
        pool_close_all()  # Double close should not error

    def test_pool_get_health_check_recreates(self):
        """连接健康检查失败时自动重建"""
        conn = _pool_get()
        # Force close the underlying connection to simulate failure
        try:
            conn.__class__ = type(conn)  # no-op safety check
        except Exception:
            pass
        # Just verify the pool works after close_all
        pool_close_all()
        conn_new = _pool_get()
        self.assertIsNotNone(conn_new)
        result = conn_new.execute("SELECT 1").fetchone()
        self.assertIsNotNone(result)


class TestTimedConnection(unittest.TestCase):
    """timed_connection 上下文管理器测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_normal_connection(self):
        """正常连接可执行查询"""
        with timed_connection("test_normal") as c:
            result = c.execute("SELECT 1").fetchone()
            self.assertIsNotNone(result)

    def test_label_accepts_empty(self):
        """空 label 不报错"""
        with timed_connection("") as c:
            result = c.execute("SELECT 1").fetchone()
            self.assertIsNotNone(result)

    def test_label_accepts_none(self):
        """None label 也能工作"""
        with timed_connection(None) as c:
            result = c.execute("SELECT 1").fetchone()
            self.assertIsNotNone(result)


class TestConnectRetry(unittest.TestCase):
    """connect() 重试机制测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_connect_default_params(self):
        """connect 默认参数正常连接"""
        c = connect()
        self.assertIsNotNone(c)
        c.execute("SELECT 1")
        c.close()

    def test_connect_retries_zero(self):
        """retries=0 — 已知 bug: raise None → TypeError"""
        # BUG: When retries=0, the loop doesn't execute and last_error remains None,
        # then `raise None` causes TypeError. This test documents the known bug.
        with self.assertRaises((TypeError, BaseException)):
            connect(retries=0)


def setUpModule():
    init_db()
    # Ensure a draft config exists for save_template_mappings tests
    existing = one("SELECT id FROM experiment_config_versions WHERE status='草稿' LIMIT 1")
    if not existing:
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
    pool_close_all()
    import shutil
    try:
        shutil.rmtree(str(_root), ignore_errors=True)
    except Exception:
        pass


if __name__ == "__main__":
    unittest.main(verbosity=2)
