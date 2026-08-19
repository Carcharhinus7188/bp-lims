"""原始记录 API — 完整复核流程"""
from __future__ import annotations

import json
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.deps import get_current_user, get_db, require_role
from app.core.calc_formulas import rules_from_columns
from app.core.calc_engine import evaluate_rules
from app.core.encoding_rules import china_today
from app.services.audit_service import write_audit_log, log_operation, log_modification

router = APIRouter(prefix="/records", tags=["原始记录"])


class RecordBrief(BaseModel):
    record_no: str
    task_no: str
    version: int
    experiment: str | None
    status: str
    owner: str | None
    owner_name: str | None = None
    created_at: str | None


# ═══════════════════════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════════════════════

def _report_no_for_task(task_no: str) -> str:
    """报告编号 = R + task_no去掉BP前缀"""
    return "R" + task_no[2:] if task_no.startswith("BP") else f"R{task_no}"


def _correction_report_no(supersedes_report_no: str) -> str:
    """由被更正的报告号派生更正报告号：R…-T01 → R…-T01-V2 → R…-T01-V3"""
    import re as _re
    m = _re.match(r"^(.*)-V(\d+)$", supersedes_report_no)
    if m:
        return f"{m.group(1)}-V{int(m.group(2)) + 1}"
    return f"{supersedes_report_no}-V2"


async def _display_names(db: AsyncSession, usernames: set[str]) -> dict[str, str]:
    """批量解析 username → display_name（姓名），未命中时回退到账号名本身。"""
    uniq = {u for u in usernames if u}
    if not uniq:
        return {}
    placeholders = ", ".join(f":u{i}" for i in range(len(uniq)))
    params = {f"u{i}": u for i, u in enumerate(uniq)}
    result = await db.execute(
        text(f"SELECT username, display_name FROM users WHERE username IN ({placeholders})"),
        params,
    )
    return {uname: (dname or uname) for uname, dname in result.fetchall()}


async def _load_commission_context(task: dict | None, db: AsyncSession) -> tuple[dict, list, list]:
    """根据任务加载委托 + 样品组 + 样品数据，用于原始记录模板头部填充"""
    commission: dict = {}
    groups: list = []
    samples: list = []
    if not task:
        return commission, groups, samples
    cn = task.get("commission_no", "")
    if cn:
        c_result = await db.execute(text("SELECT * FROM commissions WHERE commission_no=:c"), {"c": cn})
        c_row = c_result.fetchone()
        if c_row:
            commission = dict(zip(c_result.keys(), c_row))
        g_result = await db.execute(
            text("SELECT * FROM sample_groups WHERE commission_no=:c ORDER BY group_no"), {"c": cn}
        )
        groups = [dict(zip(g_result.keys(), r)) for r in g_result.fetchall()]
        s_result = await db.execute(
            text("SELECT * FROM samples WHERE commission_no=:c ORDER BY sample_no"), {"c": cn}
        )
        samples = [dict(zip(s_result.keys(), r)) for r in s_result.fetchall()]
    return commission, groups, samples


async def _ensure_report_for_task(task_no: str, db: AsyncSession) -> str | None:
    """复核通过后自动生成检验报告初稿（状态=待质量审核）"""
    # 查任务信息
    task_result = await db.execute(
        text("""
            SELECT t.commission_no, t.experiment, t.assignee, t.reviewer,
                   t.quality_inspector, t.package_no
            FROM tasks t
            WHERE t.task_no = :t
        """),
        {"t": task_no},
    )
    task_row = task_result.fetchone()
    if not task_row:
        return None

    # 查最新锁定记录
    locked = await db.execute(
        text("""
            SELECT version, template_version, sop_version, payload
            FROM records
            WHERE record_no = :r AND status = '已锁定'
            ORDER BY version DESC LIMIT 1
        """),
        {"r": task_no},
    )
    locked_row = locked.fetchone()
    if not locked_row:
        return None

    # 查是否有已存在的报告（支持更正：已作废的报告可生成新版本）
    existing = await db.execute(
        text("SELECT report_no, status FROM reports WHERE task_no = :t ORDER BY created_at DESC, report_no DESC"),
        {"t": task_no},
    )
    existing_rows = existing.fetchall()
    existing_row = existing_rows[0] if existing_rows else None
    supersedes_report_no: str | None = None

    # 查管理员作为默认批准人
    admin_result = await db.execute(
        text("SELECT username FROM users WHERE role = '管理员' AND enabled = TRUE ORDER BY username LIMIT 1")
    )
    admin_row = admin_result.fetchone()
    approver_username = admin_row[0] if admin_row else ""

    # 查质量负责人（从tasks表）
    quality_inspector = task_row[4] or ""

    source_versions = json.dumps({
        task_no: locked_row[0],
        "record_template": locked_row[1] or "",
        "sop": locked_row[2] or "",
    }, ensure_ascii=False)

    payload = locked_row[3] if isinstance(locked_row[3], dict) else (json.loads(locked_row[3]) if locked_row[3] else {})

    if existing_row:
        # 已有报告：如果是退回状态，重置为待质量审核
        if existing_row[1] in ("质量退回", "复核退回"):
            await db.execute(
                text("""
                    UPDATE reports SET status = '待质量审核',
                        source_versions = :sv,
                        conclusion = :conc, notes = :notes,
                        updated_at = localtimestamp
                    WHERE report_no = :r
                """),
                {
                    "sv": source_versions,
                    "conc": payload.get("report_conclusion", ""),
                    "notes": payload.get("report_summary", ""),
                    "r": existing_row[0],
                },
            )
            await db.execute(
                text("""
                    INSERT INTO report_actions (report_no, actor, action, comment, created_at)
                    VALUES (:r, 'system', '根据新记录版本重生成初稿', :c, localtimestamp)
                """),
                {"r": existing_row[0], "c": f"原始记录V{locked_row[0]}"},
            )
            await write_audit_log(db, "report", existing_row[0], "system", "根据新记录版本重生成初稿",
                                  comment=f"原始记录V{locked_row[0]}")
            return existing_row[0]
        if existing_row[1] == "已作废":
            supersedes_report_no = existing_row[0]  # 更正重签：生成新版本
        else:
            return existing_row[0]

    # 新建报告
    report_no = _correction_report_no(supersedes_report_no) if supersedes_report_no else _report_no_for_task(task_no)

    await db.execute(
        text("""
            INSERT INTO reports (
                report_no, commission_no, task_no, status,
                tester, verifier, quality_inspector, approver,
                source_versions, report_category, sample_statement,
                conclusion, notes, supersedes_report_no, created_at, updated_at
            ) VALUES (
                :rn, :cn, :tn, '待质量审核',
                :tr, :vf, :qi, :ap,
                :sv, '委托检验', '',
                :conc, :notes, :sn, localtimestamp, localtimestamp
            )
        """),
        {
            "rn": report_no, "cn": task_row[0], "tn": task_no,
            "tr": task_row[2] or "",
            "vf": task_row[3] or "", "qi": quality_inspector,
            "ap": approver_username,
            "sv": source_versions,
            "conc": payload.get("report_conclusion", ""),
            "notes": payload.get("report_summary", ""),
            "sn": supersedes_report_no,
        },
    )

    await db.execute(
        text("""
            INSERT INTO report_actions (report_no, actor, action, comment, created_at)
            VALUES (:r, 'system', '自动生成报告初稿', '原始记录复核通过后自动生成', localtimestamp)
        """),
        {"r": report_no},
    )
    await write_audit_log(db, "report", report_no, "system", "自动生成报告初稿",
                          comment="原始记录复核通过后自动生成")

    return report_no


