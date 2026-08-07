# -*- coding: utf-8 -*-
"""BPLab Trace — 数据库操作测试：备份、恢复、健康检查、并发"""
from __future__ import annotations

import os, tempfile, unittest, threading
from pathlib import Path

_root = Path(tempfile.mkdtemp(prefix="bplab_db_test_"))
_db = _root / "test_db.db"
os.environ["BPLAB_DB_PATH"] = str(_db)
os.environ["BPLAB_ATTACHMENT_DIR"] = str(_root / "att")
os.environ["BPLAB_SIGNATURE_DIR"] = str(_root / "sig")
os.environ["BPLAB_DEMO_MODE"] = "true"

import lims_db
lims_db.DB_PATH = _db
lims_db.ATTACHMENT_DIR = _root / "att"
lims_db.SIGNATURE_DIR = _root / "sig"

from lims_db import (
    init_db, connect, rows, one, now, china_now,
    db_health_check, db_maintenance,
    backup_database, restore_database, list_backups,
    export_table_csv, reset_business_history,
    authenticate, create_session, session_user,
)


class TestDatabaseHealthCheck(unittest.TestCase):
    """数据库健康检查测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_health_check_returns_expected_keys(self):
        """健康检查返回所有预期键"""
        h = db_health_check()
        expected = [
            "db_path", "db_size_bytes", "db_size_mb", "wal_size_bytes",
            "wal_size_mb", "table_count", "total_rows", "table_rows",
            "integrity_check", "integrity_ok", "foreign_key_ok", "fk_violations",
        ]
        for key in expected:
            self.assertIn(key, h, f"Missing key: {key}")

    def test_integrity_check_passes(self):
        """完整性检查通过"""
        h = db_health_check()
        self.assertTrue(h["integrity_ok"], f"Integrity: {h['integrity_check']}")

    def test_foreign_keys_ok(self):
        """外键检查通过"""
        h = db_health_check()
        self.assertTrue(h["foreign_key_ok"], f"FK violations: {h['fk_violations']}")

    def test_table_count_reasonable(self):
        """表数量合理（>15）"""
        h = db_health_check()
        self.assertGreater(h["table_count"], 15)

    def test_db_size_positive(self):
        """数据库大小 > 0"""
        h = db_health_check()
        self.assertGreater(h["db_size_bytes"], 0)


class TestDatabaseMaintenance(unittest.TestCase):
    """数据库维护操作测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_optimize_returns_success(self):
        """PRAGMA optimize执行成功"""
        r = db_maintenance("optimize")
        self.assertEqual(r.get("optimize"), "done")

    def test_checkpoint_returns_success(self):
        """WAL checkpoint执行成功"""
        r = db_maintenance("checkpoint")
        self.assertEqual(r.get("checkpoint"), "done")

    def test_vacuum_returns_success(self):
        """VACUUM执行成功"""
        r = db_maintenance("vacuum")
        self.assertEqual(r.get("vacuum"), "done")

    def test_all_maintenance(self):
        """执行所有维护操作"""
        r = db_maintenance("all")
        for key in ("optimize", "checkpoint", "vacuum"):
            self.assertEqual(r.get(key), "done")


class TestDatabaseBackupRestore(unittest.TestCase):
    """数据库备份恢复测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_backup_creates_file(self):
        """备份创建有效文件"""
        target = str(_root / "test_backup.db")
        info = backup_database(target)
        self.assertTrue(Path(target).exists())
        self.assertGreater(info["size_bytes"], 0)

    def test_backup_auto_naming(self):
        """自动命名备份文件"""
        info = backup_database()
        self.assertIn("bplab_trace_backup_", info["target_path"])

    def test_list_backups(self):
        """列出备份文件"""
        backup_database(str(_root / "backup_list_test.db"))
        backups = list_backups()
        self.assertGreater(len(backups), 0)

    def test_restore_from_backup(self):
        """从备份恢复数据库"""
        # Create backup
        target = str(_root / "restore_test_backup.db")
        backup_database(target)
        self.assertTrue(Path(target).exists())

        # Restore from backup
        restore_database(target, "admin")
        h = db_health_check()
        self.assertTrue(h["integrity_ok"])

    def test_restore_invalid_file_raises(self):
        """无效备份文件抛出异常"""
        invalid = _root / "invalid.db"
        invalid.write_text("not a database")
        with self.assertRaises(ValueError):
            restore_database(str(invalid), "admin")


class TestDatabaseExport(unittest.TestCase):
    """数据导出测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_export_users_csv(self):
        """导出用户表为CSV"""
        data = export_table_csv("users")
        self.assertIsInstance(data, bytes)
        # CSV with BOM — check content after BOM
        self.assertIn(b"username", data)
        # Should contain admin user
        self.assertIn(b"admin", data)

    def test_export_empty_returns_empty(self):
        """导出不存在表（不含数据）"""
        # audit_logs might be empty in a fresh DB
        data = export_table_csv("audit_logs")
        self.assertIsInstance(data, bytes)


class TestConcurrentAccess(unittest.TestCase):
    """并发访问测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_concurrent_reads(self):
        """多个线程同时读取"""
        errors = []
        def read_db():
            try:
                for _ in range(10):
                    r = one("SELECT COUNT(*) AS n FROM users")
                    if r is None:
                        errors.append("None result")
            except Exception as e:
                errors.append(str(e))

        threads = [threading.Thread(target=read_db) for _ in range(5)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        self.assertEqual(len(errors), 0, f"Concurrent read errors: {errors}")

    def test_concurrent_writes(self):
        """多个线程并发写入login_attempts"""
        errors = []
        def write_db(i):
            try:
                with connect() as c:
                    c.execute(
                        "INSERT INTO login_attempts(username,attempt_at,source_ip,success) VALUES(?,?,?,?)",
                        (f"thread_test_{i}", now(), "test", 0),
                    )
            except Exception as e:
                errors.append(f"Thread {i}: {e}")

        threads = [threading.Thread(target=write_db, args=(i,)) for i in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        self.assertEqual(len(errors), 0, f"Concurrent write errors: {errors}")

        # Clean up
        with connect() as c:
            c.execute("DELETE FROM login_attempts WHERE username LIKE 'thread_test_%'")


class TestResetBusinessHistory(unittest.TestCase):
    """系统初始化测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_reset_requires_admin_role(self):
        """非管理员无法初始化"""
        with self.assertRaises(ValueError):
            reset_business_history("tester")

    def test_reset_returns_counts(self):
        """初始化返回删除计数"""
        result = reset_business_history("admin")
        self.assertIsInstance(result, dict)
        self.assertIn("commissions", result)


def setUpModule():
    _root.mkdir(parents=True, exist_ok=True)
    (_root / "att").mkdir(parents=True, exist_ok=True)
    (_root / "sig").mkdir(parents=True, exist_ok=True)
    init_db()


def tearDownModule():
    import shutil
    try:
        shutil.rmtree(str(_root), ignore_errors=True)
    except Exception:
        pass


if __name__ == "__main__":
    unittest.main(verbosity=2)
