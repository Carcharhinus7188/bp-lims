# -*- coding: utf-8 -*-
from __future__ import annotations
from datetime import datetime
from typing import Any
import pandas as pd
from experiment_schemas import SCHEMAS


def _db_schema(kind: str) -> dict[str, Any] | None:
    """尝试从数据库读取现行版本的实验配置。无配置时返回 None。"""
    try:
        from lims_db import current_full_config
        import json as _json
        cfg = current_full_config(kind)
        if cfg and cfg.get("sections"):
            sections = []
            for sec in cfg["sections"]:
                fields = []
                for f in sec["fields"]:
                    field_def = {
                        "key": f["key"], "label": f["label"], "type": f["type"],
                    }
                    if f.get("default"):
                        field_def["default"] = f["default"]
                    if f.get("options"):
                        field_def["options"] = f["options"]
                    if f.get("readonly"):
                        field_def["readonly"] = True
                    if f.get("actual"):
                        field_def["actual"] = True
                    if f.get("required"):
                        field_def["required"] = True
                    fields.append(field_def)
                sections.append({"title": sec["title"], "fields": fields})
            # 列定义（含默认值、计算表达式、精度）
            columns = []
            _col_defaults: dict[str, Any] = {}
            _col_calcs: list[dict[str, Any]] = []
            for c in (cfg.get("columns") or []):
                key = c["column_key"]
                columns.append((key, c["column_label"], c["column_type"]))
                if c.get("column_default") is not None:
                    _col_defaults[key] = c["column_default"]
                if c.get("calc_expression") and str(c["calc_expression"]).strip():
                    _col_calcs.append({
                        "target": key,
                        "expression": str(c["calc_expression"]).strip(),
                        "precision": int(c.get("calc_precision", 3)),
                    })
            # face_labels 解析
            face_labels_raw = cfg.get("face_labels", "")
            face_labels: list[str] | None = None
            if face_labels_raw and face_labels_raw.startswith("["):
                try:
                    face_labels = _json.loads(face_labels_raw)
                except Exception:
                    pass
            return {
                "title": cfg.get("experiment_name", ""),
                "sections": sections,
                "columns": columns,
                "kind": cfg.get("kind", kind),
                "row_expansion": cfg.get("row_expansion", ""),
                "face_labels": face_labels,
                "_column_defaults": _col_defaults,
                "_column_calcs": _col_calcs,
                "_result_title": cfg.get("result_title", ""),
                "_result_unit": cfg.get("result_unit", ""),
                "_result_value_key": cfg.get("result_value_key", ""),
                "_result_face_suffix": bool(cfg.get("result_face_suffix", 0)),
                "_obsolete_param_keys": cfg.get("obsolete_param_keys", ""),
                "_db_cfg": cfg,
            }
    except Exception:
        pass
    return None


def schema(kind: str) -> dict[str, Any]:
    db_cfg = _db_schema(kind)
    if db_cfg:
        return db_cfg
    return SCHEMAS.get(kind) or SCHEMAS["generic"]


def initial_parameters(kind: str, preset: dict[str, Any] | None = None, detection_location: str = "") -> dict[str, Any]:
    values: dict[str, Any] = {}
    for section in schema(kind)["sections"]:
        for field in section["fields"]:
            key = field["key"]
            default = field.get("default", "")
            if key == "detection_location":
                default = detection_location
            values[key] = default
    if preset:
        for key, value in preset.items():
            if value not in (None, ""):
                values[key] = value
    return values


def initial_rows(kind: str, sample_ids: list[str]) -> list[dict[str, Any]]:
    ids = sample_ids or [""]
    s = schema(kind)
    columns = s["columns"]
    rows: list[dict[str, Any]] = []
    # 行扩展模式：优先 DB face_labels，回落硬编码
    if s.get("row_expansion") == "faces":
        face_labels = s.get("face_labels")
        if not face_labels:
            face_labels = ["Z轴方向", "X轴方向"] if kind == "hv" else ["面1", "面2"]
        for sid in ids:
            for face in face_labels:
                row = {key: _default_for_column(kind, key, ctype) for key, _, ctype in columns}
                row["sample_no"] = sid
                row["face"] = face
                rows.append(row)
    else:
        for sid in ids:
            row = {key: _default_for_column(kind, key, ctype) for key, _, ctype in columns}
            row["sample_no"] = sid
            rows.append(row)
    return calculate_rows(kind, rows)


