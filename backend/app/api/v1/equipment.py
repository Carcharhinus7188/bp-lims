"""设备库 API"""
from __future__ import annotations

from typing import Annotated

import json

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, require_role
from app.services.audit_service import log_modification

router = APIRouter(prefix="/equipment", tags=["设备库"])


class EquipmentOut(BaseModel):
    management_no: str
    seq: int | None
    equipment_name: str
    model: str | None
    measuring_range: str | None
    manufacturer: str | None
    serial_no: str | None
    purchase_time: str | None
    calibration_time: str | None
    calibration_due: str | None
    calibration_certificate: str | None
    responsible: str | None
    equipment_class: str | None
    enabled: bool
    lifecycle_status: str | None
    notes: str | None


class EquipmentCreate(BaseModel):
    management_no: str = Field(..., min_length=1)
    equipment_name: str = Field(..., min_length=1)
    model: str | None = None
    measuring_range: str | None = None
    manufacturer: str | None = None
    serial_no: str | None = None
    purchase_time: str | None = None
    calibration_time: str | None = None
    calibration_due: str | None = None
    calibration_certificate: str | None = None
    responsible: str | None = None
    equipment_class: str | None = None
    lifecycle_status: str | None = None
    notes: str | None = None


@router.get("", response_model=list[EquipmentOut])
async def list_equipment(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
    search: str | None = Query(None),
    equipment_class: str | None = Query(None),
    include_disabled: bool = Query(False),
    limit: int = Query(200, le=500),
):
    """设备列表"""
    where = "WHERE enabled=TRUE" if not include_disabled else "WHERE 1=1"
    params: dict = {}
    if search:
        where += " AND (equipment_name ILIKE :s OR management_no ILIKE :s OR model ILIKE :s)"
        params["s"] = f"%{search}%"
    if equipment_class:
        where += " AND equipment_class=:ec"
        params["ec"] = equipment_class

    result = await db.execute(
        text(f"SELECT management_no, seq, equipment_name, model, measuring_range, manufacturer, "
             f"serial_no, purchase_time, calibration_time, calibration_due, calibration_certificate, "
             f"responsible, equipment_class, enabled, lifecycle_status, notes "
             f"FROM equipment_registry {where} ORDER BY seq LIMIT :limit"),
        {**params, "limit": limit},
    )
    return [
        EquipmentOut(
            management_no=r[0], seq=r[1], equipment_name=r[2], model=r[3],
            measuring_range=r[4], manufacturer=r[5], serial_no=r[6],
            purchase_time=r[7], calibration_time=r[8], calibration_due=r[9],
            calibration_certificate=r[10], responsible=r[11],
            equipment_class=r[12], enabled=r[13], lifecycle_status=r[14], notes=r[15],
        )
        for r in result.fetchall()
    ]


@router.post("", response_model=EquipmentOut, status_code=201)
async def create_equipment(
    body: EquipmentCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """新增设备（仅管理员）"""
    # 检查管理编号是否已存在
    existing = await db.execute(
        text("SELECT management_no FROM equipment_registry WHERE management_no=:mn"),
        {"mn": body.management_no},
    )
    if existing.fetchone():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="设备管理编号已存在")

    # 自动生成 seq
    seq_result = await db.execute(text("SELECT COALESCE(MAX(seq), 0) + 1 FROM equipment_registry"))
    next_seq = seq_result.fetchone()[0]

    await db.execute(
        text("""
            INSERT INTO equipment_registry (management_no, seq, equipment_name, model,
              measuring_range, manufacturer, serial_no, purchase_time, calibration_time,
              calibration_due, calibration_certificate,
              responsible, equipment_class, lifecycle_status, notes)
            VALUES (:mn, :sq, :en, :md, :mr, :mf, :sn, :pt, :ct, :cd, :cc, :rp, :ec, :ls, :nt)
        """),
        {
            "mn": body.management_no, "sq": next_seq, "en": body.equipment_name,
            "md": body.model, "mr": body.measuring_range, "mf": body.manufacturer,
            "sn": body.serial_no, "pt": body.purchase_time, "ct": body.calibration_time,
            "cd": body.calibration_due, "cc": body.calibration_certificate,
            "rp": body.responsible, "ec": body.equipment_class,
            "ls": body.lifecycle_status or "正常", "nt": body.notes,
        },
    )

    return EquipmentOut(
        management_no=body.management_no, seq=next_seq, equipment_name=body.equipment_name,
        model=body.model, measuring_range=body.measuring_range, manufacturer=body.manufacturer,
        serial_no=body.serial_no, purchase_time=body.purchase_time,
        calibration_time=body.calibration_time, calibration_due=body.calibration_due,
        calibration_certificate=body.calibration_certificate, responsible=body.responsible,
        equipment_class=body.equipment_class, enabled=True,
        lifecycle_status=body.lifecycle_status or "正常", notes=body.notes,
    )