# ═══════════════════════════════════════════════════════════════
# API 端点
# ═══════════════════════════════════════════════════════════════

# ── 保存原始记录 ──

class SaveRecordRequest(BaseModel):
    task_no: str
    business_record: dict[str, Any] = {}
    report_summary: str = ""
    report_conclusion: str = ""
    tester_self_check: bool = False
    submit_for_review: bool = False


async def _validate_required_photos(
    db: AsyncSession, task_no: str, experiment_code: str, business_record: dict
) -> None:
    """提交复核前校验必拍照片数量（拍照点 × 样品数），防绕过前端"""
    from app.api.v1.experiment_config import _get_photo_checkpoints, _resolve_kind

    # 样品数量（tasks.sample_nos 为逗号分隔）
    sample_count = 1
    sr = (await db.execute(
        text("SELECT sample_nos FROM tasks WHERE task_no=:t"), {"t": task_no}
    )).fetchone()
    if sr and sr[0]:
        sample_count = max(1, len([s for s in sr[0].split(",") if s.strip()]))

    # 拍照节点配置（DB 现行版本优先，缺省回退硬编码）
    cps: list[dict] = []
    cid = (await db.execute(
        text("""SELECT id FROM experiment_config_versions
                WHERE experiment_code=:ec AND status='现行'
                ORDER BY effective_date DESC LIMIT 1"""),
        {"ec": experiment_code},
    )).fetchone()
    if cid:
        rows = (await db.execute(
            text("""SELECT checkpoint_code, checkpoint_label, is_required, is_sample_level
                    FROM experiment_config_photo_checkpoints
                    WHERE config_id=:cid ORDER BY sort_order"""),
            {"cid": cid[0]},
        )).fetchall()
        for r in rows:
            cps.append({
                "code": r[0], "label": r[1] or r[0],
                "required": bool(r[2]) if isinstance(r[2], bool) else (r[2] is not False),
                "is_sample_level": bool(r[3]),
            })
    if not cps:
        kind = _resolve_kind(experiment_code) or experiment_code
        cps = [{
            "code": c.get("code") or c.get("checkpoint_code", ""),
            "label": c.get("label") or c.get("checkpoint_label", c.get("code", "")),
            "required": c.get("required", True) is not False,
            "is_sample_level": bool(c.get("is_sample_level", False)),
        } for c in _get_photo_checkpoints(kind)]

    # 任务确认现场照：所有试验的必拍任务级节点（需求 14）
    cps.append({"code": "TASK_CONFIRM", "label": "任务确认现场照", "required": True, "is_sample_level": False})

    photos = business_record.get("_photos") or []
    photo_map = {p.get("code"): p for p in photos if isinstance(p, dict) and p.get("code")}
    task_confirm_photo = business_record.get("_task_confirm_photo") or ""

    missing: list[str] = []
    for cp in cps:
        if not cp.get("required"):
            continue
        entry = photo_map.get(cp["code"])
        if cp["code"] == "TASK_CONFIRM":
            have = 1 if task_confirm_photo else 0
            need = 1
        elif cp.get("is_sample_level"):
            have = len((entry or {}).get("samples") or []) if entry else 0
            need = sample_count
        else:
            have = 1 if (entry and (entry.get("previewUrl") or entry.get("file"))) else 0
            need = 1
        if have < need:
            missing.append(f"{cp['label']}（需 {need} 张，实拍 {have} 张）")

    if missing:
        raise HTTPException(status_code=400, detail="必拍照片未完成：" + "；".join(missing))


async def _validate_equipment_gate(db: AsyncSession, business_record: dict) -> None:
    """提交复核前校验设备启用/校准有效期门禁（Track 8）。

    - 停用（enabled=FALSE）设备一律阻断；
    - 校准有效期（calibration_due）已过期且可解析为日期的阻断；
    - 校准有效期缺失/不可解析的存量数据不阻断（避免存量卡死）。
    """
    from datetime import date as _date

    checks = business_record.get("_equipment_checks") or []
    if not isinstance(checks, list):
        return

    blocked: list[str] = []
    seen: set[str] = set()
    for eq in checks:
        if not isinstance(eq, dict):
            continue
        mgmt = (eq.get("management_no") or "").strip()
        if not mgmt or mgmt in seen:
            continue
        seen.add(mgmt)
        row = (await db.execute(
            text("SELECT equipment_name, enabled, calibration_due FROM equipment_registry WHERE management_no=:m"),
            {"m": mgmt},
        )).fetchone()
        if not row:
            continue  # 未登记设备不阻断（辅助/临时设备）
        name = row[0] or mgmt
        enabled = bool(row[1]) if row[1] is not None else True
        due = (row[2] or "").strip()
        if not enabled:
            blocked.append(f"{name}（{mgmt}）已停用")
            continue
        if due:
            d = None
            try:
                d = _date.fromisoformat(due[:10])
            except (ValueError, TypeError):
                d = None
            if d is not None and d < china_today():
                blocked.append(f"{name}（{mgmt}）校准有效期至 {due} 已过期")

    if blocked:
        raise HTTPException(status_code=400, detail="设备启用/校准期门禁未通过：" + "；".join(blocked))


