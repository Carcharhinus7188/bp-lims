"""样品资料库 API"""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

import json

from app.core.deps import get_current_user, get_db, require_role
from app.core.model_utils import normalize_model
from app.services.audit_service import log_modification

router = APIRouter(prefix="/catalog", tags=["样品资料库"])


class SampleCatalogOut(BaseModel):
    id: int
    sample_code: str | None
    sample_name: str
    model: str
    material_name: str
    detection_method: str | None
    detection_basis: str | None
    process: str | None
    category: str | None
    unit: str | None
    experiment_codes: list | None
    enabled: bool


class SampleCatalogCreate(BaseModel):
    sample_name: str = Field(..., min_length=1)
    model: str = Field(..., min_length=1)
    material_name: str = Field(..., min_length=1)
    sample_code: str | None = None
    detection_method: str | None = None
    detection_basis: str | None = None
    process: str | None = None
    material_suffix: str | None = None
    source_sequence: str | None = None
    category: str | None = None
    unit: str | None = None
    experiment_codes: list[str] | None = None
    notes: str | None = None


@router.get("", response_model=list[SampleCatalogOut])
async def list_catalog(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
    search: str | None = Query(None),
    limit: int = Query(100, le=500),
):
    """样品目录列表"""
    where = "WHERE enabled=TRUE"
    params: dict = {}
    if search:
        where += " AND (sample_name ILIKE :s OR sample_code ILIKE :s OR material_name ILIKE :s)"
        params["s"] = f"%{search}%"

    result = await db.execute(
        text(f"SELECT id, sample_code, sample_name, model, material_name, detection_method, "
             f"detection_basis, process, category, unit, experiment_codes, enabled "
             f"FROM sample_catalog {where} ORDER BY id LIMIT :limit"),
        {**params, "limit": limit},
    )
    return [
        SampleCatalogOut(
            id=r[0], sample_code=r[1], sample_name=r[2], model=r[3],
            material_name=r[4], detection_method=r[5], detection_basis=r[6],
            process=r[7], category=r[8], unit=r[9],
            experiment_codes=r[10], enabled=r[11],
        )
        for r in result.fetchall()
    ]


@router.post("", response_model=SampleCatalogOut, status_code=201)
async def create_catalog_entry(
    body: SampleCatalogCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """新增样品资料（仅管理员）"""
    model = normalize_model(body.model)
    if not model:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="规格型号不能为空或占位符（如「-」「无」），请填写真实规格型号",
        )
    result = await db.execute(
        text("""
            INSERT INTO sample_catalog (sample_code, sample_name, model, material_name,
              detection_method, detection_basis, process, material_suffix, source_sequence,
              category, unit, experiment_codes, notes)
            VALUES (:sc, :sn, :md, :mn, :dm, :db, :pr, :ms, :ss, :ct, :un, CAST(:ec AS jsonb), :nt)
            RETURNING id
        """),
        {
            "sc": body.sample_code, "sn": body.sample_name, "md": model,
            "mn": body.material_name, "dm": body.detection_method, "db": body.detection_basis,
            "pr": body.process, "ms": body.material_suffix,
            "ss": body.source_sequence, "ct": body.category, "un": body.unit,
            "ec": json.dumps(body.experiment_codes or []), "nt": body.notes,
        },
    )
    new_id = result.fetchone()[0]
    return SampleCatalogOut(
        id=new_id, sample_code=body.sample_code, sample_name=body.sample_name,
        model=model, material_name=body.material_name,
        detection_method=body.detection_method, detection_basis=body.detection_basis,
        process=body.process, category=body.category, unit=body.unit,
        experiment_codes=body.experiment_codes or [], enabled=True,
    )


