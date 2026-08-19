"""报告 API — 完整三级审批链：质量负责人 → 管理员（授权签字人）→ 发放"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import HTMLResponse, Response
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.deps import get_current_user, get_db, require_role
from app.services.audit_service import log_operation
from app.services.report_docx import generate_report_docx, docx_to_html

router = APIRouter(prefix="/reports", tags=["报告"])


def _resolve_attachment_url(url: str) -> Path | None:
    """将 /api/v1/attachments/file/{task_no}/{filename} 解析为本地文件路径"""
    if not url:
        return None
    prefix = "/api/v1/attachments/file/"
    if prefix in url:
        rel = url.split(prefix, 1)[1]
        return Path(settings.ATTACHMENT_DIR) / rel
    return None


class ReportBrief(BaseModel):
    report_no: str
    commission_no: str
    task_no: str | None
    experiment: str | None = None
    status: str
    tester: str | None
    verifier: str | None
    quality_inspector: str | None
    publish_date: str | None
    created_at: str | None
    supersedes_report_no: str | None = None


def _report_no_for_task(task_no: str) -> str:
    """报告编号 = R + task_no去掉BP前缀"""
    return "R" + task_no[2:] if task_no.startswith("BP") else f"R{task_no}"


def _correction_report_no(supersedes_report_no: str) -> str:
    """由被更正的报告号派生更正报告号：R…-T01 → R…-T01-V2 → R…-T01-V3"""
    m = re.match(r"^(.*)-V(\d+)$", supersedes_report_no)
    if m:
        return f"{m.group(1)}-V{int(m.group(2)) + 1}"
    return f"{supersedes_report_no}-V2"


# ═══════════════════════════════════════════════════════════════
# ── 生成报告 ──
# ═══════════════════════════════════════════════════════════════

class GenerateReportRequest(BaseModel):
    task_no: str


@router.post("", status_code=201)
async def generate_report(
    body: GenerateReportRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("质量负责人", "复核员", "管理员"))],
):
    """手动生成检验报告（通常由复核通过自动触发，也可手动补生成）"""
    # 验证任务已复核
    task_result = await db.execute(
        text("""
            SELECT t.commission_no, t.experiment, t.assignee, t.reviewer,
                   t.quality_inspector, t.status
            FROM tasks t
            WHERE t.task_no = :t
        """),
        {"t": body.task_no},
    )
    task = task_result.fetchone()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    if task[5] not in ("已复核", "已完成"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail="任务未完成复核，无法生成报告")

    # 检查是否已有报告（支持更正：已作废的报告可生成新版本）
    existing = await db.execute(
        text("SELECT report_no, status FROM reports WHERE task_no = :t ORDER BY created_at DESC, report_no DESC"),
        {"t": body.task_no},
    )
    existing_rows = existing.fetchall()
    existing_row = existing_rows[0] if existing_rows else None
    supersedes_report_no: str | None = None
    if existing_row:
        if existing_row[1] in ("质量退回", "复核退回"):
            # 重置为待质量审核
            await db.execute(
                text("UPDATE reports SET status='待质量审核', updated_at=localtimestamp WHERE report_no=:r"),
                {"r": existing_row[0]},
            )
            return {"report_no": existing_row[0], "status": "待质量审核", "message": "报告已重置为待质量审核"}
        if existing_row[1] == "已作废":
            supersedes_report_no = existing_row[0]  # 更正重签：生成新版本报告
        else:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                              detail=f"该任务已有报告（状态：{existing_row[1]}）")

    # 检查是否有锁定记录
    rec_check = await db.execute(
        text("SELECT 1 FROM records WHERE task_no=:t AND status='已锁定'"),
        {"t": body.task_no},
    )
    if not rec_check.fetchone():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="记录未通过复核，无法生成报告")

    # 查管理员作为默认批准人
    admin_result = await db.execute(
        text("SELECT username FROM users WHERE role='管理员' AND enabled=TRUE ORDER BY username LIMIT 1")
    )
    admin_row = admin_result.fetchone()

    report_no = _correction_report_no(supersedes_report_no) if supersedes_report_no else _report_no_for_task(body.task_no)

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
                '{}'::jsonb, '委托检验', '',
                '', '', :sn, localtimestamp, localtimestamp
            )
        """),
        {
            "rn": report_no, "cn": task[0], "tn": body.task_no,
            "tr": task[2] or "",
            "vf": task[3] or "", "qi": task[4] or "",
            "ap": admin_row[0] if admin_row else "",
            "sn": supersedes_report_no,
        },
    )

    await log_operation(db, "report", report_no, user, "手动生成报告",
                      comment="手动补生成报告初稿")

    return {"report_no": report_no, "status": "待质量审核", "message": "报告已生成，待质量负责人审核"}


# ═══════════════════════════════════════════════════════════════
# ── 质量负责人审核 ──
# ═══════════════════════════════════════════════════════════════

