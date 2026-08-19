"""样品留样/处置 API — 回库后的留样登记与到期处置"""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db

router = APIRouter(prefix="/samples", tags=["样品管理"])


class RetainRequest(BaseModel):
    retention_period: str = ""  # 留样期限（如「12个月」「直至报告异议期满」）
    retention_until: str = ""   # 到期日 YYYY-MM-DD（空则无固定到期）


class DisposeRequest(BaseModel):
    disposal_type: str = Field(default="销毁", pattern=r"^(销毁|报废)$")
    disposal_method: str = ""   # 具体处置方式
    disposal_date: str = ""     # YYYY-MM-DD
    disposal_note: str = ""


@router.get("")
async def list_samples(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
    status_filter: str | None = Query(None, alias="status"),
    search: str | None = Query(None, description="按样品编号/名称/材料搜索"),
    limit: int = Query(100, le=500),
    offset: int = Query(0, ge=0),
):
    """样品列表（含留样/处置字段），供留样管理视图使用"""
    where = "WHERE 1=1"
    params: dict = {}
    if status_filter:
        where += " AND s.status = :st"
        params["st"] = status_filter
    if search:
        where += " AND (s.sample_no ILIKE :s OR s.sample_name ILIKE :s OR s.material_name ILIKE :s)"
        params["s"] = f"%{search}%"

    result = await db.execute(
        text(f"""
            SELECT s.* FROM samples s
            {where}
            ORDER BY s.updated_at DESC
            LIMIT :limit OFFSET :offset
        """),
        {**params, "limit": limit, "offset": offset},
    )
    return [dict(zip(result.keys(), r)) for r in result.fetchall()]


@router.post("/{sample_no}/retain")
async def retain_sample(
    sample_no: str,
    body: RetainRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """样品管理员登记留样（期限/到期日）"""
    if user.get("role") != "样品管理员":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只有样品管理员可以登记留样")

    sample = await db.execute(
        text("SELECT sample_no FROM samples WHERE sample_no=:s"), {"s": sample_no}
    )
    if not sample.fetchone():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="样品不存在")

    until = body.retention_until.strip() or None
    await db.execute(
        text("""
            UPDATE samples SET retention_period=:rp, retention_until=:ru,
                updated_at=localtimestamp WHERE sample_no=:s
        """),
        {"rp": body.retention_period.strip(), "ru": until, "s": sample_no},
    )

    await db.execute(
        text("""
            INSERT INTO audit_logs (entity_type, entity_id, actor, actor_name, actor_role, action, created_at)
            VALUES ('sample', :eid, :actor, :name, :role, 'retain_sample', localtimestamp)
        """),
        {
            "eid": sample_no,
            "actor": user["username"],
            "name": user.get("display_name", ""),
            "role": user.get("role", ""),
        },
    )
    return {"message": "留样已登记", "sample_no": sample_no,
            "retention_period": body.retention_period.strip(), "retention_until": until}


@router.post("/{sample_no}/dispose")
async def dispose_sample(
    sample_no: str,
    body: DisposeRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """样品管理员处置/销毁/报废样品"""
    if user.get("role") != "样品管理员":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只有样品管理员可以处置样品")

    sample = await db.execute(
        text("SELECT status FROM samples WHERE sample_no=:s"), {"s": sample_no}
    )
    row = sample.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="样品不存在")

    new_status = "已销毁" if body.disposal_type == "销毁" else "已报废"
    await db.execute(
        text("""
            UPDATE samples SET status=:st, disposal_method=:dm, disposal_date=:dd,
                disposal_note=:dn, disposed_by=:by, updated_at=localtimestamp
            WHERE sample_no=:s
        """),
        {
            "st": new_status,
            "dm": body.disposal_method.strip(),
            "dd": body.disposal_date.strip() or None,
            "dn": body.disposal_note.strip(),
            "by": user["username"],
            "s": sample_no,
        },
    )

    await db.execute(
        text("""
            INSERT INTO audit_logs (entity_type, entity_id, actor, actor_name, actor_role, action, created_at)
            VALUES ('sample', :eid, :actor, :name, :role, 'dispose_sample', localtimestamp)
        """),
        {
            "eid": sample_no,
            "actor": user["username"],
            "name": user.get("display_name", ""),
            "role": user.get("role", ""),
        },
    )
    return {"message": f"样品已{body.disposal_type}", "sample_no": sample_no, "status": new_status}
