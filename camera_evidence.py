# -*- coding: utf-8 -*-
from __future__ import annotations

from io import BytesIO
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont, ImageOps

from lims_db import now, save_attachment, supersede_camera_checkpoint, task
from constants import SAMPLE_LEVEL_PHOTO_CODES


def _font(size: int):
    candidates = [
        Path("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"),
        Path("/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc"),
        Path("/System/Library/Fonts/PingFang.ttc"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            try:
                return ImageFont.truetype(str(candidate), size=size)
            except Exception:
                pass
    return ImageFont.load_default()


def _normalized_jpeg(content: bytes) -> bytes:
    image = ImageOps.exif_transpose(Image.open(BytesIO(content))).convert("RGB")
    output = BytesIO()
    image.save(output, "JPEG", quality=94, optimize=True)
    return output.getvalue()


def _watermarked(content: bytes, lines: list[str]) -> bytes:
    image = Image.open(BytesIO(content)).convert("RGB")
    width, height = image.size
    font = _font(max(18, min(width, height) // 42))
    padding = max(12, width // 90)
    draw = ImageDraw.Draw(image, "RGBA")
    line_boxes = [draw.textbbox((0, 0), line, font=font) for line in lines]
    line_height = max(box[3] - box[1] for box in line_boxes) + max(6, padding // 2)
    box_width = max(box[2] - box[0] for box in line_boxes) + padding * 2
    box_height = line_height * len(lines) + padding * 2
    left = max(0, width - box_width - padding)
    top = max(0, height - box_height - padding)
    draw.rounded_rectangle(
        (left, top, width - padding, height - padding),
        radius=max(8, padding),
        fill=(0, 0, 0, 168),
        outline=(255, 255, 255, 205),
        width=max(1, padding // 5),
    )
    for index, line in enumerate(lines):
        draw.text(
            (left + padding, top + padding + index * line_height),
            line,
            font=font,
            fill=(255, 255, 255, 255),
        )
    output = BytesIO()
    image.save(output, "JPEG", quality=92, optimize=True)
    return output.getvalue()


def save_live_camera_photo(
    meta: dict[str, Any], content: bytes, actor: str, actor_name: str,
) -> tuple[str, str]:
    """Persist an immutable original and a server-watermarked derivative."""
    captured_at = now()
    time_code = captured_at[11:19].replace(":", "")
    normalized = _normalized_jpeg(content)
    task_no = str(meta["task_no"])
    checkpoint_code = str(meta["checkpoint_code"])
    checkpoint_label = str(meta["checkpoint_label"])
    sample_no = str(meta.get("sample_no") or "")
    if checkpoint_code in SAMPLE_LEVEL_PHOTO_CODES:
        task_row = task(task_no) or {}
        if sample_no not in (task_row.get("sample_nos_list") or []):
            raise ValueError("该拍照节点必须选择并关联一个实际实体样品")
    else:
        sample_no = ""
        meta = {**meta, "sample_no": ""}
    supersede_camera_checkpoint(task_no, checkpoint_code, actor, sample_no)
    base = {
        **meta,
        "attachment_type": "实验现场照片",
        "captured_at": captured_at,
        "server_captured_at": captured_at,
        "capture_source": "live_camera",
        "evidence_status": "有效",
        "description": checkpoint_label,
    }
    original_id = save_attachment(
        {
            **base,
            "original_name": f"{task_no}_{time_code}.jpg",
            "is_original": True,
        },
        normalized,
        actor,
    )
    lines = [
        captured_at.replace("T", " "),
        f"Task: {task_no}",
        f"Sample: {meta.get('sample_no') or 'group'}",
        f"Step: {checkpoint_code} {checkpoint_label}",
        f"Operator: {actor_name} ({actor})",
        f"Device: {meta.get('device_id') or 'tablet'}",
        f"Evidence: {original_id}",
    ]
    derivative = _watermarked(normalized, lines)
    watermarked_id = save_attachment(
        {
            **base,
            "original_name": f"{task_no}_{time_code}.jpg",
            "is_original": False,
            "parent_attachment_id": original_id,
        },
        derivative,
        actor,
    )
    return original_id, watermarked_id