class ReviewReportRequest(BaseModel):
    decision: str = Field(..., pattern=r"^(通过|退回)$")
    comment: str = ""


@router.post("/{report_no}/quality-review")
async def quality_review_report(
    report_no: str,
    body: ReviewReportRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("质量负责人"))],
):
    """质量负责人预览确认报告 — 通过→待管理员签发，退回→质量退回+任务退回修改"""
    rep = await db.execute(
        text("SELECT status, quality_inspector, task_no FROM reports WHERE report_no=:r"),
        {"r": report_no},
    )
    rep_row = rep.fetchone()
    if not rep_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    if rep_row[0] not in ("待质量审核", "待管理员签发"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail=f"报告状态为'{rep_row[0]}'，无法进行质量审核")
    # 质量负责人角色可审核任何待审核报告（quality_inspector 仅用于记录，不做硬限制）
    if rep_row[1] and rep_row[1] != user["username"] and rep_row[0] == "待管理员签发":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                          detail="该报告已由其他质量负责人审核，当前状态不可修改")

    if body.decision == "通过":
        new_status = "待管理员签发"
        # 更新报告状态（质量负责人仅预览确认，不形成电子签字）
        await db.execute(
            text("""
                UPDATE reports SET status=:st, quality_inspector=:qi,
                    signed_by_quality=NULL, updated_at=localtimestamp
                WHERE report_no=:r
            """),
            {"st": new_status, "qi": user["username"], "r": report_no},
        )

        await log_operation(db, "report", report_no, user, "质量审核通过",
                          comment=body.comment,
                          field_name="status", old_value=rep_row[0], new_value=new_status)
        return {"message": "质量审核通过，报告待管理员签发", "status": new_status}

    else:
        new_status = "质量退回"
        await db.execute(
            text("""
                UPDATE reports SET status=:st, updated_at=localtimestamp
                WHERE report_no=:r
            """),
            {"st": new_status, "r": report_no},
        )

        await log_operation(db, "report", report_no, user, "质量审核退回",
                          comment=body.comment,
                          field_name="status", old_value=rep_row[0], new_value=new_status)

        # 联动：将任务退回修改，解锁原始记录以便实验员重新编辑
        task_no = rep_row[2]
        if task_no:
            await db.execute(
                text("UPDATE tasks SET status='退回修改', updated_at=localtimestamp WHERE task_no=:t"),
                {"t": task_no},
            )
            # 解锁关联的原始记录
            await db.execute(
                text("UPDATE records SET status='编辑中', updated_at=localtimestamp WHERE task_no=:t AND status IN ('已锁定','已复核')"),
                {"t": task_no},
            )

        return {"message": "质量审核退回，任务已退回至实验员修改（修改后需重新提交→复核→质量审核）", "status": new_status}


# ═══════════════════════════════════════════════════════════════
# ── 管理员（授权签字人）签发 ──
# ═══════════════════════════════════════════════════════════════

@router.post("/{report_no}/approve")
async def approve_report(
    report_no: str,
    body: ReviewReportRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员", "授权签字人"))],
):
    """管理员 / 授权签字人最终审核签发 — 批准→已发布，退回→待质量审核（approver 记录实际签署人）"""
    rep = await db.execute(
        text("SELECT status FROM reports WHERE report_no=:r"),
        {"r": report_no},
    )
    rep_row = rep.fetchone()
    if not rep_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    if rep_row[0] != "待管理员签发":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail=f"报告状态为'{rep_row[0]}'，无法签发")

    if body.decision == "通过":
        # ── 电子签名（Track 12）：从 signatures 表取签署人签名图引用 ──
        sig_row = (await db.execute(
            text("SELECT image_file FROM signatures WHERE username=:u"),
            {"u": user["username"]},
        )).fetchone()
        approver_signature = (sig_row[0] if sig_row and sig_row[0] else user["username"])

        # ── 批准签发 ──
        await db.execute(
            text("""
                UPDATE reports SET status='已发布',
                    approver=:ap, signed_by_approver=localtimestamp,
                    approver_signature=:asg,
                    publish_date=CURRENT_DATE, validity_status='有效',
                    updated_at=localtimestamp
                WHERE report_no=:r
            """),
            {"ap": user["username"], "r": report_no, "asg": approver_signature},
        )

        await log_operation(db, "report", report_no, user, "批准签发",
                          comment=body.comment,
                          field_name="status", old_value=rep_row[0], new_value="已发布")
        return {"message": "报告已签发", "status": "已发布"}

    else:
        # ── 退回质量审核 ──
        old_status = rep_row[0]
        await db.execute(
            text("""
                UPDATE reports SET status='待质量审核',
                    approver=NULL, signed_by_approver=NULL,
                    updated_at=localtimestamp
                WHERE report_no=:r
            """),
            {"r": report_no},
        )

        await log_operation(db, "report", report_no, user, "签发退回",
                          comment=body.comment,
                          field_name="status", old_value=old_status, new_value="待质量审核")
        return {"message": "报告已退回质量负责人重新审核（一层层返回：管理员→质量负责人）", "status": "待质量审核"}


