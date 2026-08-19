"""
把 camera_hints / report_decisive_photo_codes / record_template_file 灌入
experiment_config_versions.extra_json（配置驱动化 P0，幂等）。

用法: cd backend && .venv/Scripts/python.exe scripts/backfill_extra_json.py

说明:
  - 先执行 ALTER TABLE ... ADD COLUMN IF NOT EXISTS extra_json（等价 004_config_driven.sql）。
  - 对每个 status='现行' 的配置版本，把当前硬编码兜底值写进 extra_json，
    使 DB 成为权威来源；行为与改造前逐格一致。
  - 只更新 camera_hints / report_decisive_photo_codes / record_template_file 三个键，
    保留 extra_json 中已存在的其它键（constants 等由 P3 种子另行写入）。
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import psycopg2

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

BACKEND = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND))

# 硬编码兜底值（改造前唯一来源）
from app.api.v1.experiment_config import (  # noqa: E402
    _CAMERA_HINTS,
    _KIND_TO_NAME,
    _REPORT_DECISIVE_PHOTO_CODES,
    _TEMPLATE_FILE_MAP,
)

# experiment_methods 里的 legacy kind → SCHEMAS 规范 kind（与 record_word_engine._KIND_TO_MAPPER 一致）
_KIND_ALIAS = {
    "crack": "mc_crack",
    "warpage": "warp",
    "thermal_shock": "shock",
    "bending": "bend",
    "vickers": "hv",
    "color_stability": "color",
}


def _canonical_kind(kind: str) -> str:
    if not kind:
        return kind
    return _KIND_ALIAS.get(kind, kind)


def _conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "123456"),
        dbname=os.getenv("DB_NAME", "bplab"),
    )


def main() -> None:
    conn = _conn()
    cur = conn.cursor()
    try:
        cur.execute(
            "ALTER TABLE experiment_config_versions ADD COLUMN IF NOT EXISTS extra_json JSONB DEFAULT '{}'"
        )
        print("✓ extra_json 列已确保存在")

        cur.execute(
            "SELECT id, experiment_code, experiment_name, kind, extra_json "
            "FROM experiment_config_versions WHERE status='现行'"
        )
        rows = cur.fetchall()
        updated = 0
        for config_id, code, name, kind, extra_json in rows:
            kind_c = _canonical_kind(kind or "")
            existing = extra_json if isinstance(extra_json, dict) else {}
            payload = dict(existing)
            payload["camera_hints"] = _CAMERA_HINTS
            exp_name = name or _KIND_TO_NAME.get(kind_c, "")
            payload["report_decisive_photo_codes"] = _REPORT_DECISIVE_PHOTO_CODES.get(exp_name, [])
            payload["record_template_file"] = _TEMPLATE_FILE_MAP.get(kind_c, "")
            cur.execute(
                "UPDATE experiment_config_versions SET extra_json = %s WHERE id = %s",
                (json.dumps(payload, ensure_ascii=False), config_id),
            )
            updated += 1
            print(f"  · {code} [{kind_c}] → extra_json 已写入 "
                  f"(decisive={len(payload['report_decisive_photo_codes'])}, "
                  f"template={payload['record_template_file']})")

        conn.commit()
        print(f"✓ 完成：{updated} 个现行配置版本已回填 extra_json")
    except Exception as e:
        conn.rollback()
        print(f"❌ 失败已回滚: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
