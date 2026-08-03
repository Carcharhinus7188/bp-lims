# -*- coding: utf-8 -*-
from __future__ import annotations

from io import BytesIO
import json
import textwrap
from typing import Any

import fitz


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

    document = fitz.open()
    per_page = 42
    for offset in range(0, len(wrapped), per_page):
        page = document.new_page(width=595, height=842)
        page.insert_textbox(
            fitz.Rect(45, 45, 550, 800),
            "\n".join(wrapped[offset:offset + per_page]),
            fontname="china-s", fontsize=10.5, lineheight=1.35,
            color=(0.08, 0.16, 0.22),
        )
    return document.tobytes(garbage=4, deflate=True)


def pdf_page_images(content: bytes) -> list[BytesIO]:
    document = fitz.open(stream=content, filetype="pdf")
    images: list[BytesIO] = []
    for page in document:
        pixmap = page.get_pixmap(matrix=fitz.Matrix(1.45, 1.45), alpha=False)
        images.append(BytesIO(pixmap.tobytes("png")))
    return images