# ═══════════════════════════════════════════════════════════════
# ── 报告列表 ──
# ═══════════════════════════════════════════════════════════════

@router.get("", response_model=list[ReportBrief])
async def list_reports(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
    status_filter: str | None = Query(None, alias="status"),
    limit: int = Query(50, le=200),
):
    """报告列表（按角色过滤）"""
    role = user["role"]
    username = user["username"]

    params: dict = {}
    if role == "质量负责人":
        where = "WHERE (quality_inspector=:username OR quality_inspector='' OR quality_inspector IS NULL)"
        params["username"] = username
    elif role == "复核员":
        where = "WHERE verifier=:username"
        params["username"] = username
    elif role == "实验员":
        where = "WHERE tester=:username"
        params["username"] = username
    elif role == "管理员":
        # 管理员可看到待签发和已发布的报告
        where = "WHERE 1=1"
    elif role == "样品管理员":
        where = "WHERE 1=1"
    else:
        where = "WHERE 1=1"

    if status_filter:
        where += " AND status=:status_filter"
        params["status_filter"] = status_filter

    result = await db.execute(
        text(f"""
            SELECT report_no, commission_no, task_no, status, tester, verifier,
                   quality_inspector, publish_date, created_at, supersedes_report_no
            FROM reports {where}
            ORDER BY created_at DESC LIMIT :limit
        """),
        {**params, "limit": limit},
    )
    return [
        ReportBrief(
            report_no=r[0], commission_no=r[1], task_no=r[2], experiment=None,
            status=r[3], tester=r[4], verifier=r[5], quality_inspector=r[6],
            publish_date=str(r[7]) if r[7] else None,
            created_at=str(r[8]) if r[8] else None,
            supersedes_report_no=r[9],
        )
        for r in result.fetchall()
    ]


# ═══════════════════════════════════════════════════════════════
# ── 报告详情 ──
# ═══════════════════════════════════════════════════════════════

