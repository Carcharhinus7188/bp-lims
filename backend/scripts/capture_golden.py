# -*- coding: utf-8 -*-
"""CMA 受控原始记录改造的 golden 基线捕获 / 比对（任务二 P3 坐标/阈值/设备号数据化）。

用法:
  cd backend && .venv/Scripts/python.exe scripts/capture_golden.py           # 捕获基线
  cd backend && .venv/Scripts/python.exe scripts/capture_golden.py --compare # 重新生成并 diff

产出 backend/data/_golden/manifest.json，含两部分:
  1) `records`: 库内每条 record 的受控映射结果（apply_controlled_mapping 的 values+touched）
     —— 这是逐格一致性的权威基线（不经过 _template_fields 历史缓存，任何遗漏都会暴露）。
  2) `mappers`: 14 个 kind 用「确定性合成 payload」跑 apply_controlled_mapping 的 values+touched
     —— 覆盖库内无记录的实验类型；每个 key 由 crc32 映射为稳定 float，坐标/常量错位即告警。
  3) `docx`: 库内每条 record 的完整导出 DOCX 逐格文本（端到端二次校验）。

compare 模式用完全相同的输入生成逻辑重跑，再逐项 diff；要求 0 差异。
"""
from __future__ import annotations

import argparse
import json
import sys
import zlib
from io import BytesIO
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(BACKEND.parent))

import psycopg2  # noqa: E402
from docx import Document  # noqa: E402

from app.services.controlled_template_mappings import (  # noqa: E402
    MAPPERS,
    apply_controlled_mapping,
)
from app.services.record_word_engine import _get_kind  # noqa: E402

TEMPLATE_DIR = BACKEND.parent / "templates"
SIGNATURE_DIR = BACKEND / "data" / "signatures"
GOLDEN_DIR = BACKEND / "data" / "_golden"
MANIFEST = GOLDEN_DIR / "manifest.json"

# kind → 模板代码（与 record_word_engine._KIND_MAP 一致）
_KIND_TO_TEMPLATE = {
    "rough": "R001", "mc_crack": "R004", "xray": "R005",
    "warp": "R006", "cte": "R007", "shock": "R009",
    "bend": "R010", "hv": "R011", "color": "R012", "thickness": "R013",
    "fixed_denture": "R014", "removable_denture": "R015",
    "density": "R016", "tarnish": "R017",
}


def _conn():
    return psycopg2.connect(
        host="localhost", port=5432, user="postgres", password="123456", dbname="bplab",
    )


# ── 确定性合成 payload ────────────────────────────────────────────────
def _gen_value(namespace: str, key: str) -> float:
    """把 (namespace, key) 稳定映射到 [1, 901) 的 float，进程无关（crc32）。"""
    return (zlib.crc32(f"{namespace}:{key}".encode("utf-8")) % 90000) / 100.0 + 1.0


class GenDict(dict):
    """get 永远返回确定性 float，覆盖 .get(f"...") 动态键且无需预先枚举。"""

    def __init__(self, namespace: str = "", seed: int = 0):
        super().__init__()
        self._ns = namespace
        self._seed = seed

    def _value(self, key):
        return _gen_value(self._ns, f"{self._seed}:{key}")

    def __getitem__(self, key):
        return self._value(key)

    def get(self, key, default=None):
        if not isinstance(key, str):
            return default
        return self._value(key)


def synthetic_business_record() -> dict:
    params = GenDict("params", 0)
    rows = [GenDict("row", j) for j in range(30)]
    return {
        "parameters": params,
        "rows": rows,
        "_equipment_checks": [{"status": "正常"}, {"status": "正常"}],
    }


def synthetic_context() -> dict:
    return GenDict("context", 0)


# ── 模板解析 ──────────────────────────────────────────────────────────
def _scan_template(kind: str) -> str:
    code = _KIND_TO_TEMPLATE.get(kind)
    if not code:
        return ""
    if not TEMPLATE_DIR.exists():
        return ""
    for prefix in (code + "_", code + ".", "RECORD_" + code, "SOP_" + code):
        for f in TEMPLATE_DIR.iterdir():
            if f.suffix == ".docx" and f.name.startswith(prefix):
                return f.name
    return ""


# ── 记录读取 ──────────────────────────────────────────────────────────
def _load_records() -> tuple[list[dict], dict]:
    conn = _conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT * FROM records ORDER BY record_no, version")
        rec_cols = [d[0] for d in cur.description]
        records = [dict(zip(rec_cols, r)) for r in cur.fetchall()]
        cur.execute("SELECT * FROM tasks")
        t_cols = [d[0] for d in cur.description]
        tasks = {t["task_no"]: t for t in (dict(zip(t_cols, r)) for r in cur.fetchall())}
    finally:
        cur.close()
        conn.close()
    return records, tasks


def _build_context(record: dict, task: dict | None) -> dict:
    return {
        "experiment": record.get("experiment") or (task.get("experiment") if task else ""),
        "experiment_code": (task.get("experiment_code") if task else "") or "",
        "tester": record.get("owner", ""),
        "operator": record.get("owner") or (task.get("assignee") if task else ""),
        "reviewer": (task.get("reviewer") if task else "") or record.get("reviewer", ""),
    }


