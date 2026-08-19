"""
V10.0 Seed Script - Import 14 experiment methods
Run once to upgrade from V9.x to V10.0
Usage: cd backend && python scripts/seed_v10.py

说明：设备 / 设备绑定 / 模板已随 bplab_dump.sql 进入数据库，不再由本脚本从 CSV 导入。
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import async_session
from sqlalchemy import text

EXPERIMENT_METHODS = [
    ("I001", "表面粗糙度试验", "YY/T 1702", "YY/T 1702-2020；GB/T 10610-2009", "roughness"),
    ("I002", "金属-陶瓷结合裂纹萌生试验", "YY 0621.1", "YY 0621.1-2016 / ISO 9693-1", "crack"),
    ("I003", "金属内部质量X射线灰度分析", "GB 17168", "GB 17168及实验室受控SOP", "xray"),
    ("I004", "翘曲变形试验", "YY/T 1702", "YY/T 1702-2020 第7.3.2条", "warpage"),
    ("I005", "热膨胀系数试验", "YY 0621.1", "YY 0621.1及实验室受控SOP", "cte"),
    ("I006", "陶瓷牙耐急冷急热试验", "YY 0300", "YY 0300-2009 第7.10条", "thermal_shock"),
    ("I007", "弯曲性能试验", "YY/T 1702", "YY/T 1702-2020", "bending"),
    ("I008", "维氏硬度试验", "GB/T 4340.1", "GB/T 4340.1-2024", "vickers"),
    ("I009", "增材制造金属试样厚度测量", "YY/T 1702", "YY/T 1702-2020", "thickness"),
    ("I010", "牙科材料色稳定性试验", "YY 0710", "YY 0710及产品技术要求", "color_stability"),
    ("I011", "定制式固定义齿检验", "YY/T 1936", "YY/T 1936及产品技术要求", "fixed_denture"),
    ("I012", "定制式活动义齿检验", "YY 0270.1", "YY 0270.1及产品技术要求", "removable_denture"),
    ("I013", "激光选区熔化金属材料密度试验", "YY/T 1702", "YY/T 1702-2020", "density"),
    ("I014", "金属材料抗晦暗性能试验", "YY 0710", "YY 0710-2009", "tarnish"),
]


async def seed_experiment_methods(db) -> int:
    count = 0
    for code, name, method, standard, kind in EXPERIMENT_METHODS:
        existing = await db.execute(
            text("SELECT 1 FROM experiment_methods WHERE experiment_code=:c"), {"c": code}
        )
        if existing.fetchone():
            await db.execute(
                text("""
                    UPDATE experiment_methods
                    SET experiment_name=:n, method_code=:m, standard=:s, kind=:k, updated_at=localtimestamp
                    WHERE experiment_code=:c
                """),
                {"n": name, "m": method, "s": standard, "k": kind, "c": code},
            )
            print(f"  Updated: {code} {name}")
        else:
            await db.execute(
                text("""
                    INSERT INTO experiment_methods (experiment_code, experiment_name, method_code, standard,
                        kind, enabled, created_at, updated_at)
                    VALUES (:c, :n, :m, :s, :k, TRUE, localtimestamp, localtimestamp)
                """),
                {"c": code, "n": name, "m": method, "s": standard, "k": kind},
            )
            print(f"  Inserted: {code} {name}")
            count += 1
    return count


async def seed_experiment_configs(db) -> int:
    # V11: 配置版本由 auto_seed() 完整创建（含字段/列/拍照节点），
    # 此函数保留空壳以防 auto_seed 遗漏 I010-I014，但不再创建无子配置的空版本。
    return 0


async def main():
    print("=" * 60)
    print("BPLab Trace V10.0 Seed Script")
    print("=" * 60)

    async with async_session() as db:
        try:
            print("\n[1/2] Seeding experiment_methods...")
            await seed_experiment_methods(db)
            await db.commit()

            print("\n[2/2] Creating experiment_config_versions...")
            await seed_experiment_configs(db)
            await db.commit()

            print("\nAll database changes committed!")

        except Exception as e:
            await db.rollback()
            print(f"\nError: {e}")
            raise

    # Verify
    print("\n" + "=" * 60)
    print("Verification:")
    async with async_session() as db:
        r = await db.execute(text("SELECT COUNT(*) FROM experiment_methods"))
        print(f"  experiment_methods: {r.fetchone()[0]} rows")
        r = await db.execute(
            text("SELECT experiment_code, experiment_name FROM experiment_methods ORDER BY experiment_code")
        )
        print("  Methods:")
        for row in r.fetchall():
            print(f"    {row[0]} = {row[1]}")
        await db.commit()

    print("\nDone! V10.0 seed complete.")


if __name__ == "__main__":
    asyncio.run(main())
