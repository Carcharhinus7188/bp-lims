"""
One-off: 修正 experiment_methods 的 method_code / standard，
对齐 seed_configs.py / seed.py 的 _EXPERIMENT_META（I011=YY/T 1936、I012=YY 0270.1 等）。

仅更新 method_code / standard，不动 kind / experiment_name / enabled。
Usage: cd backend && .venv/Scripts/python.exe scripts/fix_methods.py
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import text
from app.database import async_session

# (method_code, standard) 与 seed_configs.py EXPERIMENT_META 完全一致
METHODS: dict[str, tuple[str, str]] = {
    "I001": ("YY/T 1702",   "YY/T 1702-2020；GB/T 10610-2009"),
    "I002": ("YY 0621.1",   "YY 0621.1-2016 / ISO 9693-1"),
    "I003": ("GB 17168",    "GB 17168及实验室受控SOP"),
    "I004": ("YY/T 1702",   "YY/T 1702-2020 第7.3.2条"),
    "I005": ("YY 0621.1",   "YY 0621.1及实验室受控SOP"),
    "I006": ("YY 0300",     "YY 0300-2009 第7.10条"),
    "I007": ("YY/T 1702",   "YY/T 1702-2020"),
    "I008": ("GB/T 4340.1", "GB/T 4340.1-2024"),
    "I009": ("YY/T 1702",   "YY/T 1702-2020"),
    "I010": ("YY 0710",     "YY 0710及产品技术要求"),
    "I011": ("YY/T 1936",   "YY/T 1936及产品技术要求"),
    "I012": ("YY 0270.1",   "YY 0270.1及产品技术要求"),
    "I013": ("YY/T 1702",   "YY/T 1702-2020"),
    "I014": ("YY 0710",     "YY 0710-2009"),
}


async def main() -> None:
    async with async_session() as db:
        print("Before:")
        rows = (await db.execute(
            text("SELECT experiment_code, method_code, standard FROM experiment_methods ORDER BY experiment_code")
        )).fetchall()
        for code, mc, std in rows:
            print(f"  {code} | {mc} | {std}")

        changed = 0
        for code, (mc, std) in METHODS.items():
            res = await db.execute(
                text(
                    "UPDATE experiment_methods "
                    "SET method_code=:mc, standard=:std, updated_at=localtimestamp "
                    "WHERE experiment_code=:c AND (method_code IS DISTINCT FROM :mc OR standard IS DISTINCT FROM :std)"
                ),
                {"mc": mc, "std": std, "c": code},
            )
            changed += res.rowcount or 0
        await db.commit()

        print(f"\nChanged {changed} row(s).\nAfter:")
        rows = (await db.execute(
            text("SELECT experiment_code, method_code, standard FROM experiment_methods ORDER BY experiment_code")
        )).fetchall()
        for code, mc, std in rows:
            print(f"  {code} | {mc} | {std}")


if __name__ == "__main__":
    asyncio.run(main())
