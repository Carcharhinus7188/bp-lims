"""检测项目与方法库 API"""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, require_role
from app.services.audit_service import log_modification

router = APIRouter(prefix="/methods", tags=["检测方法"])


class MethodOut(BaseModel):
    experiment_code: str
    experiment_name: str
    method_code: str
    standard: str | None
    category: str | None
    kind: str | None
    template_code: str | None = None
    sop_file: str | None = None
    enabled: bool
    sort_order: int


class MethodCreate(BaseModel):
    experiment_code: str = Field(..., min_length=1, description="实验编码，如 I001")
    experiment_name: str = Field(..., min_length=1, description="实验名称，如 表面粗糙度检测")
    method_code: str = Field(..., min_length=1, description="方法编号，如 GB/T 1031-2009")
    standard: str | None = None
    category: str | None = None
    kind: str = Field(default="generic", description="实验类型")
    template_code: str | None = None
    sop_file: str | None = None


@router.get("", response_model=list[MethodOut])
async def list_methods(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
    enabled_only: bool = Query(True),
):
    """检测项目列表"""
    where = "WHERE enabled=TRUE" if enabled_only else ""
    result = await db.execute(
        text(f"SELECT experiment_code, experiment_name, method_code, standard, category, kind, template_code, sop_file, enabled, sort_order "
             f"FROM experiment_methods {where} ORDER BY sort_order, experiment_code")
    )
    return [
        MethodOut(
            experiment_code=r[0], experiment_name=r[1], method_code=r[2],
            standard=r[3], category=r[4], kind=r[5],
            template_code=r[6], sop_file=r[7],
            enabled=r[8], sort_order=r[9],
        )
        for r in result.fetchall()
    ]


@router.post("", response_model=MethodOut, status_code=201)
async def create_method(
    body: MethodCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """新增检测项目（仅管理员）"""
    # 检查实验编码是否已存在
    existing = await db.execute(
        text("SELECT experiment_code, experiment_name, enabled, sort_order FROM experiment_methods WHERE experiment_code=:c"),
        {"c": body.experiment_code},
    )
    existing_row = existing.fetchone()
    if existing_row:
        if existing_row[2]:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="实验编码已存在")
        else:
            # 已停用 → 重新启用并更新
            await db.execute(
                text("""UPDATE experiment_methods SET enabled=TRUE, experiment_name=:en,
                    method_code=:mc, standard=:st, category=:ct, kind=:kd,
                    template_code=:tc, sop_file=:sf, updated_at=localtimestamp
                    WHERE experiment_code=:c"""),
                {"c": body.experiment_code, "en": body.experiment_name, "mc": body.method_code,
                 "st": body.standard, "ct": body.category, "kd": body.kind,
                 "tc": body.template_code, "sf": body.sop_file},
            )
            return MethodOut(
                experiment_code=body.experiment_code,
                experiment_name=body.experiment_name,
                method_code=body.method_code,
                standard=body.standard, category=body.category,
                kind=body.kind, enabled=True,
                template_code=body.template_code, sop_file=body.sop_file,
                sort_order=existing_row[3],
            )

    # 自动排序号
    seq_result = await db.execute(text("SELECT COALESCE(MAX(sort_order), 0) + 1 FROM experiment_methods"))
    next_seq = seq_result.fetchone()[0]

    await db.execute(
        text("""
            INSERT INTO experiment_methods (experiment_code, experiment_name, method_code,
              standard, category, kind, template_code, sop_file, enabled, sort_order, created_at, updated_at)
            VALUES (:ec, :en, :mc, :st, :ct, :kd, :tc, :sf, TRUE, :so, localtimestamp, localtimestamp)
        """),
        {
            "ec": body.experiment_code, "en": body.experiment_name, "mc": body.method_code,
            "st": body.standard, "ct": body.category, "kd": body.kind,
            "tc": body.template_code, "sf": body.sop_file, "so": next_seq,
        },
    )

    return MethodOut(
        experiment_code=body.experiment_code,
        experiment_name=body.experiment_name,
        method_code=body.method_code,
        standard=body.standard,
        category=body.category,
        kind=body.kind,
        template_code=body.template_code,
        sop_file=body.sop_file,
        enabled=True,
        sort_order=next_seq,
    )


class MethodUpdate(BaseModel):
    experiment_name: str | None = None
    method_code: str | None = None
    standard: str | None = None
    category: str | None = None
    kind: str | None = None
    template_code: str | None = None
    sop_file: str | None = None
    enabled: bool | None = None


