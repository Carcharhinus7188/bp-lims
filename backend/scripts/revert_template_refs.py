# -*- coding: utf-8 -*-
"""一次性把 DB 中 10 类受控原始记录模板引用由 V11.2 文件名改回 V9.4.2 文件名。

范围：
  1) experiment_config_versions.extra_json.record_template_file（V2.0 行）
  2) template_field_mappings.template_name

R014-R017（固定义齿/活动义齿/密度/抗晦暗）为 V11.2 新增、无 V9.4.2 模板，保持不变。
SOP 文件 V9.4.2 与 V11.2 字节一致（仅改名 SOP_RXXX→SOP-XXX），无需改。

默认 dry-run 只打印拟变更；加 --apply 才写库。
Usage: cd backend && .venv/Scripts/python.exe scripts/revert_template_refs.py [--apply]
"""
from __future__ import annotations

import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import text
from app.database import async_session

# V11.2 文件名 → V9.4.2 文件名（仅 10 类有 V9.4.2 模板的 kind）
NAME_MAP = {
    "R001_表面粗糙度试验_CMA原始记录表.docx": "RECORD_R001_ROUGHNESS.docx",
    "R004_金属-陶瓷结合裂纹萌生试验_CMA原始记录表.docx": "RECORD_R004_MC_CRACK.docx",
    "R005_金属内部质量X射线灰度分析_CMA原始记录表.docx": "RECORD_R005_XRAY.docx",
    "R006_翘曲变形试验_CMA原始记录表.docx": "RECORD_R006_WARPAGE.docx",
    "R007_热膨胀系数试验_CMA原始记录表.docx": "RECORD_R007_CTE.docx",
    "R009_陶瓷牙耐急冷急热试验_CMA原始记录表.docx": "RECORD_R009_THERMAL_SHOCK.docx",
    "R010_弯曲性能试验_CMA原始记录表.docx": "RECORD_R010_BENDING.docx",
    "R011_维氏硬度试验_CMA原始记录表.docx": "RECORD_R011_VICKERS.docx",
    "R012_牙科材料色稳定性试验_CMA原始记录表.docx": "RECORD_R012_COLOR_STABILITY.docx",
    "R013_增材制造金属试样厚度测量_CMA原始记录表.docx": "RECORD_R013_THICKNESS.docx",
}


async def main(apply: bool) -> None:
    changes: list[tuple[str, str, str, str]] = []  # (table, key, old, new)

    async with async_session() as db:
        # 1) experiment_config_versions.extra_json.record_template_file
        rows = (await db.execute(text(
            "SELECT id, experiment_code, extra_json->>'record_template_file' "
            "FROM experiment_config_versions "
            "WHERE extra_json->>'record_template_file' IS NOT NULL"
        ))).fetchall()
        for oid, code, rtf in rows:
            if rtf in NAME_MAP:
                changes.append(("experiment_config_versions", f"id={oid}({code})", rtf, NAME_MAP[rtf]))
                if apply:
                    new_extra = json.dumps({"record_template_file": NAME_MAP[rtf]})
                    await db.execute(text(
                        "UPDATE experiment_config_versions "
                        "SET extra_json = extra_json || CAST(:x AS jsonb) "
                        "WHERE id=:i"
                    ), {"x": new_extra, "i": oid})

        # 2) template_field_mappings.template_name
        rows = (await db.execute(text(
            "SELECT id, template_name FROM template_field_mappings "
            "WHERE template_name IS NOT NULL"
        ))).fetchall()
        for mid, tn in rows:
            if tn in NAME_MAP:
                changes.append(("template_field_mappings", f"id={mid}", tn, NAME_MAP[tn]))
                if apply:
                    await db.execute(text(
                        "UPDATE template_field_mappings SET template_name=:n, updated_at=localtimestamp WHERE id=:i"
                    ), {"n": NAME_MAP[tn], "i": mid})

        print(f"拟变更 {len(changes)} 条：\n")
        for table, key, old, new in changes:
            print(f"  {table}.{key}: {old} -> {new}")

        if apply:
            await db.commit()
            print(f"\n已写入 {len(changes)} 条。")
        else:
            print("\n（dry-run，未写入。确认后加 --apply 执行。）")


if __name__ == "__main__":
    asyncio.run(main("--apply" in sys.argv))