# 后端完整性检查可选键集合（镜像前端 ExperimentRun.vue 的 OPTIONAL_* / AUTO_ROW_KEYS）
_OPTIONAL_PARAMETER_KEYS = frozenset([
    "cutoff_filter", "measurement_direction", "zero_force", "atmosphere",
    "pv_range", "objective", "magnification", "calibration_scale",
    "observer_1", "observer_2", "observer_3", "lamp_no", "lamp_hours",
    "filter_no", "filter_hours", "background", "sample_preparation",
    "procedure_summary", "acceptance_criteria", "test_conditions",
    "spindle_speed", "metal_batch", "em_source_file", "parallel_block_no",
] + [f"monitor_{p}_note" for p in range(1, 6)]
  + [f"color_monitor_{p}_note" for p in range(1, 7)])

_OPTIONAL_ROW_KEYS = frozenset([
    "position", "note", "crack_position", "thickness_relation",
    "estimated_thickness", "defect", "edge_condition", "control_no",
    "shape", "size", "cover_method", "cover_direction", "measurement_item",
    "unit", "calculated_value", "retest_mean", "failure_mode", "retake",
    "cut_start", "cut_end",
])

_AUTO_ROW_KEYS = frozenset([
    "file_no", "curve_no", "image_no", "photo_no", "image_path", "data_path",
])


async def _validate_completeness(db: AsyncSession, experiment_code: str, record: dict) -> None:
    """提交复核前完整性检查（Track 9）：required 字段/列非空、判定结论已算、环境记录齐全。

    与前端 validate_business_record 语义对齐，但只做无歧义的结构性校验，
    避免对「全部可编辑字段」的过度收紧导致存量/边缘记录误阻断。
    """
    from app.api.v1.experiment_config import _resolve_kind

    issues: list[str] = []
    kind = _resolve_kind(experiment_code) or experiment_code

    # 1) 任务与样品确认
    tc = record.get("_task_confirmations") or {}
    if isinstance(tc, dict):
        for k, label in (("sample_received", "样品已收到"), ("number_match", "样品编号一致"), ("sample_condition", "样品状态正常")):
            if not tc.get(k):
                issues.append(f"任务与样品确认未完成：{label}")

    # 2) 原始数据行非空
    rows = record.get("_rows")
    if not isinstance(rows, list) or not rows:
        issues.append("原始测量数据为空")

    form = record.get("_form") or {}
    if not isinstance(form, dict):
        form = {}

    # 3) 环境记录：非 cte 需起止时间；cte 需升温速率在 5±1 ℃/min
    if kind != "cte":
        if not str(form.get("start_time", "") or "").strip():
            issues.append("尚未记录实验开始时间")
        if not str(form.get("end_time", "") or "").strip():
            issues.append("尚未记录实验结束时间")
    else:
        hr = form.get("heating_rate")
        try:
            hr_v = float(hr)
        except (TypeError, ValueError):
            hr_v = None
        if hr_v is None or not (4.0 <= hr_v <= 6.0):
            issues.append("升温速率应在 5±1 ℃/min 范围内")

    # 4) 加载现行配置字段/列
    fields: list[dict] = []
    cols: list[dict] = []
    cid = (await db.execute(
        text("""SELECT id FROM experiment_config_versions
                WHERE experiment_code=:ec AND status='现行'
                ORDER BY effective_date DESC LIMIT 1"""),
        {"ec": experiment_code},
    )).fetchone()
    if cid:
        for r in (await db.execute(
            text("""SELECT field_key, field_label, is_required, is_readonly, field_default
                    FROM experiment_config_fields WHERE config_id=:cid"""),
            {"cid": cid[0]},
        )).fetchall():
            fields.append({"key": r[0], "label": r[1], "required": bool(r[2]),
                           "readonly": bool(r[3]), "default": r[4]})
        for r in (await db.execute(
            text("""SELECT column_key, column_label, column_type, calc_expression, sort_order
                    FROM experiment_config_columns WHERE config_id=:cid"""),
            {"cid": cid[0]},
        )).fetchall():
            cols.append({"key": r[0], "label": r[1], "type": r[2], "expr": r[3], "sort": r[4]})

    # 5) required 字段非空（有默认值/只读/可选 不校验）
    for f in fields:
        if not f["required"] or f["readonly"] or f["key"] in _OPTIONAL_PARAMETER_KEYS:
            continue
        d = f.get("default")
        if d is not None and str(d).strip() not in ("", "null", "{}", "[]"):
            continue  # 有默认值 → 前端已自动填充，不视为缺失
        val = form.get(f["key"])
        if val is None or (isinstance(val, str) and not val.strip()):
            issues.append(f"未填写：{f['label']}")

    # 6) 每行：输入列非空 + 计算列（判定/结论）已算
    calc_keys = {r["column_key"] for r in rules_from_columns(cols)}
    if isinstance(rows, list):
        for i, row in enumerate(rows):
            if not isinstance(row, dict):
                continue
            sid = row.get("sample_no") or f"第{i + 1}条"
            for col in cols:
                ck = col["key"]
                if not ck or ck == "sample_no" or ck == "note" or ck.startswith("_"):
                    continue
                if ck in _AUTO_ROW_KEYS or ck in _OPTIONAL_ROW_KEYS:
                    continue
                val = row.get(ck)
                empty = val is None or (isinstance(val, str) and not val.strip())
                if ck in calc_keys:
                    if empty:
                        issues.append(f"{sid} 判定/结论未计算：{col['label']}")
                elif empty:
                    issues.append(f"{sid} 未填写：{col['label']}")

    # 7) 结果摘要
    summary = record.get("report_summary") or record.get("_report_summary")
    if not summary or not str(summary).strip():
        issues.append("检验结果摘要尚未形成")

    # 8) 异常一致性
    if record.get("_overall_status") == "存在异常" and not str(record.get("_deviation") or "").strip():
        issues.append("标记存在异常但未填写偏离说明")

    if issues:
        raise HTTPException(status_code=400, detail="完整性检查未通过：" + "；".join(issues))