@router.put("/{experiment_code}")
async def update_method(
    experiment_code: str,
    body: MethodUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """编辑检测项目，并回写方法编号/标准到历史检测项目/任务"""
    existing = await db.execute(
        text("""SELECT experiment_name, method_code, standard, category, kind,
                template_code, sop_file, enabled FROM experiment_methods WHERE experiment_code=:c"""),
        {"c": experiment_code},
    )
    old = existing.fetchone()
    if not old:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="检测项目不存在")

    old_vals = {
        "experiment_name": old[0], "method_code": old[1], "standard": old[2],
        "category": old[3], "kind": old[4], "template_code": old[5],
        "sop_file": old[6], "enabled": old[7],
    }

    updates = []
    params: dict = {"c": experiment_code}
    for field in ["experiment_name", "method_code", "standard", "category", "kind",
                   "template_code", "sop_file", "enabled"]:
        value = getattr(body, field, None)
        if value is not None:
            updates.append(f"{field}=:{field}")
            params[field] = value

    if not updates:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="没有要更新的字段")

    await db.execute(
        text(f"UPDATE experiment_methods SET {', '.join(updates)}, updated_at=localtimestamp WHERE experiment_code=:c"),
        params,
    )

    # 回写方法编号/标准到历史 requested_tests + tasks
    synced = 0
    if body.method_code is not None:
        r1 = await db.execute(
            text("UPDATE requested_tests SET method_code=:m WHERE experiment_code=:c"),
            {"m": body.method_code, "c": experiment_code},
        )
        r2 = await db.execute(
            text("UPDATE tasks SET method_code=:m WHERE experiment_code=:c"),
            {"m": body.method_code, "c": experiment_code},
        )
        synced += r1.rowcount + r2.rowcount
    if body.standard is not None:
        r1 = await db.execute(
            text("UPDATE requested_tests SET standard=:s WHERE experiment_code=:c"),
            {"s": body.standard, "c": experiment_code},
        )
        r2 = await db.execute(
            text("UPDATE tasks SET standard=:s WHERE experiment_code=:c"),
            {"s": body.standard, "c": experiment_code},
        )
        synced += r1.rowcount + r2.rowcount

    # 审计
    for field in ["experiment_name", "method_code", "standard", "category", "kind",
                  "template_code", "sop_file", "enabled"]:
        new_value = getattr(body, field, None)
        if new_value is not None and str(new_value) != str(old_vals[field]):
            await log_modification(
                db, "experiment_method", experiment_code, user, field,
                old_value=str(old_vals[field]) if old_vals[field] is not None else None,
                new_value=str(new_value),
                reason=f"编辑检测项目，回写历史 {synced} 条",
            )

    return {"message": f"检测项目 {experiment_code} 已更新", "synced": synced}


