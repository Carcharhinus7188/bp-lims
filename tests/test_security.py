# -*- coding: utf-8 -*-
"""BPLab Trace — 安全功能测试：暴力破解防护、密码策略、会话安全"""
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
os.environ["BPLAB_MAX_LOGIN_ATTEMPTS"] = "5"
os.environ["BPLAB_LOGIN_LOCKOUT_MINUTES"] = "15"
os.environ["BPLAB_PASSWORD_MIN_LENGTH"] = "8"

import lims_db
lims_db.DB_PATH = _db
lims_db.ATTACHMENT_DIR = _root / "att"
lims_db.SIGNATURE_DIR = _root / "sig"

from lims_db import (
    init_db, authenticate, create_session, session_user,
    delete_session, add_user, change_password, admin_reset_password,
    invalidate_user_sessions, _validate_password_strength,
    _check_login_lockout, _record_login_attempt, reset_login_attempts,
    PasswordValidationError, TooManyLoginAttempts,
    touch_session, list_active_sessions, terminate_session,
    cleanup_expired_sessions, connect, now, china_now,
)


class TestBruteForceProtection(unittest.TestCase):
    """暴力破解防护测试"""

    @classmethod
    def setUpClass(cls):
        init_db()
        # Ensure test user exists
        try:
            add_user("locktest", "锁测试", "StrongPass1", "实验员")
        except Exception:
            pass

    def test_account_not_initially_locked(self):
        """初始状态下账户未锁定"""
        self.assertFalse(_check_login_lockout("locktest"))

    def test_lockout_after_max_failures(self):
        """连续失败5次后账户锁定"""
        reset_login_attempts("locktest")
        for _ in range(5):
            _record_login_attempt("locktest", success=False)
        self.assertTrue(_check_login_lockout("locktest"))

    def test_successful_login_clears_lockout(self):
        """成功登录不清除锁定（需管理员手动解锁）"""
        # First lock the account
        reset_login_attempts("locktest")
        for _ in range(5):
            _record_login_attempt("locktest", success=False)
        self.assertTrue(_check_login_lockout("locktest"))

        # A successful login record should NOT automatically unlock
        _record_login_attempt("locktest", success=True)
        # Lockout check still counts previous failures within the window
        self.assertTrue(_check_login_lockout("locktest"))

        # Admin reset should unlock
        reset_login_attempts("locktest")
        self.assertFalse(_check_login_lockout("locktest"))

    def test_valid_login_works(self):
        """正确密码登录成功"""
        reset_login_attempts("locktest")
        u = authenticate("locktest", "StrongPass1")
        self.assertIsNotNone(u)
        self.assertEqual(u["username"], "locktest")

    def test_invalid_password_records_attempt(self):
        """错误密码记录失败尝试"""
        reset_login_attempts("locktest")
        authenticate("locktest", "wrong_password")
        # Should be recorded
        with connect() as c:
            cnt = c.execute(
                "SELECT COUNT(*) FROM login_attempts WHERE username='locktest' AND success=0"
            ).fetchone()[0]
        self.assertGreater(cnt, 0)

    def test_lockout_returns_none(self):
        """锁定账户authenticate返回None"""
        reset_login_attempts("locktest")
        for _ in range(5):
            _record_login_attempt("locktest", success=False)
        u = authenticate("locktest", "StrongPass1")
        self.assertIsNone(u)

    def test_nonexistent_user_not_locked(self):
        """不存在用户不被锁定检查影响"""
        self.assertFalse(_check_login_lockout("nonexistent_xyz_123"))


class TestPasswordValidation(unittest.TestCase):
    """密码复杂度验证测试"""

    def test_too_short_password(self):
        """密码过短被拒绝"""
        with self.assertRaises(PasswordValidationError):
            _validate_password_strength("Ab1")

    def test_no_digit_rejected(self):
        """无数字密码被拒绝"""
        with self.assertRaises(PasswordValidationError):
            _validate_password_strength("abcdefgh")

    def test_no_letter_rejected(self):
        """无字母密码被拒绝"""
        with self.assertRaises(PasswordValidationError):
            _validate_password_strength("12345678")

    def test_valid_password_accepted(self):
        """有效密码通过验证"""
        _validate_password_strength("MyPass123")

    def test_common_weak_passwords_rejected(self):
        """常见弱密码被拒绝"""
        for pw in ("admin123", "password", "12345678", "test123"):
            with self.assertRaises(PasswordValidationError, msg=f"Should reject: {pw}"):
                _validate_password_strength(pw)

    def test_min_length_8(self):
        """最少8个字符"""
        _validate_password_strength("Ab123456")  # 8 chars, ok
        with self.assertRaises(PasswordValidationError):
            _validate_password_strength("Ab12345")  # 7 chars, not ok


