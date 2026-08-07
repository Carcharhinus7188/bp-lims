# -*- coding: utf-8 -*-
from __future__ import annotations

import base64
import shutil
import subprocess
import tempfile
from html import escape
from io import BytesIO
from pathlib import Path

try:
    import fitz
except ImportError:  # pragma: no cover - deployment normally uses PyMuPDF
    fitz=None
from docx import Document
from docx.oxml.ns import qn
from docx.table import Table
from docx.text.paragraph import Paragraph


class DocxPreviewError(RuntimeError):
    pass


def docx_page_images(content: bytes, scale: float = 1.7) -> list[bytes]:
    """Render the actual DOCX with LibreOffice, then return one PNG per page."""
    soffice=shutil.which("soffice") or shutil.which("libreoffice")
    if not soffice:
        raise DocxPreviewError("服务器未安装办公文档渲染引擎")
    with tempfile.TemporaryDirectory(prefix="bplab_docx_preview_") as temp_name:
        temp_dir=Path(temp_name)
        source=temp_dir/"controlled_document.docx"
        output=temp_dir/"controlled_document.pdf"
        profile=temp_dir/"lo_profile"
        source.write_bytes(content)
        command=[
            soffice,
            f"-env:UserInstallation={profile.as_uri()}",
            "--headless","--nologo","--nodefault","--nolockcheck",
            "--convert-to","pdf:writer_pdf_Export",
            "--outdir",str(temp_dir),str(source),
        ]
        try:
            completed=subprocess.run(
                command,capture_output=True,text=True,timeout=90,check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise DocxPreviewError("受控Word预览生成超时") from exc
        if completed.returncode!=0 or not output.exists():
            detail=(completed.stderr or completed.stdout or "").strip()
            raise DocxPreviewError("受控Word预览生成失败"+(f"：{detail[:180]}" if detail else ""))
        try:
            if fitz is not None:
                document=fitz.open(output)
                if not document.page_count:
                    raise DocxPreviewError("受控Word没有可显示页面")
                if document.page_count>50:
                    raise DocxPreviewError(f"预览页数异常（{document.page_count}页），已停止显示")
                matrix=fitz.Matrix(scale,scale)
                return [
                    page.get_pixmap(matrix=matrix,alpha=False).tobytes("png")
                    for page in document
                ]
            pdftoppm=shutil.which("pdftoppm")
            if not pdftoppm:
                raise DocxPreviewError("服务器未安装PDF页面渲染引擎")
            prefix=temp_dir/"page"
            rendered=subprocess.run(
                [pdftoppm,"-png","-r",str(int(96*scale)),str(output),str(prefix)],
                capture_output=True,text=True,timeout=90,check=False,
            )
            page_paths=sorted(
                temp_dir.glob("page-*.png"),
                key=lambda path:int(path.stem.rsplit("-",1)[-1]),
            )
            if rendered.returncode!=0 or not page_paths:
                raise DocxPreviewError("受控Word页面渲染失败")
            if len(page_paths)>50:
                raise DocxPreviewError(f"预览页数异常（{len(page_paths)}页），已停止显示")
            return [path.read_bytes() for path in page_paths]
        except DocxPreviewError:
            raise
        except Exception as exc:
            raise DocxPreviewError("受控Word页面读取失败") from exc


def _blocks(document):
    for child in document.element.body.iterchildren():
        if child.tag.endswith("}p"):
            yield Paragraph(child, document)
        elif child.tag.endswith("}tbl"):
            yield Table(child, document)


def _run_html(run) -> str:
    content=escape(run.text or "").replace("\n","<br>")
    for blip in run._r.xpath(".//a:blip"):
        relationship=blip.get(qn("r:embed"))
        part=run.part.related_parts.get(relationship) if relationship else None
        if not part:
            continue
        mime=getattr(part,"content_type","image/png")
        encoded=base64.b64encode(part.blob).decode("ascii")
        content+=f'<img class="signature" src="data:{mime};base64,{encoded}" alt="电子签名">'
    return content


def _paragraph_inner(paragraph: Paragraph) -> str:
    return "".join(_run_html(run) for run in paragraph.runs)


def _paragraph_html(paragraph: Paragraph) -> str:
    text = _paragraph_inner(paragraph)
    if not text:
        return '<div class="blank">&nbsp;</div>'
    style = (paragraph.style.name if paragraph.style else "").lower()
    tag = "h2" if "heading" in style or "标题" in style else "p"
    return f"<{tag}>{text}</{tag}>"


def _table_html(table: Table) -> str:
    rows = []
    for row in table.rows:
        cells = []
        seen = set()
        for cell in row.cells:
            cell_id = id(cell._tc)
            if cell_id in seen:
                continue
            seen.add(cell_id)
            grid_span = cell._tc.xpath("./w:tcPr/w:gridSpan/@w:val")
            colspan = int(grid_span[0]) if grid_span else 1
            value = "<br>".join(_paragraph_inner(paragraph) for paragraph in cell.paragraphs) or "&nbsp;"
            cells.append(f'<td colspan="{colspan}">{value}</td>')
        rows.append("<tr>" + "".join(cells) + "</tr>")
    return '<table class="controlled-form">' + "".join(rows) + "</table>"


def docx_review_html(content: bytes, title: str) -> str:
    document = Document(BytesIO(content))
    body = []
    for block in _blocks(document):
        body.append(_paragraph_html(block) if isinstance(block, Paragraph) else _table_html(block))
    return f"""<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><style>
html,body{{margin:0;background:#F1F5F9;color:#0F172A;font-family:"Noto Sans CJK SC","Microsoft YaHei",Arial,sans-serif}}
.toolbar{{position:sticky;top:0;z-index:2;background:#1E3A5F;color:white;padding:10px 18px;font-weight:600}}
.page{{box-sizing:border-box;width:210mm;min-height:297mm;margin:18px auto;padding:16mm;
background:white;box-shadow:0 2px 14px rgba(15,23,42,.12)}}
p{{margin:5px 0;white-space:pre-wrap;line-height:1.45;font-size:14px}}
h2{{text-align:center;margin:8px 0 14px;font-size:21px;font-weight:700}}
.blank{{height:7px}}
table.controlled-form{{width:100%;border-collapse:collapse;table-layout:fixed;margin:8px 0 12px;font-size:12px}}
table.controlled-form td{{border:1px solid #CBD5E1;padding:5px 6px;vertical-align:top;white-space:pre-wrap;word-break:break-word}}
.signature{{display:inline-block;max-width:130px;max-height:42px;object-fit:contain;vertical-align:middle;margin:0 5px}}
@media(max-width:900px){{.page{{width:calc(100% - 20px);margin:10px;padding:18px}}}}
</style></head><body>
<div class="toolbar">{escape(title)}｜DOCX 在线审核阅读器</div>
<main class="page">{''.join(body)}</main>
</body></html>"""
