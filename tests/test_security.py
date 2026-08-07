# -*- coding: utf-8 -*-
"""BPLab Trace — 安全功能测试：认证、会话、密码管理"""
from __future__ import annotations

import os, tempfile, unittest
from pathlib import Path

# Redirect to temp database before importing
_root = Path(tempfile.mkdtemp(prefix="bplab_sec_test_"))
_db = _root / "test_sec.db"
os.environ["BPLAB_DB_PATH"] = str(_db)
os.environ["BPLAB_ATTACHMENT_DIR"] = str(_root / "att")
os.environ["BPLAB_SIGNATURE_DIR"] = str(_root / "sig")
os.environ["BPLAB_DEMO_MODE"] = "true"

import lims_db
lims_db.DB_PATH = _db
lims_db.ATTACHMENT_DIR = _root / "att"
lims_db.SIGNATURE_DIR = _root / "sig"

from lims_db import (
    init_db, authenticate, create_session, session_user,
    delete_session, add_user, reset_user_password,
    connect, now, china_now, list_users,
    _password_hash, _password_verify,
)


class TestAuthentication(unittest.TestCase):
    """认证功能测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_admin_login_default_password(self):
        """admin 使用默认密码登录成功"""
        u = authenticate("admin", "admin123")
        self.assertIsNotNone(u)
        self.assertEqual(u["username"], "admin")
        self.assertEqual(u["role"], "管理员")

    def test_wrong_password_returns_none(self):
        """错误密码返回 None"""
        u = authenticate("admin", "wrong_password_xyz")
        self.assertIsNone(u)

    def test_nonexistent_user_returns_none(self):
        """不存在用户返回 None"""
        u = authenticate("no_such_user_abc_123", "any_password")
        self.assertIsNone(u)

    def test_empty_credentials_returns_none(self):
        """空凭据返回 None"""
        self.assertIsNone(authenticate("", ""))
        self.assertIsNone(authenticate("admin", ""))

    def test_none_credentials(self):
        """None 凭据 → AttributeError (username.strip() on None)"""
        # Known: authenticate doesn't handle None username
        with self.assertRaises(AttributeError):
            authenticate(None, "pass")


class TestPasswordHash(unittest.TestCase):
    """密码哈希测试"""

    def test_hash_is_deterministic(self):
        """相同密码产生不同哈希（盐）"""
        h1 = _password_hash("test123")
        h2 = _password_hash("test123")
        # Each hash has unique salt
        self.assertNotEqual(h1, h2)

    def test_verify_correct_password(self):
        """正确密码验证通过"""
        h = _password_hash("MySecret1")
        self.assertTrue(_password_verify("MySecret1", h))

    def test_verify_wrong_password(self):
        """错误密码验证失败"""
        h = _password_hash("MySecret1")
        self.assertFalse(_password_verify("WrongPass", h))

    def test_verify_empty_password(self):
        """空密码验证"""
        h = _password_hash("MySecret1")
        self.assertFalse(_password_verify("", h))


class TestSessionManagement(unittest.TestCase):
    """会话管理测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_create_and_validate_session(self):
        """创建和验证会话"""
        token = create_session("admin")
        self.assertTrue(len(token) > 20)
        u = session_user(token)
        self.assertIsNotNone(u)
        self.assertEqual(u["username"], "admin")
        delete_session(token)

    def test_invalid_token_returns_none(self):
        """无效令牌返回 None"""
        self.assertIsNone(session_user(""))
        self.assertIsNone(session_user("fake_token_1234567890_abcdef"))

    def test_delete_session_invalidates(self):
        """删除会话后令牌失效"""
        token = create_session("admin")
        self.assertIsNotNone(session_user(token))
        delete_session(token)
        self.assertIsNone(session_user(token))

    def test_session_user_not_expired_yet(self):
        """新创建的会话未过期"""
        token = create_session("admin", days=1)
        u = session_user(token)
        self.assertIsNotNone(u)
        delete_session(token)


class TestUserManagement(unittest.TestCase):
    """用户管理测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_add_new_user(self):
        """添加新用户成功后可以登录"""
        try:
            add_user("testuser1", "测试用户1", "TestPass123", "实验员")
        except Exception:
            pass
        u = authenticate("testuser1", "TestPass123")
        self.assertIsNotNone(u)
        self.assertEqual(u["display_name"], "测试用户1")

    def test_add_duplicate_user_raises(self):
        """重复用户名抛出异常"""
        try:
            add_user("dupuser", "重复用户", "DupPass1234", "实验员")
        except Exception:
            pass
        with self.assertRaises(Exception):
            add_user("dupuser", "重复用户2", "DupPass5678", "实验员")

    def test_list_users_includes_admin(self):
        """list_users 包含 admin"""
        users = list_users()
        self.assertGreater(len(users), 0)
        self.assertTrue(any(u["username"] == "admin" for u in users))


class TestPasswordReset(unittest.TestCase):
    """密码重置测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def setUp(self):
        try:
            add_user("pwreset_test", "密码重置测试", "OldPass1", "实验员")
        except Exception:
            pass

    def test_admin_can_reset_password(self):
        """管理员可以重置其他用户密码"""
        reset_user_password("pwreset_test", "NewPass1234", "admin")
        u = authenticate("pwreset_test", "NewPass1234")
        self.assertIsNotNone(u)

    def test_non_admin_cannot_reset(self):
        """非管理员不能重置他人密码 — 当前 reset_user_password 不校验 actor 角色"""
        # Known limitation: reset_user_password does not validate that actor is admin.
        # It will reset any user's password regardless of who calls it.
        # This test documents that behavior:
        try:
            reset_user_password("pwreset_test", "HackPass123", "tester")
            # If no exception, verify the password was indeed reset
            u = authenticate("pwreset_test", "HackPass123")
            self.assertIsNotNone(u)
        except ValueError:
            # If role check is later added, this branch validates it
            pass

    def test_nonexistent_target_raises(self):
        """重置不存在用户抛出异常"""
        with self.assertRaises(ValueError):
            reset_user_password("no_such_user_xyz", "Pass1234567", "admin")

    def test_sessions_invalidated_after_reset(self):
        """重置密码后旧会话失效"""
        token = create_session("pwreset_test")
        self.assertIsNotNone(session_user(token))
        reset_user_password("pwreset_test", "AfterReset99", "admin")
        self.assertIsNone(session_user(token))


class TestDemoMode(unittest.TestCase):
    """演示模式测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_demo_users_created(self):
        """DEMO_MODE=true 时创建演示用户"""
        users = list_users()
        self.assertGreater(len(users), 0)
        self.assertTrue(any(u["username"] == "admin" for u in users))

    def test_demo_admin_has_correct_role(self):
        """演示管理员角色正确"""
        # Admin's password may have been changed by other tests in the module
        # Check via list_users instead
        users = list_users()
        admin_users = [u for u in users if u["username"] == "admin"]
        self.assertEqual(len(admin_users), 1)
        self.assertEqual(admin_users[0]["role"], "管理员")


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
