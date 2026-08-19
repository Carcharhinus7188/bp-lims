"""实验照片 / 附件上传与读取"""
from __future__ import annotations

import hashlib
import uuid
from datetime import datetime
from pathlib import Path
from typing import Annotated

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.deps import get_current_user
from app.core.encoding_rules import CHINA_TZ
from app.database import get_db
from app.services.audit_service import log_modification

router = APIRouter(prefix="/attachments", tags=["attachments"])

# 图片 + PDF（实验照片/证书扫描件）+ 设备原始数据文件
ALLOWED_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".pdf",
    ".csv", ".xlsx", ".xls", ".txt", ".dat", ".xml", ".json", ".zip",
}


@router.post("/upload")
async def upload_attachment(
    file: UploadFile | None = File(default=None),
    files: list[UploadFile] | None = File(default=None),
    task_no: str = Form(...),
    attachment_type: str = Form("photo"),
    capture_source: str = Form("file"),
    checkpoint_code: str = Form(""),
    checkpoint_label: str = Form(""),
    sample_no: str = Form(""),
    commission_no: str = Form(""),
    user: Annotated[dict, Depends(get_current_user)] = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """上传实验照片 / 设备原始文件到服务器（返回持久化 URL），逐文件写入 attachments 表。

    - 单文件（照片）：`file` 字段，`attachment_type` 默认 'photo'，`capture_source` 默认 'file'。
    - 多文件（设备原始数据）：`files` 字段（重复），`attachment_type` 传类型中文名，
      `capture_source='device_export'`。
    """
    incoming: list[UploadFile] = []
    if file is not None:
        incoming.append(file)
    if files:
        incoming.extend(files)
    if not incoming:
        raise HTTPException(status_code=400, detail="未接收到文件")

    # 按任务编号分目录
    task_dir = Path(settings.ATTACHMENT_DIR) / task_no
    task_dir.mkdir(parents=True, exist_ok=True)

    # 如果前端未传 commission_no，从任务表反查
    if not commission_no:
        try:
            row = (await db.execute(
                text("SELECT commission_no FROM tasks WHERE task_no=:t LIMIT 1"),
                {"t": task_no},
            )).fetchone()
            if row and row[0]:
                commission_no = row[0]
        except Exception:
            pass

    # 先落盘 + 收集元数据（文件写入失败即中断，不留半套记录）
    now = datetime.now(CHINA_TZ)
    prepared: list[dict] = []
    for f in incoming:
        ext = Path(f.filename).suffix.lower() if f.filename else ""
        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(status_code=400, detail=f"不支持的文件类型: {ext or '(无扩展名)'}")

        content = await f.read()

        # 命名格式: {task_no}_{HHMMSS}{ext}（24小时制，时/分/秒两位补零）
        stem = f"{task_no}_{now.strftime('%H%M%S')}"
        filename = f"{stem}{ext}"
        filepath = task_dir / filename
        # 同一秒内多个文件时追加序号，避免覆盖
        n = 1
        while filepath.exists():
            filename = f"{stem}_{n}{ext}"
            filepath = task_dir / filename
            n += 1

        filepath.write_bytes(content)

        prepared.append({
            "aid": uuid.uuid4().hex[:16],
            "oname": f.filename or filename,
            "sname": filename,
            "rpath": f"{task_no}/{filename}",
            "sha": hashlib.sha256(content).hexdigest(),
            "size": len(content),
            "ext": ext,
        })

    # 逐文件写入 attachments 数据库记录
    try:
        for p in prepared:
            await db.execute(
                text("""
                    INSERT INTO attachments (
                        attachment_id, commission_no, task_no, sample_no,
                        attachment_type, original_name, stored_name, relative_path,
                        sha256, uploader, checkpoint_code, checkpoint_label,
                        capture_source, server_captured_at, created_at
                    ) VALUES (
                        :aid, :cn, :tn, :sn,
                        :atype, :oname, :sname, :rpath,
                        :sha, :up, :cp, :cpl,
                        :csrc, :scap, :cat
                    )
                """),
                {
                    "aid": p["aid"],
                    "cn": commission_no or "",
                    "tn": task_no,
                    "sn": sample_no or "",
                    "atype": attachment_type,
                    "oname": p["oname"],
                    "sname": p["sname"],
                    "rpath": p["rpath"],
                    "sha": p["sha"],
                    "up": user.get("username", ""),
                    "cp": checkpoint_code or "",
                    "cpl": checkpoint_label or "",
                    "csrc": capture_source or "file",
                    "scap": now,
                    "cat": now,
                },
            )
        await db.commit()
    except Exception as e:
        # 即使写 DB 失败也不影响已保存的文件
        await db.rollback()
        import logging
        logging.getLogger(__name__).warning(f"附件记录写入失败: {e}")

    results = [
        {
            "url": f"/api/v1/attachments/file/{task_no}/{p['sname']}",
            "filename": p["sname"],
            "original_name": p["oname"],
            "attachment_id": p["aid"],
            "size": p["size"],
        }
        for p in prepared
    ]

    first = results[0]
    return {
        "url": first["url"],            # 兼容单文件照片调用 data.url
        "filename": first["filename"],
        "task_no": task_no,
        "checkpoint_code": checkpoint_code,
        "sample_no": sample_no,
        "size": first["size"],
        "files": results,
        "uploaded": len(results),
    }


@router.get("/file/{task_no}/{filename}")
async def serve_attachment(task_no: str, filename: str):
    """读取上传的附件（图片/PDF/设备数据文件）"""
    filepath = Path(settings.ATTACHMENT_DIR) / task_no / filename
    if not filepath.exists():
        raise HTTPException(status_code=404, detail="文件不存在")
    # 防止路径穿越
    if not filepath.resolve().is_relative_to(Path(settings.ATTACHMENT_DIR).resolve()):
        raise HTTPException(status_code=403, detail="禁止访问")
    return FileResponse(filepath)


@router.delete("/{attachment_id}")
async def delete_attachment(
    attachment_id: str,
    user: Annotated[dict, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """删除附件（软删除：evidence_status→已删除 + 移除磁盘文件）。

    仅上传者本人或管理员可删除；已删除的附件不可重复删除。
    """
    row = (await db.execute(
        text("SELECT relative_path, uploader, evidence_status FROM attachments WHERE attachment_id=:a"),
        {"a": attachment_id},
    )).fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="附件不存在")

    rel_path, uploader, evidence_status = row
    if evidence_status != "有效":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="附件已删除")

    is_admin = user.get("role") == "管理员"
    if not is_admin and uploader != user.get("username"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="仅上传者或管理员可删除")

    await db.execute(
        text("UPDATE attachments SET evidence_status='已删除' WHERE attachment_id=:a"),
        {"a": attachment_id},
    )
    await log_modification(
        db, "attachment", attachment_id, user, "evidence_status",
        old_value="有效", new_value="已删除", reason="删除实验/设备附件",
    )
    await db.commit()

    # 移除磁盘文件（失败不阻断，仅告警）
    try:
        p = Path(settings.ATTACHMENT_DIR) / rel_path
        if p.exists():
            p.unlink()
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"附件文件移除失败: {e}")

    return {"message": "附件已删除", "attachment_id": attachment_id}
