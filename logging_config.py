# -*- coding: utf-8 -*-
"""Centralized logging configuration for BPLab Trace.

Provides a `get_logger` factory that returns a Python logger with both
console (Streamlit-safe) and rotating file handlers.
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
