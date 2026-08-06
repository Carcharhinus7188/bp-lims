# -*- coding: utf-8 -*-
"""Unified configuration for BPLab Trace.

Configuration is read in priority order:
1. Streamlit secrets (.streamlit/secrets.toml) — highest priority
2. Environment variables
3. Default values in this module — lowest priority

Never hardcode secrets in this file. Use .env or secrets.toml for production.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

ROOT = Path(__file__).parent


def _try_streamlit_secrets():
    """Attempt to read Streamlit secrets without importing streamlit eagerly.
    Returns None if no secrets file is found or streamlit is not available."""
    try:
        import streamlit as st
        if hasattr(st, "secrets"):
            # st.secrets may exist but raise if no secrets.toml is present.
            # Check for the secrets file first to avoid triggering the error.
            secrets_paths = [
                Path.home() / ".streamlit" / "secrets.toml",
                ROOT / ".streamlit" / "secrets.toml",
            ]
            has_file = any(p.exists() for p in secrets_paths)
            if not has_file:
                return None
            try:
                _ = st.secrets  # trigger parse
                return st.secrets
            except Exception:
                return None
    except Exception:
        pass
    return None


def _env_or_default(key: str, default: str = "") -> str:
    """Read a configuration value from the best available source."""
    secrets = _try_streamlit_secrets()
    if secrets is not None:
        try:
            if key in secrets:
                return str(secrets[key])
        except Exception:
            pass
    return os.environ.get(key, default)


# ---------- database ----------
DB_PATH = Path(_env_or_default("BPLAB_DB_PATH", str(ROOT / "data" / "bplab_trace.db")))
ATTACHMENT_DIR = Path(
    _env_or_default(
        "BPLAB_ATTACHMENT_DIR", str(ROOT / "data" / "attachments")
    )
)
SIGNATURE_DIR = Path(
    _env_or_default(
        "BPLAB_SIGNATURE_DIR", str(ROOT / "data" / "signatures")
    )
)

# ---------- security ----------
SECRET_KEY = _env_or_default("BPLAB_SECRET_KEY", "")
SESSION_MAX_AGE_DAYS = int(_env_or_default("BPLAB_SESSION_MAX_AGE_DAYS", "7"))
MAX_LOGIN_ATTEMPTS = int(_env_or_default("BPLAB_MAX_LOGIN_ATTEMPTS", "5"))

# ---------- demo / seed mode ----------
DEMO_MODE = _env_or_default("BPLAB_DEMO_MODE", "true").lower() in ("true", "1", "yes")

# Demo users: JSON string like [["admin","管理员","admin123","管理员"], ...]
# If empty or not set, demo users are skipped.
DEMO_USERS_JSON = _env_or_default("BPLAB_DEMO_USERS", "")
DEMO_USERS: list[tuple[str, str, str, str]] = []
if DEMO_USERS_JSON:
    try:
        DEMO_USERS = [
            tuple(item) for item in json.loads(DEMO_USERS_JSON)
        ]
    except (json.JSONDecodeError, TypeError):
        pass
else:
    # Built-in defaults (used only for development/demo)
    DEMO_USERS = [
        ("admin", "系统管理员", "admin123", "管理员"),
        ("receiver", "样品管理员王工", "receive123", "样品管理员"),
        ("tester", "实验员张工", "test123", "实验员"),
        ("reviewer", "复核员李工", "review123", "复核员"),
        ("quality", "质量负责人周工", "quality123", "质量负责人"),
    ]

# ---------- company / branding ----------
COMPANY_CN = _env_or_default("BPLAB_COMPANY_CN", "大连标普检测有限公司")
COMPANY_EN = _env_or_default("BPLAB_COMPANY_EN", "DALIAN BIAOPU TESTING CO., LTD.")
APP_VERSION = _env_or_default("BPLAB_APP_VERSION", "BPLab Trace V9.3 移动摄像头与高保真预览版")
TIMEZONE_NAME = _env_or_default("BPLAB_TIMEZONE", "Asia/Shanghai")

# ---------- logging ----------
LOG_DIR = Path(_env_or_default("BPLAB_LOG_DIR", str(ROOT / "logs")))
LOG_LEVEL = _env_or_default("BPLAB_LOG_LEVEL", "INFO")
LOG_MAX_BYTES = int(_env_or_default("BPLAB_LOG_MAX_BYTES", str(10 * 1024 * 1024)))
LOG_BACKUP_COUNT = int(_env_or_default("BPLAB_LOG_BACKUP_COUNT", "5"))

# ---------- paths ----------
TEMPLATE_DIR = ROOT / "templates"
OUTPUT_DIR = Path(_env_or_default("BPLAB_OUTPUT_DIR", str(ROOT / "data" / "outputs")))


def ensure_dirs() -> None:
    """Create all required directories if they don't exist."""
    for path in (DB_PATH.parent, ATTACHMENT_DIR, SIGNATURE_DIR, LOG_DIR, OUTPUT_DIR):
        path.mkdir(parents=True, exist_ok=True)
