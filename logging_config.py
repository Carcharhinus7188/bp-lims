# -*- coding: utf-8 -*-
"""Centralized logging configuration for BPLab Trace.

Provides a `get_logger` factory that returns a Python logger with both
console (Streamlit-safe) and rotating file handlers.

Security events (login failures, password changes, permission changes,
system initialization) are written to a dedicated `logs/security.log` file
via `get_security_logger()`.
"""
from __future__ import annotations

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from logging import Logger

# Import config lazily to avoid circular imports at module level
_log_dir: Path | None = None
_log_level: int = logging.INFO
_log_max_bytes: int = 10 * 1024 * 1024
_log_backup_count: int = 5
_initialized = False


def _init_from_config() -> None:
    global _log_dir, _log_level, _log_max_bytes, _log_backup_count, _initialized
    if _initialized:
        return
    try:
        from config import LOG_DIR, LOG_LEVEL, LOG_MAX_BYTES, LOG_BACKUP_COUNT, ensure_dirs
        ensure_dirs()
        _log_dir = LOG_DIR
        _log_level = getattr(logging, LOG_LEVEL.upper(), logging.INFO)
        _log_max_bytes = LOG_MAX_BYTES
        _log_backup_count = LOG_BACKUP_COUNT
    except ImportError:
        _log_dir = Path("logs")
        _log_dir.mkdir(parents=True, exist_ok=True)
    _initialized = True


# Custom formatter that preserves Chinese characters and includes all relevant detail
class LabFormatter(logging.Formatter):
    def __init__(self) -> None:
        super().__init__(
            fmt="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

    def format(self, record: logging.LogRecord) -> str:
        # Ensure exceptions are included
        if record.exc_info and not record.exc_text:
            record.exc_text = self.formatException(record.exc_info)
        return super().format(record)


# Shared rotating file handler (one for all loggers)
_file_handler: RotatingFileHandler | None = None


def _ensure_handlers(logger: Logger) -> None:
    """Attach console + file handlers to the logger if not already present."""
    global _file_handler
    _init_from_config()

    # Guard against double-initialization
    logger.propagate = False
    if logger.handlers:
        return

    # Console handler (writes to stderr — safe for Streamlit)
    console = logging.StreamHandler(sys.stderr)
    console.setFormatter(LabFormatter())
    console.setLevel(_log_level)
    logger.addHandler(console)

    # Shared file handler
    if _file_handler is None:
        assert _log_dir is not None
        log_path = _log_dir / "bplab.log"
        _file_handler = RotatingFileHandler(
            str(log_path),
            maxBytes=_log_max_bytes,
            backupCount=_log_backup_count,
            encoding="utf-8",
        )
        _file_handler.setFormatter(LabFormatter())
        _file_handler.setLevel(_log_level)

    logger.addHandler(_file_handler)
    logger.setLevel(_log_level)


def get_logger(name: str) -> Logger:
    """Return a configured logger for the given module name.

    Usage:
        from logging_config import get_logger
        logger = get_logger(__name__)
        logger.info("Database initialized")
    """
    logger = logging.getLogger(name)
    _ensure_handlers(logger)
    return logger


# ---------------------------------------------------------------------------
# Security event logging — dedicated file for audit-relevant security events
# ---------------------------------------------------------------------------
_security_logger: Logger | None = None


def _get_security_logger() -> Logger:
    """Create or return the singleton security event logger.

    Security events include:
    - Login success / failure (including lockout)
    - Password changes (self-service and admin reset)
    - Permission changes (role updates, user enable/disable)
    - System initialization / data purge
    - Session termination (manual)
    - Database backup / restore operations
    """
    global _security_logger
    if _security_logger is not None:
        return _security_logger

    _init_from_config()
    assert _log_dir is not None

    _security_logger = logging.getLogger("bplab.security")
    _security_logger.propagate = False
    _security_logger.setLevel(logging.INFO)

    sec_log_path = _log_dir / "security.log"
    sec_handler = RotatingFileHandler(
        str(sec_log_path),
        maxBytes=_log_max_bytes,
        backupCount=_log_backup_count,
        encoding="utf-8",
    )
    sec_handler.setFormatter(LabFormatter())
    sec_handler.setLevel(logging.INFO)
    _security_logger.addHandler(sec_handler)

    # Also echo security events to stderr in production for immediate visibility
    console = logging.StreamHandler(sys.stderr)
    console.setFormatter(LabFormatter())
    console.setLevel(logging.WARNING)  # Only WARNING+ on console
    _security_logger.addHandler(console)

    return _security_logger


def log_security_event(
    event_type: str,
    actor: str = "",
    target: str = "",
    detail: str = "",
    source_ip: str = "",
    success: bool | None = None,
) -> None:
    """Record a security-relevant event to logs/security.log.

    Args:
        event_type: One of 'login_success', 'login_failure', 'login_lockout',
                    'password_change', 'password_reset', 'role_change',
                    'user_enable', 'user_disable', 'session_terminate',
                    'system_init', 'backup_create', 'backup_restore',
                    'user_create', 'user_delete'
        actor: Username performing the action (or '' for system/anon)
        target: Username or resource affected
        detail: Human-readable description
        source_ip: Client IP address if available
        success: Whether the event succeeded (None = informational)
    """
    logger = _get_security_logger()
    parts = [f"event={event_type}"]
    if actor:
        parts.append(f"actor={actor}")
    if target:
        parts.append(f"target={target}")
    if source_ip:
        parts.append(f"ip={source_ip}")
    if success is True:
        parts.append("result=success")
    elif success is False:
        parts.append("result=failure")
    if detail:
        parts.append(f"detail={detail}")

    message = " | ".join(parts)

    if success is False:
        logger.warning(message)
    else:
        logger.info(message)
