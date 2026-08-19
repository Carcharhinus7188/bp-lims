# -*- coding: utf-8 -*-
"""受控模板坐标映射全量审计（14 个 kind）。

校验 mapping_registry.FIELD_MAPPINGS（+ DB template_field_mappings 覆盖）里每个
静态坐标 (table/row/col) 在目标模板中都能命中「可填单元格」（含空白占位 ___/＿/… 或勾选 □）。
动态 per-row 直写坐标（循环 put）不在本脚本枚举范围，另行抽查。

用法:
  cd backend && .venv/Scripts/python.exe scripts/audit_mappings.py [--with-db]
"""
from __future__ import annotations

import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(BACKEND.parent))

from app.services import mapping_registry
from app.services.record_word_engine import template_manifest, _contains_marker

CUR_TEMPLATE_DIR = BACKEND.parent / "templates"
REF_TEMPLATE_DIR = Path("D:/Downloads/bp-lims-ref/templates")

# kind → 模板代码
KIND_CODE = {
    "rough": "R001", "mc_crack": "R004", "xray": "R005", "warp": "R006",
    "cte": "R007", "shock": "R009", "bend": "R010", "hv": "R011",
    "color": "R012", "thickness": "R013",
    "fixed_denture": "R014", "removable_denture": "R015",
    "density": "R016", "tarnish": "R017",
}

# V9.4.2 参考模板（10 类）；R014-R017 无 V9.4.2，用当前 V11.2 模板
REF_TEMPLATE = {
    "rough": "RECORD_R001_ROUGHNESS.docx",
    "mc_crack": "RECORD_R004_MC_CRACK.docx",
    "xray": "RECORD_R005_XRAY.docx",
    "warp": "RECORD_R006_WARPAGE.docx",
    "cte": "RECORD_R007_CTE.docx",
    "shock": "RECORD_R009_THERMAL_SHOCK.docx",
    "bend": "RECORD_R010_BENDING.docx",
    "hv": "RECORD_R011_VICKERS.docx",
    "color": "RECORD_R012_COLOR_STABILITY.docx",
    "thickness": "RECORD_R013_THICKNESS.docx",
}


def _scan(dir_: Path, code: str) -> str:
    if not dir_.exists():
        return ""
    for prefix in (code + "_", code + ".", "RECORD_" + code, "SOP_" + code):
        for f in dir_.iterdir():
            if f.suffix == ".docx" and f.name.startswith(prefix):
                return f.name
    return ""


def check(field_map: dict, template_path: Path) -> list[str]:
    """返回未命中/不可填的 field_key 列表。"""
    if not template_path.exists():
        return [f"<模板缺失 {template_path.name}>"]
    manifest = template_manifest(str(template_path))
    by_key = {f["key"]: f for f in manifest}
    problems: list[str] = []
    for field_key, entry in sorted(field_map.items()):
        key = f"t{entry['table']}_r{entry['row']}_c{entry['col']}"
        field = by_key.get(key)
        if not field:
            problems.append(
                f"{field_key} -> (表{entry['table']} r{entry['row']} c{entry['col']}) 单元格缺失/不可填"
            )
        elif not _contains_marker(str(field.get("template_text") or "")):
            problems.append(
                f"{field_key} -> (表{entry['table']} r{entry['row']} c{entry['col']}) "
                f"非占位文本: {field.get('template_text','')!r}"
            )
    return problems


def main() -> None:
    with_db = "--with-db" in sys.argv

    db_mappings: dict[str, list[dict]] = {}
    if with_db:
        import asyncio
        from sqlalchemy import text
        from app.database import async_session

        async def _load():
            async with async_session() as db:
                rows = (await db.execute(text(
                    "SELECT m.field_key, m.table_index, m.row_index, m.col_index, m.transform, "
                    "v.kind FROM template_field_mappings m "
                    "JOIN experiment_config_versions v ON v.id = m.config_id "
                    "WHERE v.status='现行'"
                ))).fetchall()
                for r in rows:
                    db_mappings.setdefault(r[5], []).append({
                        "field_key": r[0], "table_index": r[1], "row_index": r[2],
                        "col_index": r[3], "transform": r[4],
                    })
        asyncio.run(_load())
        print(f"[DB] 已读取 {sum(len(v) for v in db_mappings.values())} 条 template_field_mappings\n")

    total_problems = 0
    for kind, code in KIND_CODE.items():
        field_map = mapping_registry.get_field_map(kind, db_mappings.get(kind))
        if not field_map:
            print(f"✓ {kind:<16} ({code})  无静态坐标（全动态）")
            continue

        # 目标模板：优先 V9.4.2（10 类），否则当前 V11.2
        if kind in REF_TEMPLATE:
            target_dir = REF_TEMPLATE_DIR
            target_name = REF_TEMPLATE[kind]
        else:
            target_dir = CUR_TEMPLATE_DIR
            target_name = _scan(CUR_TEMPLATE_DIR, code)

        target_path = target_dir / target_name
        problems = check(field_map, target_path)
        if problems:
            total_problems += len(problems)
            print(f"✗ {kind:<16} ({code}) {target_name}  {len(problems)} 处问题:")
            for p in problems:
                print(f"     - {p}")
        else:
            print(f"✓ {kind:<16} ({code}) {target_name}  {len(field_map)} 个坐标全部命中")

    print(f"\n{'=' * 60}")
    if total_problems:
        print(f"✗ 共 {total_problems} 处坐标问题")
        sys.exit(1)
    print("✓ 全部 14 类静态坐标映射与目标模板一致")


if __name__ == "__main__":
    main()