def normalize_rows(kind: str, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Upgrade saved rows to the current controlled schema without losing readings."""
    normalized = [dict(row) for row in rows]
    if kind != "hv":
        return normalized
    per_sample: dict[str, int] = {}
    for row in normalized:
        sample_no = str(row.get("sample_no") or "")
        position = per_sample.get(sample_no, 0)
        current = str(row.get("face") or "")
        if position == 0 or current in {"面1", "Z", "Z方向"}:
            row["face"] = "Z轴方向"
        elif current not in {"X轴方向", "Y轴方向"}:
            row["face"] = "X轴方向"
        row.pop("surface_confirm", None)
        row.pop("conclusion", None)
        per_sample[sample_no] = position + 1
    return normalized


def _default_for_column(kind: str, key: str, ctype: str) -> Any:
    # 1) 优先从数据库配置读取列默认值
    db_s = _db_schema(kind)
    if db_s and db_s.get("_column_defaults"):
        val = db_s["_column_defaults"].get(key)
        if val is not None:
            return val
    # 2) 回落到硬编码默认值
    if ctype == "number" or ctype == "calc":
        defaults = {
            ("rough", "limit"): 15.0,
            ("warp", "limit"): 0.5,
            ("bend", "length"): 25.0,
            ("bend", "width"): 2.0,
            ("bend", "height"): 2.0,
            ("bend", "span"): 20.0,
            ("bend", "speed"): 1.0,
            ("cte", "t1"): 25.0,
            ("cte", "t2"): 550.0,
        }
        return defaults.get((kind, key))
    if ctype.startswith("select:"):
        options = ctype.split(":", 1)[1].split("|")
        return options[0] if options else ""
    return ""


def columns_for_editor(kind: str) -> list[dict[str, str]]:
    return [{"key": key, "label": label, "type": ctype} for key, label, ctype in schema(kind)["columns"]]


def dataframe(kind: str, rows: list[dict[str, Any]]) -> pd.DataFrame:
    cols = [x[0] for x in schema(kind)["columns"]]
    return pd.DataFrame(rows)[cols]


def calculate_rows(kind: str, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    # 从数据库配置读取计算表达式
    db_calcs: list[dict[str, Any]] = []
    db_s = _db_schema(kind)
    if db_s:
        db_calcs = db_s.get("_column_calcs") or []

    for raw in normalize_rows(kind, rows):
        row = dict(raw)
        try:
            # ---- 硬编码计算逻辑（回退安全网）----
            if kind == "mc_crack":
                vals = [_number_or_none(row.get("dm1")), _number_or_none(row.get("dm2")), _number_or_none(row.get("dm3"))]
                row["dm_mean"] = round(sum(vals) / 3, 4) if all(v is not None for v in vals) else None
                k_value, fail_value = _number_or_none(row.get("k")), _number_or_none(row.get("ffail"))
                row["tau"] = round(k_value * fail_value, 2) if k_value is not None and fail_value is not None else None
                row["conclusion"] = ("符合" if row["tau"] > 25 else "不符合") if row["tau"] is not None else ""
            elif kind == "rough":
                vals = [_number_or_none(row.get("ra1")), _number_or_none(row.get("ra2")), _number_or_none(row.get("ra3"))]
                row["mean"] = round(sum(vals) / 3, 3) if all(v is not None for v in vals) else None
                row["conclusion"] = ("符合" if row["mean"] <= _num(row.get("limit"), 15) else "不符合") if row["mean"] is not None else ""
            elif kind == "xray":
                roi_means = []
                for roi in range(1, 4):
                    values = [_number_or_none(row.get(f"roi{roi}_reading{reading}")) for reading in range(1, 4)]
                    legacy = _number_or_none(row.get(f"roi{roi}"))
                    roi_mean = round(sum(values) / 3, 2) if all(value is not None for value in values) else legacy
                    row[f"roi{roi}"] = roi_mean
                    roi_means.append(roi_mean)
                row["roi_mean"] = round(sum(roi_means) / 3, 2) if all(value is not None for value in roi_means) else None
            elif kind == "warp":
                h1, h2 = _number_or_none(row.get("h1")), _number_or_none(row.get("h2"))
                row["delta"] = round(h1 - h2, 4) if h1 is not None and h2 is not None else None
                row["conclusion"] = ("合格" if abs(row["delta"]) <= _num(row.get("limit"), .5) else "不合格") if row["delta"] is not None else ""
            elif kind == "cte":
                t1, t2 = _number_or_none(row.get("t1")), _number_or_none(row.get("t2"))
                row["delta_t"] = round(t2 - t1, 3) if t1 is not None and t2 is not None else None
                l0, dt, delta_l = _number_or_none(row.get("l0")), _number_or_none(row.get("delta_t")), _number_or_none(row.get("delta_l"))
                row["alpha"] = round((delta_l / 1000.0) / (l0 * dt) * 1_000_000, 3) if l0 and dt and delta_l is not None else None
                row["conclusion"] = row.get("judgement_result") or ""
            elif kind == "shock":
                row["conclusion"] = "符合" if all(str(row.get(k, "无")) == "无" for k in ("crack", "chipping", "fracture")) else "不符合"
            elif kind == "bend":
                row["conclusion"] = "符合" if _num(row.get("stress_02")) >= 800 else "不符合"
            elif kind == "hv":
                vals = [_number_or_none(row.get("indent1")), _number_or_none(row.get("indent2")), _number_or_none(row.get("indent3"))]
                row["mean"] = round(sum(vals) / 3, 1) if all(v is not None for v in vals) else None
            elif kind == "thickness":
                groups = {}
                for section in ("fixed", "middle", "free"):
                    keys = [f"r{repeat}_{section}_p{point}" for repeat in range(1, 4) for point in range(1, 4)]
                    vals = [_number_or_none(row.get(key)) for key in keys]
                    groups[section] = vals
                    row[f"{section}_mean"] = round(sum(vals) / len(vals), 4) if all(v is not None for v in vals) else None
                all_values = [value for values in groups.values() for value in values]
                row["mean"] = round(sum(all_values) / len(all_values), 4) if all(v is not None for v in all_values) else None
                design = _number_or_none(row.get("design_thickness"))
                if design is None:
                    design = _number_or_none(row.get("_design_thickness"))
                row["deviation"] = round(row["mean"] - design, 4) if row["mean"] is not None and design is not None else None
                row["conclusion"] = ("符合" if abs(row["deviation"]) <= 0.05 else "不符合") if row["deviation"] is not None else ""
            elif kind == "color":
                observations = [row.get("observer1"), row.get("observer2"), row.get("observer3")]
                severe = sum(x == "明显差异" for x in observations)
                unable = sum(x == "无法判定" for x in observations)
                row["overall"] = "无法判定" if unable >= 2 else ("明显差异" if severe >= 2 else "未见明显差异/轻微差异")
                row["conclusion"] = "不符合" if severe >= 2 else ("需复核" if unable >= 2 else "符合")
        except Exception:
            pass

        # ---- 数据库驱动的计算表达式（覆盖/补充硬编码）----
        for calc in db_calcs:
            try:
                target = calc["target"]
                expr = calc["expression"]
                precision = int(calc.get("precision", 3))
                # 构建安全求值环境：row 值 + 内置函数
                _env = {
                    **{k: v for k, v in row.items()},
                    "row": row,
                    "round": round, "abs": abs, "sum": sum, "min": min, "max": max,
                    "str": str, "float": float, "int": int, "len": len, "bool": bool,
                    "all": all, "any": any,
                    "None": None, "True": True, "False": False,
                }
                val = eval(expr, {"__builtins__": {}}, _env)
                if val is not None:
                    row[target] = val
            except Exception:
                pass
        result.append(row)
    return result


def _num(value: Any, default: float = 0.0) -> float:
    try:
        if value in (None, ""):
            return float(default)
        return float(value)
    except Exception:
        return float(default)


def _number_or_none(value: Any) -> float | None:
    if value in (None, ""):
        return None
    try:
        return float(value)
    except Exception:
        return None


def result_summary(kind: str, rows: list[dict[str, Any]]) -> tuple[str, str]:
    rows = calculate_rows(kind, rows)
    conclusions = [str(x.get("conclusion", "")) for x in rows if x.get("conclusion")]
    if conclusions and all(x in ("符合", "合格") for x in conclusions):
        overall = "符合"
    elif any(x in ("不符合", "不合格") for x in conclusions):
        overall = "不符合"
    elif conclusions:
        overall = "；".join(dict.fromkeys(conclusions))
    else:
        overall = "仅描述结果"

    # 优先从数据库读取结果标签配置
    db_s = _db_schema(kind)
    if db_s and db_s.get("_result_title"):
        title = db_s["_result_title"]
        unit = db_s["_result_unit"]
        value_key = db_s["_result_value_key"]
        face_suffix = db_s["_result_face_suffix"]
    else:
        labels = {
            "rough": ("平均Ra", "μm", "mean"),
            "mc_crack": ("结合强度", "MPa", "tau"),
            "xray": ("ROI平均灰度", "", "roi_mean"),
            "warp": ("翘曲变化量ΔH", "mm", "delta"),
            "cte": ("线膨胀系数α", "×10⁻⁶/K", "alpha"),
            "bend": ("0.2%规定非比例弯曲应力", "MPa", "stress_02"),
            "hv": ("平均维氏硬度", "HV10", "mean"),
            "thickness": ("平均厚度", "mm", "mean"),
            "color": ("目视比较结果", "", "overall"),
            "shock": ("耐急冷急热结果", "", "conclusion"),
        }
        title, unit, value_key = labels.get(kind, ("检验结果", "", "calculated_value"))
        face_suffix = (kind == "hv")

    summary_parts = []
    for row in rows:
        sid = row.get("sample_no", "")
        if face_suffix and row.get("face"):
            sid = f"{sid}-{row.get('face')}"
        value = row.get(value_key)
        if value not in (None, ""):
            summary_parts.append(f"{sid}：{title}{_display_number(value)}{unit}")
    if not summary_parts:
        return "尚未形成有效检验结果", overall
    return "；".join(summary_parts), overall


def _display_number(value: Any) -> str:
    if isinstance(value, float):
        return f"{value:.6f}".rstrip("0").rstrip(".")
    return str(value)
