"""
一次性补全 sample_catalog 义齿/试样样品的 experiment_codes（对齐样品库五字段展示）。

规则：
- 定制式固定义齿 → I011（YY/T 1936）；金属/金属-陶瓷类（纯钛/钴铬/镍铬/钛合金/金合金）追加 I001（表面粗糙度）
- 定制式活动义齿 → I012（YY 0270.1）
- SY-* 试样按名称对应实验（弯曲→I007、抗晦暗→I014、金瓷结合→I002、粗糙度/硬度/密度→I001+I008+I013、线胀系数→I005）

默认 dry-run 只打印拟变更；加 --apply 才写库。
Usage: cd backend && .venv/Scripts/python.exe scripts/update_sample_experiments.py [--apply]
"""
from __future__ import annotations

import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import text
from app.database import async_session

METAL_TOKENS = ["纯钛", "钴铬", "镍铬", "钛合金", "金合金"]


def propose(sample_name: str, material: str) -> list[str]:
    name = sample_name or ""
    mat = material or ""
    if name == "定制式固定义齿":
        codes = ["I011"]
        if any(t in mat for t in METAL_TOKENS):
            codes.append("I001")
        return codes
    if name == "定制式活动义齿":
        return ["I012"]
    if "试样" in name:
        if "弯曲" in name:
            return ["I007"]
        if "抗晦暗" in name:
            return ["I014"]
        if "金瓷结合" in name or "结合强度" in name:
            return ["I002"]
        if "粗糙度" in name and "硬度" in name and "密度" in name:
            return ["I001", "I008", "I013"]
        if "线胀系数" in name or "热膨胀" in name:
            return ["I005"]
        return []
    return []


async def main(apply: bool) -> None:
    async with async_session() as db:
        rows = (await db.execute(
            text("SELECT id, sample_code, sample_name, material_name, experiment_codes, enabled "
                 "FROM sample_catalog WHERE enabled=TRUE ORDER BY id")
        )).fetchall()

        changes = []
        for oid, code, name, material, current, enabled in rows:
            current = current if isinstance(current, list) else []
            new_codes = sorted(set(propose(name, material)))
            if not new_codes or current == new_codes:
                continue
            changes.append((oid, code, name, material, current, new_codes))

        print(f"拟变更 {len(changes)} 条：\n")
        print(f"{'id':>3} | {'样品代码':<12} | {'样品名称':<14} | {'材料名称':<22} | 旧 -> 新")
        print("-" * 104)
        for oid, code, name, material, cur, new in changes:
            cur_s = ",".join(cur) or "[]"
            new_s = ",".join(new)
            print(f"{oid:>3} | {(code or ''):<12} | {name:<14} | {material:<22} | {cur_s} -> {new_s}")

        if apply and changes:
            for oid, code, name, material, cur, new in changes:
                await db.execute(
                    text("UPDATE sample_catalog SET experiment_codes=CAST(:ec AS jsonb), updated_at=localtimestamp WHERE id=:i"),
                    {"ec": json.dumps(new), "i": oid},
                )
            await db.commit()
            print(f"\n已写入 {len(changes)} 条。")
        elif apply:
            print("\n无变更。")
        else:
            print("\n（dry-run，未写入。确认后加 --apply 执行。）")


if __name__ == "__main__":
    asyncio.run(main("--apply" in sys.argv))
