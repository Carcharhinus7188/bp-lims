"""一次性修复数据库：缺失列 + 样品资料库初始数据"""
import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import async_session
from sqlalchemy import text

SAMPLE_CATALOG_DATA = [
    ("SL001", "牙科用钴铬合金", "标准", "钴铬合金", "I001,I002,I003,I004,I005,I006,I007,I008,I009"),
    ("SL002", "牙科用纯钛", "标准", "纯钛", "I001,I004,I005,I007,I008,I009"),
    ("SL003", "牙科用钛合金", "标准", "钛合金", "I001,I002,I004,I005,I007,I008,I009"),
    ("SL004", "牙科用镍铬合金", "标准", "镍铬合金", "I001,I002,I003,I004,I005,I006,I007,I008,I009"),
    ("SL005", "牙科用氧化锆陶瓷", "标准", "氧化锆陶瓷", "I001,I002,I006,I007,I008,I010"),
    ("SL006", "牙科用烤瓷粉", "标准", "烤瓷粉", "I006,I010"),
    ("SL007", "牙科用PMMA树脂", "标准", "聚甲基丙烯酸甲酯", "I010"),
    ("SL008", "牙科用金合金", "标准", "金合金", "I001,I002,I004,I005,I007,I008,I009,I014"),
    ("SL009", "增材制造用钴铬钼合金", "标准", "钴铬钼合金", "I001,I004,I005,I007,I008,I009,I013"),
    ("SL010", "牙科用银钯合金", "标准", "银钯合金", "I001,I004,I005,I007,I008,I009,I014"),
]


async def column_exists(db, table: str, column: str) -> bool:
    """检查列是否已存在"""
    r = await db.execute(
        text("""
            SELECT 1 FROM information_schema.columns
            WHERE table_name=:t AND column_name=:c
        """),
        {"t": table, "c": column},
    )
    return r.fetchone() is not None


async def add_column(db, table: str, column: str, col_def: str = "TEXT") -> bool:
    """安全添加列，如果已存在则跳过"""
    if await column_exists(db, table, column):
        print(f"  [SKIP] exists: {table}.{column}")
        return True
    try:
        await db.execute(
            text(f"ALTER TABLE {table} ADD COLUMN {column} {col_def}")
        )
        await db.commit()
        print(f"  [OK] added: {table}.{column}")
        return True
    except Exception as e:
        await db.rollback()
        print(f"  [FAIL] {table}.{column}: {e}")
        return False


async def fix():
    print("=" * 50)
    print("BPLab 数据库修复脚本")
    print("=" * 50)

    # ── 1. experiment_methods ──
    print("\n[1/5] 修复 experiment_methods ...")
    async with async_session() as db:
        for col in ["template_code", "sop_file"]:
            await add_column(db, "experiment_methods", col)

    # ── 2. sample_catalog 缺列（detection_method / detection_basis）──
    print("\n[2/5] 修复 sample_catalog ...")
    async with async_session() as db:
        for col in ["detection_method", "detection_basis"]:
            await add_column(db, "sample_catalog", col)

    # ── 3. audit_logs ──
    print("\n[3/5] 修复 audit_logs ...")
    async with async_session() as db:
        await add_column(db, "audit_logs", "commission_no")

    # ── 4. modification_logs ──
    print("\n[4/5] 修复 modification_logs ...")
    async with async_session() as db:
        await add_column(db, "modification_logs", "commission_no")

    # ── 5. sample_groups 缺列 ──
    print("\n[5/6] 修复 sample_groups ...")
    async with async_session() as db:
        for col in ["experiment_codes", "batch_no"]:
            await add_column(db, "sample_groups", col)

    # ── 6. 样品资料库 ──
    print("\n[6/6] 导入样品资料库 ...")
    async with async_session() as db:
        count = 0
        for sample_code, sample_name, model, material_name, experiment_codes in SAMPLE_CATALOG_DATA:
            existing = await db.execute(
                text("SELECT 1 FROM sample_catalog WHERE sample_code=:c"),
                {"c": sample_code},
            )
            if existing.fetchone():
                print(f"  [SKIP] exists: {sample_code} {material_name}")
                continue

            codes_json = json.dumps(experiment_codes.split(","))
            await db.execute(
                text("""
                    INSERT INTO sample_catalog
                        (sample_code, sample_name, model, material_name,
                         experiment_codes, enabled, created_at, updated_at)
                    VALUES
                        (:sc, :sn, :md, :mn,
                         CAST(:ec AS jsonb), TRUE, localtimestamp, localtimestamp)
                """),
                {
                    "sc": sample_code, "sn": sample_name,
                    "md": model, "mn": material_name, "ec": codes_json,
                },
            )
            print(f"  [OK] imported: {sample_code} {material_name}")
            count += 1

        await db.commit()
        print(f"\n  样品资料库共导入 {count} 条新记录")

    print("\n" + "=" * 50)
    print("Database fix complete! Please restart the server.")
    print("=" * 50)


if __name__ == "__main__":
    asyncio.run(fix())