@router.delete("/{experiment_code}")
async def delete_method(
    experiment_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """删除检测项目（软删除，仅管理员）"""
    result = await db.execute(
        text("UPDATE experiment_methods SET enabled=FALSE, updated_at=localtimestamp WHERE experiment_code=:c AND enabled=TRUE"),
        {"c": experiment_code},
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="检测项目不存在或已停用")
    return {"message": f"检测项目 {experiment_code} 已停用"}


@router.get("/categories")
async def method_categories(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """获取所有检测类别"""
    result = await db.execute(
        text("SELECT DISTINCT category FROM experiment_methods WHERE enabled=TRUE AND category IS NOT NULL ORDER BY category")
    )
    return [r[0] for r in result.fetchall()]


# ============ 标准变体（一个检测项目多个标准，拆分独立使用） ============

class StandardOut(BaseModel):
    id: int
    experiment_code: str
    standard: str
    enabled: bool
    sort_order: int


class StandardCreate(BaseModel):
    standard: str = Field(..., min_length=1, description="标准全文")


class StandardUpdate(BaseModel):
    standard: str | None = None
    enabled: bool | None = None
    sort_order: int | None = None


_STANDARD_COLS = ("standard", "enabled", "sort_order")


@router.get("/{experiment_code}/standards", response_model=list[StandardOut])
async def list_standards(
    experiment_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """列出某检测项目的所有标准变体"""
    result = await db.execute(
        text("""
            SELECT id, experiment_code, standard, enabled, sort_order
            FROM experiment_standards
            WHERE experiment_code=:c
            ORDER BY sort_order, id
        """),
        {"c": experiment_code},
    )
    return [dict(zip(result.keys(), r)) for r in result.fetchall()]


@router.post("/{experiment_code}/standards", response_model=StandardOut, status_code=201)
async def create_standard(
    experiment_code: str,
    body: StandardCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """为检测项目新增一个标准变体（沿用父实验编码，仅管理员）"""
    parent = await db.execute(
        text("SELECT experiment_code FROM experiment_methods WHERE experiment_code=:c"),
        {"c": experiment_code},
    )
    if not parent.fetchone():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="检测项目不存在")

    dup = await db.execute(
        text("SELECT id FROM experiment_standards WHERE experiment_code=:c AND standard=:st"),
        {"c": experiment_code, "st": body.standard},
    )
    if dup.fetchone():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="该标准已存在")

    seq_result = await db.execute(
        text("SELECT COALESCE(MAX(sort_order), 0) + 1 FROM experiment_standards WHERE experiment_code=:c"),
        {"c": experiment_code},
    )
    sort_order = seq_result.fetchone()[0]

    result = await db.execute(
        text("""
            INSERT INTO experiment_standards
              (experiment_code, standard, enabled, sort_order, created_at, updated_at)
            VALUES (:ec, :st, TRUE, :so, localtimestamp, localtimestamp)
            RETURNING id
        """),
        {"ec": experiment_code, "st": body.standard, "so": sort_order},
    )
    new_id = result.fetchone()[0]

    await log_modification(
        db, "experiment_standard", str(new_id), user, "standard",
        old_value=None, new_value=body.standard,
        reason=f"为 {experiment_code} 新增标准变体", action="create",
    )

    return StandardOut(
        id=new_id, experiment_code=experiment_code, standard=body.standard,
        enabled=True, sort_order=sort_order,
    )


@router.put("/{experiment_code}/standards/{standard_id}")
async def update_standard(
    experiment_code: str,
    standard_id: int,
    body: StandardUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """编辑某标准变体（仅管理员）"""
    existing = await db.execute(
        text("SELECT standard, enabled, sort_order FROM experiment_standards WHERE id=:id AND experiment_code=:c"),
        {"id": standard_id, "c": experiment_code},
    )
    old = existing.fetchone()
    if not old:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="标准变体不存在")

    old_vals = {"standard": old[0], "enabled": old[1], "sort_order": old[2]}

    updates = []
    params: dict = {"id": standard_id, "c": experiment_code}
    for field in _STANDARD_COLS:
        value = getattr(body, field, None)
        if value is not None:
            updates.append(f"{field}=:{field}")
            params[field] = value

    if not updates:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="没有要更新的字段")

    if body.standard is not None:
        dup = await db.execute(
            text("SELECT id FROM experiment_standards WHERE experiment_code=:c AND standard=:st AND id<>:id"),
            {"c": experiment_code, "st": body.standard, "id": standard_id},
        )
        if dup.fetchone():
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="该标准已存在")

    await db.execute(
        text(f"UPDATE experiment_standards SET {', '.join(updates)}, updated_at=localtimestamp "
             f"WHERE id=:id AND experiment_code=:c"),
        params,
    )

    for field in _STANDARD_COLS:
        new_value = getattr(body, field, None)
        if new_value is not None and str(new_value) != str(old_vals[field]):
            await log_modification(
                db, "experiment_standard", str(standard_id), user, field,
                old_value=str(old_vals[field]) if old_vals[field] is not None else None,
                new_value=str(new_value), reason=f"编辑标准变体 {experiment_code}",
            )

    return {"message": "标准变体已更新"}


@router.delete("/{experiment_code}/standards/{standard_id}")
async def delete_standard(
    experiment_code: str,
    standard_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """删除某标准变体（仅管理员）"""
    existing = await db.execute(
        text("SELECT standard FROM experiment_standards WHERE id=:id AND experiment_code=:c"),
        {"id": standard_id, "c": experiment_code},
    )
    old = existing.fetchone()
    if not old:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="标准变体不存在")

    await db.execute(
        text("DELETE FROM experiment_standards WHERE id=:id AND experiment_code=:c"),
        {"id": standard_id, "c": experiment_code},
    )
    await log_modification(
        db, "experiment_standard", str(standard_id), user, "standard",
        old_value=old[0], new_value=None,
        reason="删除标准变体", action="delete",
    )
    return {"message": "标准变体已删除"}
