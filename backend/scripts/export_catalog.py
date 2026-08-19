"""导出本地 sample_catalog 数据，通过 API 导入到目标机器"""
import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import async_session
from sqlalchemy import text


async def export_and_push():
    # 1. 从本地 DB 导出
    records = []
    async with async_session() as db:
        r = await db.execute(text("""
            SELECT sample_code, sample_name, model, material_name, experiment_codes,
                   process, material_suffix, source_sequence, category, unit, notes
            FROM sample_catalog WHERE enabled=TRUE ORDER BY id
        """))
        for row in r.fetchall():
            ec = row[4]
            if isinstance(ec, str):
                ec = json.loads(ec) if ec else []
            records.append({
                "sample_code": row[0],
                "sample_name": row[1],
                "model": row[2],
                "material_name": row[3],
                "experiment_codes": ec,
                "process": row[5],
                "material_suffix": row[6],
                "source_sequence": row[7],
                "category": row[8],
                "unit": row[9] or "件",
                "notes": row[10],
            })

    # 2. 保存到 JSON 文件，方便拷贝
    out_path = Path(__file__).parent.parent.parent / "sample_catalog_export.json"
    out_path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Exported {len(records)} records to {out_path}")
    print("Copy this file to target machine, then run import script.")


if __name__ == "__main__":
    asyncio.run(export_and_push())