def _build_business_record(payload: dict) -> dict:
    business_record = dict(payload)
    business_record.setdefault("parameters", payload.get("_form") or {})
    business_record.setdefault("rows", payload.get("_rows") or [])
    for extra_key in ("_standard_block_measured", "standard_block_measured"):
        extra_val = payload.get(extra_key)
        if extra_val not in (None, ""):
            business_record["parameters"].setdefault(extra_key, extra_val)
    return business_record


def _extract_docx_cells(data: bytes) -> list[dict]:
    doc = Document(BytesIO(data))
    cells = []
    for ti, table in enumerate(doc.tables):
        for ri, row in enumerate(table.rows):
            seen = set()
            for ci, cell in enumerate(row.cells):
                if cell._tc in seen:
                    continue
                seen.add(cell._tc)
                cells.append({"t": ti, "r": ri, "c": ci, "x": cell.text.strip()})
    return cells


# ── 捕获 ──────────────────────────────────────────────────────────────
def capture() -> dict:
    manifest: dict = {"records": {}, "mappers": {}, "docx": {}}

    records, tasks = _load_records()
    for record in records:
        task = tasks.get(record.get("task_no"))
        kind = _get_kind(record, task)
        template_name = record.get("record_template_file") or _scan_template(kind)
        key = f"{record['record_no']}@v{record['version']}"

        # 1) mapper 级 values（权威基线）
        if template_name:
            template_path = TEMPLATE_DIR / template_name
            business_record = _build_business_record(record.get("payload") or {})
            context = _build_context(record, task)
            values, touched = apply_controlled_mapping(
                str(template_path), kind, {}, context, business_record, ""
            )
            manifest["records"][key] = {
                "kind": kind,
                "template": template_name,
                "values": {k: values[k] for k in sorted(values)},
                "touched": sorted(touched),
            }
        else:
            manifest["records"][key] = {"kind": kind, "template": "", "values": {}, "touched": []}

        # 2) 端到端 DOCX 逐格文本
        try:
            from app.services.record_word_engine import export_record_docx

            rec = dict(record)
            rec["record_template_file"] = template_name
            docx_bytes = export_record_docx(
                rec, task, template_dir=TEMPLATE_DIR, signature_dir=SIGNATURE_DIR,
            )
            manifest["docx"][key] = _extract_docx_cells(docx_bytes)
        except Exception as e:  # noqa: BLE001
            manifest["docx"][key] = [{"error": f"{type(e).__name__}: {e}"}]

    # 3) 14 个 kind 的合成 payload
    for kind in MAPPERS:
        template_name = _scan_template(kind)
        if not template_name:
            manifest["mappers"][kind] = {"template": "", "values": {}, "touched": []}
            continue
        template_path = TEMPLATE_DIR / template_name
        business_record = synthetic_business_record()
        context = synthetic_context()
        values, touched = apply_controlled_mapping(
            str(template_path), kind, {}, context, business_record, "ATTACH_REF",
        )
        manifest["mappers"][kind] = {
            "template": template_name,
            "values": {k: values[k] for k in sorted(values)},
            "touched": sorted(touched),
        }

    return manifest


def _diff(name: str, golden: dict, current: dict, diffs: list) -> None:
    if golden == current:
        return
    if set(golden.keys()) != set(current.keys()):
        diffs.append(f"{name}: 键集合不一致 (golden {sorted(golden.keys())} vs cur {sorted(current.keys())})")
        return
    for k in sorted(golden.keys()):
        g, c = golden[k], current[k]
        if g == c:
            continue
        if isinstance(g, dict) and isinstance(c, dict):
            for kk in sorted(set(g) | set(c)):
                if g.get(kk) != c.get(kk):
                    diffs.append(f"{name}.{k}.{kk}: {g.get(kk)!r} -> {c.get(kk)!r}")
        else:
            diffs.append(f"{name}.{k}: {g!r} -> {c!r}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compare", action="store_true", help="重新生成并 diff")
    args = parser.parse_args()

    GOLDEN_DIR.mkdir(parents=True, exist_ok=True)
    current = capture()

    if not args.compare:
        MANIFEST.write_text(json.dumps(current, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"✓ 基线已写入 {MANIFEST}")
        print(f"  records: {len(current['records'])} 条, mappers: {len(current['mappers'])} 个, docx: {len(current['docx'])} 份")
        return

    if not MANIFEST.exists():
        print("❌ 未找到基线 manifest.json，请先运行 capture")
        sys.exit(1)
    golden = json.loads(MANIFEST.read_text(encoding="utf-8"))

    diffs: list[str] = []
    _diff("records", golden["records"], current["records"], diffs)
    _diff("mappers", golden["mappers"], current["mappers"], diffs)
    _diff("docx", golden["docx"], current["docx"], diffs)

    if diffs:
        print(f"❌ 存在 {len(diffs)} 处差异：")
        for d in diffs[:200]:
            print("  -", d)
        if len(diffs) > 200:
            print(f"  … 其余 {len(diffs) - 200} 处省略")
        sys.exit(1)
    print("✓ 0 差异：改造后与基线逐格一致")


if __name__ == "__main__":
    main()
