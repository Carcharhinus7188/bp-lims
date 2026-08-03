# -*- coding: utf-8 -*-
from __future__ import annotations

from io import BytesIO
import json
import textwrap
from typing import Any

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4


def _plain(value: Any) -> str:
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, default=str)
    return str(value if value not in (None, "") else "—")


def build_preview_pdf(title: str, sections: list[tuple[str, Any]]) -> bytes:
    """Create a read-only review PDF without exposing a download artifact."""
    lines = [title, ""]
    for heading, value in sections:
        lines.extend([f"【{heading}】"])
        if isinstance(value, list):
            for index, item in enumerate(value, 1):
                lines.append(f"{index}. {_plain(item)}")
        elif isinstance(value, dict):
            for key, item in value.items():
                lines.append(f"{key}：{_plain(item)}")
        else:
            lines.append(_plain(value))
        lines.append("")

    wrapped: list[str] = []
    for line in lines:
        wrapped.extend(textwrap.wrap(line, width=48, replace_whitespace=False) or [""])

    pdfmetrics.registerFont(UnicodeCIDFont("STSong-Light"))
    output = BytesIO()
    writer = canvas.Canvas(output, pagesize=A4, pageCompression=1)
    width, height = A4
    y = height - 48
    writer.setFont("STSong-Light", 15)
    writer.drawString(45, y, title)
    y -= 28
    writer.setFont("STSong-Light", 10.5)
    for line in wrapped[2:]:
        if y < 48:
            writer.showPage()
            writer.setFont("STSong-Light", 10.5)
            y = height - 48
        writer.drawString(45, y, line)
        y -= 16
    writer.save()
    return output.getvalue()


def pdf_page_images(content: bytes) -> list[BytesIO]:
    import fitz
    document = fitz.open(stream=content, filetype="pdf")
    images: list[BytesIO] = []
    for page in document:
        pixmap = page.get_pixmap(matrix=fitz.Matrix(1.45, 1.45), alpha=False)
        images.append(BytesIO(pixmap.tobytes("png")))
    return images