def _diff_record_payload(old: dict | None, new: dict) -> list[tuple[str, str | None, str | None]]:
    """逐字段比较旧/新记录 payload，返回 [(field_path, old, new), ...] 用于字段级追溯"""
    if not old:
        return []
    diffs: list[tuple[str, str | None, str | None]] = []

    def _norm(v):
        if v is None:
            return None
        if isinstance(v, (dict, list)):
            return json.dumps(v, ensure_ascii=False, default=str)
        if isinstance(v, bool):
            return "是" if v else "否"
        return str(v)

    # 顶层标量字段
    scalar_keys = {"report_summary", "report_conclusion", "tester_self_check",
                   "_overall_status", "_deviation", "_retest", "_fixed_param_mode",
                   "_precheck_note", "_change_reason", "_task_confirm_photo",
                   "_report_summary", "_report_conclusion"}
    for k in scalar_keys:
        ov, nv = _norm(old.get(k)), _norm(new.get(k))
        if ov != nv:
            diffs.append((k, ov, nv))

    # _form 字段
    old_form = old.get("_form") or {}
    new_form = new.get("_form") or {}
    for k in sorted(set(old_form) | set(new_form)):
        ov, nv = _norm(old_form.get(k)), _norm(new_form.get(k))
        if ov != nv:
            diffs.append((f"_form.{k}", ov, nv))

    # _rows 逐行逐列
    old_rows = old.get("_rows") or []
    new_rows = new.get("_rows") or []
    for i in range(max(len(old_rows), len(new_rows))):
        orow = old_rows[i] if i < len(old_rows) else {}
        nrow = new_rows[i] if i < len(new_rows) else {}
        for k in sorted(set(orow) | set(nrow)):
            if k.startswith("_") and k != "_showNote":
                continue
            ov, nv = _norm(orow.get(k)), _norm(nrow.get(k))
            if ov != nv:
                diffs.append((f"_rows[{i}].{k}", ov, nv))

    return diffs


# 字段级编辑门禁：复核退回后仅允许修改复核员指定步骤的字段
_STEP_OF_KEY = {
    "_task_confirmations": "①任务与样品确认",
    "_equipment_checks": "②设备与实验前检查",
    "_prechecks": "②设备与实验前检查",
    "_precheck_note": "②设备与实验前检查",
    "_precheck_all_items": "②设备与实验前检查",
    "_form": "③环境与参数",
    "_fixed_param_mode": "③环境与参数",
    "_rows": "④原始数据",
    "_template_fields": "⑤母版过程确认",
    "_overall_status": "⑦实验员自查",
    "_deviation": "⑦实验员自查",
    "_retest": "⑦实验员自查",
    "_report_summary": "⑦实验员自查",
    "_report_conclusion": "⑦实验员自查",
    "_tester_self_check": "⑦实验员自查",
}

# 这些键不参与门禁（后端权威值 / 运行时元数据 / 照片往返不稳定）
_UNGATED_KEYS = {
    "_photos", "_task_confirm_photo", "_standard_block_measured",
    "_change_reason", "_equipment_meta",
    "report_summary", "report_conclusion", "tester_self_check",
}


def _rows_comparable(rows):
    """剥离 _rows 中的运行时键（_showNote/_index 等），只比较业务数据列。"""
    if not isinstance(rows, list):
        return rows
    out = []
    for r in rows:
        if isinstance(r, dict):
            out.append({k: v for k, v in r.items() if not str(k).startswith("_")})
        else:
            out.append(r)
    return out


def _value_changed(key, old, new) -> bool:
    """比较单个顶层字段是否变化（_rows 剥离运行时键后比较）。"""
    if key == "_rows":
        old = _rows_comparable(old)
        new = _rows_comparable(new)
    return json.dumps(old, ensure_ascii=False, sort_keys=True, default=str) != \
           json.dumps(new, ensure_ascii=False, sort_keys=True, default=str)


async def recompute_calc_rows(
    db: AsyncSession, experiment_code: str, rows: list[dict]
) -> list[dict]:
    """后端权威计算：按当前配置版本的计算列公式重算 _rows 计算列。

    无配置版本 / 无公式时原样返回（不臆造行为，保证与改造前逐格一致）。
    """
    if not rows:
        return rows
    cid = (await db.execute(
        text("""SELECT id FROM experiment_config_versions
                WHERE experiment_code=:ec AND status='现行'
                ORDER BY effective_date DESC LIMIT 1"""),
        {"ec": experiment_code},
    )).fetchone()
    if not cid:
        return rows
    col_rows = (await db.execute(
        text("""SELECT column_key, column_type, calc_expression, sort_order
                FROM experiment_config_columns
                WHERE config_id=:cid ORDER BY sort_order"""),
        {"cid": cid[0]},
    )).fetchall()
    columns = [{
        "column_key": r[0],
        "column_type": r[1],
        "calc_expression": r[2],
        "sort_order": r[3],
    } for r in col_rows]
    rules = rules_from_columns(columns)
    if not rules:
        return rows
    return evaluate_rules(rules, rows)


