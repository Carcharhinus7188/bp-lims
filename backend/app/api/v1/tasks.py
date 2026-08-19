"""任务包 + 实验任务 API"""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, require_role
from app.services.audit_service import log_operation

router = APIRouter(prefix="/tasks", tags=["任务"])


async def _column_exists(db: AsyncSession, table: str, column: str) -> bool:
    """检查列是否存在（用于兼容尚未迁移 sample_name 列的数据库）"""
    r = await db.execute(
        text("SELECT 1 FROM information_schema.columns WHERE table_name=:t AND column_name=:c"),
        {"t": table, "c": column},
    )
    return r.fetchone() is not None


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


class TaskPackageBrief(BaseModel):
    package_no: str
    commission_no: str
    group_no: str
    assignee: str
    reviewer: str
    assigned_by: str | None
    assignee_name: str | None = None
    reviewer_name: str | None = None
    assigned_by_name: str | None = None
    material_name: str | None
    sample_name: str | None = None
    experiments: str | None
    status: str
    assigned_at: str | None


class TaskBrief(BaseModel):
    task_no: str
    package_no: str
    experiment: str | None
    experiment_code: str | None
    method_code: str | None
    status: str
    detection_location: str | None
    experiment_started_at: str | None
    experiment_ended_at: str | None


# ── 创建任务包 ──

class CreatePackageRequest(BaseModel):
    group_id: int
    experiment_codes: list[str]
    assignee: str
    reviewer: str                # 必填，手动选择
    quality_inspector: str       # 必填，手动选择
    detection_locations: dict[str, str] = {}  # experiment_code → location