@router.get("/{report_no}")
async def get_report(
    report_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """报告详情（含操作历史）"""
    result = await db.execute(
        text("SELECT * FROM reports WHERE report_no=:r"), {"r": report_no}
    )
    row = result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    report = dict(zip(result.keys(), row))

    # 操作历史
    actions_result = await db.execute(
        text("SELECT actor, action, comment, created_at FROM report_actions WHERE report_no=:r ORDER BY created_at"),
        {"r": report_no},
    )
    report["actions"] = [dict(zip(actions_result.keys(), r)) for r in actions_result.fetchall()]
    actors = {a.get("actor") for a in report["actions"]}
    if actors:
        placeholders = ", ".join(f":u{i}" for i in range(len(actors)))
        params = {f"u{i}": u for i, u in enumerate(actors)}
        actor_rows = await db.execute(
            text(f"SELECT username, display_name FROM users WHERE username IN ({placeholders})"),
            params,
        )
        actor_names = {uname: (dname or uname) for uname, dname in actor_rows.fetchall()}
        for a in report["actions"]:
            if a.get("actor"):
                a["actor_name"] = actor_names.get(a["actor"], a["actor"])

    # 关联原始记录
    if report.get("task_no"):
        rec_result = await db.execute(
            text("SELECT record_no, version, status, task_no, experiment FROM records WHERE task_no=:t ORDER BY version DESC LIMIT 1"),
            {"t": report["task_no"]},
        )
        rec_row = rec_result.fetchone()
        if rec_row:
            report["linked_record"] = {"record_no": rec_row[0], "version": rec_row[1], "status": rec_row[2], "task_no": rec_row[3], "experiment": rec_row[4]}

    # 关联委托信息
    commission_no = report.get("commission_no", "")
    if commission_no:
        comm_result = await db.execute(
            text("SELECT * FROM commissions WHERE commission_no=:c"),
            {"c": commission_no},
        )
        comm_row = comm_result.fetchone()
        if comm_row:
            report["commission"] = dict(zip(comm_result.keys(), comm_row))
            # 样品组
            sg_result = await db.execute(
                text("SELECT * FROM sample_groups WHERE commission_no=:c ORDER BY group_no"),
                {"c": commission_no},
            )
            report["sample_groups"] = [dict(zip(sg_result.keys(), r)) for r in sg_result.fetchall()]
            # 样品
            s_result = await db.execute(
                text("SELECT * FROM samples WHERE commission_no=:c ORDER BY sample_no"),
                {"c": commission_no},
            )
            report["samples"] = [dict(zip(s_result.keys(), r)) for r in s_result.fetchall()]

    # 关联任务列表
    if commission_no:
        task_result = await db.execute(
            text("SELECT * FROM tasks WHERE commission_no=:c ORDER BY task_no"),
            {"c": commission_no},
        )
        report["tasks"] = [dict(zip(task_result.keys(), r)) for r in task_result.fetchall()]

    # 关联危废记录
    hw_result = await db.execute(
        text("SELECT * FROM hazardous_waste_records WHERE commission_no=:c ORDER BY created_at DESC"),
        {"c": commission_no},
    )
    hw_rows = hw_result.fetchall()
    if hw_rows:
        report["hazardous_waste"] = [dict(zip(hw_result.keys(), r)) for r in hw_rows]

    # 关联借出归还记录 (via sample_no → commission_no)
    lr_result = await db.execute(
        text("""
            SELECT pl.* FROM package_loans pl
            JOIN samples s ON pl.sample_no = s.sample_no
            WHERE s.commission_no=:c
            ORDER BY pl.borrowed_at DESC
        """),
        {"c": commission_no},
    )
    lr_rows = lr_result.fetchall()
    if lr_rows:
        report["sample_loans"] = [dict(zip(lr_result.keys(), r)) for r in lr_rows]

    return report


# ═══════════════════════════════════════════════════════════════
# ── 报告发放 ──
# ═══════════════════════════════════════════════════════════════

class DeliverReportRequest(BaseModel):
    delivery_method: str  # 自取/邮寄/电子邮件/其他
    recipient: str
    recipient_contact: str = ""
    note: str = ""


@router.post("/{report_no}/delivery")
async def deliver_report(
    report_no: str,
    body: DeliverReportRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("样品管理员", "管理员"))],
):
    """登记报告发放"""
    rep = await db.execute(
        text("SELECT r.status, r.commission_no, c.client_name FROM reports r LEFT JOIN commissions c ON r.commission_no = c.commission_no WHERE r.report_no=:r"),
        {"r": report_no},
    )
    rep_row = rep.fetchone()
    if not rep_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    if rep_row[0] != "已发布":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail=f"报告状态为'{rep_row[0]}'，不能发放")

    if not body.delivery_method.strip():
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="发放方式不能为空")
    if not body.recipient.strip():
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="接收人不能为空")

    await db.execute(
        text("""INSERT INTO report_deliveries (
                report_no, client_name, delivery_method, recipient, recipient_contact,
                delivered_at, receipt_status, receipt_note, created_at
            ) VALUES (
                :rn, :client, :dm, :rc, :rct,
                localtimestamp, '已签收', :note, localtimestamp
            )"""),
        {"rn": report_no, "client": rep_row[2] or "", "dm": body.delivery_method,
         "rc": body.recipient, "rct": body.recipient_contact, "note": body.note},
    )

    await log_operation(db, "report", report_no, user, "报告发放",
                      comment=f"方式：{body.delivery_method}｜接收人：{body.recipient}")

    return {"message": "报告发放已登记", "report_no": report_no, "recipient": body.recipient}


@router.get("/{report_no}/deliveries")
async def list_deliveries(
    report_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """报告发放记录"""
    result = await db.execute(
        text("SELECT * FROM report_deliveries WHERE report_no=:r ORDER BY delivered_at DESC"),
        {"r": report_no},
    )
    return [dict(zip(result.keys(), r)) for r in result.fetchall()]


# ═══════════════════════════════════════════════════════════════
# ── 报告撤回 ──
# ═══════════════════════════════════════════════════════════════

class RevokeRequest(BaseModel):
    reason: str = ""


@router.post("/{report_no}/revoke")
async def revoke_report(
    report_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员", "质量负责人"))],
    body: RevokeRequest = RevokeRequest(),
):
    """撤回已签发的报告（管理员/质量负责人）— 同步退回关联任务"""
    rep = await db.execute(
        text("SELECT r.status, r.commission_no, r.task_no FROM reports r WHERE r.report_no=:r"),
        {"r": report_no})
    row = rep.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    if row[0] != "已发布":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail=f"报告状态为'{row[0]}'，只能撤回已签发的报告")

    old_status = row[0]
    commission_no = row[1]
    task_no = row[2]

    # ── 一层层返回：管理员撤回 → 质量负责人重新审核 → (如需)复核员 → 实验员 ──
    # 报告重置为待质量审核，清除签发信息，任务保持已复核状态
    await db.execute(
        text("""
            UPDATE reports SET status='待质量审核', validity_status=NULL,
                approver=NULL, signed_by_approver=NULL, approver_signature=NULL, publish_date=NULL,
                updated_at=localtimestamp
            WHERE report_no=:r
        """),
        {"r": report_no},
    )

    # 任务保持已复核 — 质量负责人重新审核报告后决定是否退回实验员
    # 这样形成: 管理员 → 质量负责人 → (如需)复核员 → 实验员 的逐层返回链
    if task_no:
        await db.execute(
            text("UPDATE tasks SET updated_at=localtimestamp WHERE task_no=:t"),
            {"t": task_no},
        )

    reason_text = body.reason or "撤回已签发报告，退回质量负责人重新审核"
    await log_operation(db, "report", report_no, user, "撤回报告",
                      comment=reason_text,
                      field_name="status", old_value=old_status, new_value="待质量审核",
                      reason=reason_text)
    return {"message": "报告已撤回并退回质量负责人重新审核（一层层返回）", "report_no": report_no, "status": "待质量审核"}