@router.post("")
async def save_record(
    body: SaveRecordRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("实验员"))],
):
    """保存/提交原始记录"""
    # 验证任务存在且属于当前用户
    task_result = await db.execute(
        text("SELECT experiment, experiment_code, assignee, status FROM tasks WHERE task_no=:t"),
        {"t": body.task_no},
    )
    task = task_result.fetchone()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    if task[2] != user["username"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只能提交自己的实验记录")

    # ── 异议证据冻结（Track 10）：存在进行中客户异议的任务，其原始记录冻结不可再改 ──
    active_obj = await db.execute(
        text("""SELECT 1 FROM objections o
                JOIN reports r ON r.report_no = o.report_no
                WHERE r.task_no = :t AND o.status != '已归档' LIMIT 1"""),
        {"t": body.task_no},
    )
    if active_obj.fetchone():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该任务存在进行中的客户异议，原始记录已冻结，暂不能修改",
        )

    record_no = body.task_no

    # 查当前最大版本号及最新记录状态
    ver_result = await db.execute(
        text("SELECT COALESCE(MAX(version), 0) FROM records WHERE record_no=:r"),
        {"r": record_no},
    )
    max_version = ver_result.fetchone()[0]

    prev_status = None
    prev_payload: dict | None = None
    if max_version > 0:
        prev = await db.execute(
            text("SELECT status, id, payload FROM records WHERE record_no=:r AND version=:v"),
            {"r": record_no, "v": max_version},
        )
        prev_row = prev.fetchone()
        if prev_row:
            prev_status = prev_row[0]
            prev_id = prev_row[1]
            prev_payload = prev_row[2] if isinstance(prev_row[2], dict) else (json.loads(prev_row[2]) if prev_row[2] else None)

    # ── 版本号规则 ──
    # 草稿反复保存 → 同一版本 (UPDATE)，不升版
    # 退回后由 review_record 创建新草稿版本 → 用户在该版本上反复保存仍为同一版本
    # 只有 review_record 的退回操作才触发升版

    # 检查历史上是否有退回记录（用于 change_reason / new_status 判定）
    was_rejected = False
    if max_version > 0:
        rejected_check = await db.execute(
            text("SELECT 1 FROM records WHERE record_no=:r AND status IN ('复核退回','质量退回') LIMIT 1"),
            {"r": record_no},
        )
        was_rejected = rejected_check.fetchone() is not None

    if max_version > 0 and prev_status == "草稿":
        version = max_version       # 覆盖当前草稿（含复核退回后由 review_record 创建的新草稿）
    else:
        version = max_version + 1 if max_version > 0 else 1

    if body.submit_for_review:
        if prev_status in ("复核退回", "质量退回"):
            new_status = "更正待复核"
        elif version > 1:
            new_status = "更正待复核"
        else:
            new_status = "待复核"
    else:
        new_status = "草稿"

    # 提交复核前校验必拍照片数量（拍照点 × 样品数）
    if body.submit_for_review:
        await _validate_required_photos(db, body.task_no, task[1], body.business_record)
        await _validate_equipment_gate(db, body.business_record)

    # 将报告摘要/结论/自检标记合并到 business_record 中，统一存入 payload
    merged_record = dict(body.business_record)

    # 后端权威计算：按配置公式重算测量行计算列（判定字段由比较算子生成，实验员不可手改）
    _rows = merged_record.get("_rows")
    if isinstance(_rows, list) and _rows:
        merged_record["_rows"] = await recompute_calc_rows(db, task[1], _rows)

    merged_record["report_summary"] = body.report_summary
    merged_record["report_conclusion"] = body.report_conclusion
    merged_record["tester_self_check"] = body.tester_self_check

    # 完整性检查（Track 9）：在 calc 重算 + 摘要合并之后，用最终记录做校验
    if body.submit_for_review:
        await _validate_completeness(db, task[1], merged_record)

    payload_json = json.dumps(merged_record, ensure_ascii=False, default=str)

    # 模板/SOP版本
    tm_version = "A/0"
    sm_version = "A/0"
    if max_version > 0:
        prev_versions = await db.execute(
            text("SELECT template_version, sop_version FROM records WHERE record_no=:r ORDER BY version DESC LIMIT 1"),
            {"r": record_no},
        )
        pv_row = prev_versions.fetchone()
        if pv_row:
            tm_version = pv_row[0] or "A/0"
            sm_version = pv_row[1] or "A/0"

    change_reason = ""
    cf: list[str] = []
    if was_rejected:
        last_review = await db.execute(
            text("""
                SELECT comment, correction_fields FROM reviews
                WHERE record_no=:r AND decision='退回'
                ORDER BY reviewed_at DESC LIMIT 1
            """),
            {"r": record_no},
        )
        lr = last_review.fetchone()
        if lr:
            cf = json.loads(lr[1]) if isinstance(lr[1], str) else (lr[1] or [])
            change_reason = f"复核退回二次编辑：{'；'.join(cf)}；{lr[0] or ''}"

    # ── 字段级编辑门禁：退回修改状态下，仅允许修改复核员指定步骤的字段 ──
    if task[3] == "退回修改" and cf and prev_payload is not None:
        allowed_steps = set(cf)
        blocked = []
        for key, step in _STEP_OF_KEY.items():
            if key in _UNGATED_KEYS:
                continue
            if step in allowed_steps:
                continue
            if _value_changed(key, prev_payload.get(key), merged_record.get(key)):
                blocked.append(f"{key}（{step}）")
        if blocked:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"复核退回后仅允许修改指定步骤字段，以下字段被锁定：{'、'.join(blocked)}",
            )

    # ── 持久化：草稿覆盖同一版本(UPDATE)，退回后编辑新建版本(INSERT) ──
    if max_version > 0 and prev_status == "草稿":
        # 覆盖同一草稿版本
        await db.execute(
            text("""
                UPDATE records SET
                    payload = CAST(:pl AS jsonb),
                    status = :st,
                    tester_signed_at = CASE WHEN :sfr THEN localtimestamp ELSE tester_signed_at END,
                    change_reason = :cr,
                    updated_at = localtimestamp
                WHERE record_no = :rn AND version = :v
            """),
            {
                "rn": record_no, "v": version, "st": new_status,
                "pl": payload_json, "cr": change_reason,
                "sfr": body.submit_for_review,
            },
        )
    else:
        await db.execute(
            text("""
                INSERT INTO records (record_no, task_no, version, experiment, owner, status,
                  payload,
                  template_version, sop_version, change_reason, tester_signed_at,
                  created_at, updated_at)
                VALUES (:rn, :tn, :v, :ex, :ow, :st, CAST(:pl AS jsonb),
                  :tv, :sv, :cr,
                  CASE WHEN :sfr THEN localtimestamp ELSE NULL END,
                  localtimestamp, localtimestamp)
            """),
            {
                "rn": record_no, "tn": body.task_no, "v": version,
                "ex": task[0], "ow": user["username"], "st": new_status,
                "pl": payload_json,
                "tv": tm_version, "sv": sm_version, "cr": change_reason,
                "sfr": body.submit_for_review,
            },
        )

    # 如果提交复核，更新任务状态，自动记录结束时间，并同步任务包状态
    if body.submit_for_review:
        await db.execute(
            text("""
                UPDATE tasks SET status = :st,
                    experiment_ended_at = COALESCE(experiment_ended_at, localtimestamp),
                    reviewer = COALESCE(tasks.reviewer, tp.reviewer),
                    updated_at = localtimestamp
                FROM task_packages tp
                WHERE tasks.task_no = :t AND tasks.package_no = tp.package_no
            """),
            {"st": new_status, "t": body.task_no},
        )

        # 同步任务包状态：实验员提交后 → 待复核；复核通过后 → 已复核
        await db.execute(
            text("""
                UPDATE task_packages tp SET status =
                    CASE
                        WHEN (SELECT COUNT(*) FROM tasks t
                              WHERE t.package_no = tp.package_no
                                AND t.status NOT IN ('已复核','已锁定'))
                             = 0
                        THEN '已复核'
                        WHEN (SELECT COUNT(*) FROM tasks t
                              WHERE t.package_no = tp.package_no
                                AND t.status NOT IN ('待复核','更正待复核','已复核','已锁定'))
                             = 0
                        THEN '待复核'
                        ELSE tp.status
                    END,
                    updated_at = localtimestamp
                WHERE tp.package_no = (
                    SELECT t2.package_no FROM tasks t2 WHERE t2.task_no = :t
                )
            """),
            {"t": body.task_no},
        )

    # 审计日志
    comm_result = await db.execute(
        text("SELECT commission_no FROM tasks WHERE task_no=:t"),
        {"t": body.task_no},
    )
    comm_row = comm_result.fetchone()
    if comm_row:
        action = "提交复核" if body.submit_for_review else "保存草稿"
        await log_operation(db, "record", record_no, user, action,
                             commission_no=comm_row[0],
                             comment=f"版本V{version} 实验:{task[0]}")

        # 字段级追溯：逐字段 old→new 写入 modification_logs / audit_logs
        if prev_payload is not None:
            diffs = _diff_record_payload(prev_payload, merged_record)
            for field_path, old_val, new_val in diffs:
                await log_modification(
                    db=db, entity_type="record", entity_id=record_no, user=user,
                    field_name=field_path, old_value=old_val, new_value=new_val,
                    commission_no=comm_row[0], reason=change_reason,
                )

    return {
        "record_no": record_no,
        "version": version,
        "status": new_status,
        "message": "记录已提交复核" if body.submit_for_review else "记录已保存",
    }