@router.post("/packages", status_code=201)
async def create_package(
    body: CreatePackageRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("管理员", "样品管理员"))],
):
    """创建任务包并绑定委托、分配实验员（复核员/质量负责人必填手动选择）"""
    # 查询样品组信息
    group_result = await db.execute(
        text("SELECT group_no, commission_no, material_name, sample_name FROM sample_groups WHERE id=:i AND is_void=FALSE"),
        {"i": body.group_id},
    )
    group = group_result.fetchone()
    if not group:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="样品组不存在")

    group_no = group[0]
    commission_no = group[1]
    material_name = group[2]
    sample_name = group[3] or ""

    # 需求 11：新建任务包时带出委托样品组的「样品名称」（列到位后生效，兼容尚未迁移的库）
    pkg_sample_col, pkg_sample_val = "", ""
    task_sample_col, task_sample_val = "", ""
    if await _column_exists(db, "task_packages", "sample_name"):
        pkg_sample_col, pkg_sample_val = ", sample_name", ", :sname"
    if await _column_exists(db, "tasks", "sample_name"):
        task_sample_col, task_sample_val = ", sample_name", ", :sname"

    # 验证委托存在且有效
    comm_result = await db.execute(
        text("SELECT commission_no, status FROM commissions WHERE commission_no=:c"),
        {"c": commission_no},
    )
    comm = comm_result.fetchone()
    if not comm:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"委托 {commission_no} 不存在")
    if comm[1] == "已作废":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"委托 {commission_no} 已作废，无法创建任务包")

    # 任务包整组去重：一个样品组只能分配一个任务包
    existing_pkg = await db.execute(
        text("SELECT package_no, status FROM task_packages WHERE group_id=:gid LIMIT 1"),
        {"gid": body.group_id},
    )
    if existing_pkg.fetchone():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该样品组已分配过任务包，不能重复分配")

    # 验证实验员存在且为实验员角色
    tester_check = await db.execute(
        text("SELECT role FROM users WHERE username=:u AND enabled=TRUE"),
        {"u": body.assignee},
    )
    tester_row = tester_check.fetchone()
    if not tester_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"实验员 {body.assignee} 不存在或已禁用")
    if tester_row[0] != "实验员":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"{body.assignee} 不是实验员")

    # 复核员必须手动指定，并校验角色
    reviewer = body.reviewer.strip() if body.reviewer else ""
    if not reviewer:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="请选择复核员")
    rv_check = await db.execute(
        text("SELECT role FROM users WHERE username=:u AND enabled=TRUE"),
        {"u": reviewer},
    )
    rv_row = rv_check.fetchone()
    if not rv_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"复核员 {reviewer} 不存在或已禁用")
    if rv_row[0] != "复核员":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"{reviewer} 不是复核员")

    # 质量负责人必须手动指定，并校验角色
    quality_inspector = body.quality_inspector.strip() if body.quality_inspector else ""
    if not quality_inspector:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="请选择质量负责人")
    qi_check = await db.execute(
        text("SELECT role FROM users WHERE username=:u AND enabled=TRUE"),
        {"u": quality_inspector},
    )
    qi_row = qi_check.fetchone()
    if not qi_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"质量负责人 {quality_inspector} 不存在或已禁用")
    if qi_row[0] != "质量负责人":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"{quality_inspector} 不是质量负责人")

    # 查询实验方法
    experiments_str = ", ".join(body.experiment_codes)
    method_names = []
    for code in body.experiment_codes:
        m = await db.execute(
            text("SELECT experiment_name, method_code FROM experiment_methods WHERE experiment_code=:c"),
            {"c": code},
        )
        row = m.fetchone()
        if row:
            method_names.append(row[0])

    experiments_label = ", ".join(method_names) if method_names else experiments_str

    # 生成任务包编号（内部概念，不进入任务号/记录号/报告号）
    count_result = await db.execute(
        text("SELECT COUNT(*) FROM task_packages WHERE group_no=:g"),
        {"g": group_no},
    )
    pkg_seq = count_result.fetchone()[0] + 1
    package_no = f"BAG-{group_no}-P{pkg_seq:02d}"

    # 插入任务包（绑定委托，记录分配人）
    await db.execute(
        text(f"""
            INSERT INTO task_packages (package_no, commission_no, group_id, group_no, assignee, reviewer,
              assigned_by, material_name{pkg_sample_col}, experiment_codes, experiments, status, assigned_at, created_at, updated_at)
            VALUES (:pn, :cn, :gid, :gn, :a, :rv, :ab, :mn{pkg_sample_val}, :ec, :ex, '待接收', localtimestamp, localtimestamp, localtimestamp)
        """),
        {
            "pn": package_no, "cn": commission_no, "gid": body.group_id, "gn": group_no,
            "a": body.assignee, "rv": reviewer, "ab": user["username"],
            "mn": material_name, "ec": experiments_str, "ex": experiments_label,
            "sname": sample_name,
        },
    )

    # 为每个实验方法创建任务
    # 实验任务编号: {group_no}-T{NN}（NN 为同一样品组内全局两位序号，跨任务包累计）
    task_count = await db.execute(
        text("SELECT COUNT(*) FROM tasks WHERE group_no=:g"),
        {"g": group_no},
    )
    start_seq = task_count.fetchone()[0] + 1
    tasks_created = []
    for offset, code in enumerate(body.experiment_codes):
        seq = start_seq + offset
        task_no = f"{group_no}-T{seq:02d}"
        m = await db.execute(
            text("SELECT experiment_name, method_code, standard, kind FROM experiment_methods WHERE experiment_code=:c"),
            {"c": code},
        )
        method = m.fetchone()
        exp_name = method[0] if method else code
        method_code = method[1] if method else None
        standard = method[2] if method else None

        location = body.detection_locations.get(code, "性能检测室")

        # 查询样品编号（从 samples 表聚合）
        sample_nos_result = await db.execute(
            text("SELECT string_agg(sample_no, ', ' ORDER BY sample_no) FROM samples WHERE group_id=:i"),
            {"i": body.group_id},
        )
        sample_nos_row = sample_nos_result.fetchone()
        sample_nos = sample_nos_row[0] if sample_nos_row else None

        await db.execute(
            text(f"""
                INSERT INTO tasks (task_no, package_no, commission_no, group_id, group_no, experiment,
                  method_code, experiment_code, standard, material_name{task_sample_col}, sample_nos,
                  assignee, reviewer, quality_inspector, status, detection_location, created_at, updated_at)
                VALUES (:tn, :pn, :cn, :gid, :gn, :ex, :mc, :ec, :st, :mn{task_sample_val}, :sn,
                  :a, :rv, :qi, '待接收', :dl, localtimestamp, localtimestamp)
            """),
            {
                "tn": task_no, "pn": package_no, "cn": commission_no, "gid": body.group_id,
                "gn": group_no, "ex": exp_name, "mc": method_code, "ec": code,
                "st": standard, "mn": material_name, "sn": sample_nos,
                "a": body.assignee, "rv": reviewer, "qi": quality_inspector or "", "dl": location,
                "sname": sample_name,
            },
        )
        tasks_created.append({
            "task_no": task_no,
            "experiment": exp_name,
            "method_code": method_code,
        })

    # 审计日志
    task_nos_str = ", ".join([t["task_no"] for t in tasks_created])
    await log_operation(db, "task_package", package_no, user, "创建任务包",
                         commission_no=commission_no,
                         comment=f"实验员:{body.assignee} 复核员:{reviewer} 任务:{task_nos_str}")

    return {
        "commission_no": commission_no,
        "group_no": group_no,
        "status": "待接收",
        "assigned_by": user["username"],
        "reviewer": reviewer,
        "quality_inspector": quality_inspector or "",
        "tasks": tasks_created,
    }


