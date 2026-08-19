"""规格型号占位符回填为「标准」，幂等。

历史数据里「规格型号」存在 '', '-', '—', '无', '暂无' 等占位符（无数据）。
按需求：没有数据的都改成「标准」；已有真实值（含「标准」本身）的保持不变。

覆盖三张样品相关表：
  - sample_catalog.model
  - sample_groups.model
  - samples.model
（设备表 equipment_registry.model 是设备型号，不属于样品规格型号，不动。）

用法: cd backend && .venv/Scripts/python.exe scripts/backfill_model_standard.py
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import psycopg2

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

BACKEND = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND))

from app.core.model_utils import normalize_model  # noqa: E402

_TARGET = "标准"

# 每张表: (表名, 主键列)
_TABLES = [
    ("sample_catalog", "id"),
    ("sample_groups", "id"),
    ("samples", "sample_no"),
]


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
        total = 0
        for table, pk in _TABLES:
            cur.execute(f"SELECT {pk}, model FROM {table}")
            rows = cur.fetchall()
            changed = 0
            for key, model in rows:
                if not normalize_model(model):  # 无数据/占位符 → 回填「标准」
                    cur.execute(
                        f"UPDATE {table} SET model=%s WHERE {pk}=%s",
                        (_TARGET, key),
                    )
                    changed += 1
            total += changed
            print(f"  · {table}: 回填 {changed} 条（共 {len(rows)} 条）")

        conn.commit()
        print(f"\n✓ 完成：共回填 {total} 条占位符规格型号 → 「标准」")
    except Exception as e:
        conn.rollback()
        print(f"❌ 失败已回滚: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