# ── 复核记录 ──

class ReviewRecordRequest(BaseModel):
    decision: str = Field(..., pattern=r"^(通过|退回)$")
    comment: str = ""
    correction_fields: list[str] = []


@router.post("/{record_no}/review")
async def review_record(
    record_no: str,
    body: ReviewRecordRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("复核员"))],
):
    """复核原始记录 — 通过则锁定并自动生成报告；退回则创建新草稿版本"""
    # 获取最新版本
    rec_result = await db.execute(
        text("""
            SELECT r.task_no, r.version, r.status, r.experiment, r.owner,
                   r.payload, r.template_version, r.sop_version
            FROM records r
            WHERE r.record_no = :r
            ORDER BY r.version DESC LIMIT 1
        """),
        {"r": record_no},
    )
    record = rec_result.fetchone()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="记录不存在")

    # 允许"待复核"和"更正待复核"
    if record[2] not in ("待复核", "更正待复核"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail=f"记录状态为'{record[2]}'，无法复核")

    task_no = record[0]
    version = record[1]

    # 验证复核员权限
    task_check = await db.execute(
        text("""
            SELECT COALESCE(t.reviewer, tp.reviewer) AS reviewer,
                   t.assignee, t.package_no
            FROM tasks t
            JOIN task_packages tp ON tp.package_no = t.package_no
            WHERE t.task_no = :t
        """),
        {"t": task_no},
    )
    task_row = task_check.fetchone()
    if not task_row or task_row[0] != user["username"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                          detail="只能复核分配给自己的任务")
    if task_row[1] == user["username"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail="实验人员不得复核本人完成的实验")

    # 退回时必须填写意见和指定修改字段
    if body.decision == "退回":
        if not body.comment.strip():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                              detail="退回实验员修改时必须填写复核意见")
        if not body.correction_fields:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                              detail="退回实验员修改时必须至少指定一个需要修改的字段")

    # 插入复核记录
    correction_json = json.dumps(body.correction_fields, ensure_ascii=False)
    await db.execute(
        text("""
            INSERT INTO reviews (record_no, version, reviewer, decision, comment,
              correction_fields, reviewed_at)
            VALUES (:rn, :v, :rv, :d, :c, CAST(:cf AS jsonb), localtimestamp)
        """),
        {
            "rn": record_no, "v": version, "rv": user["username"],
            "d": body.decision, "c": body.comment, "cf": correction_json,
        },
    )

    if body.decision == "通过":
        # ── 通过：锁定记录，更新任务为"已复核"，自动生成报告 ──
        await db.execute(
            text("""
                UPDATE records SET status = '已锁定',
                    reviewer_signed_at = localtimestamp,
                    updated_at = localtimestamp
                WHERE record_no = :r AND version = :v
            """),
            {"r": record_no, "v": version},
        )

        await db.execute(
            text("UPDATE tasks SET status = '已复核', updated_at = localtimestamp WHERE task_no = :t"),
            {"t": task_no},
        )

        # 同步任务包状态
        await db.execute(
            text("""
                UPDATE task_packages SET status = '已复核', updated_at = localtimestamp
                WHERE package_no = (SELECT t.package_no FROM tasks t WHERE t.task_no = :t)
                  AND NOT EXISTS (
                    SELECT 1 FROM tasks t2
                    WHERE t2.package_no = task_packages.package_no
                      AND t2.status NOT IN ('已复核', '已锁定')
                  )
            """),
            {"t": task_no},
        )

        # 自动生成报告
        await _ensure_report_for_task(task_no, db)

        # 审计日志
        comm_result = await db.execute(
            text("SELECT commission_no FROM tasks WHERE task_no=:t"),
            {"t": task_no},
        )
        comm_row = comm_result.fetchone()
        if comm_row:
            await log_operation(db, "record", record_no, user, "复核通过",
                                 commission_no=comm_row[0],
                                 comment=f"版本V{version} 实验:{record[3]}")

        return {"message": "复核通过，记录已锁定，报告已自动生成", "status": "已锁定"}

    else:
        # ── 退回：标记当前版本为复核退回，创建新草稿版本 ──
        await db.execute(
            text("""
                UPDATE records SET status = '复核退回',
                    updated_at = localtimestamp
                WHERE record_no = :r AND version = :v
            """),
            {"r": record_no, "v": version},
        )

        await db.execute(
            text("UPDATE tasks SET status = '退回修改', updated_at = localtimestamp WHERE task_no = :t"),
            {"t": task_no},
        )

        # 同步任务包状态：有退回的任务包标记为"部分退回"
        await db.execute(
            text("""
                UPDATE task_packages SET status = '部分退回', updated_at = localtimestamp
                WHERE package_no = (SELECT t.package_no FROM tasks t WHERE t.task_no = :t)
            """),
            {"t": task_no},
        )

        # 创建新草稿版本，复制原payload供实验员修改
        next_version = version + 1
        # 确认不冲突
        existing_next = await db.execute(
            text("SELECT 1 FROM records WHERE record_no=:r AND version=:v"),
            {"r": record_no, "v": next_version},
        )
        if existing_next.fetchone():
            max_ver = await db.execute(
                text("SELECT COALESCE(MAX(version), 0) FROM records WHERE record_no=:r"),
                {"r": record_no},
            )
            next_version = max_ver.fetchone()[0] + 1

        change_reason = f"复核退回二次编辑：{'；'.join(body.correction_fields)}；{body.comment}"
        payload_raw = record[5]
        payload_str = json.dumps(
            payload_raw if isinstance(payload_raw, dict) else (json.loads(payload_raw) if payload_raw else {}),
            ensure_ascii=False, default=str,
        )

        await db.execute(
            text("""
                INSERT INTO records (record_no, task_no, version, experiment, owner, status,
                  payload, template_version, sop_version, change_reason,
                  created_at, updated_at)
                VALUES (:rn, :tn, :v, :ex, :ow, '草稿',
                  CAST(:pl AS jsonb), :tv, :sv, :cr,
                  localtimestamp, localtimestamp)
            """),
            {
                "rn": record_no, "tn": task_no, "v": next_version,
                "ex": record[3], "ow": record[4],
                "pl": payload_str,
                "tv": record[6] or "A/0", "sv": record[7] or "A/0",
                "cr": change_reason,
            },
        )

        # 审计日志
        comm_result = await db.execute(
            text("SELECT commission_no FROM tasks WHERE task_no=:t"),
            {"t": task_no},
        )
        comm_row = comm_result.fetchone()
        if comm_row:
            await log_operation(db, "record", record_no, user, "复核退回",
                                 commission_no=comm_row[0],
                                 comment=f"版本V{version}→V{next_version} 原因:{body.comment}")

        return {
            "message": f"复核退回，新草稿版本V{next_version}已创建",
            "status": "复核退回",
            "next_version": next_version,
            "correction_fields": body.correction_fields,
        }


