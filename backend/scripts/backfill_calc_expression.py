"""
把计算列公式（扁平规则列表）写入 experiment_config_columns.calc_expression（任务四 P2，幂等）。

用法: cd backend && .venv/Scripts/python.exe scripts/backfill_calc_expression.py

说明:
  - 对每个 status='现行' 的配置版本，按 kind 取 calc_formulas.CALC_FORMULAS 的规则列表。
  - 命中的 calc 列：calc_expression = 单条规则 JSON（含 column_key）。
  - 未命中的 calc 列（无配方，如 thickness.deviation / density.* 等）：calc_expression = ''（清除死标签）。
  - 非 calc 列不动。
  - 行为与改造前逐格一致：未配方列保持「不计算」，不臆造行为。
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

from app.core.calc_formulas import rules_for_kind, rules_by_column  # noqa: E402

# experiment_methods / experiment_config_versions 里的 legacy kind → 规范 kind
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
            "SELECT id, experiment_code, kind FROM experiment_config_versions WHERE status='现行'"
        )
        versions = cur.fetchall()

        total_written = 0
        total_cleared = 0
        for config_id, code, kind in versions:
            kind_c = _canonical_kind(kind or "")
            rule_map = rules_by_column(rules_for_kind(kind_c))

            cur.execute(
                "SELECT id, column_key, column_type FROM experiment_config_columns "
                "WHERE config_id=%s AND column_type='calc' ORDER BY sort_order",
                (config_id,),
            )
            calc_cols = cur.fetchall()

            written = 0
            cleared = 0
            for col_id, col_key, col_type in calc_cols:
                rule = rule_map.get(col_key)
                if rule:
                    cur.execute(
                        "UPDATE experiment_config_columns SET calc_expression=%s WHERE id=%s",
                        (json.dumps(rule, ensure_ascii=False), col_id),
                    )
                    written += 1
                else:
                    cur.execute(
                        "UPDATE experiment_config_columns SET calc_expression='' WHERE id=%s",
                        (col_id,),
                    )
                    cleared += 1

            total_written += written
            total_cleared += cleared
            print(f"  · {code} [{kind_c}] 配方列 {written} 写公式, 未配方 calc 列 {cleared} 清空")

        conn.commit()
        print(f"\n✓ 完成：{len(versions)} 个现行版本；写入公式 {total_written} 列，清空 {total_cleared} 列")
    except Exception as e:
        conn.rollback()
        print(f"❌ 失败已回滚: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
