"""委托单 API"""
from __future__ import annotations

import json
from typing import Annotated

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.model_utils import normalize_model
from app.services.audit_service import log_operation, log_modification

router = APIRouter(prefix="/commissions", tags=["委托单"])


class CommissionBrief(BaseModel):
    commission_no: str
    client_name: str
    production_org_name: str
    commission_date: str | None
    status: str
    created_at: str | None


class CommissionDetail(BaseModel):
    commission_no: str
    client_name: str
    client_address: str | None
    contact: str | None
    phone: str | None
    production_org_name: str
    production_relation: str
    commission_date: str | None
    due_date: str | None
    status: str
    notes: str | None
    created_by: str | None
    created_at: str | None
    total_sample_count: int = 0
    sample_groups: list[dict] = []
    samples: list[dict] = []


@router.get("", response_model=list[CommissionBrief])
async def list_commissions(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
    status: str | None = Query(None),
    limit: int = Query(50, le=200),
    offset: int = Query(0),
):
    """委托单列表"""
    where = "WHERE 1=1"
    params: dict = {}
    if status:
        where += " AND status=:status"
        params["status"] = status

    result = await db.execute(
        text(f"SELECT commission_no, client_name, production_org_name, commission_date, status, created_at AT TIME ZONE 'Asia/Shanghai' FROM commissions {where} ORDER BY created_at DESC LIMIT :limit OFFSET :offset"),
        {**params, "limit": limit, "offset": offset},
    )
    return [
        CommissionBrief(commission_no=r[0], client_name=r[1], production_org_name=r[2],
                        commission_date=str(r[3]) if r[3] else None,
                        status=r[4], created_at=str(r[5]) if r[5] else None)
        for r in result.fetchall()
    ]


@router.get("/{commission_no}", response_model=CommissionDetail)
async def get_commission(
    commission_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """委托单详情（含样品组和样品）"""
    result = await db.execute(
        text("SELECT * FROM commissions WHERE commission_no=:c"),
        {"c": commission_no},
    )
    row = result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="委托单不存在")

    cols = result.keys()
    comm = dict(zip(cols, row))

    # 样品组
    groups_result = await db.execute(
        text("SELECT id, group_no, sample_name, model, material_name, experiment_codes, batch_no, quantity, status FROM sample_groups WHERE commission_no=:c AND is_void=FALSE ORDER BY id"),
        {"c": commission_no},
    )
    groups = [dict(zip(groups_result.keys(), r)) for r in groups_result.fetchall()]

    # 计算样品总数 = 各样品组 quantity 之和
    total_sample_count = sum(g.get("quantity", 0) or 0 for g in groups)

    # 样品
    samples_result = await db.execute(
        text("""SELECT sample_no, group_no, sample_name, condition, current_location, status,
                     retention_period, retention_until, disposal_method, disposal_date, disposed_by
                FROM samples WHERE commission_no=:c ORDER BY sample_no"""),
        {"c": commission_no},
    )
    samples = [dict(zip(samples_result.keys(), r)) for r in samples_result.fetchall()]

    return CommissionDetail(
        commission_no=comm["commission_no"],
        client_name=comm.get("client_name", ""),
        client_address=comm.get("client_address"),
        contact=comm.get("contact"),
        phone=comm.get("phone"),
        production_org_name=comm.get("production_org_name", ""),
        production_relation=comm.get("production_relation", ""),
        commission_date=str(comm["commission_date"]) if comm.get("commission_date") else None,
        due_date=str(comm["due_date"]) if comm.get("due_date") else None,
        status=comm.get("status", ""),
        notes=comm.get("notes"),
        created_by=comm.get("created_by"),
        created_at=str(comm["created_at"]) if comm.get("created_at") else None,
        total_sample_count=total_sample_count,
        sample_groups=groups,
        samples=samples,
    )


# ── 归档 ──

class ArchiveRequest(BaseModel):
    note: str = ""