@router.delete("/{management_no}")
async def delete_equipment(
    management_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """删除设备（软删除，仅管理员）"""
    result = await db.execute(
        text("UPDATE equipment_registry SET enabled=FALSE WHERE management_no=:mn AND enabled=TRUE"),
        {"mn": management_no},
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="设备不存在或已停用")
    return {"message": f"设备 {management_no} 已停用"}


class LifecycleRequest(BaseModel):
    note: str = ""


@router.post("/{management_no}/enable")
async def enable_equipment(
    management_no: str,
    body: LifecycleRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """启用设备（仅管理员，用于故障隔离/停用后重新启用）"""
    result = await db.execute(
        text("""UPDATE equipment_registry SET enabled=TRUE, lifecycle_status='启用',
                status_note=COALESCE(NULLIF(:nt, ''), '恢复使用'), updated_at=localtimestamp
                WHERE management_no=:mn"""),
        {"mn": management_no, "nt": body.note.strip()},
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="设备不存在")
    return {"message": f"设备 {management_no} 已启用", "management_no": management_no, "enabled": True}


@router.post("/{management_no}/disable")
async def disable_equipment(
    management_no: str,
    body: LifecycleRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(require_role("管理员"))],
):
    """停用设备（仅管理员，故障/报废/维护隔离）"""
    result = await db.execute(
        text("""UPDATE equipment_registry SET enabled=FALSE, lifecycle_status='停用',
                status_note=COALESCE(NULLIF(:nt, ''), '管理员停用'), updated_at=localtimestamp
                WHERE management_no=:mn"""),
        {"mn": management_no, "nt": body.note.strip()},
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="设备不存在")
    return {"message": f"设备 {management_no} 已停用", "management_no": management_no, "enabled": False}


class EquipmentUpdate(BaseModel):
    equipment_name: str | None = None
    model: str | None = None
    measuring_range: str | None = None
    manufacturer: str | None = None
    serial_no: str | None = None
    purchase_time: str | None = None
    calibration_time: str | None = None
    calibration_due: str | None = None
    calibration_certificate: str | None = None
    responsible: str | None = None
    equipment_class: str | None = None
    lifecycle_status: str | None = None
    notes: str | None = None
    enabled: bool | None = None


@router.put("/{management_no}")
async def update_equipment(
    management_no: str,
    body: EquipmentUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员"))],
):
    """编辑设备（仅管理员），并回写历史快照到记录 payload 的设备清单"""
    old_row = await db.execute(
        text("""SELECT equipment_name, model, measuring_range, manufacturer, serial_no,
                calibration_time, calibration_due, calibration_certificate, responsible,
                equipment_class, lifecycle_status, notes, enabled
                FROM equipment_registry WHERE management_no=:mn"""),
        {"mn": management_no},
    )
    old = old_row.fetchone()
    if not old:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="设备不存在")

    old_vals = {
        "equipment_name": old[0], "model": old[1], "measuring_range": old[2],
        "manufacturer": old[3], "serial_no": old[4], "calibration_time": old[5],
        "calibration_due": old[6], "calibration_certificate": old[7], "responsible": old[8],
        "equipment_class": old[9], "lifecycle_status": old[10], "notes": old[11], "enabled": old[12],
    }

    updates: list[str] = []
    params: dict = {"mn": management_no}
    for field in ["equipment_name", "model", "measuring_range", "manufacturer", "serial_no",
                  "purchase_time", "calibration_time", "calibration_due", "calibration_certificate",
                  "responsible", "equipment_class", "lifecycle_status", "notes", "enabled"]:
        value = getattr(body, field, None)
        if value is not None:
            updates.append(f"{field}=:{field}")
            params[field] = value

    if not updates:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="没有要更新的字段")

    # 1) 更新设备库本身
    await db.execute(
        text(f"UPDATE equipment_registry SET {', '.join(updates)}, updated_at=localtimestamp WHERE management_no=:mn"),
        params,
    )

    # 2) 回写 records.payload._equipment_checks 里匹配该设备的快照字段
    snapshot_fields = ["equipment_name", "model", "measuring_range", "manufacturer", "serial_no",
                       "calibration_time", "calibration_due", "calibration_certificate",
                       "equipment_class", "responsible"]
    patch = {f: getattr(body, f) for f in snapshot_fields if getattr(body, f) is not None}

    synced = 0
    if patch:
        patch_json = json.dumps(patch, ensure_ascii=False)
        r = await db.execute(
            text("""
                UPDATE records SET payload = jsonb_set(
                    payload,
                    '{_equipment_checks}',
                    (SELECT jsonb_agg(
                            CASE WHEN elem->>'management_no' = CAST(:mn AS text)
                                 THEN elem || CAST(:patch AS jsonb)
                                 ELSE elem END)
                     FROM jsonb_array_elements(payload->'_equipment_checks') elem),
                    false
                ), updated_at = localtimestamp
                WHERE payload->'_equipment_checks' IS NOT NULL
                  AND payload->'_equipment_checks' @> jsonb_build_array(jsonb_build_object('management_no', CAST(:mn AS text)))
            """),
            {"mn": management_no, "patch": patch_json},
        )
        synced = r.rowcount

    # 3) 审计：逐字段记录旧值→新值
    for field in ["equipment_name", "model", "measuring_range", "manufacturer", "serial_no",
                  "calibration_time", "calibration_due", "calibration_certificate",
                  "responsible", "equipment_class", "lifecycle_status", "notes", "enabled"]:
        new_value = getattr(body, field, None)
        if new_value is not None and str(new_value) != str(old_vals[field]):
            await log_modification(
                db, "equipment", management_no, user, field,
                old_value=str(old_vals[field]) if old_vals[field] is not None else None,
                new_value=str(new_value),
                reason=f"编辑设备，回写记录快照 {synced} 条",
            )

    return {"message": f"设备 {management_no} 已更新", "synced": synced}