# ═══════════════════════════════════════════════════════════════
# ── 报告预览 / 下载 ──
# ═══════════════════════════════════════════════════════════════

@router.get("/{report_no}/preview", response_class=HTMLResponse)
async def preview_report(
    report_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """在线预览检验报告 DOCX（质量负责人/管理员专用）"""
    role = user.get("role", "")
    if role not in ("质量负责人", "管理员", "复核员", "样品管理员"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权预览报告")

    # 查报告
    rep_result = await db.execute(
        text("SELECT * FROM reports WHERE report_no=:r"), {"r": report_no}
    )
    rep_row = rep_result.fetchone()
    if not rep_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    report = dict(zip(rep_result.keys(), rep_row))

    commission_no = report.get("commission_no", "")

    # 查委托
    comm = {}
    if commission_no:
        c_result = await db.execute(
            text("SELECT * FROM commissions WHERE commission_no=:c"), {"c": commission_no}
        )
        c_row = c_result.fetchone()
        if c_row:
            comm = dict(zip(c_result.keys(), c_row))

    # 查样品组
    groups = []
    if commission_no:
        g_result = await db.execute(
            text("SELECT * FROM sample_groups WHERE commission_no=:c ORDER BY group_no"),
            {"c": commission_no},
        )
        groups = [dict(zip(g_result.keys(), r)) for r in g_result.fetchall()]

    # 查任务
    tasks = []
    if commission_no:
        t_result = await db.execute(
            text("SELECT * FROM tasks WHERE commission_no=:c ORDER BY task_no"),
            {"c": commission_no},
        )
        tasks = [dict(zip(t_result.keys(), r)) for r in t_result.fetchall()]

    # 查所有原始记录
    records_map = {}
    for t in tasks:
        tn = t.get("task_no", "")
        if tn:
            r_result = await db.execute(
                text("SELECT * FROM records WHERE task_no=:t ORDER BY version DESC LIMIT 1"),
                {"t": tn},
            )
            r_row = r_result.fetchone()
            if r_row:
                rec = dict(zip(r_result.keys(), r_row))
                payload = rec.get("payload")
                if isinstance(payload, str):
                    try:
                        rec["payload"] = json.loads(payload)
                    except Exception:
                        pass
                records_map[tn] = rec

    # 查用户显示名
    user_names = {}
    u_result = await db.execute(text("SELECT username, display_name FROM users"))
    for u_row in u_result.fetchall():
        user_names[u_row[0]] = u_row[1] or u_row[0]

    # 查照片附件 — 从 attachments 表 + 记录 payload 中收集
    photo_paths: list[str] = []
    seen_files: set[str] = set()  # 去重：用文件名做 key

    # 1) 从 attachments 表
    try:
        p_result = await db.execute(
            text("SELECT relative_path, stored_name FROM attachments WHERE commission_no=:c AND attachment_type='photo'"),
            {"c": commission_no},
        )
        for p_row in p_result.fetchall():
            rel_path = p_row[0] or ""
            stored = p_row[1] or ""
            if rel_path:
                full = settings.ATTACHMENT_DIR / rel_path
            elif stored:
                full = settings.UPLOAD_DIR / stored
            else:
                continue
            if full.exists() and full.name not in seen_files:
                photo_paths.append(str(full))
                seen_files.add(full.name)
    except Exception:
        pass

    # 2) 从记录 payload._photos 提取
    for tn, rec in records_map.items():
        payload = rec.get("payload", {}) if isinstance(rec.get("payload"), dict) else {}
        photos_meta = payload.get("_photos", []) or []
        if isinstance(photos_meta, list):
            for cp in photos_meta:
                if not isinstance(cp, dict):
                    continue
                # 主照片
                url = cp.get("previewUrl", "")
                if url:
                    path = _resolve_attachment_url(url)
                    if path and path.exists() and path.name not in seen_files:
                        photo_paths.append(str(path))
                        seen_files.add(path.name)
                # 样品级照片
                for sn, data in (cp.get("samplePhotos", {}) or {}).items():
                    if isinstance(data, dict):
                        url = data.get("previewUrl", "")
                        if url:
                            path = _resolve_attachment_url(url)
                            if path and path.exists() and path.name not in seen_files:
                                photo_paths.append(str(path))
                                seen_files.add(path.name)

    try:
        docx_bytes = generate_report_docx(comm, groups, tasks, records_map, report, user_names, photo_paths or None)
        title = f"检验报告 — {report_no}"
        html = docx_to_html(docx_bytes, title)
        return HTMLResponse(content=html)
    except FileNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"生成预览失败: {e}")


@router.get("/{report_no}/export")
async def download_report(
    report_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """下载检验报告 DOCX（质量负责人/管理员可下载，其他角色仅已发布可下载）"""
    role = user.get("role", "")

    rep_result = await db.execute(
        text("SELECT * FROM reports WHERE report_no=:r"), {"r": report_no}
    )
    rep_row = rep_result.fetchone()
    if not rep_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    report = dict(zip(rep_result.keys(), rep_row))

    # 权限：质量负责人/管理员可下载任意状态；其他角色仅已发布
    if role not in ("质量负责人", "管理员", "样品管理员"):
        if report.get("status") != "已发布":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="仅可下载已签发的报告")

    commission_no = report.get("commission_no", "")

    # 查委托
    comm = {}
    if commission_no:
        c_result = await db.execute(
            text("SELECT * FROM commissions WHERE commission_no=:c"), {"c": commission_no}
        )
        c_row = c_result.fetchone()
        if c_row:
            comm = dict(zip(c_result.keys(), c_row))

    # 查样品组
    groups = []
    if commission_no:
        g_result = await db.execute(
            text("SELECT * FROM sample_groups WHERE commission_no=:c ORDER BY group_no"),
            {"c": commission_no},
        )
        groups = [dict(zip(g_result.keys(), r)) for r in g_result.fetchall()]

    # 查任务
    tasks = []
    if commission_no:
        t_result = await db.execute(
            text("SELECT * FROM tasks WHERE commission_no=:c ORDER BY task_no"),
            {"c": commission_no},
        )
        tasks = [dict(zip(t_result.keys(), r)) for r in t_result.fetchall()]

    # 查记录
    records_map = {}
    for t in tasks:
        tn = t.get("task_no", "")
        if tn:
            r_result = await db.execute(
                text("SELECT * FROM records WHERE task_no=:t ORDER BY version DESC LIMIT 1"),
                {"t": tn},
            )
            r_row = r_result.fetchone()
            if r_row:
                rec = dict(zip(r_result.keys(), r_row))
                payload = rec.get("payload")
                if isinstance(payload, str):
                    try:
                        rec["payload"] = json.loads(payload)
                    except Exception:
                        pass
                records_map[tn] = rec

    user_names = {}
    u_result = await db.execute(text("SELECT username, display_name FROM users"))
    for u_row in u_result.fetchall():
        user_names[u_row[0]] = u_row[1] or u_row[0]

    # 查照片附件 — 从 attachments 表 + 记录 payload 中收集
    photo_paths: list[str] = []
    seen_files: set[str] = set()

    # 1) 从 attachments 表
    try:
        p_result = await db.execute(
            text("SELECT relative_path, stored_name FROM attachments WHERE commission_no=:c AND attachment_type='photo'"),
            {"c": commission_no},
        )
        for p_row in p_result.fetchall():
            rel_path = p_row[0] or ""
            stored = p_row[1] or ""
            if rel_path:
                full = settings.ATTACHMENT_DIR / rel_path
            elif stored:
                full = settings.UPLOAD_DIR / stored
            else:
                continue
            if full.exists() and full.name not in seen_files:
                photo_paths.append(str(full))
                seen_files.add(full.name)
    except Exception:
        pass

    # 2) 从记录 payload._photos 提取
    for tn, rec in records_map.items():
        payload = rec.get("payload", {}) if isinstance(rec.get("payload"), dict) else {}
        photos_meta = payload.get("_photos", []) or []
        if isinstance(photos_meta, list):
            for cp in photos_meta:
                if not isinstance(cp, dict):
                    continue
                url = cp.get("previewUrl", "")
                if url:
                    path = _resolve_attachment_url(url)
                    if path and path.exists() and path.name not in seen_files:
                        photo_paths.append(str(path))
                        seen_files.add(path.name)
                for sn, data in (cp.get("samplePhotos", {}) or {}).items():
                    if isinstance(data, dict):
                        url = data.get("previewUrl", "")
                        if url:
                            path = _resolve_attachment_url(url)
                            if path and path.exists() and path.name not in seen_files:
                                photo_paths.append(str(path))
                                seen_files.add(path.name)

    try:
        docx_bytes = generate_report_docx(comm, groups, tasks, records_map, report, user_names, photo_paths or None)
        return Response(
            content=docx_bytes,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers={"Content-Disposition": f"attachment; filename={report_no}.docx"},
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"导出失败: {e}")


# ═══════════════════════════════════════════════════════════════
# ── 报告关单据列表 ──
# ═══════════════════════════════════════════════════════════════

@router.get("/{report_no}/documents")
async def list_report_documents(
    report_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """返回报告关联的所有单据清单和可用操作"""
    role = user.get("role", "")
    if role not in ("质量负责人", "管理员", "复核员", "样品管理员"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看")

    rep_result = await db.execute(
        text("SELECT * FROM reports WHERE report_no=:r"), {"r": report_no}
    )
    rep_row = rep_result.fetchone()
    if not rep_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    report = dict(zip(rep_result.keys(), rep_row))

    commission_no = report.get("commission_no", "")
    documents = []

    # 1. 原始记录
    linked_record = None
    if report.get("task_no"):
        rec_result = await db.execute(
            text("SELECT record_no, version, status, task_no FROM records WHERE task_no=:t ORDER BY version DESC LIMIT 1"),
            {"t": report["task_no"]},
        )
        rec_row = rec_result.fetchone()
        if rec_row:
            linked_record = {"record_no": rec_row[0], "version": rec_row[1], "status": rec_row[2], "task_no": rec_row[3]}
            documents.append({
                "type": "原始记录",
                "code": "RECORD",
                "label": f"原始记录表 — {linked_record['record_no']} V{linked_record['version']}",
                "preview_url": f"/api/v1/records/{linked_record['record_no']}/v{linked_record['version']}/preview",
                "download_url": f"/api/v1/records/{linked_record['record_no']}/v{linked_record['version']}/export",
                "available": True,
            })

    # 2. SOP — 通过关联任务查找对应 SOP 模板
    sop_task_no = report.get("task_no", "")
    sop_available = False
    sop_preview_url = None
    sop_download_url = None
    sop_label = "标准操作规程 (SOP)"
    if sop_task_no:
        try:
            from pathlib import Path
            from app.config import settings
            tk_result = await db.execute(
                text("SELECT experiment_code FROM tasks WHERE task_no=:t"),
                {"t": sop_task_no},
            )
            tk_row = tk_result.fetchone()
            if tk_row and tk_row[0]:
                exp_code = tk_row[0]
                sop_code = exp_code.replace("R", "SOP-")
                if not sop_code.startswith("SOP-"):
                    sop_code = f"SOP-{sop_code}"
                tmpl_dir = Path(settings.TEMPLATE_DIR)
                for f in tmpl_dir.glob(f"{sop_code}_*.docx"):
                    sop_available = True
                    sop_label = f"标准操作规程 (SOP) — {exp_code}"
                    sop_preview_url = f"/api/v1/export/sop/{sop_task_no}/preview"
                    sop_download_url = f"/api/v1/export/sop/{sop_task_no}/export"
                    break
        except Exception:
            pass
    documents.append({
        "type": "SOP",
        "code": "SOP",
        "label": sop_label,
        "preview_url": sop_preview_url,
        "download_url": sop_download_url,
        "available": sop_available,
        "note": "" if sop_available else "SOP文件请从方法管理模块查看",
    })

    # 3. 委托单
    if commission_no:
        documents.append({
            "type": "委托单",
            "code": "COMMISSION",
            "label": f"检验委托单 — {commission_no}",
            "preview_url": f"/api/v1/export/commission/{commission_no}/preview",
            "download_url": f"/api/v1/export/commission/{commission_no}/export",
            "available": True,
        })

    # 4. 样品登记表
    if commission_no:
        documents.append({
            "type": "样品登记表",
            "code": "SAMPLE_REGISTER",
            "label": f"样品登记表 — {commission_no}",
            "preview_url": f"/api/v1/export/sample-register/{commission_no}/preview",
            "download_url": f"/api/v1/export/sample-register/{commission_no}/export",
            "available": True,
        })

    # 5. 借出归还表
    has_loans = False
    if commission_no:
        lr_check = await db.execute(
            text("""
                SELECT 1 FROM package_loans pl
                JOIN samples s ON pl.sample_no = s.sample_no
                WHERE s.commission_no=:c LIMIT 1
            """),
            {"c": commission_no},
        )
        has_loans = lr_check.fetchone() is not None
    documents.append({
        "type": "借出归还表",
        "code": "LOAN_RETURN",
        "label": f"样品借出/归还登记表 — {commission_no}",
        "preview_url": f"/api/v1/export/loan-return/{commission_no}/preview" if has_loans else None,
        "download_url": f"/api/v1/export/loan-return/{commission_no}/export" if has_loans else None,
        "available": has_loans,
    })

    # 6. 危废处置表
    has_hw = False
    if commission_no:
        hw_check = await db.execute(
            text("SELECT 1 FROM hazardous_waste_records WHERE commission_no=:c LIMIT 1"),
            {"c": commission_no},
        )
        has_hw = hw_check.fetchone() is not None
    documents.append({
        "type": "危废处置表",
        "code": "HAZARDOUS_WASTE",
        "label": f"危废处置登记表 — {commission_no}",
        "preview_url": f"/api/v1/export/hazardous-waste/{commission_no}/preview" if has_hw else None,
        "download_url": f"/api/v1/export/hazardous-waste/{commission_no}/export" if has_hw else None,
        "available": has_hw,
    })

    # 7. 检验报告
    documents.append({
        "type": "检验报告",
        "code": "REPORT",
        "label": f"检验报告 — {report_no}",
        "preview_url": f"/api/v1/reports/{report_no}/preview",
        "download_url": f"/api/v1/reports/{report_no}/export",
        "available": True,
    })

    # 8. 报告发放登记表
    del_check = await db.execute(
        text("SELECT 1 FROM report_deliveries WHERE report_no=:r LIMIT 1"),
        {"r": report_no},
    )
    has_deliveries = del_check.fetchone() is not None
    documents.append({
        "type": "发放登记表",
        "code": "REPORT_DELIVERY",
        "label": f"报告发放登记表 — {report_no}",
        "preview_url": f"/api/v1/export/report-delivery/{report_no}/preview" if has_deliveries else None,
        "download_url": f"/api/v1/export/report-delivery/{report_no}/export" if has_deliveries else None,
        "available": has_deliveries,
    })

    return {
        "report_no": report_no,
        "status": report.get("status"),
        "commission_no": commission_no,
        "linked_record": linked_record,
        "documents": documents,
    }


# ═══════════════════════════════════════════════════════════════
# ── 作废 / 更正 ──
# ═══════════════════════════════════════════════════════════════

class VoidCorrectRequest(BaseModel):
    reason: str = Field(..., min_length=1, description="作废/更正原因")
    action: str = Field(default="void", pattern=r"^(void|correct)$")


@router.post("/{report_no}/void")
async def void_report(
    report_no: str,
    body: VoidCorrectRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """管理员作废已发布报告"""
    rep = await db.execute(
        text("SELECT status FROM reports WHERE report_no=:r"), {"r": report_no}
    )
    row = rep.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    if row[0] != "已发布":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail=f"报告状态为'{row[0]}'，只能作废已发布的报告")

    await db.execute(
        text("UPDATE reports SET status='已作废', validity_status='已作废', updated_at=localtimestamp WHERE report_no=:r"),
        {"r": report_no},
    )
    await log_operation(db, "report", report_no, user, "作废报告",
                      comment=body.reason,
                      field_name="status", old_value=row[0], new_value="已作废",
                      reason=body.reason)
    return {"message": "报告已作废", "report_no": report_no, "status": "已作废"}


@router.post("/{report_no}/correct")
async def correct_report(
    report_no: str,
    body: VoidCorrectRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """管理员更正并重新签发报告：作废旧报告 + 生成新版本更正报告"""
    rep = await db.execute(
        text("SELECT status, task_no, commission_no FROM reports WHERE report_no=:r"),
        {"r": report_no},
    )
    row = rep.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="报告不存在")
    if row[0] != "已发布":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                          detail=f"报告状态为'{row[0]}'，只能更正已发布的报告")

    old_status = row[0]
    task_no = row[1]
    # 作废旧报告
    await db.execute(
        text("""
            UPDATE reports SET status='已作废', validity_status='已作废',
                updated_at=localtimestamp WHERE report_no=:r
        """),
        {"r": report_no},
    )
    await log_operation(db, "report", report_no, user, "更正重签",
                      comment=f"更正并重新签发。原因：{body.reason}",
                      field_name="status", old_value=old_status, new_value="已作废",
                      reason=body.reason)

    # 无任务号（异常数据）则仅作废，不生成更正版本
    if not task_no:
        return {"message": "报告已作废（无关联任务，无法自动生成更正版本）",
                "report_no": report_no, "status": "已作废"}

    # 生成更正报告新版本（status=待质量审核，走正常审核→签发流程）
    new_report_no = _correction_report_no(report_no)
    task_res = await db.execute(
        text("SELECT assignee, reviewer, quality_inspector FROM tasks WHERE task_no=:t"),
        {"t": task_no},
    )
    tr = task_res.fetchone()
    admin_res = await db.execute(
        text("SELECT username FROM users WHERE role='管理员' AND enabled=TRUE ORDER BY username LIMIT 1")
    )
    admin_row = admin_res.fetchone()

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
                '{}'::jsonb, '委托检验', '',
                '', '', :sn, localtimestamp, localtimestamp
            )
        """),
        {
            "rn": new_report_no, "cn": row[2], "tn": task_no,
            "tr": (tr[0] if tr else "") or "",
            "vf": (tr[1] if tr else "") or "",
            "qi": (tr[2] if tr else "") or "",
            "ap": admin_row[0] if admin_row else "",
            "sn": report_no,
        },
    )
    await log_operation(db, "report", new_report_no, user, "生成更正报告",
                      comment=f"更正自 {report_no}，原因：{body.reason}")
    return {"message": "已作废旧报告并生成更正报告新版本",
            "report_no": report_no, "new_report_no": new_report_no,
            "status": "已作废", "new_status": "待质量审核"}