@router.post("/{commission_no}/archive")
async def archive_commission(
    commission_no: str,
    body: ArchiveRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """管理员归档已完结委托（整单报告已发布/作废、样品已处置或留样）"""
    if user.get("role") != "管理员":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只有管理员可以归档")

    comm = await db.execute(
        text("SELECT status, archived_at FROM commissions WHERE commission_no=:c"),
        {"c": commission_no},
    )
    row = comm.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="委托单不存在")
    if row[1]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该委托已归档")

    # 校验：所有报告已发布/作废（无待审核/退回/签发中的报告）
    pending = await db.execute(
        text("""SELECT COUNT(*) FROM reports WHERE commission_no=:c
                AND status NOT IN ('已发布','已作废','已撤回')"""),
        {"c": commission_no},
    )
    if pending.fetchone()[0] > 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="存在未完结的报告，暂不能归档")

    # 校验：样品已处置（销毁/报废/消耗归档）或已登记留样
    undisposed = await db.execute(
        text("""SELECT COUNT(*) FROM samples WHERE commission_no=:c
                AND status NOT IN ('已销毁','已报废','全部消耗，记录归档')
                AND (retention_period IS NULL OR retention_period = '')"""),
        {"c": commission_no},
    )
    if undisposed.fetchone()[0] > 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="存在未处置且未留样的样品，暂不能归档")

    await db.execute(
        text("""UPDATE commissions SET status='已归档', archived_at=localtimestamp,
                archived_by=:a, updated_at=localtimestamp WHERE commission_no=:c"""),
        {"a": user["username"], "c": commission_no},
    )
    await db.execute(
        text("UPDATE reports SET archived_at=localtimestamp WHERE commission_no=:c"),
        {"c": commission_no},
    )
    await log_operation(db, "commission", commission_no, user, "归档委托", comment=body.note)
    return {"message": "委托已归档", "commission_no": commission_no, "status": "已归档"}


# ── 创建 ──

class CommissionCreate(BaseModel):
    client_org_id: int
    production_org_id: int
    production_relation: str = "客户提供"
    commission_date: str | None = None
    due_date: str | None = None
    notes: str | None = None


@router.post("", response_model=CommissionBrief)
async def create_commission(
    body: CommissionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """新建委托单"""
    # 查找客户信息
    client = await db.execute(
        text("SELECT org_name, address, contact, phone FROM organizations WHERE id=:i"),
        {"i": body.client_org_id},
    )
    client_row = client.fetchone()
    if not client_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="客户单位不存在")

    # 查找生产单位信息
    prod = await db.execute(
        text("SELECT org_name FROM organizations WHERE id=:i"),
        {"i": body.production_org_id},
    )
    prod_row = prod.fetchone()
    if not prod_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="生产单位不存在")

    # 生成委托编号: WT + YYYYMMDD + 3位序号
    # 使用 pg_advisory_xact_lock 防止并发重复
    today_str = body.commission_date or "2026-01-01"
    date_part = today_str.replace("-", "")
    commission_date_obj = date.fromisoformat(today_str)
    due_date_obj = date.fromisoformat(body.due_date) if body.due_date else None
    await db.execute(text("SELECT pg_advisory_xact_lock(1)"))
    result = await db.execute(
        text("SELECT MAX(commission_no) FROM commissions WHERE commission_no LIKE :pattern"),
        {"pattern": f"WT{date_part}%"},
    )
    max_no = result.fetchone()[0]
    seq = (int(max_no[-3:]) + 1) if max_no else 1
    commission_no = f"WT{date_part}{seq:03d}"

    await db.execute(
        text("""
            INSERT INTO commissions (commission_no, client_org_id, client_name, client_address, contact, phone,
              production_org_id, production_org_name, production_relation,
              commission_date, due_date, notes, status, created_by, created_at, updated_at)
            VALUES (:cn, :coi, :cnm, :ca, :ct, :ph,
              :poi, :pnm, :pr,
              :cd, :dd, :nt, '已入库', :cb, localtimestamp, localtimestamp)
        """),
        {
            "cn": commission_no, "coi": body.client_org_id,
            "cnm": client_row[0], "ca": client_row[1], "ct": client_row[2], "ph": client_row[3],
            "poi": body.production_org_id, "pnm": prod_row[0], "pr": body.production_relation,
            "cd": commission_date_obj, "dd": due_date_obj, "nt": body.notes,
            "cb": user["username"],
        },
    )

    # 显式提交，确保后续请求能立即看到该委托单
    await db.commit()

    # 审计日志
    await log_operation(db, "commission", commission_no, user, "创建委托",
                         commission_no=commission_no, comment=f"委托单位:{client_row[0]}")

    return CommissionBrief(
        commission_no=commission_no,
        client_name=client_row[0],
        production_org_name=prod_row[0],
        commission_date=body.commission_date,
        status="已入库",
        created_at=None,
    )


# ── 样品组创建 ──

class SampleGroupCreate(BaseModel):
    catalog_id: int | None = None
    material_name: str
    sample_name: str | None = None
    model: str | None = None
    sample_count: int = Field(ge=1, le=200)
    experiment_codes: list[str] = Field(default_factory=list)
    experiments: list[str] = Field(default_factory=list)
    batch_no: str = Field(min_length=1)
    notes: str | None = None


class SampleGroupResponse(BaseModel):
    group_no: str
    group_id: int
    sample_nos: list[str]
    message: str


