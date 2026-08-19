"""回库确认 API — 样品借出归还管理"""
from __future__ import annotations

import json
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, require_role
from app.services.audit_service import log_operation

router = APIRouter(prefix="/returns", tags=["回库确认"])


class ReturnConfirm(BaseModel):
    return_condition: str | None = None
    return_note: str | None = None
    confirmed_location: str | None = None


class SubmitReturnRequest(BaseModel):
    package_no: str
    sample_nos: list[str]
    detection_location: str = ""
    purpose: str = "实验检测"
    issue_note: str = ""


@router.get("")
async def list_returns(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
    package_no: str | None = Query(None, description="任务包编号过滤"),
    return_status: str | None = Query(None, description="归还状态过滤：未归还/已归还/已确认"),
    search: str | None = Query(None, description="搜索样品编号或借用人"),
    limit: int = Query(100, le=500),
    offset: int = Query(0, ge=0),
):
    """样品借出/归还记录列表"""
    where = "WHERE 1=1"
    params: dict = {}

    if package_no:
        where += " AND pl.package_no = :pkg"
        params["pkg"] = package_no
    if return_status:
        where += " AND pl.return_status = :rs"
        params["rs"] = return_status
    if search:
        where += " AND (pl.sample_no ILIKE :s OR pl.borrower ILIKE :s)"
        params["s"] = f"%{search}%"

    result = await db.execute(
        text(f"""
            SELECT pl.id, pl.package_no, pl.sample_no, pl.borrower, pl.borrowed_at,
                   pl.purpose, pl.detection_location, pl.issue_note,
                   pl.return_condition, pl.return_note, pl.returned_by, pl.returned_at,
                   pl.return_status, pl.confirmed_by, pl.confirmed_at, pl.confirmed_location,
                   s.sample_name, s.material_name
            FROM package_loans pl
            LEFT JOIN samples s ON pl.sample_no = s.sample_no
            {where}
            ORDER BY pl.borrowed_at DESC
            LIMIT :limit OFFSET :offset
        """),
        {**params, "limit": limit, "offset": offset},
    )
    rows = result.fetchall()
    return [dict(zip(result.keys(), r)) for r in rows]


@router.put("/{loan_id}/confirm")
async def confirm_return(
    loan_id: int,
    body: ReturnConfirm,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """确认样品回库（样品管理员操作）"""
    # 检查记录存在
    result = await db.execute(
        text("SELECT id, return_status, sample_no, package_no FROM package_loans WHERE id=:id"),
        {"id": loan_id},
    )
    loan = result.fetchone()
    if not loan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="借出记录不存在")
    if loan[1] == "已确认":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该记录已确认回库")

    sample_no = loan[2]
    package_no = loan[3]

    # 解析 commission_no（用于审计追溯）
    comm_row = await db.execute(
        text("SELECT commission_no FROM samples WHERE sample_no=:sn"),
        {"sn": sample_no},
    )
    comm_val = comm_row.fetchone()
    commission_no = comm_val[0] if comm_val else None

    now = text("localtimestamp")
    await db.execute(
        text("""
            UPDATE package_loans
            SET return_condition = COALESCE(:cond, return_condition),
                return_note = COALESCE(:note, return_note),
                return_status = '已确认',
                confirmed_by = :user,
                confirmed_at = :now,
                confirmed_location = COALESCE(:loc, confirmed_location)
            WHERE id = :id
        """),
        {
            "id": loan_id,
            "cond": body.return_condition,
            "note": body.return_note,
            "loc": body.confirmed_location,
            "user": user["username"],
            "now": now,
        },
    )

    # 回写样品状态：借出中 → 已入库，清空持有人
    await db.execute(
        text("""UPDATE samples SET status='已入库', current_holder='', updated_at=localtimestamp
                WHERE sample_no=:sn AND status='借出中'"""),
        {"sn": sample_no},
    )

    # 审计日志（完整落库，含哈希链 + commission_no 追溯）
    await log_operation(db, "package_loan", str(loan_id), user, "确认回库",
                        commission_no=commission_no,
                        comment=body.return_condition or "样品已回库")

    return {"message": "回库已确认", "loan_id": loan_id, "sample_no": sample_no}


@router.post("/submit", status_code=201)
async def submit_return(
    body: SubmitReturnRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """实验员提交样品归还清单"""
    actor = user["username"]
    if user.get("role") != "实验员":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只有实验员可以提交归还")

    if not body.sample_nos:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="至少选择一个样品")

    # 门禁：任务包内所有任务必须已走完复核流程，实验员才可归还样品
    task_rows = await db.execute(
        text("SELECT task_no, status FROM tasks WHERE package_no=:pn"),
        {"pn": body.package_no},
    )
    pkg_tasks = task_rows.fetchall()
    if not pkg_tasks:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务包不存在或未关联任务")
    pending = [t[0] for t in pkg_tasks if t[1] not in ("已复核", "已完成", "已回库")]
    if pending:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                             detail=f"任务未完成复核，暂不能归还样品：{', '.join(pending)}")

    updated = 0
    for sno in body.sample_nos:
        res = await db.execute(
            text("""SELECT id, return_status FROM package_loans
                    WHERE package_no=:pn AND sample_no=:sn AND borrower=:b"""),
            {"pn": body.package_no, "sn": sno, "b": actor},
        )
        loan = res.fetchone()
        if not loan:
            continue
        if dict(zip(res.keys(), loan)).get("return_status") != "未归还":
            continue

        await db.execute(
            text("""UPDATE package_loans SET return_status='已归还',
                    returned_by=:b, returned_at=localtimestamp, updated_at=localtimestamp
                    WHERE id=:id"""),
            {"id": loan[0], "b": actor},
        )
        updated += 1

    if updated == 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="没有可归还的借出记录")

    # 通知样品管理员
    admins = await db.execute(
        text("SELECT username FROM users WHERE role='样品管理员' AND enabled IS TRUE"))
    for r in admins.fetchall():
        await db.execute(
            text("""INSERT INTO notifications (recipient, title, message, entity_type, entity_id, created_at)
                    VALUES (:r, '样品待确认回库', :b, 'package_loan', :pn, localtimestamp)"""),
            {"r": r[0], "b": f"任务包{body.package_no}中{updated}个样品已归还，请确认回库", "pn": body.package_no},
        )

    return {"message": f"已提交 {updated} 个样品归还", "return_count": updated}


@router.get("/pending")
async def list_pending_returns(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """样品管理员查看待确认的归还记录"""
    result = await db.execute(
        text("""
            SELECT pl.*, s.sample_name, s.material_name
            FROM package_loans pl
            LEFT JOIN samples s ON pl.sample_no = s.sample_no
            WHERE pl.return_status = '已归还'
            ORDER BY pl.returned_at DESC
            LIMIT 200
        """)
    )
    return [dict(zip(result.keys(), r)) for r in result.fetchall()]


@router.get("/stats")
async def return_stats(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """回库统计"""
    result = await db.execute(
        text("""
            SELECT return_status, COUNT(*) as cnt
            FROM package_loans
            GROUP BY return_status
        """)
    )
    stats = {r[0]: r[1] for r in result.fetchall()}
    return {
        "total": sum(stats.values()),
        "unreturned": stats.get("未归还", 0),
        "returned": stats.get("已归还", 0),
        "confirmed": stats.get("已确认", 0),
    }