@router.delete("/{catalog_id}")
async def delete_catalog_entry(
    catalog_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """删除样品资料（软删除，仅管理员）"""
    result = await db.execute(
        text("UPDATE sample_catalog SET enabled=FALSE WHERE id=:i AND enabled=TRUE"),
        {"i": catalog_id},
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="样品资料不存在或已停用")
    return {"message": "样品资料已停用"}


class SampleCatalogUpdate(BaseModel):
    sample_code: str | None = None
    sample_name: str | None = None
    model: str | None = None
    material_name: str | None = None
    detection_method: str | None = None
    detection_basis: str | None = None
    process: str | None = None
    category: str | None = None
    unit: str | None = None
    experiment_codes: list[str] | None = None
    notes: str | None = None
    enabled: bool | None = None


@router.put("/{catalog_id}")
async def update_catalog_entry(
    catalog_id: int,
    body: SampleCatalogUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """编辑样品资料（仅管理员），并回写历史快照到委托样品组/样品/检测项目/任务"""
    old_row = await db.execute(
        text("""SELECT sample_code, sample_name, model, material_name, detection_method,
                detection_basis, process, category, unit, notes, enabled
                FROM sample_catalog WHERE id=:i"""),
        {"i": catalog_id},
    )
    old = old_row.fetchone()
    if not old:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="样品资料不存在")

    old_vals = {
        "sample_code": old[0], "sample_name": old[1], "model": old[2],
        "material_name": old[3], "detection_method": old[4], "detection_basis": old[5],
        "process": old[6], "category": old[7], "unit": old[8], "notes": old[9],
        "enabled": old[10],
    }

    # 归一化规格型号（若填写）
    model_value = None
    if body.model is not None:
        model_value = normalize_model(body.model)
        if not model_value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="规格型号不能为空或占位符（如「-」「无」），请填写真实规格型号",
            )

    updates: list[str] = []
    params: dict = {"i": catalog_id}
    for field in ["sample_code", "sample_name", "material_name", "detection_method",
                  "detection_basis", "process", "category", "unit", "notes", "enabled"]:
        value = getattr(body, field, None)
        if value is not None:
            updates.append(f"{field}=:{field}")
            params[field] = value
    if model_value is not None:
        updates.append("model=:model")
        params["model"] = model_value
    if body.experiment_codes is not None:
        updates.append("experiment_codes=CAST(:ec AS jsonb)")
        params["ec"] = json.dumps(body.experiment_codes)

    if not updates:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="没有要更新的字段")

    # 1) 更新库本身
    await db.execute(
        text(f"UPDATE sample_catalog SET {', '.join(updates)}, updated_at=localtimestamp WHERE id=:i"),
        params,
    )

    # 2) 回写历史快照（只回写本次实际变更的字段）
    synced = 0
    group_result = await db.execute(
        text("SELECT id FROM sample_groups WHERE catalog_id=:i"), {"i": catalog_id}
    )
    group_ids = [r[0] for r in group_result.fetchall()]

    if group_ids:
        # 样品名称 / 规格型号 / 材料名称 / 单位 → 样品组
        sg_updates: list[str] = []
        sg_params: dict = {"i": catalog_id}
        for f in ["sample_name", "model", "material_name", "unit"]:
            v = model_value if f == "model" and model_value is not None else getattr(body, f, None)
            if v is not None:
                sg_updates.append(f"{f}=:{f}")
                sg_params[f] = v
        if sg_updates:
            r = await db.execute(
                text(f"UPDATE sample_groups SET {', '.join(sg_updates)}, updated_at=localtimestamp WHERE catalog_id=:i"),
                sg_params,
            )
            synced += r.rowcount

        # 样品名称 / 规格型号 / 材料名称 → 样品
        sm_updates: list[str] = []
        sm_params: dict = {"gids": group_ids}
        for f in ["sample_name", "model", "material_name"]:
            v = model_value if f == "model" and model_value is not None else getattr(body, f, None)
            if v is not None:
                sm_updates.append(f"{f}=:{f}")
                sm_params[f] = v
        if sm_updates:
            r = await db.execute(
                text(f"UPDATE samples SET {', '.join(sm_updates)}, updated_at=localtimestamp WHERE group_id = ANY(:gids)"),
                sm_params,
            )
            synced += r.rowcount

        # 检测方法 → requested_tests.method_code + tasks.method_code
        if body.detection_method is not None:
            r1 = await db.execute(
                text("UPDATE requested_tests SET method_code=:m WHERE group_id = ANY(:gids)"),
                {"m": body.detection_method, "gids": group_ids},
            )
            r2 = await db.execute(
                text("UPDATE tasks SET method_code=:m WHERE group_id = ANY(:gids)"),
                {"m": body.detection_method, "gids": group_ids},
            )
            synced += r1.rowcount + r2.rowcount

        # 检测依据 → requested_tests.standard + tasks.standard
        if body.detection_basis is not None:
            r1 = await db.execute(
                text("UPDATE requested_tests SET standard=:s WHERE group_id = ANY(:gids)"),
                {"s": body.detection_basis, "gids": group_ids},
            )
            r2 = await db.execute(
                text("UPDATE tasks SET standard=:s WHERE group_id = ANY(:gids)"),
                {"s": body.detection_basis, "gids": group_ids},
            )
            synced += r1.rowcount + r2.rowcount

    # 3) 审计：逐字段记录旧值→新值
    for field in ["sample_name", "model", "material_name", "detection_method",
                  "detection_basis", "process", "category", "unit", "notes", "enabled"]:
        new_value = model_value if field == "model" and model_value is not None else getattr(body, field, None)
        if new_value is not None and str(new_value) != str(old_vals[field]):
            await log_modification(
                db, "sample_catalog", str(catalog_id), user, field,
                old_value=str(old_vals[field]) if old_vals[field] is not None else None,
                new_value=str(new_value),
                reason=f"编辑样品资料，回写历史快照 {synced} 条",
            )

    return {"message": "样品资料已更新", "synced": synced}