class TestPasswordChange(unittest.TestCase):
    """密码修改测试"""

    @classmethod
    def setUpClass(cls):
        init_db()
        try:
            add_user("pwuser", "密码测试", "OldPass1", "实验员")
        except Exception:
            pass

    def setUp(self):
        # Reset password for each test
        with connect() as c:
            from lims_db import _password_hash
            c.execute(
                "UPDATE users SET password_hash=? WHERE username='pwuser'",
                (_password_hash("OldPass1"),),
            )
        reset_login_attempts("pwuser")

    def test_change_password_success(self):
        """正确旧密码修改成功"""
        change_password("pwuser", "OldPass1", "NewPass2")
        u = authenticate("pwuser", "NewPass2")
        self.assertIsNotNone(u)

    def test_change_password_wrong_old(self):
        """错误旧密码修改失败"""
        with self.assertRaises(ValueError):
            change_password("pwuser", "WrongOld1", "NewPass2")

    def test_change_password_same_as_old(self):
        """新旧密码相同被拒绝"""
        with self.assertRaises(ValueError):
            change_password("pwuser", "OldPass1", "OldPass1")

    def test_change_password_weak_new(self):
        """新密码过弱被拒绝"""
        with self.assertRaises(PasswordValidationError):
            change_password("pwuser", "OldPass1", "123")

    def test_sessions_invalidated_after_change(self):
        """修改密码后旧会话失效"""
        token = create_session("pwuser")
        self.assertIsNotNone(session_user(token))
        change_password("pwuser", "OldPass1", "NewPass3")
        self.assertIsNone(session_user(token))


class TestAdminPasswordReset(unittest.TestCase):
    """管理员密码重置测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_admin_can_reset_password(self):
        """管理员可以重置其他用户密码"""
        # Ensure target user exists
        try:
            add_user("resettarget", "重置目标", "Target1A", "实验员")
        except Exception:
            pass
        admin_reset_password("admin", "resettarget", "Reset01B")
        u = authenticate("resettarget", "Reset01B")
        self.assertIsNotNone(u)

    def test_non_admin_cannot_reset(self):
        """非管理员不能重置密码"""
        with self.assertRaises(ValueError):
            admin_reset_password("tester", "admin", "HackPass1")

    def test_nonexistent_target_raises(self):
        """不存在目标用户抛出异常"""
        with self.assertRaises(ValueError):
            admin_reset_password("admin", "no_such_user_xyz", "Pass1234")


class TestSessionSecurity(unittest.TestCase):
    """会话安全测试"""

    @classmethod
    def setUpClass(cls):
        init_db()

    def test_session_create_and_validate(self):
        """创建和验证会话"""
        token = create_session("admin")
        self.assertTrue(len(token) > 20)
        u = session_user(token)
        self.assertIsNotNone(u)
        delete_session(token)

    def test_invalid_token_returns_none(self):
        """无效令牌返回None"""
        self.assertIsNone(session_user(""))
        self.assertIsNone(session_user("fake_token_1234567890"))

    def test_touch_session_updates_activity(self):
        """touch_session更新时间戳"""
        token = create_session("admin")
        user_before = session_user(token)
        self.assertIsNotNone(user_before)
        touch_session(token)
        user_after = session_user(token)
        self.assertIsNotNone(user_after)

    def test_terminate_session(self):
        """终止会话"""
        token = create_session("admin")
        terminate_session(token)
        self.assertIsNone(session_user(token))

    def test_list_active_sessions(self):
        """列出活跃会话"""
        token = create_session("admin")
        sessions = list_active_sessions()
        self.assertTrue(any(s["username"] == "admin" for s in sessions))
        delete_session(token)

    def test_cleanup_expired_sessions(self):
        """清理过期会话"""
        # Insert an already-expired session
        with connect() as c:
            c.execute(
                "INSERT INTO sessions(token,username,expires_at,created_at,last_activity_at) VALUES(?,?,?,?,?)",
                ("expired_test_token", "admin", "2020-01-01T00:00:00", "2020-01-01T00:00:00", "2020-01-01T00:00:00"),
            )
        n = cleanup_expired_sessions()
        self.assertGreater(n, 0)
        self.assertIsNone(session_user("expired_test_token"))


class TestDemoModeSecurity(unittest.TestCase):
    """演示模式安全测试"""

    def test_demo_users_created_when_enabled(self):
        """DEMO_MODE=true时创建演示用户"""
        users = lims_db.list_users()
        self.assertTrue(any(u["username"] == "admin" for u in users))

    def test_demo_users_have_default_passwords(self):
        """演示用户使用默认密码（警告：生产环境应变更）"""
        u = authenticate("admin", "admin123")
        self.assertIsNotNone(u)
        self.assertEqual(u["role"], "管理员")


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