# ── 待复核列表 ──

@router.get("/pending-review", response_model=list[RecordBrief])
async def pending_reviews(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
    limit: int = Query(50, le=200),
):
    """待复核的记录（含"待复核"和"更正待复核"）"""
    result = await db.execute(
        text("""
            SELECT r.record_no, r.task_no, r.version, r.experiment, r.status, r.owner, r.created_at
            FROM records r
            JOIN tasks t ON t.task_no = r.task_no
            LEFT JOIN task_packages tp ON tp.package_no = t.package_no
            WHERE COALESCE(t.reviewer, tp.reviewer) = :reviewer
              AND r.status IN ('待复核', '更正待复核')
            ORDER BY r.created_at DESC LIMIT :limit
        """),
        {"reviewer": user["username"], "limit": limit},
    )
    rows = result.fetchall()
    names = await _display_names(db, {r[5] for r in rows if r[5]})
    return [
        RecordBrief(record_no=r[0], task_no=r[1], version=r[2], experiment=r[3],
                    status=r[4], owner=r[5], owner_name=names.get(r[5], r[5]),
                    created_at=str(r[6]) if r[6] else None)
        for r in rows
    ]


# ── 查询接口 ──

@router.get("/{record_no}/versions")
async def record_versions(
    record_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """某记录的所有版本"""
    result = await db.execute(
        text("""
            SELECT id, record_no, task_no, version, experiment, owner, status,
                   template_version, sop_version, change_reason,
                   tester_signed_at, reviewer_signed_at, quality_signed_at, created_at
            FROM records WHERE record_no = :r ORDER BY version DESC
        """),
        {"r": record_no},
    )
    rows = result.fetchall()
    if not rows:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="记录不存在")
    return [dict(zip(result.keys(), r)) for r in rows]


@router.get("/{record_no}/v{version}")
async def get_record(
    record_no: str,
    version: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """获取某版本的记录详情（含 payload 和审核历史）"""
    result = await db.execute(
        text("SELECT * FROM records WHERE record_no = :r AND version = :v"),
        {"r": record_no, "v": version},
    )
    row = result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="记录不存在")
    record = dict(zip(result.keys(), row))

    # 审核历史
    reviews_result = await db.execute(
        text("""
            SELECT reviewer, decision, comment, correction_fields, reviewed_at
            FROM reviews WHERE record_no = :r AND version = :v
            ORDER BY reviewed_at
        """),
        {"r": record_no, "v": version},
    )
    reviews = [dict(zip(reviews_result.keys(), r)) for r in reviews_result.fetchall()]

    # 解析姓名（实验员 owner + 各审核人 reviewer）
    names = await _display_names(
        db, {record.get("owner")} | {rv.get("reviewer") for rv in reviews}
    )
    record["owner_name"] = names.get(record.get("owner"), record.get("owner") or "")
    for rv in reviews:
        rv["reviewer_name"] = names.get(rv.get("reviewer"), rv.get("reviewer") or "")
    record["reviews"] = reviews

    return record


# ═══════════════════════════════════════════════════════════════
# ── Word 预览 / 导出 ──
# ═══════════════════════════════════════════════════════════════

from fastapi.responses import HTMLResponse, Response


@router.get("/{record_no}/v{version}/preview", response_class=HTMLResponse)
async def preview_record_word(
    record_no: str,
    version: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """复核员/质量负责人预览填入数据的受控Word — 返回HTML审核阅读器"""
    # 查询记录
    rec_result = await db.execute(
        text("SELECT * FROM records WHERE record_no=:r AND version=:v"),
        {"r": record_no, "v": version},
    )
    row = rec_result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="记录不存在")
    record = dict(zip(rec_result.keys(), row))

    # 权限检查：复核员/质量负责人/管理员可预览
    role = user.get("role", "")
    if role not in ("复核员", "质量负责人", "管理员", "样品管理员"):
        if record.get("owner") != user["username"]:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权预览此记录")

    # 查询关联任务
    task_no = record.get("task_no", "")
    task = None
    if task_no:
        t_result = await db.execute(
            text("SELECT * FROM tasks WHERE task_no=:t"), {"t": task_no}
        )
        t_row = t_result.fetchone()
        if t_row:
            task = dict(zip(t_result.keys(), t_row))

    commission, groups, samples = await _load_commission_context(task, db)

    # 加载受控模板映射的 DB 权威值（坐标 + 常量），供导出注入（空则硬编码兜底）
    from app.api.v1.experiment_config import load_mapping_registry, resolve_record_template_file
    code = (task or {}).get("experiment_code") or ""
    registry = await load_mapping_registry(db, code, task_no)

    # 模板文件：任务配置快照（检测期间锁定）优先，其次现行配置，最后交给引擎 kind 推断
    if not record.get("record_template_file"):
        snapshot_template = ((registry.get("extra_json") or {}).get("record_template_file")) or ""
        record["record_template_file"] = snapshot_template or await resolve_record_template_file(db, code)

    # 姓名解析：表中显示姓名（display_name）而非账号名
    names = await _display_names(
        db, {record.get("owner")} | {(task or {}).get("assignee"), (task or {}).get("reviewer"), record.get("reviewer")}
    )

    # 生成 DOCX
    try:
        from app.services.record_word_engine import export_record_docx
        from app.services.docx_preview import docx_review_html
        docx_bytes = export_record_docx(
            record, task,
            template_dir=settings.TEMPLATE_DIR,
            signature_dir=settings.SIGNATURE_DIR,
            commission=commission,
            groups=groups,
            samples=samples,
            registry=registry,
            display_names=names,
        )
        title = f"{record.get('experiment','原始记录')} — {record_no} V{version}"
        html = docx_review_html(docx_bytes, title)
        return HTMLResponse(content=html)
    except ImportError as e:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail=f"预览服务不可用：{e}",
        )