@router.post("/{commission_no}/sample-groups", response_model=SampleGroupResponse)
async def create_sample_group(
    commission_no: str,
    body: SampleGroupCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
):
    """为委托创建样品组和样品"""
    # 验证委托存在
    comm = await db.execute(
        text("SELECT commission_no, commission_date FROM commissions WHERE commission_no=:c"),
        {"c": commission_no},
    )
    comm_row = comm.fetchone()
    if not comm_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="委托单不存在")

    # 如果提供了 catalog_id，从样品资料库中获取预设信息
    catalog_model = ""
    catalog_sample_name = ""
    catalog_material = body.material_name
    if body.catalog_id:
        cat_result = await db.execute(
            text("SELECT sample_name, model, material_name, experiment_codes FROM sample_catalog WHERE id=:i AND enabled=TRUE"),
            {"i": body.catalog_id},
        )
        cat_row = cat_result.fetchone()
        if cat_row:
            catalog_sample_name = cat_row[0] or ""
            catalog_material = cat_row[2] or body.material_name
            catalog_model = normalize_model(cat_row[1])
            # 如果前端未指定检测项目，则使用资料库中的预设
            if not body.experiment_codes and cat_row[3]:
                preset_codes = json.loads(cat_row[3]) if isinstance(cat_row[3], str) else cat_row[3]
                body.experiment_codes = preset_codes or []

    # 最终取值：前端显式传入优先，其次资料库预设，最后用材料名称兜底
    sample_name = body.sample_name or catalog_sample_name or catalog_material
    material_name = catalog_material
    model = normalize_model(body.model) or normalize_model(catalog_model)
    if not model:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="规格型号不能为空或占位符（如「-」「无」），请填写真实规格型号",
        )

    # 检测项目为必填项
    if not body.experiment_codes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="请选择检测项目（检测项目为必填项）",
        )

    # 生成样品组编号: BP + YYYYMMDD + 3位序号
    today_str = str(comm_row[1]) if comm_row[1] else "2026-01-01"
    date_part = today_str.replace("-", "") if "-" in today_str else today_str
    await db.execute(text("SELECT pg_advisory_xact_lock(2)"))
    result = await db.execute(
        text("SELECT MAX(group_no) FROM sample_groups WHERE group_no LIKE :p"),
        {"p": f"BP{date_part}%"},
    )
    max_no = result.fetchone()[0]
    seq = (int(max_no[-3:]) + 1) if max_no else 1
    group_no = f"BP{date_part}{seq:03d}"

    # 生成样品编号
    sample_nos = [f"{group_no}-S{i+1:02d}" for i in range(body.sample_count)]

    # 插入样品组（使用资料库信息或前端传入值）
    ecodes_str = ", ".join(body.experiment_codes) if body.experiment_codes else ""
    await db.execute(
        text("""
            INSERT INTO sample_groups (group_no, commission_no, catalog_id, sample_name, material_name,
              model, batch_no, experiment_codes, quantity, status, notes, updated_at)
            VALUES (:gn, :cn, :cid, :sn, :mn, :md, :bn, :ec, :qty, '已入库', :nt, localtimestamp)
        """),
        {
            "gn": group_no, "cn": commission_no, "cid": body.catalog_id,
            "sn": sample_name, "mn": material_name, "md": model,
            "bn": body.batch_no, "ec": ecodes_str, "qty": body.sample_count, "nt": body.notes,
        },
    )

    # 获取插入的 group_id
    gid_result = await db.execute(
        text("SELECT id FROM sample_groups WHERE group_no=:gn"),
        {"gn": group_no},
    )
    group_id = gid_result.fetchone()[0]

    # 插入样品（使用资料库信息）
    for sno in sample_nos:
        await db.execute(
            text("""
                INSERT INTO samples (sample_no, group_id, group_no, commission_no, sample_name,
                  material_name, model, condition, current_location, status, created_at, updated_at)
                VALUES (:sn, :gid, :gn, :cn, :snm, :mn, :md, '待检', '样品库', '待检', localtimestamp, localtimestamp)
            """),
            {
                "sn": sno, "gid": group_id, "gn": group_no, "cn": commission_no,
                "snm": sample_name, "mn": material_name, "md": model,
            },
        )

    # 审计日志
    await log_operation(db, "sample_group", group_no, user, "创建样品组",
                         commission_no=commission_no,
                         comment=f"样品数:{body.sample_count} 检测项目:{','.join(body.experiment_codes)}")

    return SampleGroupResponse(
        group_no=group_no,
        group_id=group_id,
        sample_nos=sample_nos,
        message=f"已创建样品组 {group_no}，包含 {body.sample_count} 个样品",
    )