# ── 接收任务包 ──

class AcceptPackageRequest(BaseModel):
    acceptance_note: str = ""
    detection_locations: dict[str, str] = {}
    sample_condition: str = "完好"


@router.post("/packages/{package_no}/accept")
async def accept_package(
    package_no: str,
    body: AcceptPackageRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("实验员"))],
):
    """实验员接收任务包"""
    pkg = await db.execute(
        text("SELECT status, assignee FROM task_packages WHERE package_no=:p"),
        {"p": package_no},
    )
    pkg_row = pkg.fetchone()
    if not pkg_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务包不存在")
    if pkg_row[0] != "待接收":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"任务包状态为'{pkg_row[0]}'，无法接收")
    if pkg_row[1] != user["username"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只能接收分配给自己的任务包")

    await db.execute(
        text("UPDATE task_packages SET status='检测中', updated_at=localtimestamp WHERE package_no=:p"),
        {"p": package_no},
    )

    # 更新各任务的检测地点、状态，自动记录开始时间
    for task_no, location in body.detection_locations.items():
        await db.execute(
            text("""
                UPDATE tasks SET status='检测中', detection_location=:dl,
                    experiment_started_at = COALESCE(experiment_started_at, localtimestamp),
                    updated_at=localtimestamp
                WHERE task_no=:t AND package_no=:p
            """),
            {"dl": location, "t": task_no, "p": package_no},
        )

    # 锁定任务配置快照（检测开始前固化当前「现行」配置版本，检测期间不漂移）
    from app.api.v1.experiment_config import snapshot_task_config
    pkg_tasks = await db.execute(
        text("SELECT task_no, experiment_code FROM tasks WHERE package_no=:p"),
        {"p": package_no},
    )
    for tk in pkg_tasks.fetchall():
        await snapshot_task_config(db, tk[0], tk[1])

    # 自动创建借出记录（样品 → 实验员）
    sample_tasks = await db.execute(
        text("SELECT sample_nos, commission_no FROM tasks WHERE package_no=:p"),
        {"p": package_no},
    )
    all_sample_nos: set[str] = set()
    comm_no_from_task = None
    for row in sample_tasks.fetchall():
        if row[0]:
            for s in str(row[0]).split(","):
                s = s.strip()
                if s:
                    all_sample_nos.add(s)
        if not comm_no_from_task and row[1]:
            comm_no_from_task = row[1]

    for sno in all_sample_nos:
        await db.execute(
            text("""INSERT INTO package_loans (
                    package_no, sample_no, borrower, borrowed_at, purpose,
                    detection_location, return_status
                ) VALUES (
                    :pn, :sn, :b, localtimestamp, '实验检测',
                    '', '未归还'
                ) ON CONFLICT (package_no, sample_no) DO NOTHING"""),
            {"pn": package_no, "sn": sno, "b": user["username"]},
        )
        # 更新样品状态为借出中
        await db.execute(
            text("UPDATE samples SET status='借出中', current_holder=:a, updated_at=localtimestamp WHERE sample_no=:sn AND status='已入库'"),
            {"sn": sno, "a": user["username"]},
        )

    # 审计日志
    await log_operation(db, "task_package", package_no, user, "接收任务包",
                         commission_no=comm_no_from_task, comment=body.acceptance_note or "开始检测")

    return {"message": "任务包已接收", "status": "检测中"}


# ── 标记实验时间 ──

class MarkTimeRequest(BaseModel):
    action: str = Field(..., pattern=r"^(开始|结束)$")


@router.put("/{task_no}/time")
async def mark_task_time(
    task_no: str,
    body: MarkTimeRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(require_role("实验员"))],
):
    """标记实验开始/结束时间"""
    task_result = await db.execute(
        text("SELECT assignee, status FROM tasks WHERE task_no=:t"),
        {"t": task_no},
    )
    task_row = task_result.fetchone()
    if not task_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    if task_row[0] != user["username"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="只能操作自己的任务")

    if body.action == "开始":
        await db.execute(
            text("UPDATE tasks SET experiment_started_at=localtimestamp, status='检测中', updated_at=localtimestamp WHERE task_no=:t"),
            {"t": task_no},
        )
    else:
        await db.execute(
            text("UPDATE tasks SET experiment_ended_at=localtimestamp, updated_at=localtimestamp WHERE task_no=:t"),
            {"t": task_no},
        )

    # 审计日志
    comm_result = await db.execute(
        text("SELECT commission_no FROM tasks WHERE task_no=:t"),
        {"t": task_no},
    )
    comm_row = comm_result.fetchone()
    if comm_row:
        await log_operation(db, "task", task_no, user, f"标记实验{body.action}",
                             commission_no=comm_row[0])

    return {"message": f"已标记实验{body.action}时间"}


