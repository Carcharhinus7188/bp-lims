"""从本地数据库导出样品资料库，通过 API 推送到目标机器"""
import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import httpx
from app.database import async_session
from sqlalchemy import text


TARGET = "http://192.168.8.123:8000"
USERNAME = "admin"
PASSWORD = "admin123"


async def main():
    # 1. 从本地 DB 读取所有样品
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
            elif ec is None:
                ec = []
            records.append({
                "sample_code": row[0],
                "sample_name": row[1] or "",
                "model": row[2] or "",
                "material_name": row[3] or "",
                "experiment_codes": ec,
                "process": row[5],
                "material_suffix": row[6],
                "source_sequence": row[7],
                "category": row[8],
                "unit": row[9] or "件",
                "notes": row[10],
            })

    print(f"Local records: {len(records)}")

    # 2. 登录目标机器
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(f"{TARGET}/api/v1/auth/login", json={
            "username": USERNAME, "password": PASSWORD,
        })
        if resp.status_code != 200:
            print(f"Login failed: {resp.status_code} {resp.text}")
            return
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 3. 获取目标已有记录
        resp = await client.get(f"{TARGET}/api/v1/catalog", params={"limit": 500}, headers=headers)
        existing_codes = {r["sample_code"] for r in resp.json()} if resp.status_code == 200 else set()
        print(f"Target existing: {len(existing_codes)}")

        # 4. 推送缺失的
        inserted = 0
        skipped = 0
        for rec in records:
            if rec["sample_code"] in existing_codes:
                skipped += 1
                continue

            payload = {
                "sample_code": rec["sample_code"],
                "sample_name": rec["sample_name"],
                "model": rec["model"],
                "material_name": rec["material_name"],
                "experiment_codes": rec["experiment_codes"],
                "process": rec["process"],
                "material_suffix": rec["material_suffix"],
                "source_sequence": rec["source_sequence"],
                "category": rec["category"],
                "unit": rec["unit"],
                "notes": rec["notes"],
            }
            resp = await client.post(f"{TARGET}/api/v1/catalog", json=payload, headers=headers)
            if resp.status_code in (200, 201):
                print(f"  [OK] {rec['sample_code']} {rec['material_name']}")
                inserted += 1
            else:
                detail = resp.json().get("detail", resp.text)
                print(f"  [FAIL] {rec['sample_code']}: {resp.status_code} {detail}")

        print(f"\nDone: {inserted} inserted, {skipped} skipped, {len(records)} total")


if __name__ == "__main__":
    asyncio.run(main())
