"""
样品批号/生产日期字段改为只读（随任务包/样品组自动带出，实验员无需填写），幂等。

用法: cd backend && .venv/Scripts/python.exe scripts/backfill_batch_prod_readonly.py

说明:
  - 对每个 status='现行' 的配置版本，把字段 field_key ∈
    {sample_production_date, production_date} 的 is_readonly 置 TRUE、is_actual 置 FALSE。
  - sample_production_date 对应「样品生产日期/批次日期」（通用）或「样品批号」（hv/thickness），
    值来自 sample_groups.batch_no；production_date 对应「生产日期」（thickness），值来自
    sample_groups.production_date。
  - 这些字段由前端 applySampleGroupPrefill 从样品组自动预填，实验员无需填写。
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

_TARGET_KEYS = ("sample_production_date", "production_date")


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
            "SELECT id, experiment_code FROM experiment_config_versions WHERE status='现行'"
        )
        versions = cur.fetchall()

        total = 0
        for config_id, code in versions:
            cur.execute(
                "UPDATE experiment_config_fields "
                "SET is_readonly=TRUE, is_actual=FALSE, field_default=NULL "
                "WHERE config_id=%s AND field_key IN %s",
                (config_id, _TARGET_KEYS),
            )
            n = cur.rowcount
            total += n
            if n:
                print(f"  · {code}: 置只读 {n} 个字段")

        conn.commit()
        print(f"\n✓ 完成：{len(versions)} 个现行版本；共置只读 {total} 个字段")
    except Exception as e:
        conn.rollback()
        print(f"❌ 失败已回滚: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
