# -*- coding: utf-8 -*-
"""受控模板映射灌库（任务二 P3）：把硬编码的坐标 + 常量写入 DB，使 DB 成为权威来源。

写入内容：
  1) `template_field_mappings` —— 每个现行 config version 的静态单元格坐标
     （field_key → table/row/col/transform，来自 `mapping_registry.FIELD_MAPPINGS`）。
  2) `experiment_config_versions.extra_json.constants` —— devices / thresholds / fixed_text
     （来自 `mapping_registry.CONSTANTS`，与原 extra_json 三键合并，不覆盖已有键）。

幂等：先 DELETE 该 config_id 的 template_field_mappings 再 INSERT；constants 覆盖写。
灌库后 DB 值 == 硬编码值，逐格一致（golden 0 差异），改 DB 即可覆盖坐标/常量。

用法：
  cd backend && .venv/Scripts/python.exe scripts/seed_mappings.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(BACKEND.parent))

import psycopg2  # noqa: E402

from app.services import mapping_registry  # noqa: E402
from app.services.record_word_engine import _CODE_TO_MAPPER  # noqa: E402

TEMPLATE_DIR = BACKEND.parent / "templates"

# kind → 模板代码（与 record_word_engine._KIND_MAP 一致）
_KIND_TO_TEMPLATE = {
    "rough": "R001", "mc_crack": "R004", "xray": "R005",
    "warp": "R006", "cte": "R007", "shock": "R009",
    "bend": "R010", "hv": "R011", "color": "R012", "thickness": "R013",
    "fixed_denture": "R014", "removable_denture": "R015",
    "density": "R016", "tarnish": "R017",
}


def _resolve_template_name(kind: str, fallback: str = "") -> str:
    """kind → 模板文件名（优先 DB extra_json.record_template_file，再目录扫描）。"""
    if fallback:
        return fallback
    code = _KIND_TO_TEMPLATE.get(kind, "")
    if code and TEMPLATE_DIR.exists():
        for prefix in (code + "_", code + ".", "RECORD_" + code, "SOP_" + code):
            for f in TEMPLATE_DIR.iterdir():
                if f.suffix == ".docx" and f.name.startswith(prefix):
                    return f.name
    return ""


def main() -> None:
    conn = psycopg2.connect(
        host="localhost", port=5432, user="postgres", password="123456", dbname="bplab",
    )
    cur = conn.cursor()
    constants_json = json.dumps(
        mapping_registry.CONSTANTS, ensure_ascii=False
    )

    total_mappings = 0
    total_configs = 0
    try:
        # 现行 config version：id + extra_json（含 record_template_file）
        cur.execute(
            "SELECT id, experiment_code, extra_json FROM experiment_config_versions "
            "WHERE status='现行' ORDER BY experiment_code"
        )
        configs = cur.fetchall()

        for config_id, experiment_code, extra_json in configs:
            kind = _CODE_TO_MAPPER.get(experiment_code)
            if not kind:
                print(f"  ⚠ {experiment_code}: 无 mapper kind，跳过")
                continue

            field_map = mapping_registry.kind_field_mappings(kind)
            extra = extra_json if isinstance(extra_json, dict) else {}
            template_name = _resolve_template_name(
                kind, (extra.get("record_template_file") or "")
            )
            if not template_name:
                print(f"  ⚠ {experiment_code}({kind}): 无法解析模板文件名，跳过")
                continue

            # 1) 覆盖写坐标（幂等）
            cur.execute(
                "DELETE FROM template_field_mappings WHERE config_id=%s", (config_id,)
            )
            for sort_order, (field_key, entry) in enumerate(sorted(field_map.items())):
                cur.execute(
                    """
                    INSERT INTO template_field_mappings
                        (config_id, field_source, field_key, template_name,
                         table_index, row_index, col_index, transform,
                         checkbox_selection, sort_order)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        config_id,
                        "static",
                        field_key,
                        template_name,
                        int(entry["table"]),
                        int(entry["row"]),
                        int(entry["col"]),
                        entry.get("transform") or "text",
                        entry.get("checkbox_selection") or "",
                        sort_order,
                    ),
                )
                total_mappings += 1

            # 2) 合并 constants 进 extra_json（保留 camera_hints / record_template_file 等）
            extra["constants"] = mapping_registry.CONSTANTS
            cur.execute(
                "UPDATE experiment_config_versions SET extra_json=%s WHERE id=%s",
                (json.dumps(extra, ensure_ascii=False), config_id),
            )
            total_configs += 1
            print(f"  ✓ {experiment_code}({kind}): {len(field_map)} 条坐标 + constants")

        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()

    print(f"\n✓ 灌库完成：{total_configs} 个现行版本，共 {total_mappings} 条坐标映射。")
    print("  运行 golden 比对：.venv/Scripts/python.exe scripts/capture_golden.py --compare")


if __name__ == "__main__":
    main()