# ── 任务包 ──

@router.get("/packages", response_model=list[TaskPackageBrief])
async def list_packages(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
    status_filter: str | None = Query(None, alias="status"),
    limit: int = Query(50, le=200),
):
    """任务包列表 — 实验员/复核员只看自己的；管理员/样品管理员看全部"""
    role = user["role"]
    username = user["username"]

    where_clauses = []
    params: dict = {}

    if role == "实验员":
        where_clauses.append("assignee=:username")
        params["username"] = username
    elif role == "复核员":
        where_clauses.append("reviewer=:username")
        params["username"] = username
    elif role == "质量负责人":
        # 质量负责人可看到自己参与的任务包
        where_clauses.append("(reviewer=:username OR EXISTS (SELECT 1 FROM tasks t2 WHERE t2.package_no=task_packages.package_no AND t2.quality_inspector=:username2))")
        params["username"] = username
        params["username2"] = username
    # 管理员、样品管理员 — 不添加人员限制，看全部

    if status_filter:
        where_clauses.append("status=:status_filter")
        params["status_filter"] = status_filter

    where = f"WHERE {' AND '.join(where_clauses)}" if where_clauses else ""

    result = await db.execute(
        text(f"SELECT package_no, commission_no, group_no, assignee, reviewer, assigned_by, material_name, experiments, status, assigned_at, (SELECT sg.sample_name FROM sample_groups sg WHERE sg.id = task_packages.group_id LIMIT 1) AS sample_name FROM task_packages {where} ORDER BY created_at DESC LIMIT :limit"),
        {**params, "limit": limit},
    )
    rows = result.fetchall()
    names = await _display_names(db, {r[3] for r in rows} | {r[4] for r in rows} | {r[5] for r in rows if r[5]})
    return [
        TaskPackageBrief(package_no=r[0], commission_no=r[1], group_no=r[2], assignee=r[3],
                          reviewer=r[4], assigned_by=r[5], material_name=r[6], experiments=r[7],
                          status=r[8], assigned_at=str(r[9]) if r[9] else None, sample_name=r[10],
                          assignee_name=names.get(r[3], r[3]),
                          reviewer_name=names.get(r[4], r[4]),
                          assigned_by_name=names.get(r[5], r[5]) if r[5] else None)
        for r in rows
    ]