@router.get("/{record_no}/v{version}/export")
async def export_record_docx_endpoint(
    record_no: str,
    version: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """导出填入数据的受控Word文档（仅管理员/质量负责人可下载）"""
    role = user.get("role", "")
    if role not in ("管理员", "质量负责人", "复核员", "样品管理员"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权下载此记录")

    rec_result = await db.execute(
        text("SELECT * FROM records WHERE record_no=:r AND version=:v"),
        {"r": record_no, "v": version},
    )
    row = rec_result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="记录不存在")
    record = dict(zip(rec_result.keys(), row))

    task_no = record.get("task_no", "")
    task = None
    if task_no:
        t_result = await db.execute(
            text("SELECT * FROM tasks WHERE task_no=:t"), {"t": task_no}
        )
        t_row = t_result.fetchone()
        if t_row:
            task = dict(zip(t_result.keys(), t_row))

    commission, groups, samples = await _load_commission_context(task, db)

    # 加载受控模板映射的 DB 权威值（坐标 + 常量），供导出注入（空则硬编码兜底）
    from app.api.v1.experiment_config import load_mapping_registry, resolve_record_template_file
    code = (task or {}).get("experiment_code") or ""
    registry = await load_mapping_registry(db, code, task_no)

    # 模板文件：任务配置快照（检测期间锁定）优先，其次现行配置，最后交给引擎 kind 推断
    if not record.get("record_template_file"):
        snapshot_template = ((registry.get("extra_json") or {}).get("record_template_file")) or ""
        record["record_template_file"] = snapshot_template or await resolve_record_template_file(db, code)

    # 姓名解析：表中显示姓名（display_name）而非账号名
    names = await _display_names(
        db, {record.get("owner")} | {(task or {}).get("assignee"), (task or {}).get("reviewer"), record.get("reviewer")}
    )

    try:
        from app.services.record_word_engine import export_record_docx
        docx_bytes = export_record_docx(
            record, task,
            template_dir=settings.TEMPLATE_DIR,
            signature_dir=settings.SIGNATURE_DIR,
            commission=commission,
            groups=groups,
            samples=samples,
            registry=registry,
            display_names=names,
        )
        filename = f"{record_no}_V{version}_原始记录表.docx"
        from urllib.parse import quote
        ascii_fallback = f"{record_no}_V{version}.docx"
        headers = {
            "Content-Disposition": f"attachment; filename=\"{ascii_fallback}\"; filename*=UTF-8''{quote(filename)}"
        }
        return Response(
            content=docx_bytes,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers=headers,
        )
    except ImportError as e:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail=f"导出服务不可用：{e}",
        )


class TemplateSupplementRequest(BaseModel):
    task_no: str
    business_record: dict[str, Any] = {}


@router.post("/template-supplement")
async def template_supplement(
    body: TemplateSupplementRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("实验员"))],
):
    """⑤母版过程确认 — 后端统一预填，仅返回仍需实验员补充的模板字段。

    与导出 DOCX 共用同一套 compute_template_values 数据源，保证 ⑤ 展示与
    最终导出的原始记录表逐格一致（日期/委托头部/受控映射均由后端权威预填）。
    """
    task_result = await db.execute(
        text("SELECT * FROM tasks WHERE task_no=:t"), {"t": body.task_no}
    )
    task_row = task_result.fetchone()
    if not task_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    task = dict(zip(task_result.keys(), task_row))
    if task.get("assignee") != user["username"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只能确认自己的实验")

    # 构建伪 record（供 compute_template_values 复用导出同一套逻辑）
    record: dict[str, Any] = {
        "payload": dict(body.business_record or {}),
        "owner": user["username"],
        "experiment": task.get("experiment", ""),
        "experiment_code": task.get("experiment_code", ""),
        "kind": task.get("kind", ""),
    }

    commission, groups, samples = await _load_commission_context(task, db)

    # 配置兜底：任务配置快照（检测期间锁定）优先，其次现行配置
    from app.api.v1.experiment_config import resolve_record_template_file, load_mapping_registry
    registry = await load_mapping_registry(
        db, task.get("experiment_code") or "", body.task_no
    )
    snapshot_template = ((registry.get("extra_json") or {}).get("record_template_file")) or ""
    resolved = snapshot_template or await resolve_record_template_file(db, task.get("experiment_code") or "")
    if resolved:
        record["record_template_file"] = resolved

    # 姓名解析：表中显示姓名（display_name）而非账号名
    names = await _display_names(
        db, {user["username"], task.get("reviewer") or "", task.get("assignee") or ""}
    )

    from app.services.record_word_engine import (
        compute_template_values,
        template_supplement_requirements,
        template_manifest,
    )

    template_name, template_path, values = compute_template_values(
        record, task,
        template_dir=settings.TEMPLATE_DIR,
        commission=commission,
        groups=groups,
        samples=samples,
        registry=registry,
        finalize=False,
        display_names=names,
    )
    if template_path is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="未找到受控记录模板"
        )

    requirements = template_supplement_requirements(template_path, values)
    # 附上当前值，供前端在输入框内展示已预填内容
    for f in requirements:
        f["value"] = values.get(f["key"], "")

    total_count = len(requirements)
    return {
        "template_name": template_name,
        "total_count": total_count,
        "prefilled_count": max(0, len(template_manifest(template_path)) - total_count),
        "fields": requirements,
    }