@router.get("/packages/{package_no}")
async def get_package(
    package_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """任务包详情 + 包含的实验任务"""
    result = await db.execute(
        text("SELECT * FROM task_packages WHERE package_no=:p"), {"p": package_no}
    )
    row = result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务包不存在")
    pkg = dict(zip(result.keys(), row))

    # 账号 → 姓名
    pkg_names = await _display_names(
        db, {pkg.get("assignee"), pkg.get("reviewer"), pkg.get("assigned_by")}
    )
    for key in ("assignee", "reviewer", "assigned_by"):
        if pkg.get(key):
            pkg[f"{key}_name"] = pkg_names.get(pkg[key], pkg[key])

    # 补充 sample_name（task_packages 不存样品名称，从样品组回查）
    if not pkg.get("sample_name") and pkg.get("group_id"):
        sg = await db.execute(
            text("SELECT sample_name FROM sample_groups WHERE id=:gid"),
            {"gid": pkg["group_id"]},
        )
        srow = sg.fetchone()
        if srow:
            pkg["sample_name"] = srow[0]

    tasks_result = await db.execute(
        text("SELECT task_no, experiment, experiment_code, method_code, status, detection_location, experiment_started_at, experiment_ended_at FROM tasks WHERE package_no=:p ORDER BY task_no"),
        {"p": package_no},
    )
    tasks = [dict(zip(tasks_result.keys(), r)) for r in tasks_result.fetchall()]

    return {"package": pkg, "tasks": tasks}


# ── 实验任务 ──

@router.get("/my", response_model=list[TaskBrief])
async def list_my_tasks(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[dict, Depends(get_current_user)],
    status_filter: str | None = Query(None, alias="status"),
    limit: int = Query(50, le=200),
):
    """我的实验任务列表"""
    params: dict = {"assignee": user["username"]}
    where = "WHERE assignee=:assignee"
    if status_filter:
        where += " AND status=:status"
        params["status"] = status_filter

    result = await db.execute(
        text(f"SELECT task_no, package_no, experiment, experiment_code, method_code, status, detection_location, experiment_started_at, experiment_ended_at FROM tasks {where} ORDER BY created_at DESC LIMIT :limit"),
        {**params, "limit": limit},
    )
    return [
        TaskBrief(task_no=r[0], package_no=r[1], experiment=r[2], experiment_code=r[3],
                  method_code=r[4], status=r[5], detection_location=r[6],
                  experiment_started_at=str(r[7]) if r[7] else None,
                  experiment_ended_at=str(r[8]) if r[8] else None)
        for r in result.fetchall()
    ]


@router.get("/{task_no}")
async def get_task(
    task_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """实验任务详情（含原始记录和附件）"""
    result = await db.execute(
        text("SELECT * FROM tasks WHERE task_no=:t"), {"t": task_no}
    )
    row = result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    task = dict(zip(result.keys(), row))

    # 补充可能缺失的 material_name / standard / sample_nos / sample_name
    # sample_nos 从 samples 表聚合，sample_name 从 sample_groups 回查
    if not task.get("material_name") or not task.get("standard") or not task.get("sample_nos") or not task.get("sample_name"):
        enrich = await db.execute(
            text("""
                SELECT pk.material_name, em.standard,
                  (SELECT string_agg(s.sample_no, ', ' ORDER BY s.sample_no)
                   FROM samples s WHERE s.group_id = t.group_id),
                  sg.sample_name
                FROM tasks t
                JOIN task_packages pk ON pk.package_no = t.package_no
                LEFT JOIN experiment_methods em ON em.experiment_code = t.experiment_code
                LEFT JOIN sample_groups sg ON sg.id = t.group_id
                WHERE t.task_no = :t
            """),
            {"t": task_no},
        )
        enrich_row = enrich.fetchone()
        if enrich_row:
            if not task.get("material_name") and enrich_row[0]:
                task["material_name"] = enrich_row[0]
            if not task.get("standard") and enrich_row[1]:
                task["standard"] = enrich_row[1]
            if not task.get("sample_nos") and enrich_row[2]:
                task["sample_nos"] = enrich_row[2]
            if not task.get("sample_name") and enrich_row[3]:
                task["sample_name"] = enrich_row[3]

    # 原始记录
    records_result = await db.execute(
        text("SELECT record_no, version, status, owner, created_at FROM records WHERE task_no=:t ORDER BY version DESC"),
        {"t": task_no},
    )
    records = [dict(zip(records_result.keys(), r)) for r in records_result.fetchall()]

    # 附件
    att_result = await db.execute(
        text("SELECT attachment_id, attachment_type, original_name, checkpoint_code, checkpoint_label, captured_at, uploader FROM attachments WHERE task_no=:t AND evidence_status='有效' ORDER BY created_at DESC"),
        {"t": task_no},
    )
    attachments = [dict(zip(att_result.keys(), r)) for r in att_result.fetchall()]

    # 账号 → 姓名（表中显示姓名而非账号名）
    usernames = {
        task.get("assignee"), task.get("reviewer"), task.get("quality_inspector"),
    } | {r.get("owner") for r in records} | {a.get("uploader") for a in attachments}
    names = await _display_names(db, usernames)
    for key in ("assignee", "reviewer", "quality_inspector"):
        if task.get(key):
            task[f"{key}_name"] = names.get(task[key], task[key])
    for r in records:
        if r.get("owner"):
            r["owner_name"] = names.get(r["owner"], r["owner"])
    for a in attachments:
        if a.get("uploader"):
            a["uploader_name"] = names.get(a["uploader"], a["uploader"])

    # 退回修改时，返回复核员的修改意见和修改字段
    correction_info = None
    if task.get("status") == "退回修改":
        cr = await db.execute(
            text("""
                SELECT reviewer, decision, comment, correction_fields, reviewed_at
                FROM reviews
                WHERE record_no = :t AND decision = '退回'
                ORDER BY reviewed_at DESC LIMIT 1
            """),
            {"t": task_no},
        )
        cr_row = cr.fetchone()
        if cr_row:
            correction_info = dict(zip(cr.keys(), cr_row))

    return {"task": task, "records": records, "attachments": attachments,
            "correction": correction_info}
