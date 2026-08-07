# -*- coding: utf-8 -*-
from __future__ import annotations
from datetime import datetime, time
from pathlib import Path
import base64, csv, hashlib, html, io, json, re, uuid, zipfile
import pandas as pd
import streamlit as st
import streamlit.components.v1 as components

from constants import *
from lims_db import *
from experiment_engine import schema, initial_parameters, initial_rows, calculate_rows, dataframe, columns_for_editor
from record_word_engine import export_record
from business_record_engine import initialize_business_record, calculate_business_record, business_to_template_fields, business_completion_summary, template_supplement_requirements, template_supplement_missing
from business_record_ui import render_readonly_summary, render_task_confirmations, render_equipment_confirmation, render_prechecks, render_parameters, render_sample_data, render_exception_and_summary, render_completion, render_template_supplement
from equipment_registry import EQUIPMENT_BINDING_ROLES
from experiment_schemas import SCHEMAS
from form_engine import commission_document, sample_register_document, loan_return_document, report_document, report_delivery_document, hazardous_waste_document, modification_log_pdf, objection_application_document, objection_response_document
from report_rules import overall_conclusion, report_item
from trace_excel_engine import build_internal_trace_workbook
from camera_evidence import save_live_camera_photo
from pdf_preview import build_preview_pdf, pdf_page_images
from docx_preview import DocxPreviewError, docx_page_images, docx_review_html
from quick_demo import create_pending_review_demo, create_full_document_demo, create_objection_application_demo

ROOT=Path(__file__).parent
TEMPLATE_DIR=ROOT/"templates"
SIG_DIR=ROOT/"data"/"signatures";SIG_DIR.mkdir(parents=True,exist_ok=True)
MOBILE_CAMERA_COMPONENT=components.declare_component(
    "bplab_mobile_camera",
    path=str(ROOT/"camera_component"),
)

st.set_page_config(page_title="BPLab Trace",page_icon="🧪",layout="wide",initial_sidebar_state="expanded")
st.markdown("""
<style>
:root{
  --lab-navy:#334155;--lab-blue:#7183a6;--lab-cyan:#79a9a3;
  --lab-ink:#293443;--lab-muted:#7b8492;--lab-line:#e3e8ee;
  --lab-bg:#eef2f5;--lab-panel:#ffffff;--lab-soft:#e8edf5;
}
html,body,.stApp,[data-testid=stAppViewContainer]{
  background:var(--lab-bg);color:var(--lab-ink);font-family:"Inter","PingFang SC","Microsoft YaHei",sans-serif;
}
.block-container{max-width:1480px;padding:1.25rem 2rem 4rem}
[data-testid=stSidebar]{
  background:#fbfcfd;border-right:1px solid #e2e7ec;min-width:270px;
  box-shadow:5px 0 20px rgba(50,65,80,.035);
}
[data-testid=stSidebar] h1,[data-testid=stSidebar] h2,[data-testid=stSidebar] h3,
[data-testid=stSidebar] p,[data-testid=stSidebar] label{color:#3f4b5b!important}
[data-testid=stSidebar] [data-testid=stCaptionContainer] p{
  color:#89929f!important;font-size:.72rem;letter-spacing:.07em;font-weight:700;
}
[data-testid=stSidebar] [role=radiogroup]{gap:3px}
[data-testid=stSidebar] [role=radio]{
  background:transparent;border:1px solid transparent;border-radius:8px;
  padding:10px 12px;margin:2px 0;transition:none;
}
[data-testid=stSidebar] [role=radio]:has(input:checked){
  background:#e8edf5;border-color:#dfe5ed;box-shadow:inset 3px 0 0 #8292b0;
}
[data-testid=stSidebar] .stButton>button{
  width:100%;justify-content:flex-start;border:1px solid transparent;background:transparent;
  color:#667080;border-radius:9px;min-height:38px;padding:.45rem .7rem;font-weight:560;
}
[data-testid=stSidebar] .stButton>button:hover{
  background:#f0f3f6;border-color:#e5e9ee;color:#354154;
}
[data-testid=stSidebar] .stButton>button[kind=primary]{
  background:#e6ebf3;border-color:#dce3ec;color:#33445f;
  box-shadow:inset 3px 0 0 #8293b2;font-weight:750;
}
.sidebar-profile{
  background:#f1f4f7;border:1px solid #e5e9ee;border-radius:11px;
  padding:11px 12px;margin:8px 0 15px;
}
.sidebar-profile b{color:#344154}.sidebar-profile span{color:#89929f;font-size:.76rem}
.lab-topbar{
  display:flex;align-items:center;justify-content:space-between;background:#fff;
  border:1px solid var(--lab-line);border-radius:10px 10px 0 0;padding:10px 18px;
  color:var(--lab-muted);font-size:.8rem;
}
.lab-header{
  background:var(--lab-panel);border:1px solid var(--lab-line);border-top:0;
  padding:20px 22px;margin-bottom:20px;border-radius:0 0 10px 10px;
  box-shadow:0 4px 16px rgba(15,26,47,.04);
}
.lab-kicker{color:var(--lab-blue);font-size:.75rem;font-weight:800;letter-spacing:.12em;text-transform:uppercase}
.lab-header h2{font-size:1.5rem;margin:.25rem 0;color:var(--lab-ink);font-weight:760}
.lab-meta{color:var(--lab-muted);font-size:.82rem}
.card,.timeline,[data-testid=stMetric],div[data-testid=stVerticalBlockBorderWrapper]{
  background:var(--lab-panel);border:1px solid var(--lab-line)!important;border-radius:11px!important;
  box-shadow:0 4px 14px rgba(15,26,47,.035);
}
.card{padding:16px}.timeline{border-left:4px solid var(--lab-blue)!important;padding:12px 15px;margin:8px 0}
.notice{background:#fff9e9;border:1px solid #eadba6;padding:12px;border-radius:6px}
[data-testid=stMetric]{padding:14px}
.stButton>button,.stDownloadButton>button{
  border-radius:7px;font-weight:700;min-height:40px;box-shadow:none;
}
.stButton>button[kind=primary]{background:var(--lab-blue);border-color:var(--lab-blue)}
[data-baseweb=tab-list]{
  gap:0;background:var(--lab-panel);border:1px solid var(--lab-line);padding:0;border-radius:9px;
  overflow-x:auto;
}
[data-baseweb=tab]{border-radius:0;padding:10px 15px;border-right:1px solid var(--lab-line)}
[data-baseweb=tab][aria-selected=true]{background:var(--lab-soft);color:var(--lab-navy);box-shadow:inset 0 -3px 0 var(--lab-blue)}
[data-testid=stExpander]{background:var(--lab-panel);border-color:var(--lab-line);border-radius:6px}
div[data-testid=stForm]{border-color:var(--lab-line)!important;border-radius:7px}
input,textarea,[data-baseweb=select]>div{border-radius:7px!important}
[data-testid=stNumberInput] button{min-width:38px;min-height:38px;font-size:1rem}
hr{border-color:var(--lab-line)}
.locked-field{border-left:3px solid #8fa3ad;background:#f4f6f7;padding:9px 12px;color:#536873;margin:6px 0}
@media(max-width:900px){.block-container{padding:1rem .8rem 3rem}[data-testid=stSidebar]{min-width:245px}}
</style>
""",unsafe_allow_html=True)


def header(title:str):
    current_date=china_now().strftime("%Y年%m月%d日")
    st.markdown(
        f'<div class="lab-topbar"><span>BPLab Trace · 实验室全过程追溯系统</span>'
        f'<span>{current_date} · {TIMEZONE_NAME}</span></div>'
        f'<section class="lab-header"><div class="lab-kicker">CONTROLLED LABORATORY WORKSPACE</div>'
        f'<h2>{title}</h2><div class="lab-meta">{COMPANY_CN} · {COMPANY_EN}　|　'
        f'{APP_VERSION}</div></section>',
        unsafe_allow_html=True,
    )


def show_df(data,columns=None):
    if not data:
        st.info("暂无数据");return
    frame=pd.DataFrame(data)
    if columns:frame=frame[[x for x in columns if x in frame.columns]]
    st.dataframe(frame,hide_index=True,use_container_width=True)


def user_map():return {x["username"]:x["display_name"] for x in list_users()}
def display_user(username):return user_map().get(username,username or "")
def role_users(role):return [x for x in list_users() if x["role"]==role and x["enabled"]]


def quality_evidence_choices(commission_no,selected_task_nos):
    """Readable investigation choices without exposing internal program keys."""
    selected=set(selected_task_nos);photo_options=[];record_options=[]
    for item in list_attachments(commission_no=commission_no):
        if (
            item.get("task_no") not in selected
            or item.get("evidence_status")!="有效"
            or item.get("capture_source")!="live_camera"
        ):continue
        photo_options.append(
            f"{item.get('attachment_id','')}｜{item.get('task_no','')}｜"
            f"{item.get('sample_no') or '任务整体'}｜{item.get('checkpoint_label') or item.get('attachment_type','')}｜"
            f"{item.get('server_captured_at') or item.get('captured_at','')}"
        )
    for task_no in selected_task_nos:
        task_row=task(task_no) or {};record_row=latest_record(task_no) or {}
        business=(record_row.get("payload") or {}).get("business_record") or {}
        kind=(task_config_snapshot(task_no) or {}).get("kind") or "generic"
        definition=SCHEMAS.get(kind) or SCHEMAS["generic"];labels={}
        for section in definition.get("sections",[]):
            for field in section.get("fields",[]):labels[field["key"]]=field.get("label") or field["key"]
        for key,label,_field_type in definition.get("columns",[]):labels[key]=label
        for key,value in (business.get("parameters") or {}).items():
            if key in labels and value not in (None,"",[]):
                record_options.append(f"{task_no}｜{task_row.get('experiment','')}｜环境/参数｜{labels[key]}={value}")
        for raw in business.get("rows") or []:
            sample_no=raw.get("sample_no","")
            for key,value in raw.items():
                if key in labels and key!="sample_no" and value not in (None,"",[]):
                    record_options.append(f"{task_no}｜{sample_no or '任务整体'}｜原始测量｜{labels[key]}={value}")
        for label,key in (("结果摘要","report_summary"),("单项结论","report_conclusion"),("异常/偏离","deviation"),("是否复测","retest")):
            value=business.get(key)
            if value not in (None,"",[]):record_options.append(f"{task_no}｜{task_row.get('experiment','')}｜{label}={value}")
    other_options=[
        "检验委托单及客户信息","样品登记表与样品状态","实验任务派发与接收记录",
        "实验开始/结束时间轴","设备配置与校准有效期","检测方法及SOP受控版本",
        "原始记录历史版本","修改记录日志PDF","检验报告及审批记录",
        "报告发放登记表","样品领用归还记录","危废处置记录",
    ]
    return list(dict.fromkeys(photo_options)),list(dict.fromkeys(record_options)),other_options


def review_correction_field_options(kind, business, template_name="", template_fields=None):
    """Return reviewer-facing Chinese field labels grouped by experiment step."""
    definition=SCHEMAS.get(kind) or SCHEMAS["generic"]
    options=[
        "①任务与样品确认｜样品接收、编号或状态确认",
        "②设备与实验前检查｜设备状态、校准信息或异常说明",
        "②设备与实验前检查｜实验前检查项目或说明",
    ]
    seen=set(options)
    for section in definition.get("sections",[]):
        for field in section.get("fields",[]):
            label=field.get("label") or field.get("key")
            value=f"③环境与实验参数｜{label}"
            if value not in seen:
                options.append(value);seen.add(value)
    for _key,label,_field_type in definition.get("columns",[]):
        if label in ("样品编号","序号"):
            continue
        value=f"④原始测量数据｜{label}"
        if value not in seen:
            options.append(value);seen.add(value)
    for item in template_supplement_requirements(
        template_name,
        template_fields or {},
    ):
        value=f"⑤母版过程确认｜{item.get('label') or item.get('position') or item.get('key')}"
        if value not in seen:
            options.append(value);seen.add(value)
    options.extend([
        "⑥异常与设备文件｜实验完成状态",
        "⑥异常与设备文件｜异常、偏离、影响评估及处理措施",
        "⑥异常与设备文件｜是否复测/重制",
        "⑥异常与设备文件｜结果摘要或单项结论",
        "⑥异常与设备文件｜照片留档",
        "⑥异常与设备文件｜设备原始文件",
        "⑦保存提交｜实验员自查确认或修改原因",
    ])
    return options


def returned_fields(review_row):
    try:
        value=json.loads((review_row or {}).get("correction_fields") or "[]")
        if not isinstance(value,list):
            return []
        migrated=[]
        for item in value:
            text=str(item)
            if text.startswith("⑤异常与设备文件"):
                text="⑥"+text[1:]
            elif text.startswith("⑥保存提交"):
                text="⑦"+text[1:]
            migrated.append(text)
        return migrated
    except (TypeError,json.JSONDecodeError):
        return []


def focus_returned_step(fields, focus_key):
    """Open the tab containing the first reviewer-designated field once."""
    if not fields or st.session_state.get(focus_key):
        return
    first=str(fields[0])
    step=next(
        (index for index,marker in enumerate(("①","②","③","④","⑤","⑥","⑦"),1) if first.startswith(marker)),
        1,
    )
    components.html(
        f"""
        <script>
        setTimeout(function() {{
          const tabs = window.parent.document.querySelectorAll('[data-baseweb="tab"]');
          if (tabs.length >= {step}) tabs[{step-1}].click();
        }}, 250);
        </script>
        """,
        height=0,
    )
    st.session_state[focus_key]=True


def returned_step_labels(fields, marker):
    """Labels the reviewer explicitly allowed for one second-edit step."""
    return {
        str(item).split("｜",1)[1]
        for item in fields or []
        if str(item).startswith(marker+"") and "｜" in str(item)
    }


def enforce_secondary_edit_scope(payload, prior, correction_fields, kind, supplement_requirements):
    """Server-side guard: keep every non-returned business field byte-for-byte."""
    if not prior:
        return payload
    base=json.loads(json.dumps(prior,ensure_ascii=False))
    incoming=json.loads(json.dumps(payload,ensure_ascii=False))
    old_business=base.get("business_record") or {}
    new_business=incoming.get("business_record") or {}
    merged=json.loads(json.dumps(old_business,ensure_ascii=False))
    labels_by_step={marker:returned_step_labels(correction_fields,marker) for marker in ("①","②","③","④","⑤","⑥","⑦")}
    if labels_by_step["①"]:
        merged["task_confirmations"]=new_business.get("task_confirmations")
    if labels_by_step["②"]:
        for key in ("equipment_checks","prechecks","precheck_note"):
            merged[key]=new_business.get(key)
    definition=SCHEMAS.get(kind) or SCHEMAS["generic"]
    parameter_keys={
        field.get("label"):field.get("key")
        for section in definition.get("sections",[])
        for field in section.get("fields",[])
    }
    for label in labels_by_step["③"]:
        key=parameter_keys.get(label)
        if key:
            merged.setdefault("parameters",{})[key]=(new_business.get("parameters") or {}).get(key)
    row_keys={label:key for key,label,_typ in definition.get("columns",[])}
    allowed_row_keys={row_keys[label] for label in labels_by_step["④"] if label in row_keys}
    if allowed_row_keys:
        old_rows=merged.get("rows") or []
        new_rows=new_business.get("rows") or []
        for index,old_row in enumerate(old_rows):
            if index>=len(new_rows):continue
            for key in allowed_row_keys:
                old_row[key]=new_rows[index].get(key)
    exception_map={
        "实验完成状态":"overall_status",
        "异常、偏离、影响评估及处理措施":"deviation",
        "是否复测/重制":"retest",
        "结果摘要或单项结论":"report_summary",
    }
    for label,key in exception_map.items():
        if label in labels_by_step["⑥"]:
            merged[key]=new_business.get(key)
            if label=="结果摘要或单项结论":
                merged["report_conclusion"]=new_business.get("report_conclusion")
    incoming["business_record"]=calculate_business_record(kind,merged)
    old_supplement=base.get("template_supplement") or {}
    new_supplement=incoming.get("template_supplement") or {}
    allowed_supplement={
        item.get("key") for item in supplement_requirements
        if (item.get("label") or item.get("position") or item.get("key")) in labels_by_step["⑤"]
    }
    incoming["template_supplement"]={
        key:(new_supplement.get(key) if key in allowed_supplement else value)
        for key,value in old_supplement.items()
    }
    for key in allowed_supplement:
        incoming["template_supplement"][key]=new_supplement.get(key)
    if "实验员自查确认或修改原因" not in labels_by_step["⑦"]:
        incoming["tester_self_check"]=base.get("tester_self_check",True)
    incoming["photo_attachment_ids"]=(
        incoming.get("photo_attachment_ids")
        if "照片留档" in labels_by_step["⑥"]
        else base.get("photo_attachment_ids",[])
    )
    incoming["deviation"]=incoming["business_record"].get("deviation","")
    incoming["retest"]=incoming["business_record"].get("retest","否")
    incoming["report_summary"]=incoming["business_record"].get("report_summary","")
    incoming["report_conclusion"]=incoming["business_record"].get("report_conclusion","")
    return incoming


def increment_base(base,n):
    m=re.fullmatch(r"(BP\d{8})(\d{3})",base)
    return f"{m.group(1)}{int(m.group(2))+n:03d}" if m else base


def field_widget(field,value,key_prefix):
    key=f"{key_prefix}_{field['key']}";label=field["label"];typ=field.get("type","text")
    if field.get("readonly"):
        st.text_input(label,value=str(value or ""),disabled=True,key=key);return value
    if typ=="number":return st.number_input(label,value=float(value or 0),key=key)
    if typ=="select":
        opts=field.get("options",[]);idx=opts.index(value) if value in opts else 0
        return st.selectbox(label,opts,index=idx,key=key)
    if typ=="multiselect":return st.multiselect(label,field.get("options",[]),default=value or [],key=key)
    if typ=="checkbox":return st.checkbox(label,value=bool(value),key=key)
    if typ=="date":
        try:v=pd.to_datetime(value).date() if value else china_today()
        except:v=china_today()
        return str(st.date_input(label,v,key=key))
    if typ=="datetime":
        return st.text_input(label,value=str(value or now()),key=key)
    if typ=="textarea":return st.text_area(label,value=str(value or ""),key=key)
    return st.text_input(label,value=str(value or ""),key=key)


def dataframe_editor(kind,rows0,key):
    cols=columns_for_editor(kind);frame=dataframe(kind,rows0)
    config={}
    for c in cols:
        typ=c["type"];label=c["label"]
        if typ=="calc":config[c["key"]]=st.column_config.NumberColumn(label,disabled=True)
        elif typ=="number":config[c["key"]]=st.column_config.NumberColumn(label,format="%.4f")
        elif typ.startswith("select:"):config[c["key"]]=st.column_config.SelectboxColumn(label,options=typ.split(":",1)[1].split("|"))
        else:config[c["key"]]=st.column_config.TextColumn(label,disabled=c["key"]=="sample_no")
    edited=st.data_editor(frame,column_config=config,hide_index=True,use_container_width=True,num_rows="fixed",key=key)
    return calculate_rows(kind,edited.to_dict("records"))


def render_experiment_timeline(task_row, actor, key_prefix):
    """Compact event timeline; experiment times are captured, never typed."""
    start_at=task_row.get("experiment_started_at") or ""
    end_at=task_row.get("experiment_ended_at") or ""
    st.subheader("实验时间轴")
    a,b,c=st.columns([1,1,1])
    a.markdown(f'<div class="timeline"><b>任务接收</b><br>{task_row.get("created_at") or "已建立任务"}</div>',unsafe_allow_html=True)
    b.markdown(f'<div class="timeline"><b>实验开始</b><br>{start_at.replace("T"," ") if start_at else "等待记录"}</div>',unsafe_allow_html=True)
    c.markdown(f'<div class="timeline"><b>实验结束</b><br>{end_at.replace("T"," ") if end_at else "等待记录"}</div>',unsafe_allow_html=True)
    st.info("进入实验过程后，系统已自动记录开始时间；实验员只需要在全部操作完成后手动结束实验。")
    if st.button("记录实验结束时间",disabled=not start_at or bool(end_at),use_container_width=True,key=f"{key_prefix}_timeline_end"):
        try:
            mark_task_experiment_time(task_row["task_no"],actor,"结束")
            st.rerun()
        except Exception as e:st.error(str(e))
    st.caption("时间由系统按中国大陆时区自动记录并进入审计时间轴，不再单独手工输入。")
    return start_at,end_at


def render_inline_camera(
    task_row, sample_ids, checkpoints, actor, actor_name, key_prefix, title,
):
    st.markdown(f"#### 📷 {title}")
    st.caption("拍照是本实验步骤的一部分；默认启动后置摄像头，可在取景区切换前/后摄。照片由服务器加盖时间戳并按实验任务编号归档。")
    for checkpoint_code, checkpoint_label, required in checkpoints:
        status = camera_checkpoint_status(task_row["task_no"], [(checkpoint_code, checkpoint_label, required)])[0]
        marker = "✅ 已留档" if status["complete"] else ("🔴 必拍" if required else "可选")
        with st.expander(f"{checkpoint_label}｜{marker}", expanded=required and not status["complete"]):
            archived=[
                item for item in list_attachments(task_no=task_row["task_no"])
                if item.get("capture_source")=="live_camera"
                and item.get("checkpoint_code")==checkpoint_code
                and item.get("evidence_status")=="有效"
            ]
            if archived:
                st.caption("已留档照片会跨草稿和二次编辑版本保留；重新拍摄前不会丢失。")
                preview_cols=st.columns(min(3,len(archived)))
                for photo_index,item in enumerate(archived):
                    path=attachment_file(item)
                    if path.exists():
                        with preview_cols[photo_index % len(preview_cols)]:
                            st.image(
                                str(path),
                                caption=f"{item.get('sample_no') or '任务整体'}｜"
                                        f"{item.get('server_captured_at') or item.get('captured_at','')}",
                                use_container_width=True,
                            )
            if checkpoint_code in SAMPLE_LEVEL_PHOTO_CODES:
                if status.get("missing_samples"):
                    st.warning("仍需拍摄："+"、".join(status["missing_samples"]))
                else:
                    st.success("本节点所有实体样品均已有有效照片。")
                # While a checkpoint is incomplete, only offer samples that
                # still need evidence. Including the photo count in the widget
                # key resets the selector after each successful capture, so
                # the next missing sample becomes the automatic default.
                sample_options = status.get("missing_samples") or sample_ids
                sample_no = st.selectbox(
                    "本次拍摄的实体样品", sample_options,
                    key=f"{key_prefix}_{checkpoint_code}_sample_{status['photo_count']}",
                )
            else:
                sample_no = ""
                st.info("该照片关联整个实验任务，仅需拍摄一次，不需要逐个样品重复拍照。")
            camera_entity = sample_no or "TASK"
            camera_widget_key=f"{key_prefix}_{checkpoint_code}_{camera_entity}_camera"
            camera_result=MOBILE_CAMERA_COMPONENT(
                label=f"现场拍摄：{checkpoint_label}",
                default_facing="environment",
                key=camera_widget_key,
                default=None,
            )
            photo_bytes=None
            capture_id=""
            if isinstance(camera_result,dict):
                capture_id=str(camera_result.get("capture_id") or "")
                consumed_key=f"{camera_widget_key}_consumed"
                if capture_id and capture_id!=st.session_state.get(consumed_key):
                    data_url=str(camera_result.get("data_url") or "")
                    if data_url.startswith("data:image/") and "," in data_url:
                        try:
                            photo_bytes=base64.b64decode(data_url.split(",",1)[1],validate=True)
                        except Exception:
                            st.error("相机照片读取失败，请重新拍摄。")
            if photo_bytes:
                st.success(
                    "照片已拍摄，当前镜头："+
                    ("后置摄像头" if camera_result.get("facing_mode")=="environment" else "前置摄像头")
                )
            if photo_bytes and st.button(
                "保存并自动盖时间戳", type="primary",
                key=f"{key_prefix}_{checkpoint_code}_{camera_entity}_save",
            ):
                save_live_camera_photo(
                    {
                        "commission_no": task_row["commission_no"],
                        "package_no": task_row["package_no"],
                        "task_no": task_row["task_no"], "sample_no": sample_no,
                        "checkpoint_code": checkpoint_code,
                        "checkpoint_label": checkpoint_label,
                        "device_id": st.session_state.device_id,
                    },
                    photo_bytes, actor, actor_name,
                )
                st.session_state[f"{camera_widget_key}_consumed"]=capture_id
                st.session_state.flash_message = f"{checkpoint_label}照片已按任务编号留档"
                st.rerun()


def task_archive(task_no):
    """Build a browser-downloadable archive with task-number folder structure."""
    output=io.BytesIO()
    with zipfile.ZipFile(output,"w",zipfile.ZIP_DEFLATED) as archive:
        for meta in list_attachments(task_no=task_no):
            path=attachment_file(meta)
            if not path.exists():
                continue
            folder="照片" if meta.get("capture_source")=="live_camera" else "设备原始文件"
            if folder=="照片" and bool(meta.get("is_original")):
                continue
            archive.writestr(f"{task_no}/{folder}/{meta['original_name']}",path.read_bytes())
        trace_rows=audit_logs(task_no)
        change_rows=modification_logs(task_no)
        archive.writestr(
            f"{task_no}/{task_no}_修改记录日志.pdf",
            modification_log_pdf(change_rows,task_no).getvalue(),
        )
        locked=latest_record(task_no)
        if locked and locked.get("status")=="已锁定":
            snapshot=task_config_snapshot(task_no)
            template_name=snapshot.get("record_template_file","")
            archive.writestr(
                f"{task_no}/{task_no}_V{locked['version']}_原始记录表.docx",
                export_record(locked,template_name,trace_rows).getvalue(),
            )
        report_row=one("SELECT * FROM reports WHERE task_no=?",(task_no,))
        if report_row and report_row.get("status")=="已发布" and report_row.get("validity_status")=="有效":
            task_row=task(task_no);commission_row=commission(task_row["commission_no"])
            groups=commission_groups(task_row["commission_no"])
            samples=commission_samples(task_row["commission_no"])
            task_row["kind"]=task_config_snapshot(task_no).get("kind") or "generic"
            task_row["sample_name"]=next(
                (item["sample_name"] for item in groups if item["id"]==task_row["group_id"]),""
            )
            users0=user_map()
            signatures0={name:signature(name) for name in users0}
            archive.writestr(
                f"{task_no}/{report_row['report_no']}_检验报告.docx",
                report_document(
                    commission_row,groups,samples,[task_row],
                    report_records_for_report(report_row["report_no"]),
                    report_row,users0,signatures0,
                ).getvalue(),
            )
        task_row=task(task_no)
        if task_row:
            archive.writestr(
                f"{task_no}/{task_row['commission_no']}_内部实验数据追溯工作簿.xlsx",
                build_internal_trace_workbook(task_row["commission_no"]).getvalue(),
            )
    return output.getvalue()


def show_pdf_preview(title, sections):
    st.markdown("#### PDF 在线预览")
    st.caption("审核期间仅以页面图像方式预览，不提供PDF或Word下载按钮。")
    content=build_preview_pdf(title,sections)
    for index,image in enumerate(pdf_page_images(content),1):
        st.image(image,caption=f"{title}｜第 {index} 页",use_container_width=True)


@st.cache_data(show_spinner=False,max_entries=40)
def controlled_docx_page_images(docx_content):
    return docx_page_images(docx_content)


def show_controlled_docx_review(title, docx_content, allow_download=True):
    st.markdown("#### 受控 Word 原版逐页预览")
    st.caption("预览由服务器直接渲染实际受控DOCX，分页、表格、签名和照片与单据中心文件保持一致。")
    try:
        with st.spinner("正在生成原版页面预览…"):
            page_images=controlled_docx_page_images(docx_content)
        for page_number,page_image in enumerate(page_images,1):
            st.image(
                page_image,
                caption=f"{title}｜第 {page_number} 页 / 共 {len(page_images)} 页",
                use_container_width=True,
            )
    except DocxPreviewError as exc:
        st.warning(f"原版页面渲染暂不可用：{exc}。已切换到兼容阅读模式。")
        components.html(
            docx_review_html(docx_content,title),
            height=920,
            scrolling=True,
        )
    if allow_download:
        st.download_button(
            "打开审核用DOCX",
            docx_content,
            f"{title}.docx",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            key=f"review_docx_{hashlib.sha256(docx_content).hexdigest()[:16]}",
            use_container_width=True,
        )


def preview_rows(kind, rows0):
    labels={key:label for key,label,_type in schema(kind).get("columns",[])}
    labels["sample_no"]="样品编号"
    return [
        {
            labels.get(key,key):value
            for key,value in row.items()
            if not key.startswith("_") and value not in (None,"")
        }
        for row in rows0
    ]


def show_report_photo_preview(task_no):
    task_row=task(task_no) or {}
    decisive_codes=REPORT_DECISIVE_PHOTO_CODES.get(task_row.get("experiment",""),[])
    photos=[
        item for item in list_attachments(task_no=task_no)
        if item.get("checkpoint_code") in decisive_codes
        and item.get("evidence_status")=="有效"
        and not bool(item.get("is_original"))
    ]
    if not photos:
        photos=[
            item for item in list_attachments(task_no=task_no)
            if item.get("checkpoint_code")=="REPORT_PHOTO"
            and item.get("evidence_status")=="有效"
            and not bool(item.get("is_original"))
        ]
    st.markdown("#### 报告照片区域预览")
    if not photos:
        st.warning("尚未取得可用于报告的决定性结果照片。")
        return
    for item in photos:
        path=attachment_file(item)
        if path.exists():
            st.image(
                str(path),
                caption=f"{item.get('sample_no') or '任务整体'}｜{item.get('checkpoint_label','')}｜{item.get('server_captured_at','')}",
                width=520,
            )


def navigate_to(target, message=""):
    if message:
        st.session_state.flash_message=message
    st.query_params["goto"]=target
    st.rerun()


init_db()
for exp,cfg in EXPERIMENTS.items():
    seed_template(exp,"原始记录表",cfg.get("template"));seed_template(exp,"SOP",cfg.get("sop"))

if "user" not in st.session_state:
    restored=session_user(st.query_params.get("session",""))
    if restored:st.session_state.user=restored
if "user" not in st.session_state:
    header("系统登录");a,b,c=st.columns([1,1.15,1])
    with b:
        username=st.text_input("用户名",key="login_username");password=st.text_input("密码",type="password",key="login_password")
        if st.button("登录",type="primary",use_container_width=True,key="login_button"):
            u=authenticate(username,password)
            if u:st.session_state.user=u;st.query_params["session"]=create_session(username);st.rerun()
            else:st.error("用户名或密码错误")
        st.caption("管理员 admin/admin123｜样品管理员 receiver/receive123｜实验员 tester/test123｜复核员 reviewer/review123｜质量负责人 quality/quality123")
    st.stop()

user=st.session_state.user;role=user["role"];username=user["username"]
if "device_id" not in st.session_state:
    st.session_state.device_id="TAB-"+uuid.uuid4().hex[:10].upper()
goto_page=st.query_params.get("goto","")
if goto_page in ROLE_MENUS[role]:
    st.session_state["main_navigation"]=goto_page
    del st.query_params["goto"]
with st.sidebar:
    st.markdown("## ◉ BPLab Trace")
    st.caption("LABORATORY MANAGEMENT")
    st.markdown(
        f'<div class="sidebar-profile"><b>{html.escape(user["display_name"])}</b><br>'
        f'<span>{html.escape(role)} · 受控工作台</span></div>',
        unsafe_allow_html=True,
    )
    if st.session_state.get("main_navigation") not in ROLE_MENUS[role]:
        st.session_state["main_navigation"]=ROLE_MENUS[role][0]
    current_page=st.session_state["main_navigation"]
    for group_index,(group_name,group_pages) in enumerate(ROLE_NAV_GROUPS[role]):
        if group_index==0:
            st.caption(group_name.upper())
            target_container=st.container()
        else:
            target_container=st.expander(
                group_name,
                expanded=current_page in group_pages,
            )
        with target_container:
            for nav_page in group_pages:
                icon=NAV_ICONS.get(nav_page,"·")
                if st.button(
                    f"{icon}　{nav_page}",
                    key=f"nav_{role}_{nav_page}",
                    type="primary" if nav_page==current_page else "secondary",
                    use_container_width=True,
                ):
                    st.session_state["main_navigation"]=nav_page
                    st.rerun()
    page=st.session_state["main_navigation"]
    st.divider();st.caption("中国大陆时间 · UTC+8")
    if st.button("退出登录",use_container_width=True,key="logout_button"):delete_session(st.query_params.get("session",""));st.session_state.clear();st.query_params.clear();st.rerun()

flash_message = st.session_state.pop("flash_message", None)
if flash_message:
    st.toast(flash_message)

st.session_state.setdefault("dismissed_notice_ids", [])
pending_notices = [
    item for item in unread_notifications(username)
    if item["id"] not in st.session_state.dismissed_notice_ids
]
if pending_notices:
    @st.dialog("您收到新的工作任务")
    def task_notice_dialog():
        for notice in pending_notices:
            st.markdown(f"**{notice['title']}**")
            st.write(notice["message"])
            st.caption(notice["created_at"])
            st.divider()
        a,b=st.columns(2)
        notice_ids=[x["id"] for x in pending_notices]
        if a.button("我已查看", type="primary", use_container_width=True):
            mark_notifications_read(username,notice_ids)
            st.session_state.dismissed_notice_ids.extend(notice_ids)
            st.rerun(scope="app")
        if b.button("稍后处理并关闭", use_container_width=True):
            st.session_state.dismissed_notice_ids.extend(notice_ids)
            st.rerun(scope="app")
    task_notice_dialog()

if page=="首页看板":
    header("委托、样品、任务包和报告状态看板");counts=dashboard_counts();cols=st.columns(7)
    if role=="管理员":
        st.info("临时测试入口：可生成待复核任务，或直接生成包含十项实验、结果照片、已签发报告和发放登记的完整单据Demo。")
        demo_a,demo_b=st.columns(2)
        if demo_a.button("生成待复核实验Demo",type="primary",key="create_pending_review_demo_home",use_container_width=True):
            try:
                demo=create_pending_review_demo()
                st.success(f"已生成：{demo['commission_no']}｜{demo['task_no']}。请使用 reviewer / review123 登录查看复核预览。")
                st.rerun()
            except Exception as error:
                st.error("生成演示数据失败："+str(error))
        if demo_b.button("生成完整单据与照片Demo",key="create_full_document_demo_home",use_container_width=True):
            try:
                demo_commission=create_full_document_demo()
                st.success(f"已生成完整演示委托：{demo_commission}。请前往单据中心查看报告、发放登记和追溯Excel。")
                st.rerun()
            except Exception as error:
                st.error("生成完整演示数据失败："+str(error))
    metrics=[("委托",counts["commissions"]),("在册样品",counts["samples"]),("待接收任务包",counts["packages"]),("检测中",counts["testing"]),("待复核",counts["reviews"]),("待回库",counts["returns"]),("待发布报告",counts["reports"])]
    for col,(label,value) in zip(cols,metrics):col.metric(label,value)
    show_df(list_samples(),["sample_no","commission_no","group_no","sample_name","model","material_name","status","current_location","current_holder","updated_at"])
    st.divider()
    st.subheader("样品组流转时间轴")
    timeline_groups=sample_groups_for_timeline()
    if timeline_groups:
        timeline_group_id=st.selectbox(
            "选择样品组",
            [x["id"] for x in timeline_groups],
            format_func=lambda group_id:next(
                f"{x['group_no']}｜{x['sample_name']}｜{x['client_name']}｜{x['status']}"
                for x in timeline_groups if x["id"]==group_id
            ),
            key="dashboard_group_timeline",
        )
        selected_group=next(x for x in timeline_groups if x["id"]==timeline_group_id)
        st.caption(
            f"委托：{selected_group['commission_no']}｜样品组：{selected_group['group_no']}｜"
            f"型号：{selected_group.get('model','')}｜批号：{selected_group.get('product_no','')}｜"
            f"当前位置/状态：{selected_group.get('storage_area','')} / {selected_group.get('status','')}"
        )
        timeline_rows=sample_group_timeline(timeline_group_id)
        for item in timeline_rows:
            safe_item={key:html.escape(str(value or "")) for key,value in item.items()}
            st.markdown(
                f"<div class='timeline'><b>{safe_item['时间']}｜{safe_item['流转环节']}</b><br>"
                f"状态：{safe_item['状态变化'] or '—'}　位置：{safe_item['位置变化'] or '—'}<br>"
                f"样品：{safe_item['涉及样品'] or '样品组整体'}　操作人：{safe_item['操作人'] or '系统'}"
                f"{'<br>说明：'+safe_item['说明'] if safe_item['说明'] else ''}</div>",
                unsafe_allow_html=True,
            )
        with st.expander("查看时间轴表格"):
            show_df(timeline_rows,["时间","流转环节","状态变化","位置变化","涉及样品","操作人","说明"])
    else:
        st.info("暂无样品组流转记录。")

elif page=="单位信息库":
    header("委托客户、生产单位和受委托生产企业信息库")
    if role not in ["管理员","样品管理员"]:st.stop()
    show_df(list_organizations(True),["org_code","org_name","short_name","is_client","is_manufacturer","is_contract_manufacturer","address","contact","phone","enabled"])
    with st.form("org_form",clear_on_submit=True):
        a,b,c=st.columns(3);code=a.text_input("单位编号");name=b.text_input("单位名称");short=c.text_input("单位简称")
        client=a.checkbox("委托客户");manufacturer=b.checkbox("生产单位");contract=c.checkbox("受委托生产企业")
        address=a.text_input("地址");contact=b.text_input("联系人");phone=c.text_input("联系电话");credit=a.text_input("统一社会信用代码");notes=st.text_area("备注")
        if st.form_submit_button("保存单位",type="primary"):
            try:add_organization({"org_code":code,"org_name":name,"short_name":short,"is_client":client,"is_manufacturer":manufacturer,"is_contract_manufacturer":contract,"address":address,"contact":contact,"phone":phone,"credit_code":credit,"notes":notes},username);st.rerun()
            except Exception as e:st.error(str(e))

elif page=="检测项目与方法库":
    header("动态检测项目与方法库")
    if role!="管理员":st.stop()
    methods=list_experiment_methods(True)
    show_df(methods,["experiment_name","method_code","standard","category","kind","enabled","sort_order","updated_at"])
    st.info("实验名称和检测方法可以继续增加、停用或调整；对正式任务生效前，应在“实验配置版本”中新建并发布配置。界面不显示内部实验标识。")
    names=["新增实验"]+[x["experiment_name"] for x in methods]
    selected=st.selectbox("新增或维护实验",names)
    current=experiment_method_by_name(selected) if selected!="新增实验" else {}
    with st.form("method_form"):
        a,b,c=st.columns(3)
        name=a.text_input("实验名称",current.get("experiment_name","") if current else "")
        method=b.text_input("检测方法",current.get("method_code","") if current else "",help="直接填写受控标准/方法名称，不设置“其他方法”选项")
        standard=c.text_input("检测依据/版本",current.get("standard","") if current else "")
        category=a.text_input("实验类别",current.get("category","") if current else "")
        kind_options=list(SCHEMAS.keys())
        current_kind=(current or {}).get("kind") or "generic"
        kind=b.selectbox("记录数据模板",kind_options,index=kind_options.index(current_kind) if current_kind in kind_options else kind_options.index("generic"),help="新增实验可先使用generic通用记录，收到SOP和原始记录表后再配置专用模板")
        order=c.number_input("排序",min_value=0,value=int((current or {}).get("sort_order",100) or 100),step=1)
        enabled=a.checkbox("启用",value=bool((current or {}).get("enabled",1)))
        if st.form_submit_button("保存检测项目与方法",type="primary"):
            try:
                save_experiment_method({"experiment_name":name,"method_code":method,"standard":standard,"category":category,"kind":kind,"sort_order":order,"enabled":enabled},username)
                st.success("已保存。新增或变更内容需建立配置版本并发布后，才用于新任务。")
                st.rerun()
            except Exception as e:st.error(str(e))

elif page=="样品资料库":
    header("样品名称、规格型号、材料和检测项目与方法资料库")
    if role not in ["管理员","样品管理员"]:st.stop()
    method_rows=list_experiment_methods();method_map={x["experiment_code"]:x for x in method_rows}
    catalog=list_catalog(True)
    for item in catalog:item["检测项目与方法"]="；".join(item.get("experiment_labels",[]))
    show_df(catalog,["source_sequence","sample_code","sample_name","model","material_name","process","material_suffix","category","unit","检测项目与方法","enabled"])
    with st.form("catalog_form",clear_on_submit=True):
        a,b,c=st.columns(3)
        code=a.text_input("样品资料编号");name=b.text_input("样品名称");model=c.text_input("规格型号")
        material=a.text_input("材料名称");category=b.text_input("类别");unit=c.text_input("单位",value="件")
        process=a.text_input("加工工艺");material_suffix=b.text_input("材料后缀")
        exp_codes=st.multiselect("检测项目与方法",[x["experiment_code"] for x in method_rows],
            format_func=lambda x:f"{method_map[x]['experiment_name']}｜{method_map[x]['method_code']}")
        notes=st.text_area("备注")
        if st.form_submit_button("保存样品资料",type="primary"):
            try:
                add_catalog({"sample_code":code,"sample_name":name,"model":model,"material_name":material,
                    "process":process,"material_suffix":material_suffix,
                    "category":category,"unit":unit,"experiment_codes":exp_codes,"notes":notes},username)
                st.rerun()
            except Exception as e:st.error(str(e))

elif page=="新建委托与入库":
    header("一份委托统一选择生产单位，并同时录入多个不同样品组")
    if role!="样品管理员":
        st.error("按照现行流程，只有样品管理员负责建立委托和收样入库。")
        st.stop()
    orgs=list_organizations();clients=[x for x in orgs if x["is_client"]]
    producers=[x for x in orgs if x["is_manufacturer"] or x["is_contract_manufacturer"]]
    catalog=list_catalog();method_rows=list_experiment_methods();method_map={x["experiment_code"]:x for x in method_rows}
    if not clients or not producers or not catalog:
        st.error("请先建立委托客户、生产单位/受委托生产企业和样品资料");st.stop()
    if "intake_groups" not in st.session_state:st.session_state.intake_groups=[]
    st.subheader("委托主单")
    a,b,c=st.columns(3)
    commission_no=a.text_input("检验委托编号（暂行规则）",value=next_commission_no())
    client_id=b.selectbox("委托客户",[x["id"] for x in clients],format_func=lambda x:next(y["org_name"] for y in clients if y["id"]==x))
    client=next(x for x in clients if x["id"]==client_id)
    producer_id=c.selectbox("生产单位/受委托生产企业",[x["id"] for x in producers],format_func=lambda x:next(y["org_name"] for y in producers if y["id"]==x))
    producer=next(x for x in producers if x["id"]==producer_id)
    relation=a.selectbox("单位关系",["生产单位","受委托生产企业"])
    commission_date=b.date_input("委托/接收日期",china_today())
    due=c.date_input("计划完成日期",add_months_to_date(commission_date,1))
    subcontract=a.selectbox("允许分包",["否","是"])
    report_medium=b.multiselect("报告载体",["纸质","电子档"],default=["电子档"])
    conformity=c.selectbox("符合性判定",["是","否"])
    uncertainty=a.selectbox("考虑不确定度",["否","是"])
    delivery=b.selectbox("递送方式",["Email","自取","快递"])
    cnas=c.selectbox("加盖CNAS章",["否","是"])
    capability=a.selectbox("检测能力评价",["完全满足","部分满足","不满足"])
    commission_notes=st.text_area("委托备注")
    st.info(f"本委托下所有样品统一使用：{producer['org_name']}（{relation}）")

    st.subheader("添加样品组")
    with st.form("add_group",clear_on_submit=False):
        cat_id=st.selectbox(
            "样品名称 / 规格型号 / 材料（完整宽度）",
            [x["id"] for x in catalog],
            format_func=lambda x:next(
                f"{y['sample_name']}｜{y['model']}｜{y['material_name']}｜{y.get('process','')}"
                for y in catalog if y["id"]==x
            ),
        )
        cat=next(x for x in catalog if x["id"]==cat_id)
        a,b,c=st.columns(3)
        base_default=increment_base(next_sample_base(),len(st.session_state.intake_groups))
        product_no=a.text_input("产品编号/批号（必填）")
        production_date=b.date_input("生产日期")
        qty=int(c.number_input("接收数量（自动生成 -S01～-Sxx）",1,99,1))
        group_no=st.text_input("样品组基础编号",value=base_default)
        condition=b.selectbox("样品状态",SAMPLE_CONDITIONS)
        storage=c.selectbox("入库区域",STORAGE_AREAS)
        unit=a.text_input("单位",value=cat["unit"])
        condition_note=b.text_input("状态备注")
        exp_codes=st.multiselect("检测项目与方法",[x["experiment_code"] for x in method_rows],
            default=[],
            format_func=lambda x:f"{method_map[x]['experiment_name']}｜{method_map[x]['method_code']}")
        st.caption("不预设检测项目，请根据本次委托逐项手动选择。")
        group_notes=st.text_area("样品组备注")
        if st.form_submit_button("加入本委托的样品明细"):
            normalized_group=group_no.strip().upper().replace(" ","")
            if not re.fullmatch(r"BP\d{11}",normalized_group):
                st.error("样品组基础编号必须符合BP年月日001，例如BP20260722001")
            elif any(g["group_no"]==normalized_group for g in st.session_state.intake_groups):
                st.error("当前委托草稿中已存在相同样品组编号")
            elif not product_no.strip():
                st.error("产品编号/批号为必填项")
            elif not exp_codes:
                st.error("请至少选择一个检测项目与方法")
            else:
                st.session_state.intake_groups.append({
                    "group_no":normalized_group,"catalog_id":cat_id,"sample_name":cat["sample_name"],
                    "model":cat["model"],"material_name":cat["material_name"],"quantity":qty,
                    "product_no":product_no,"production_date":str(production_date),
                    "unit":unit,"condition":condition,
                    "condition_note":condition_note,"storage_area":storage,
                    "experiment_codes":exp_codes,
                    "experiment_labels":[f"{method_map[x]['experiment_name']}｜{method_map[x]['method_code']}" for x in exp_codes],
                    "notes":group_notes,
                });st.rerun()
    if st.session_state.intake_groups:
        show_df(st.session_state.intake_groups,["group_no","sample_name","model","material_name","product_no","production_date","quantity","condition","storage_area","experiment_labels"])
        remove_index=st.selectbox("删除一条草稿明细",range(len(st.session_state.intake_groups)),
            format_func=lambda i:f"{i+1}. {st.session_state.intake_groups[i]['group_no']} {st.session_state.intake_groups[i]['sample_name']}")
        if st.button("删除所选草稿"):st.session_state.intake_groups.pop(remove_index);st.rerun()
        st.info("实体编号预览："+"；".join(
            f"{g['group_no']}-S01～{g['group_no']}-S{g['quantity']:02d}" if g['quantity']>1 else f"{g['group_no']}-S01"
            for g in st.session_state.intake_groups))
        selected_methods=list(dict.fromkeys(method_map[c]["method_code"] for g in st.session_state.intake_groups for c in g["experiment_codes"]))
        st.info("委托单检测方法将自动勾选："+"、".join(selected_methods))
        if st.button("生成同一份委托单并完成全部样品入库",type="primary",use_container_width=True):
            data={"commission_no":commission_no,"client_org_id":client_id,"client_name":client["org_name"],
                "client_address":client["address"],"contact":client["contact"],"phone":client["phone"],
                "production_org_id":producer_id,"production_org_name":producer["org_name"],
                "production_relation":relation,"commission_date":commission_date,"due_date":due,
                "subcontract_allowed":subcontract,"report_medium":"、".join(report_medium),
                "conformity_judgment":conformity,"uncertainty":uncertainty,"delivery_method":delivery,
                "cnas_mark":cnas,"capability":capability,"notes":commission_notes}
            try:
                create_commission(data,st.session_state.intake_groups,username)
                st.session_state.intake_groups=[]
                st.success("委托和全部样品组已入库，实验名称和检测方法已自动绑定")
                st.rerun()
            except Exception as e:st.error(str(e))

elif page=="委托与样品管理":
    header("委托、样品组、实体样品和全过程时间轴");cs=list_commissions();show_df(cs,["commission_no","client_name","production_org_name","production_relation","commission_date","due_date","status","created_by"])
    if cs:
        cn=st.selectbox("选择委托",[x["commission_no"] for x in cs]);groups=commission_groups(cn,True);show_df(groups,["id","group_no","sample_name","model","material_name","quantity","status","is_void","void_reason"])
        active=[g for g in groups if not g["is_void"]]
        if active:
            gid=st.selectbox("查看样品组",[g["id"] for g in active],format_func=lambda x:next(f"{g['group_no']} {g['sample_name']}" for g in active if g["id"]==x));samples0=group_samples(gid);show_df(samples0,["sample_no","sample_name","model","material_name","status","current_location","current_holder"])
            sn=st.selectbox("查看实体样品时间轴",[x["sample_no"] for x in samples0]);
            for e in sample_events(sn):st.markdown(f'<div class="timeline"><b>{e["created_at"]} · {e["action"]}</b><br>{e["from_status"]} → {e["to_status"]}<br>{e["from_location"]} → {e["to_location"]}<br>操作人：{display_user(e["actor"])}<br>{e["details"]}</div>',unsafe_allow_html=True)
            reason=st.text_input("错误入库删除原因")
            if st.button("删除当前错误入库样品组"):
                try:void_group(gid,username,reason);st.rerun()
                except Exception as e:st.error(str(e))

elif page=="任务包分配":
    header("一个样品组多选实验，一次下发、一次领用、一次归还")
    groups=available_groups_for_assignment();show_df(groups,["id","commission_no","group_no","sample_name","model","material_name","pending_count","status"])
    if groups:
        gid=st.selectbox("样品组",[g["id"] for g in groups],format_func=lambda x:next(f"{g['group_no']} {g['sample_name']}" for g in groups if g["id"]==x))
        pending=[x for x in requested_tests(gid) if x["status"]=="待分配"]
        pending_map={x["experiment_code"]:x for x in pending}
        experiment_codes=list(pending_map)
        st.markdown("**本样品组待下发实验（自动继承，只读）**")
        show_df(
            [
                {
                    "检测项目":pending_map[code]["experiment"],
                    "检测方法":pending_map[code]["method_code"],
                    "检测依据":pending_map[code]["standard"],
                }
                for code in experiment_codes
            ],
            ["检测项目","检测方法","检测依据"],
        )
        st.caption("检测项目已在收样入库阶段确定。本任务包自动包含该样品组全部待分配实验，收样员无需再次选择。")
        testers=role_users("实验员")
        assignee=st.selectbox("选择实验员",[x["username"] for x in testers],format_func=display_user)
        st.info("复核员和质量负责人由系统按授权有效性、人员独立性和当前工作量自动匹配。")
        if st.button("下发任务包并提醒实验员",type="primary"):
            try:
                package_no=create_task_package(gid,experiment_codes,assignee,username)
                navigate_to("首页看板","已下发："+package_no)
            except Exception as e:st.error(str(e))

elif page=="我的任务包":
    header("任务提醒、整组样品领用和多个实验子任务")
    packages=list_packages(None if role=="管理员" else role,None if role=="管理员" else username);show_df(packages,["package_no","commission_no","group_no","material_name","experiments","status","assigned_at","accepted_at","detection_location"])
    if packages:
        pn=st.selectbox("选择任务包",[x["package_no"] for x in packages]);p=package(pn);package_task_rows=package_tasks(pn);show_df(package_task_rows,["task_no","experiment","method_code","standard","material_name","detection_location","status"])
        if p["status"]=="待接收" and username==p["assignee"]:
            result=st.radio("样品实物接收确认",["样品已收到，确认完好","样品已收到，但存在异常","尚未收到样品"])
            st.subheader("逐实验选择检测位置")
            st.caption("每个实验独立选择，允许同一任务包内的实验使用不同检测位置。推荐地点仅作默认值，可按实际情况修改。")
            task_locations={}
            location_cols=st.columns(2)
            for index,item in enumerate(package_task_rows):
                recommended=device_preset(item["experiment"]).get("default_location","")
                if recommended not in DETECTION_LOCATIONS:recommended=DETECTION_LOCATIONS[0]
                with location_cols[index%2]:
                    task_locations[item["task_no"]]=st.selectbox(
                        f"{item['experiment']}｜{item['method_code']}",
                        DETECTION_LOCATIONS,
                        index=DETECTION_LOCATIONS.index(recommended),
                        key=f"task_location_{item['task_no']}",
                    )
            note=st.text_area("领用/异常备注")
            if st.button("确认整组样品领用",type="primary"):
                try:
                    accept_package(pn,username,result,task_locations,note)
                    navigate_to("实验记录","任务包已接收，实验记录窗口已为您准备")
                except Exception as e:st.error(str(e))

elif page=="实验记录":
    header("简洁实验流程记录")
    all_packages=list_packages(role,username,["检测中","待复核","退回修改","待归还","待回库确认","已回库"])
    task_list=[]
    for p in all_packages:
        task_list.extend([t for t in package_tasks(p["package_no"]) if t["status"] in ["检测中","退回修改","待复核","更正待复核","已完成"]])
    if not task_list:
        st.info("暂无可填写实验任务")
    else:
        tn=st.selectbox(
            "选择实验任务",
            [t["task_no"] for t in task_list],
            format_func=lambda x:(
                next(f"{t['task_no']}｜{t['experiment']}" for t in task_list if t['task_no']==x)
                + (
                    "｜⚠️ 二次编辑"
                    if next((t.get("status")=="退回修改" for t in task_list if t["task_no"]==x),False)
                    or int((latest_record(x) or {}).get("version") or 1)>1 else ""
                )
            ),
        )
        t=task(tn)
        # 第一次进入实验过程即自动开始；只写入一次，页面刷新不会覆盖。
        if not t.get("experiment_started_at") and t.get("status") in ("检测中","退回修改"):
            try:
                mark_task_experiment_time(tn,username,"开始",system_auto=True)
                t=task(tn)
                st.success(f"系统已自动记录实验开始时间：{str(t.get('experiment_started_at','')).replace('T',' ')}")
            except Exception as e:
                st.error(f"自动记录实验开始时间失败：{e}")
        config_snapshot=task_config_snapshot(tn);latest=latest_record(tn)
        if latest and latest["status"]=="已锁定":
            st.warning("该记录已锁定。如需更正，请在修改中心创建新版本。")
            st.stop()
        version=latest["version"] if latest else 1
        prior=latest["payload"] if latest else {}
        compare=None
        if version>1:
            versions=record_versions(tn);compare=versions[-2]["payload"] if len(versions)>1 else None
        returned_review=one(
            """SELECT rv.*,u.display_name reviewer_name FROM reviews rv
               LEFT JOIN users u ON u.username=rv.reviewer
               WHERE rv.record_no=? AND rv.decision='退回'
               ORDER BY rv.id DESC LIMIT 1""",
            (tn,),
        )
        correction_fields=returned_fields(returned_review)
        if version>1 and latest and latest.get("status")!="已锁定":
            st.error(f"⚠️ 此实验为二次编辑：当前正在编辑 V{version} 草稿，上一提交版本已由复核员退回。")
            if returned_review:
                st.warning(
                    f"复核员：{returned_review.get('reviewer_name') or returned_review.get('reviewer','')}｜"
                    f"退回时间：{returned_review.get('reviewed_at','')}｜"
                    f"复核意见：{returned_review.get('comment','')}"
                )
            if correction_fields:
                st.markdown("**复核员指定修改字段：**")
                for item in correction_fields:
                    st.write(f"- {item}")
                st.info("系统将自动打开首个指定字段所在步骤；其他指定字段可按前面的步骤编号进入。")
            st.success("上一版本已填写的实验数据、设备信息、照片原件和结论已完整保留在当前草稿中，请按复核意见修改后重新提交。")

        group0=group(t["group_id"]);commission0=commission(t["commission_no"]);package0=package(t["package_no"])
        sample_ids=t["sample_nos_list"]
        template_name=config_snapshot.get("record_template_file","") or EXPERIMENTS.get(t["experiment"],{}).get("template","")
        if not template_name or not (TEMPLATE_DIR/template_name).exists():
            st.error("该实验尚未配置有效的受控原始记录模板，不能提交正式记录。")
            st.stop()
        kind=config_snapshot.get("kind") or EXPERIMENTS.get(t["experiment"],{}).get("kind","generic")
        bound_devices=config_snapshot.get("equipment",[])
        if kind=="cte":
            # 最新线胀系数流程仅保留卡尺、温湿度表和热膨胀仪。
            allowed_cte_equipment={"BPGL-A001","BPGL-A009","BPGL-A020"}
            bound_devices=[
                item for item in bound_devices
                if (item.get("management_no") or item.get("管理编号")) in allowed_cte_equipment
            ]
        production_unit=commission0.get("production_org_name","")
        if commission0.get("production_relation")=="受委托生产企业" and production_unit:
            production_unit += "（受委托生产企业）"
        context={
            "client_name":commission0.get("client_name",""),
            "client_address":commission0.get("client_address",""),
            "production_unit":production_unit,
            "product_no":group0.get("product_no",""),
            "production_date":group0.get("production_date",""),
            "sample_name":group0.get("sample_name",""),
            "model":group0.get("model",""),
            "material":t.get("material_name",""),
            "sample_nos":sample_ids,
            "sample_quantity":len(sample_ids),
            "received_date":commission0.get("commission_date",""),
            "report_no":report_no_for_task(tn),
            "task_no":tn,
            "test_date":str(china_today()),
            "detection_location":t.get("detection_location") or package0.get("detection_location",""),
            "standard":t.get("standard",""),
            "method_code":t.get("method_code",""),
            "operator":user["display_name"],
            "reviewer":display_user(t.get("reviewer","")),
        }
        task_location=t.get("detection_location") or package0.get("detection_location","")
        business=initialize_business_record(kind,sample_ids,task_location,prior.get("business_record") or {})
        business.setdefault("parameters",{})["detection_location"]=task_location
        if kind=="hv":
            business["parameters"]["sample_production_date"]=group0.get("product_no","")
        if kind=="mc_crack":
            business["parameters"]["metal_name"]=group0.get("sample_name","")
            business["parameters"]["metal_batch"]=group0.get("product_no","")
        if kind=="thickness":
            business["parameters"]["sample_production_date"]=group0.get("product_no","")
            business["parameters"]["production_date"]=group0.get("production_date","")
        if t.get("experiment_started_at"):
            business["parameters"]["start_time"]=str(t["experiment_started_at"]).replace("T"," ")
            business["parameters"]["test_date"]=str(t["experiment_started_at"])[:10]
        if t.get("experiment_ended_at"):
            business["parameters"]["end_time"]=str(t["experiment_ended_at"]).replace("T"," ")
        key_prefix=f"simple_{tn}_{version}"
        st.info(f"{t['experiment']}｜{t['method_code']}｜{len(sample_ids)}件样品。已知信息自动带入，正常选项已设置为默认值；实验员只需确认现场状态并填写实际测量数据。")
        if kind=="cte":
            start_at=t.get("experiment_started_at") or ""
            end_at=t.get("experiment_ended_at") or ""
            business["parameters"].pop("start_time",None)
            business["parameters"].pop("end_time",None)
            if start_at:business["parameters"]["test_date"]=str(start_at)[:10]
            st.caption("本实验不显示开始/结束时间操作；系统仍在后台保留任务进入时间等审计记录。")
        else:
            start_at,end_at=render_experiment_timeline(t,username,key_prefix)
            business["parameters"]["start_time"]=str(start_at).replace("T"," ") if start_at else ""
            business["parameters"]["end_time"]=str(end_at).replace("T"," ") if end_at else ""
            if start_at:business["parameters"]["test_date"]=str(start_at)[:10]
        all_checkpoints=photo_checkpoints(t["experiment"])
        checkpoint_groups=[all_checkpoints[index::4] for index in range(4)]
        if kind=="mc_crack":
            checkpoint_groups=[
                [x for x in all_checkpoints if x[0]=="SAMPLE_BEFORE"],
                [x for x in all_checkpoints if x[0]=="SPAN_FIXTURE"],
                [],
                [x for x in all_checkpoints if x[0] in {"K_FACTOR","FASTTEST_RESULT","CRACK"}],
            ]
        elif kind=="thickness":
            checkpoint_groups=[
                [x for x in all_checkpoints if x[0]=="SAMPLE_BEFORE"],
                [],
                [],
                [x for x in all_checkpoints if x[0] in {"MEASURE_RESULT","FINAL_CURVE"}],
            ]
        secondary_edit=bool(version>1 and latest and latest.get("status")!="已锁定")
        step1_labels=returned_step_labels(correction_fields,"①") if secondary_edit else None
        step2_labels=returned_step_labels(correction_fields,"②") if secondary_edit else None
        step3_labels=returned_step_labels(correction_fields,"③") if secondary_edit else None
        step4_labels=returned_step_labels(correction_fields,"④") if secondary_edit else None
        step5_labels=returned_step_labels(correction_fields,"⑤") if secondary_edit else None
        step6_labels=returned_step_labels(correction_fields,"⑥") if secondary_edit else None
        step7_labels=returned_step_labels(correction_fields,"⑦") if secondary_edit else None
        photo_edit_allowed=not secondary_edit or "照片留档" in (step6_labels or set())
        device_file_edit_allowed=not secondary_edit or "设备原始文件" in (step6_labels or set())
        if secondary_edit:
            st.info("二次编辑采用字段级锁定：只有复核员指定退回的字段可修改，其余数据仅供查看。")
        tabs=st.tabs([
            "①任务确认","②设备与实验前检查","③环境与参数","④原始数据",
            "⑤母版过程确认","⑥异常与设备文件","⑦保存提交",
        ])
        if version>1:
            focus_returned_step(correction_fields,f"returned_focus_{tn}_{version}")
        with tabs[0]:
            render_readonly_summary(t,group0,commission0,package0,config_snapshot)
            business["task_confirmations"]=render_task_confirmations(business,key_prefix,not secondary_edit or bool(step1_labels))
            if photo_edit_allowed:render_inline_camera(t,sample_ids,checkpoint_groups[0],username,user["display_name"],key_prefix,"任务确认阶段照片")
            elif secondary_edit:st.caption("照片留档未被退回，本步骤照片已锁定。")
        with tabs[1]:
            business["equipment_checks"]=render_equipment_confirmation(bound_devices,business.get("equipment_checks") or [],key_prefix,not secondary_edit or bool(step2_labels))
            business["prechecks"],business["precheck_note"]=render_prechecks(kind,business,key_prefix,not secondary_edit or bool(step2_labels))
            if photo_edit_allowed:render_inline_camera(t,sample_ids,checkpoint_groups[1],username,user["display_name"],key_prefix,"设备与实验前检查照片")
            elif secondary_edit:st.caption("照片留档未被退回，本步骤照片已锁定。")
        with tabs[2]:
            business["parameters"],business["fixed_parameter_mode"]=render_parameters(kind,business,key_prefix,step3_labels)
            if photo_edit_allowed:render_inline_camera(t,sample_ids,checkpoint_groups[2],username,user["display_name"],key_prefix,"环境与参数照片")
            elif secondary_edit:st.caption("照片留档未被退回，本步骤照片已锁定。")
        with tabs[3]:
            business["rows"]=render_sample_data(kind,business,key_prefix,step4_labels)
            if photo_edit_allowed:render_inline_camera(t,sample_ids,checkpoint_groups[3],username,user["display_name"],key_prefix,"检测数据与结果照片")
            elif secondary_edit:st.caption("照片留档未被退回，本步骤照片已锁定。")
        with tabs[4]:
            business=calculate_business_record(kind,business)
            context["test_date"]=(business.get("parameters") or {}).get("test_date") or context["test_date"]
            attachments=list_attachments(task_no=tn)
            process_template_fields=business_to_template_fields(
                template_name,kind,context,bound_devices,business,attachments,
                prior.get("template_fields") or {},
            )
            process_requirements=template_supplement_requirements(
                template_name,process_template_fields,
            )
            st.subheader("母版过程确认")
            st.caption(
                "这里仅显示前四步尚不能自动取得的现场观察和实际填空。"
                "按原始记录表分区排列，可对明确的正常项一键确认。"
            )
            render_template_supplement(
                process_requirements,
                prior.get("template_supplement") or {},
                f"{key_prefix}_template_supplement",
                step5_labels,
            )
        with tabs[5]:
            business=render_exception_and_summary(kind,business,key_prefix,step6_labels)
            photo_rows=camera_checkpoint_status(tn,all_checkpoints)
            show_df(photo_rows,["checkpoint_label","required","complete","photo_count","captured_at"])
            incomplete=[x for x in photo_rows if x["required"] and not x["complete"]]
            if incomplete:
                st.warning(f"还有 {len(incomplete)} 个强制拍照节点未完成，请回到对应实验步骤拍摄。")
            else:
                st.success("全部强制拍照节点已经完成。")
            st.divider()
            st.subheader("设备原始文件")
            st.caption("这里只允许上传设备导出的原始数据、曲线或校准文件；图片和截图必须通过上面的现场相机取得。")
            attachments=list_attachments(task_no=tn)
            show_df(attachments,["attachment_id","checkpoint_label","capture_source","evidence_status","sample_no","attachment_type","original_name","sha256","server_captured_at","uploader"])
            atype=st.selectbox("原始文件类型",ATTACHMENT_TYPES,key=f"{key_prefix}_atype",disabled=not device_file_edit_allowed)
            sample_no=st.selectbox("文件关联样品编号",[""]+sample_ids,key=f"{key_prefix}_attach_sample",disabled=not device_file_edit_allowed)
            description=st.text_area("原始文件内容说明",key=f"{key_prefix}_attach_desc",disabled=not device_file_edit_allowed)
            files=st.file_uploader(
                "上传设备原始文件",
                type=["csv","xlsx","xls","pdf","txt","dat","xml","json","zip"],
                accept_multiple_files=True,key=f"{key_prefix}_files",
                disabled=not device_file_edit_allowed,
            )
            if files and st.button("保存设备原始文件",key=f"{key_prefix}_save_attach"):
                for f in files:
                    save_attachment({"commission_no":t["commission_no"],"package_no":t["package_no"],"task_no":tn,"sample_no":sample_no,"attachment_type":atype,"original_name":f.name,"captured_at":now(),"description":description,"is_original":True,"capture_source":"device_export"},f.getvalue(),username)
                st.success("附件已保存并计算SHA-256校验值");st.rerun()
            photos_complete=mandatory_camera_complete(tn,all_checkpoints)
        with tabs[6]:
            business=calculate_business_record(kind,business)
            context["test_date"]=(business.get("parameters") or {}).get("test_date") or context["test_date"]
            attachments=list_attachments(task_no=tn)
            template_fields=business_to_template_fields(
                template_name,kind,context,bound_devices,business,attachments,prior.get("template_fields") or {}
            )
            supplement_requirements=template_supplement_requirements(template_name,template_fields)
            template_supplement=dict(st.session_state.get(
                f"{key_prefix}_template_supplement_values",
                prior.get("template_supplement") or {},
            ))
            template_fields.update({
                key:value for key,value in template_supplement.items() if value
            })
            supplement_missing=template_supplement_missing(
                supplement_requirements,template_supplement,
            )
            summary0=business_completion_summary(kind,business,bound_devices)
            validation_key=f"{key_prefix}_validation_ready"
            timeline_complete=bool(end_at) or kind=="cte"
            if not timeline_complete:
                st.info("实验尚未点击“记录实验结束时间”。结束前暂不显示未填写区域；可先保存草稿。")
            elif not st.session_state.get(validation_key,False):
                st.info("请先点击“同步当前记录并检查”。系统会保存当前页面状态并重新核验，避免把刚填写但尚未同步的区域误报为未填写。")
            st.caption("提交后，系统会把七个步骤中的业务数据回填至受控Word母版原位置。")
            tester_self_check=st.checkbox(
                "我已完成实验员自查：样品、设备、环境、原始数据、计算结果、照片和异常记录均已核对",
                value=bool(prior.get("tester_self_check",False)),
                key=f"{key_prefix}_tester_self_check",
                disabled=secondary_edit and "实验员自查确认或修改原因" not in (step7_labels or set()),
            )
            reason=st.text_area("修改原因（首次记录可不填）",latest.get("change_reason","") if latest else "",key=f"{key_prefix}_reason")
            tm_version=config_snapshot.get("record_template_version","") or "A/0"
            sm_version=config_snapshot.get("sop_version","") or "A/0"
            payload={
                "common":{"record_no":tn,"task_no":tn,"commission_no":t["commission_no"],"report_no":report_no_for_task(tn),"client":commission0["client_name"],"sample_name":group0["sample_name"],"sample_no":"、".join(sample_ids),"model":group0["model"],"material":t["material_name"],"method_code":t["method_code"],"standard":t["standard"],"test_date":context["test_date"],"operator":user["display_name"],"reviewer":display_user(t["reviewer"])},
                "business_record":business,
                "template_name":template_name,
                "template_fields":template_fields,
                "equipment_snapshot":bound_devices,
                "deviation":business.get("deviation",""),
                "retest":business.get("retest","否"),
                "report_summary":business.get("report_summary",""),
                "report_conclusion":business.get("report_conclusion",""),
                "configuration_snapshot":config_snapshot,
                "tester_self_check":tester_self_check,
                "template_supplement":template_supplement,
                "photo_attachment_ids":[
                    item["attachment_id"] for item in list_attachments(task_no=tn)
                    if item.get("capture_source")=="live_camera"
                    and item.get("evidence_status")=="有效"
                ],
            }
            if secondary_edit:
                payload=enforce_secondary_edit_scope(
                    payload,prior,correction_fields,kind,supplement_requirements,
                )
            a,b=st.columns(2)
            if a.button("同步当前记录并检查",use_container_width=True,key=f"{key_prefix}_draft"):
                if kind=="cte" and not end_at:
                    mark_task_experiment_time(tn,username,"结束")
                save_record(tn,version,payload,username,"草稿",tm_version,sm_version,reason,compare)
                st.session_state[validation_key]=True
                st.rerun()
            validation_ready=bool(st.session_state.get(validation_key,False))
            final_sections=dict(summary0.get("sections") or {})
            final_sections.update({
                "实验员自查已确认":bool(tester_self_check),
                "强制拍照节点已完成":bool(photos_complete),
                "受控模板补充字段已完成":not supplement_missing,
            })
            if kind!="cte":
                final_sections["实验结束时间已记录"]=bool(end_at)
            final_issues=list(summary0.get("issues") or [])
            if kind!="cte" and not end_at:final_issues.append("尚未记录实验结束时间")
            if not tester_self_check:final_issues.append("尚未勾选实验员自查确认")
            if not photos_complete:
                missing_photo_labels=[
                    x["checkpoint_label"] for x in camera_checkpoint_status(tn,all_checkpoints)
                    if x["required"] and not x["complete"]
                ]
                final_issues.append("强制拍照节点未完成："+("、".join(missing_photo_labels) or "请检查照片留档"))
            if supplement_missing:
                final_issues.append(
                    "受控模板补充字段未完成："+
                    "、".join(supplement_missing[:8])+
                    (f"等共{len(supplement_missing)}项" if len(supplement_missing)>8 else "")
                )
            final_complete=bool(
                summary0["complete"] and timeline_complete and tester_self_check
                and photos_complete and not supplement_missing
            )
            if validation_ready:
                render_completion({
                    "sections":final_sections,"issues":final_issues,"complete":final_complete,
                })
            submit_clicked=b.button(
                "提交复核",type="primary",use_container_width=True,
                disabled=not validation_ready,key=f"{key_prefix}_submit",
            )
            if submit_clicked:
                if not final_complete:
                    st.error("当前不能提交复核，请先完成："+ "；".join(final_issues))
                else:
                    if kind=="cte" and not (task(tn) or {}).get("experiment_ended_at"):
                        mark_task_experiment_time(tn,username,"结束")
                    save_record(tn,version,payload,username,"更正待复核" if version>1 else "待复核",tm_version,sm_version,reason,compare)
                    navigate_to("首页看板","已提交复核，当前实验窗口已关闭")

elif page=="原始记录复核":
    header("按实验流程复核原始记录")
    rs=pending_reviews(None if role=="管理员" else username)
    show_df(rs,["record_no","version","package_no","group_no","experiment","owner","status","updated_at"])
    if rs:
        key=st.selectbox("选择记录",[f"{x['record_no']}|{x['version']}" for x in rs])
        rn,v=key.split("|");r=record(rn,int(v));snap=task_config_snapshot(rn);template_name=snap.get("record_template_file","") or r["payload"].get("template_name","")
        kind=snap.get("kind") or "generic";business=r["payload"].get("business_record") or {};summary0=business_completion_summary(kind,business,snap.get("equipment") or [])
        render_completion(summary0)
        t0=task(rn);g0=group(t0["group_id"]);c0=commission(t0["commission_no"]);p0=package(t0["package_no"])
        render_readonly_summary(t0,g0,c0,p0,snap)
        st.subheader("环境与实验参数");show_df([{"项目":k,"记录值":v0} for k,v0 in (business.get("parameters") or {}).items()],["项目","记录值"])
        st.subheader("原始测量数据");show_df(business.get("rows") or [])
        st.subheader("设备使用确认");show_df(business.get("equipment_checks") or [])
        st.subheader("异常与结果")
        st.write("实验状态：",business.get("overall_status",""));st.write("异常/偏离：",business.get("deviation","无"));st.write("复测/重制：",business.get("retest","否"));st.write("结果摘要：",business.get("report_summary",""));st.write("单项结论：",business.get("report_conclusion",""))
        record_docx=export_record(r,template_name,audit_logs(rn)).getvalue()
        show_controlled_docx_review(
            f"{rn}_V{v}_实验原始记录表",
            record_docx,
        )
        show_report_photo_preview(r["task_no"])
        st.info("原始记录由实验员提交并完成自查，复核员通过后立即锁定并开放正式文件下载。")
        st.subheader("附件索引（独立追溯）");show_df(list_attachments(task_no=rn),["attachment_id","attachment_type","original_name","sha256","description"])
        comment=st.text_area("复核意见")
        correction_options=review_correction_field_options(
            kind,business,template_name,r["payload"].get("template_fields") or {},
        )
        correction_fields=st.multiselect(
            "退回时指定需要修改的字段",
            correction_options,
        )
        a,b=st.columns(2)
        if a.button("复核通过并锁定原始记录",type="primary",disabled=not summary0["complete"]):
            review_record(rn,int(v),username,"通过",comment)
            navigate_to("首页看板","原始记录已通过复核并锁定，报告初稿已提交质量负责人预览")
        if b.button("退回修改"):
            try:
                review_record(rn,int(v),username,"退回",comment,correction_fields)
                navigate_to("首页看板","已按指定字段退回实验员修改，复核窗口已关闭")
            except Exception as e:
                st.error(str(e))

elif page=="样品归还":
    header("全部实验完成后整组样品一次归还")
    packages=return_candidates(username) if role!="管理员" else list_packages(statuses=["待归还"]);show_df(packages,["package_no","commission_no","group_no","experiments","status"])
    if packages:
        pn=st.selectbox("待归还任务包",[x["package_no"] for x in packages]);loans=package_loan_rows(pn);edit=pd.DataFrame([{"样品编号":x["sample_no"],"归还状态":"完好","归还备注":""} for x in loans]);edit=st.data_editor(edit,hide_index=True,use_container_width=True,column_config={"样品编号":st.column_config.TextColumn(disabled=True),"归还状态":st.column_config.SelectboxColumn(options=RETURN_CONDITIONS)})
        if st.button("提交整组归还",type="primary"):
            submit_package_return(pn,username,[{"sample_no":r["样品编号"],"condition":r["归还状态"],"note":r["归还备注"]} for _,r in edit.iterrows()])
            navigate_to("首页看板","整组样品已提交回库确认")

elif page=="回库确认":
    header("样品管理员逐个确认回库位置")
    packages=pending_return_packages();show_df(packages,["package_no","commission_no","group_no","assignee","return_submitted_at"])
    if packages:
        pn=st.selectbox("待回库任务包",[x["package_no"] for x in packages]);loans=[x for x in package_loan_rows(pn) if x["return_status"]=="待回库确认"];edit=pd.DataFrame([{"样品编号":x["sample_no"],"归还状态":x["return_condition"],"回库位置":"A区域"} for x in loans]);edit=st.data_editor(edit,hide_index=True,use_container_width=True,column_config={"样品编号":st.column_config.TextColumn(disabled=True),"归还状态":st.column_config.TextColumn(disabled=True),"回库位置":st.column_config.SelectboxColumn(options=STORAGE_AREAS)})
        if st.button("确认整组回库",type="primary"):
            confirm_package_return(pn,username,[{"sample_no":r["样品编号"],"location":r["回库位置"]} for _,r in edit.iterrows()])
            navigate_to("首页看板","整组样品回库已完成")

elif page=="危废处理":
    header("实验废液及废弃样品分类处置登记")
    my_tasks=rows(
        """SELECT * FROM tasks WHERE assignee=?
           AND status NOT IN ('待接收','历史作废') ORDER BY updated_at DESC""",
        (username,),
    )
    for item in my_tasks:
        item["sample_nos_list"]=json.loads(item.get("sample_nos") or "[]")
    waste_rows=list_hazardous_waste_records(actor=username)
    for item in waste_rows:
        item["关联实验任务"]="、".join(json.loads(item.get("task_nos") or "[]"))
    show_df(waste_rows,["disposal_no","关联实验任务","waste_type","waste_name","quantity","unit","hazard_category","disposal_method","container_no","occurred_at","status"])
    if waste_rows:
        selected_waste=st.selectbox(
            "查看/下载危废处置登记表",
            [x["disposal_no"] for x in waste_rows],
            index=next(
                (i for i,x in enumerate(waste_rows) if x["disposal_no"]==st.session_state.get("latest_waste_no")),
                0,
            ),
        )
        waste_item=next(x for x in waste_rows if x["disposal_no"]==selected_waste)
        show_df([waste_item],["disposal_no","关联实验任务","waste_type","waste_name","quantity","unit","hazard_category","disposal_method","container_no","handler","occurred_at","status","note"])
        st.download_button(
            "下载危废处置登记表",
            hazardous_waste_document(waste_item),
            f"{selected_waste}_危废处置登记表.docx",
            use_container_width=True,
        )
    if my_tasks:
        with st.form("hazardous_waste_form",clear_on_submit=True):
            task_nos=st.multiselect(
                "关联产生该危废的实验任务（可多选）",
                [x["task_no"] for x in my_tasks],
                format_func=lambda number:next(
                    f"{x['task_no']}｜{x['experiment']}" for x in my_tasks if x["task_no"]==number
                ),
            )
            a,b,c=st.columns(3)
            waste_type=a.selectbox("废物类型",["实验废液","废弃样品","沾染耗材","其他危废"])
            waste_name=b.text_input("废物名称（必填）")
            hazard=c.text_input("危废类别/特性")
            quantity=a.number_input("数量（必填）",min_value=0.0,step=0.1)
            unit=b.selectbox("单位",["mL","L","g","kg","件"])
            container=c.text_input("收集容器编号")
            method=st.selectbox("分类处置方式（必填）",["危废暂存柜","专用废液桶","灭菌后移交","委托有资质单位处置","其他"])
            note=st.text_area("处置说明")
            if st.form_submit_button("完成危废登记",type="primary"):
                try:
                    number=create_hazardous_waste_record({
                        "task_nos":task_nos,"waste_type":waste_type,
                        "waste_name":waste_name,"hazard_category":hazard,"quantity":quantity,
                        "unit":unit,"container_no":container,"disposal_method":method,
                        "occurred_at":now(),"note":note,
                    },username)
                    st.session_state.flash_message=f"危废处置 {number} 已登记"
                    st.session_state.latest_waste_no=number
                    st.rerun()
                except Exception as e:st.error(str(e))

elif page=="附件与内部追溯":
    header("实验照片、设备原始文件和任务归档")
    cs=list_commissions();cn=st.selectbox("按委托筛选",[""]+[x["commission_no"] for x in cs])
    attachments=list_attachments(commission_no=cn or None)
    visible=attachments
    show_df(visible,["attachment_id","commission_no","package_no","task_no","sample_no","attachment_type","original_name","relative_path","sha256","captured_at","uploader","description"])
    st.caption("附件与原始记录通过委托编号、任务编号和样品编号关联；详细索引统一进入内部实验数据追溯Excel。")
    task_numbers=list(dict.fromkeys(x["task_no"] for x in visible if x.get("task_no")))
    if task_numbers:
        archive_task=st.selectbox("按实验任务生成归档包",task_numbers)
        st.download_button(
            "下载实验任务完整归档包",
            task_archive(archive_task),
            f"{archive_task}_实验任务归档.zip",
            "application/zip",
            type="primary",
        )
        st.caption(f"压缩包内照片自动归入“{archive_task}/照片”，照片名严格采用“{archive_task}_HHMMSS.jpg”。")
    if visible:
        fieldnames=list(visible[0].keys())
        buf=io.StringIO();writer=csv.DictWriter(buf,fieldnames=fieldnames);writer.writeheader();writer.writerows(visible)
        st.download_button("下载当前附件索引CSV",buf.getvalue().encode("utf-8-sig"),"附件索引.csv","text/csv")
        aid=st.selectbox("预览/下载附件",[x["attachment_id"] for x in attachments]);meta=next(x for x in attachments if x["attachment_id"]==aid);path=attachment_file(meta)
        if path.exists():
            if path.suffix.lower() in [".png",".jpg",".jpeg",".webp"]:st.image(str(path),caption=meta["description"] or meta["original_name"])
            st.download_button("下载原始附件",path.read_bytes(),meta["original_name"])

elif page=="一键下载":
    header("一键下载实验任务完整归档")
    st.info("这里始终显示在左侧导航中，不需要先进入附件页面。原始记录复核通过后自动加入归档；正式报告经授权签字人签发后自动加入归档。")
    query="SELECT * FROM tasks WHERE 1=1"
    args=[]
    if role=="实验员":
        query+=" AND assignee=?";args.append(username)
    elif role=="复核员":
        query+=" AND reviewer=?";args.append(username)
    elif role=="质量负责人":
        query+=" AND quality_inspector=?";args.append(username)
    task_rows=rows(query+" ORDER BY updated_at DESC",args)
    show_df(task_rows,["task_no","commission_no","experiment","status","assignee","reviewer","quality_inspector","updated_at"])
    if task_rows:
        selected_task=st.selectbox(
            "选择实验任务",[x["task_no"] for x in task_rows],
            format_func=lambda number:next(
                f"{x['task_no']}｜{x['experiment']}｜{x['status']}" for x in task_rows if x["task_no"]==number
            ),
        )
        st.download_button(
            "一键下载完整归档包",
            task_archive(selected_task),
            f"{selected_task}_实验任务完整归档.zip",
            "application/zip",type="primary",use_container_width=True,
        )
        st.caption("归档包包括：现场照片、设备原始文件、修改日志、内部追溯工作簿，以及当前审批状态允许下载的原始记录和正式报告。")

elif page=="Word单据预览":
    header("Word单据在线预览")
    st.info("侧边栏预览直接读取系统实际生成的DOCX，与单据中心下载文件使用同一份数据和模板；本页不提供下载。")
    preview_kind=st.radio(
        "预览单据类型",["实验原始记录表","检验报告","其他业务单据"],
        horizontal=True,key="word_preview_kind",
    )
    if preview_kind=="实验原始记录表":
        record_rows=rows(
            """SELECT r.record_no,r.version,r.experiment,r.owner,r.status,r.updated_at,
                      t.assignee,t.reviewer,t.commission_no
               FROM records r JOIN tasks t ON t.task_no=r.task_no
               ORDER BY r.updated_at DESC,r.record_no,r.version DESC"""
        )
        if role=="实验员":
            record_rows=[item for item in record_rows if item.get("owner")==username or item.get("assignee")==username]
        elif role=="复核员":
            record_rows=[item for item in record_rows if item.get("reviewer")==username]
        show_df(record_rows,["record_no","version","experiment","status","owner","updated_at"])
        if record_rows:
            record_key=st.selectbox(
                "选择记录与版本",
                [f"{item['record_no']}|{item['version']}" for item in record_rows],
                format_func=lambda value:next(
                    f"{item['record_no']}｜V{int(item['version'])}.0｜{item['experiment']}｜{item['status']}"
                    for item in record_rows
                    if value==f"{item['record_no']}|{item['version']}"
                ),
                key="word_preview_record_key",
            )
            record_no,record_version=record_key.split("|")
            selected_record=record(record_no,int(record_version))
            snapshot=task_config_snapshot(record_no)
            selected_record["kind"]=snapshot.get("kind") or "generic"
            record_content=export_record(
                selected_record,
                snapshot.get("record_template_file",""),
                audit_logs(record_no),
            ).getvalue()
            show_controlled_docx_review(
                f"{record_no}_V{int(record_version)}.0_原始记录表",
                record_content,
                allow_download=False,
            )
    elif preview_kind=="检验报告":
        report_rows=(
            rows("SELECT * FROM reports ORDER BY updated_at DESC,report_no")
            if role in ("管理员","样品管理员")
            else list_reports(role,username)
        )
        show_df(report_rows,["report_no","commission_no","task_no","status","validity_status","updated_at"])
        if report_rows:
            selected_report_no=st.selectbox(
                "选择检验报告",[item["report_no"] for item in report_rows],
                key="word_preview_report_no",
            )
            selected_report=report(selected_report_no)
            selected_commission=commission(selected_report["commission_no"])
            selected_groups=commission_groups(selected_report["commission_no"])
            selected_samples=commission_samples(selected_report["commission_no"])
            selected_task=task(selected_report["task_no"])
            selected_task["kind"]=task_config_snapshot(selected_task["task_no"]).get("kind") or "generic"
            selected_group=next((item for item in selected_groups if item["id"]==selected_task["group_id"]),{})
            selected_task["sample_name"]=selected_group.get("sample_name","")
            preview_users=user_map()
            report_content=report_document(
                selected_commission,selected_groups,selected_samples,[selected_task],
                report_records_for_report(selected_report_no),selected_report,
                preview_users,{name:signature(name) for name in preview_users},
            ).getvalue()
            show_controlled_docx_review(
                f"{selected_report_no}_检验报告",
                report_content,
                allow_download=False,
            )
    else:
        commissions_for_preview=list_commissions()
        if not commissions_for_preview:
            st.info("暂无可预览业务单据。")
        else:
            preview_commission_no=st.selectbox(
                "选择委托",[item["commission_no"] for item in commissions_for_preview],
                key="word_preview_business_commission",
            )
            preview_commission=commission(preview_commission_no)
            preview_groups=commission_groups(preview_commission_no)
            preview_samples=commission_samples(preview_commission_no)
            preview_tests=commission_tests(preview_commission_no)
            preview_user_names=user_map()
            business_types=["检验委托单","样品登记表","样品领用归还登记表"]
            delivery_rows=rows(
                """SELECT d.* FROM report_deliveries d JOIN reports r ON r.report_no=d.report_no
                   WHERE r.commission_no=? ORDER BY d.delivered_at""",
                (preview_commission_no,),
            )
            waste_rows=rows(
                "SELECT * FROM hazardous_waste_records WHERE commission_no=? ORDER BY occurred_at",
                (preview_commission_no,),
            )
            objection_rows=rows(
                "SELECT * FROM objections WHERE commission_no=? ORDER BY created_at",
                (preview_commission_no,),
            )
            if delivery_rows:business_types.append("报告发放登记表")
            if waste_rows:business_types.append("危废处置登记表")
            if objection_rows:business_types.extend(["客户异议申请表","客户异议回复单"])
            business_type=st.selectbox(
                "选择业务单据",business_types,key="word_preview_business_type",
            )
            receiver_name=display_user(preview_commission.get("created_by",""))
            if business_type=="检验委托单":
                title=f"{preview_commission_no}_检验委托单"
                content=commission_document(
                    preview_commission,preview_groups,preview_tests,receiver_name,
                ).getvalue()
            elif business_type=="样品登记表":
                title=f"{preview_commission_no}_样品登记表"
                content=sample_register_document(
                    preview_commission,preview_groups,preview_samples,preview_tests,receiver_name,
                ).getvalue()
            elif business_type=="样品领用归还登记表":
                title=f"{preview_commission_no}_样品领用归还登记表"
                content=loan_return_document(
                    commission_loans(preview_commission_no),preview_user_names,
                ).getvalue()
            elif business_type=="报告发放登记表":
                report_numbers=list(dict.fromkeys(item["report_no"] for item in delivery_rows))
                business_report=st.selectbox(
                    "选择报告编号",report_numbers,key="word_preview_delivery_report",
                )
                title=f"{business_report}-D_报告发放登记表"
                content=report_delivery_document(
                    business_report,[x for x in delivery_rows if x["report_no"]==business_report],
                ).getvalue()
            elif business_type=="危废处置登记表":
                waste_no=st.selectbox(
                    "选择处置单",[item["disposal_no"] for item in waste_rows],
                    key="word_preview_waste_no",
                )
                waste_item=next(item for item in waste_rows if item["disposal_no"]==waste_no)
                title=f"{waste_no}_危废处置登记表"
                content=hazardous_waste_document(waste_item).getvalue()
            else:
                objection_no=st.selectbox(
                    "选择异议单",[item["objection_no"] for item in objection_rows],
                    key="word_preview_objection_no",
                )
                objection_item=objection(objection_no)
                objection_report=report(objection_item["report_no"]) or {}
                if business_type=="客户异议申请表":
                    title=f"{objection_no}_异议申请表"
                    content=objection_application_document(
                        objection_item,objection_report,preview_commission,
                    ).getvalue()
                else:
                    title=f"{objection_no}-R_异议回复单"
                    content=objection_response_document(
                        objection_item,objection_report,preview_commission,
                    ).getvalue()
            show_controlled_docx_review(title,content,allow_download=False)

elif page=="单据中心":
    header("检验委托单、样品登记、领用归还、原始记录和检验报告")
    if role=="管理员":
        st.info("临时演示工具：待复核Demo用于检查复核流程；完整Demo可直接查看十项原始记录、报告照片、发放登记和异议追溯Excel。")
        demo_a,demo_b=st.columns(2)
        if demo_a.button("生成待复核实验Demo",type="primary",key="create_pending_review_demo_documents",use_container_width=True):
            try:
                demo=create_pending_review_demo()
                st.session_state["document_commission_no"]=demo["commission_no"]
                st.toast("待复核演示任务已生成")
                st.rerun()
            except Exception as error:
                st.error("生成演示数据失败："+str(error))
        if demo_b.button("生成完整单据与照片Demo",key="create_full_document_demo_documents",use_container_width=True):
            try:
                demo_commission=create_full_document_demo()
                st.session_state["document_commission_no"]=demo_commission
                st.toast("完整单据演示已生成")
                st.rerun()
            except Exception as error:
                st.error("生成完整演示数据失败："+str(error))
    cs=list_commissions();show_df(cs,["commission_no","client_name","commission_date","due_date","status"])
    if cs:
        commission_options=[x["commission_no"] for x in cs]
        if st.session_state.get("document_commission_no") not in commission_options:
            st.session_state["document_commission_no"]=commission_options[0]
        cn=st.selectbox("选择委托",commission_options,key="document_commission_no");c0=commission(cn);groups=commission_groups(cn);samples0=commission_samples(cn);tests=commission_tests(cn);users0=user_map();st.download_button("下载检验委托单",commission_document(c0,groups,tests,display_user(c0["created_by"])),f"{cn}_检验委托单.docx");st.download_button("下载样品登记表",sample_register_document(c0,groups,samples0,tests,display_user(c0["created_by"])),f"{cn}_样品登记表.docx");st.download_button("下载样品领用归还登记表",loan_return_document(commission_loans(cn),users0),f"{cn}_样品领用归还登记表.docx")
        st.download_button("下载内部实验数据追溯Excel",build_internal_trace_workbook(cn),f"{cn}_内部实验数据追溯工作簿.xlsx",mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        st.subheader("危废处置登记表")
        waste_documents=rows(
            "SELECT * FROM hazardous_waste_records WHERE commission_no=? ORDER BY occurred_at DESC",
            (cn,),
        )
        show_df(waste_documents,["disposal_no","task_nos","waste_type","waste_name","quantity","unit","disposal_method","handler","occurred_at","status"])
        if waste_documents:
            waste_no=st.selectbox("选择危废处置登记表",[x["disposal_no"] for x in waste_documents],key="document_waste_no")
            waste_item=next(x for x in waste_documents if x["disposal_no"]==waste_no)
            st.download_button(
                "下载选定危废处置登记表",
                hazardous_waste_document(waste_item),
                f"{waste_no}_危废处置登记表.docx",
            )
        st.subheader("报告发放登记表")
        commission_deliveries=rows(
            """SELECT d.* FROM report_deliveries d JOIN reports r ON r.report_no=d.report_no
               WHERE r.commission_no=? ORDER BY d.delivered_at DESC""",
            (cn,),
        )
        show_df(commission_deliveries,["report_no","client_name","delivery_method","recipient","recipient_contact","delivered_at","receipt_status","receipt_note","operator"])
        if commission_deliveries:
            delivery_report_no=st.selectbox(
                "选择报告发放登记表",
                list(dict.fromkeys(x["report_no"] for x in commission_deliveries)),
                key="document_delivery_report",
            )
            selected_deliveries=[x for x in commission_deliveries if x["report_no"]==delivery_report_no]
            st.download_button(
                "下载选定报告发放登记表",
                report_delivery_document(delivery_report_no,selected_deliveries),
                f"{delivery_report_no}-D_报告发放登记表.docx",
            )
        record_history=[]
        for task_row in commission_tasks(cn):
            record_history.extend(record_versions(task_row["task_no"]))
        if record_history:
            st.subheader("实验原始记录历史版本")
            st.caption("退回版本、二次编辑草稿和最终锁定版本分别保留。版本之间不会互相覆盖。")
            show_df(record_history,["record_no","version","experiment","owner","status","change_reason","created_at","updated_at"])
            key=st.selectbox(
                "选择原始记录版本",
                [f"{r['record_no']}|{r['version']}" for r in record_history],
                format_func=lambda value:next(
                    f"{item['record_no']}｜V{int(item['version'])}.0｜{item['status']}｜{item.get('experiment','')}"
                    for item in record_history
                    if value==f"{item['record_no']}|{item['version']}"
                ),
            )
            rn,v=key.split("|");r=record(rn,int(v));t=task(rn);snap=task_config_snapshot(rn)
            r["kind"]=snap.get("kind") or "generic";template_name=snap.get("record_template_file","")
            changes=audit_logs(rn)
            record_docx=export_record(r,template_name,changes).getvalue()
            st.download_button(
                f"下载 V{int(v)}.0 原始记录表DOCX",record_docx,
                f"{rn}_V{int(v)}.0_原始记录表.docx",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            )
        report_rows=rows("SELECT * FROM reports WHERE commission_no=? ORDER BY report_no",(cn,))
        if report_rows:
            selected_report=st.selectbox("选择检验报告",[x["report_no"] for x in report_rows])
            rp=report(selected_report);task_row=task(rp["task_no"])
            task_row["kind"]=task_config_snapshot(task_row["task_no"]).get("kind") or "generic"
            task_row["sample_name"]=next(g["sample_name"] for g in groups if g["id"]==task_row["group_id"])
            sigs={u:signature(u) for u in users0}
            if rp["status"]=="已发布" and rp.get("validity_status")=="有效":
                report_docx=report_document(
                    c0,groups,samples0,[task_row],
                    report_records_for_report(selected_report),rp,users0,sigs,
                ).getvalue()
                st.download_button(
                    "下载授权签字人已签发的检验报告DOCX",report_docx,
                    f"{selected_report}_检验报告.docx",
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                )
            else:
                st.info("该报告尚未完成质量负责人预览确认和管理员（授权签字人）签发，仅可在线预览，不能下载。")

elif page=="报告中心":
    header("报告审核：质量负责人预览确认 → 管理员（授权签字人）签发")
    rs=list_reports(role,username)
    pending_quality=[
        item for item in rs
        if item.get("status")=="待质量审核" and item.get("quality_inspector")==username
    ]
    if role=="质量负责人":
        m1,m2,m3=st.columns(3)
        m1.metric("待审核报告",len(pending_quality))
        m2.metric("全部负责报告",len(rs))
        m3.metric("已完成确认",len([item for item in rs if item.get("status") in ("待管理员签发","已发布")]))
        if pending_quality:
            st.success("下方“质量负责人报告审核入口”已有待办，请选择报告后完成预览确认或退回整改。")
        else:
            st.info("当前没有待质量审核报告。原始记录经复核员通过后，报告会自动进入这里。")
    show_df(rs,["report_no","commission_no","task_no","status","validity_status","tester","verifier","quality_inspector","approver","updated_at"])
    if rs:
        ordered_reports=pending_quality+[item for item in rs if item not in pending_quality]
        rn=st.selectbox(
            "质量负责人报告审核入口" if role=="质量负责人" else "选择报告",
            [x["report_no"] for x in ordered_reports],
            format_func=lambda value:next(
                f"{item['report_no']}｜{item['status']}｜任务 {item.get('task_no','')}"
                for item in ordered_reports if item["report_no"]==value
            ),
        )
        r=report(rn);st.info("当前状态："+r["status"])
        task0=task(r["task_no"])
        commission0=commission(r["commission_no"])
        report_groups=commission_groups(r["commission_no"])
        report_samples=commission_samples(r["commission_no"])
        task_preview=dict(task0)
        task_preview["kind"]=task_config_snapshot(r["task_no"]).get("kind") or "generic"
        task_preview["sample_name"]=next(
            (item["sample_name"] for item in report_groups if item["id"]==task_preview["group_id"]),""
        )
        preview_users=user_map()
        preview_signatures={name:signature(name) for name in preview_users}
        report_docx=report_document(
            commission0,report_groups,report_samples,[task_preview],
            report_records_for_report(rn),r,preview_users,preview_signatures,
        ).getvalue()
        st.caption("以下预览与实验员、复核员查看原始记录时使用同一受控 Word 阅读器；内容直接来自实际检验报告母版。审批期间只允许预览。")
        show_controlled_docx_review(
            f"{rn}_检验报告",
            report_docx,
            allow_download=False,
        )
        if r["status"]=="待质量审核" and role=="质量负责人" and username==r["quality_inspector"]:
            st.info("质量负责人仅对报告进行预览确认，不形成电子签字。")
            comment=st.text_area("质量预览确认意见");a,b=st.columns(2)
            if a.button("预览确认通过",type="primary"):
                quality_review_report(rn,username,"通过",comment)
                navigate_to("首页看板","报告已提交管理员最终签发")
            if b.button("退回整改"):
                quality_review_report(rn,username,"退回",comment)
                navigate_to("首页看板","报告已退回整改")
        if r["status"]=="待管理员签发" and role=="管理员":
            comment=st.text_area("最终审核意见");a,b=st.columns(2)
            if a.button("最终审核并签发",type="primary"):
                approver_review_report(rn,username,"批准",comment)
                navigate_to("首页看板","授权签字人已签发，正式报告现已生成并开放下载")
            if b.button("退回质量审核"):approver_review_report(rn,username,"退回",comment);st.rerun()
        if r["status"]=="已发布" and role=="管理员":
            st.divider();st.subheader("管理员启动报告作废/更正")
            action=st.radio("处理方式",["更正并重新签发","直接作废"],horizontal=True,key=f"report_change_{rn}")
            reason=st.text_area("作废/更正原因（必填）",key=f"report_change_reason_{rn}")
            if st.button("确认启动报告处理流程",type="primary"):
                try:
                    start_report_void_or_correction(rn,username,action,reason)
                    navigate_to("首页看板",f"报告 {rn} 已启动：{action}")
                except Exception as e:st.error(str(e))
        show_df(report_actions(rn))

elif page=="报告发放登记":
    header("检验报告发放登记表")
    published=rows("SELECT * FROM reports WHERE status='已发布' ORDER BY publish_date DESC")
    delivery_rows=report_deliveries()
    show_df(delivery_rows,["id","report_no","client_name","delivery_method","recipient","recipient_contact","delivered_at","receipt_status","receipt_note","operator"])
    if delivery_rows:
        delivery_report=st.selectbox(
            "下载某份报告的发放登记表",
            list(dict.fromkeys(x["report_no"] for x in delivery_rows)),
            key="delivery_download_report",
        )
        selected_deliveries=[x for x in delivery_rows if x["report_no"]==delivery_report]
        st.download_button(
            "下载报告发放登记表",
            report_delivery_document(delivery_report,selected_deliveries),
            f"{delivery_report}-D_报告发放登记表.docx",
            use_container_width=True,
        )
    if published and role in ("样品管理员","管理员"):
        st.subheader("新增发放记录")
        report_no=st.selectbox("已签发报告",[x["report_no"] for x in published])
        report_row=report(report_no);commission_row=commission(report_row["commission_no"])
        a,b,c=st.columns(3)
        method=a.selectbox("发放方式",["电子邮件","自取","快递"])
        recipient=b.text_input("领取/接收人（取自委托单）",value=commission_row.get("contact",""),disabled=True)
        contact=c.text_input("联系方式（取自委托单）",value=commission_row.get("phone",""),disabled=True)
        delivered_at=a.text_input("发放时间（服务器时间）",value=now(),disabled=True)
        receipt=b.selectbox("签收状态",["已签收","已发送待确认","无需签收"])
        note=st.text_area("发放及签收备注")
        if st.button("确认发放并写入登记表",type="primary"):
            add_report_delivery({
                "report_no":report_no,"client_name":commission_row["client_name"],
                "delivery_method":method,"recipient":commission_row.get("contact",""),
                "recipient_contact":commission_row.get("phone",""),
                "delivered_at":now(),"receipt_status":receipt,"receipt_note":note,
            },username)
            st.session_state.flash_message=f"报告 {report_no} 发放记录已登记，可立即下载发放登记表"
            st.rerun()
    if role=="管理员":
        st.divider()
        st.subheader("管理员：已发放报告作废/更正")
        st.error("此处只处理已经完成发放登记的正式报告。作废后原报告立即停止使用，操作不可撤销且永久写入修改日志。")
        issued=rows(
            """SELECT DISTINCT r.* FROM reports r
               JOIN report_deliveries d ON d.report_no=r.report_no
               WHERE r.status='已发布'
               ORDER BY r.publish_date DESC,r.report_no DESC"""
        )
        if issued:
            change_report_no=st.selectbox(
                "选择已发放报告",[x["report_no"] for x in issued],
                key="delivered_report_change_no",
            )
            selected_delivery_rows=[x for x in delivery_rows if x["report_no"]==change_report_no]
            show_df(selected_delivery_rows,["report_no","client_name","delivery_method","recipient","delivered_at","receipt_status","receipt_note"])
            display_action=st.radio(
                "处理方式",["直接作废并停止使用","启动更正并重新签发"],
                horizontal=True,key="delivered_report_change_action",
            )
            original_handling=st.selectbox(
                "原报告处理结果",
                ["待联系客户处理","已收回纸质原报告","电子报告已撤回/替换","无法收回，已书面通知客户"],
                key="delivered_report_original_handling",
            )
            change_reason=st.text_area("作废/更正原因（必填）",key="delivered_report_change_reason")
            confirm_report_no=st.text_input(
                f"请输入报告编号 {change_report_no} 确认操作",
                key="delivered_report_change_confirm",
            )
            button_label="确认作废报告" if display_action.startswith("直接作废") else "确认启动更正流程"
            if st.button(button_label,type="primary",use_container_width=True):
                if confirm_report_no.strip()!=change_report_no:
                    st.error("确认报告编号不一致，未执行操作")
                else:
                    try:
                        action="直接作废" if display_action.startswith("直接作废") else "更正并重新签发"
                        full_reason=f"{change_reason.strip()}；原报告处理：{original_handling}"
                        start_report_void_or_correction(change_report_no,username,action,full_reason)
                        st.session_state.flash_message=f"报告 {change_report_no} 已执行：{action}"
                        st.rerun()
                    except Exception as e:st.error(str(e))
        else:
            st.info("当前没有可作废或更正的已发放正式报告。")

elif page=="客户异议":
    header("客户异议：登记、质量调查、重测与回复")
    objection_rows=objections_for_user(role,username)
    show_df(objection_rows,["objection_no","report_no","client_name","status","pathway","quality_inspector","customer_retest_decision","updated_at"])
    if role=="管理员":
        st.subheader("管理员异议申请测试Demo")
        st.caption("生成一套已有正式报告的完整演示委托，并自动带入下方异议申请。不会自动登记异议，便于反复测试人工录入。")
        if st.button("准备已签发报告异议Demo",type="primary",use_container_width=True):
            try:
                demo=create_objection_application_demo()
                st.session_state.objection_demo_report_no=demo["report_no"]
                st.session_state.flash_message=f"异议Demo已准备：{demo['report_no']}，请切换样品管理员录入异议申请"
                st.rerun()
            except Exception as e:st.error(str(e))
    if role=="样品管理员":
        published=rows("SELECT * FROM reports WHERE status='已发布' ORDER BY publish_date DESC")
        with st.expander("登记新的客户异议",expanded=not objection_rows):
            if published:
                report_options=[x["report_no"] for x in published]
                preferred=st.session_state.get("objection_demo_report_no")
                default_index=report_options.index(preferred) if preferred in report_options else 0
                report_no=st.selectbox("关联已签发报告",report_options,index=default_index,key="obj_report")
                report_row=report(report_no);commission_row=commission(report_row["commission_no"])
                task_rows=commission_tasks(report_row["commission_no"])
                commissioned_tests=commission_tests(report_row["commission_no"])
                group_rows=commission_groups(report_row["commission_no"])
                all_samples=[]
                for group_row in group_rows:all_samples.extend(group_samples(group_row["id"]))
                st.info(f"委托：{report_row['commission_no']}｜客户：{commission_row.get('client_name','')}｜报告状态：{report_row.get('status','')}")
                a,b,c=st.columns(3)
                submitted_at=a.date_input("客户提出日期",value=china_today())
                channel=b.selectbox("受理渠道",["书面申请","电子邮件","电话后补书面","现场提交","其他"])
                contact=c.text_input("客户联系人",commission_row.get("contact",""))
                commissioned_experiments=list(dict.fromkeys(x["experiment"] for x in commissioned_tests))
                disputed_items=st.multiselect(
                    "争议检测项目（仅限该委托已选择项目）",
                    commissioned_experiments,
                    help="不能录入该委托范围之外的实验项目。",
                )
                involved_samples=st.multiselect("涉及样品", [x["sample_no"] for x in all_samples])
                description=st.text_area("客户书面异议内容")
                evidence=st.text_area("随附材料和证据说明")
                if st.button("登记异议、生成申请表并冻结证据",type="primary"):
                    try:
                        objection_no=register_objection({
                            "report_no":report_no,"client_name":commission_row["client_name"],
                            "contact":contact,"description":description,"evidence_note":evidence,
                            "submitted_at":str(submitted_at),"application_channel":channel,
                            "disputed_items":"、".join(disputed_items),
                            "involved_samples":"、".join(involved_samples),
                        },username)
                        st.session_state.selected_objection_no=objection_no
                        st.session_state.flash_message=f"异议 {objection_no} 已登记并分配质量调查"
                        st.rerun()
                    except Exception as e:st.error(str(e))
            else:st.warning("当前没有已签发报告，无法登记异议。")
    if objection_rows:
        options=[x["objection_no"] for x in objection_rows]
        preferred=st.session_state.get("selected_objection_no")
        objection_no=st.selectbox("选择异议",options,index=options.index(preferred) if preferred in options else 0)
        obj=objection(objection_no)
        report_row=report(obj["report_no"]) or {}
        commission_row=commission(obj["commission_no"]) or {}
        st.download_button("下载客户异议申请表",objection_application_document(obj,report_row,commission_row),f"{objection_no}_客户异议申请表.docx",use_container_width=True)
        show_df(objection_actions(objection_no),["created_at","actor","action","comment"])
        if role=="质量负责人" and obj["status"]=="调查中" and obj["quality_inspector"]==username:
            st.subheader("质量调查工作台")
            st.download_button("下载异议调查追溯Excel",build_internal_trace_workbook(obj["commission_no"]),f"{objection_no}_异议调查追溯表.xlsx",use_container_width=True)
            related={obj["commission_no"],obj["report_no"],objection_no}
            related.update(x["task_no"] for x in commission_tasks(obj["commission_no"]))
            related_logs=[x for x in modification_logs() if x.get("entity_id") in related]
            st.download_button("下载相关修改日志PDF",modification_log_pdf(related_logs,scope=f"异议 {objection_no}"),f"{objection_no}_修改日志.pdf",use_container_width=True)
            st.markdown("#### ① 选择调查范围")
            disputed_names={
                x.strip() for x in str(obj.get("disputed_items") or "").split("、") if x.strip()
            }
            candidate_tasks=[
                x for x in commission_tasks(obj["commission_no"])
                if not disputed_names or x.get("experiment") in disputed_names
            ]
            selected_task_nos=st.multiselect(
                "本次调查涉及的实验任务",
                [x["task_no"] for x in candidate_tasks],
                default=[x["task_no"] for x in candidate_tasks],
                format_func=lambda task_no:next(
                    f"{x['task_no']}｜{x['experiment']}" for x in candidate_tasks if x["task_no"]==task_no
                ),
            )
            photo_options,record_options,other_options=quality_evidence_choices(
                obj["commission_no"],selected_task_nos,
            )
            st.markdown("#### ② 勾选调查证据")
            photo_evidence=st.multiselect(
                "照片证据编号",
                photo_options,
                help="选项同时显示照片编号、实验任务、样品、拍摄节点和服务器时间。",
            )
            record_evidence=st.multiselect(
                "原始记录字段",
                record_options,
                help="只显示受控原始记录里的中文字段和值，不显示程序字段。",
            )
            other_evidence=st.multiselect(
                "其他追溯资料",
                other_options,
                default=["检验委托单及客户信息","检测方法及SOP受控版本","修改记录日志PDF","检验报告及审批记录"],
            )
            st.markdown("#### ③ 核查结果")
            check_options=["符合要求","存在问题","未涉及","需要补充资料"]
            a,b=st.columns(2)
            method_check=a.selectbox("检测方法/SOP核查",check_options,key="quality_method_check")
            equipment_check=b.selectbox("设备、校准与软件数据核查",check_options,key="quality_equipment_check")
            environment_check=a.selectbox("环境与温湿度核查",check_options,key="quality_environment_check")
            operation_check=b.selectbox("人员操作与过程符合性核查",check_options,key="quality_operation_check")
            calculation_check=st.selectbox("数据计算、转录、复核与报告核查",check_options,key="quality_calculation_check")
            impact_options=st.multiselect(
                "影响范围",
                ["仅涉及本样品","涉及同批次样品","涉及本实验任务","涉及同方法其他报告","需要扩大调查"],
            )
            impact_note=st.text_input("影响范围补充说明")
            st.markdown("#### ④ 备注、结论与处理建议")
            investigation=st.text_area("调查备注")
            conclusion=st.text_area("调查结论与证据链")
            suggestion=st.text_area(
                "处理建议",
                help="例如：联系客户确认重测、维持原报告、作废替换、扩大调查等。",
            )
            pathway=st.radio(
                "责任判定（提交后自动转交样品管理员）",
                ["是我方问题","样品问题"],horizontal=True,
            )
            if st.button("提交调查结论",type="primary"):
                if not selected_task_nos:
                    st.error("至少选择一个调查实验任务")
                elif not (photo_evidence or record_evidence or other_evidence):
                    st.error("至少选择一项调查证据")
                else:
                    evidence_text=(
                        "照片证据：\n"+"\n".join(photo_evidence or ["未选"])+"\n"
                        "原始记录字段：\n"+"\n".join(record_evidence or ["未选"])+"\n"
                        "其他追溯资料：\n"+"\n".join(other_evidence or ["未选"])
                    )
                    try:
                        quality_submit_objection(objection_no,username,pathway,investigation,conclusion,{
                            "quality_evidence":evidence_text,"quality_method_check":method_check,
                            "quality_equipment_check":equipment_check,"quality_environment_check":environment_check,
                            "quality_operation_check":operation_check,"quality_calculation_check":calculation_check,
                            "impact_scope":"、".join(impact_options)+("；"+impact_note if impact_note else ""),
                            "treatment_suggestion":suggestion,
                        });st.rerun()
                    except Exception as e:st.error(str(e))
        if role=="样品管理员" and obj["status"]=="待客户确认重测":
            st.warning("质量调查判定为实验室问题。请在系统外询问客户，并在此记录处理结果。")
            a,b=st.columns(2)
            contact_at=a.text_input("联系时间",value=now())
            contact_method=b.selectbox("联系方式",["电话","微信","电子邮件","现场","其他"])
            decision=st.radio("客户是否需要重测",["需要重测","不需要重测"],horizontal=True)
            note=st.text_area("客户意见、留样/重新送样说明")
            if st.button("记录客户决定",type="primary"):
                try:record_customer_retest_decision(objection_no,username,decision,note,contact_at,contact_method);st.rerun()
                except Exception as e:st.error(str(e))
        if role=="样品管理员" and obj["status"]=="待安排重测":
            st.info("从原委托样品库选择可用留样，按编号规则生成新的重测实验任务。")
            original_task=task(report_row.get("task_no","")) if report_row else None
            available=group_samples(original_task["group_id"]) if original_task else []
            available=[x for x in available if x.get("status") not in ("全部消耗，记录归档","已销毁","已报废")]
            sample_nos=st.multiselect("选择重测样品",[x["sample_no"] for x in available],default=[x["sample_no"] for x in available])
            testers=role_users("实验员")
            assignee=st.selectbox("重测实验员",[x["username"] for x in testers],format_func=display_user,key="obj_retest_tester")
            if st.button("使用留样下发重测任务",type="primary"):
                try:
                    new_task=dispatch_retained_sample_retest(objection_no,assignee,username,sample_nos)
                    st.session_state.flash_message="已下发重测任务："+new_task;st.rerun()
                except Exception as e:st.error(str(e))
        if role=="样品管理员" and obj["status"]=="重测任务已下发":
            retest=task(obj.get("retest_task_no",""))
            st.info(f"重测任务 {obj.get('retest_task_no','')} 当前状态：{retest.get('status','') if retest else '等待任务'}。重测报告签发后将自动进入异议回复。")
        if role=="样品管理员" and obj["status"]=="待异议回复":
            default_response=(
                f"关于异议{objection_no}，经调取委托、样品、原始记录、设备、环境、审核及报告记录，"
                f"调查结论为：{obj.get('trace_conclusion','')}。处理结果："
                f"{'已按客户意见安排重测。' if obj.get('customer_retest_decision')=='需要重测' else '原报告结论有效。'}"
            )
            response=st.text_area("异议回复正文",default_response)
            response_method=st.selectbox("计划回复方式",["电子邮件","现场领取","快递","微信","其他"])
            if st.button("生成异议回复单",type="primary"):
                try:sample_manager_prepare_objection_response(objection_no,username,response,response_method);st.rerun()
                except Exception as e:st.error(str(e))
        if role=="样品管理员" and obj["status"]=="待发送":
            st.download_button("下载客户异议回复单",objection_response_document(obj,report_row,commission_row),f"{objection_no}-R_客户异议回复单.docx",use_container_width=True)
            response_method=st.selectbox("实际回复方式",["电子邮件","现场领取","快递","微信","其他"],key="obj_send_method")
            send_note=st.text_area("客户接收凭证、时间和备注")
            if st.button("发送回复并归档",type="primary"):
                try:send_and_archive_objection(objection_no,username,send_note,response_method);st.rerun()
                except Exception as e:st.error(str(e))
        if role=="样品管理员" and obj["status"]=="已归档":
            st.success("异议已回复并归档。")
            st.download_button("下载已归档客户异议回复单",objection_response_document(obj,report_row,commission_row),f"{objection_no}-R_客户异议回复单.docx",use_container_width=True)

elif page=="修改中心":
    header("⚠️ 原始记录修改中心")
    st.error("所有修改必须填写原因；系统保留修改前后字段、操作者、时间和完整历史版本。最终报告签发后，旧单据仅作为历史作废版本留痕。")
    all_records=rows("SELECT * FROM records ORDER BY updated_at DESC");show_df(all_records,["record_no","version","experiment","owner","status","change_reason","updated_at"])
    if all_records:
        rn=st.selectbox("记录编号",list(dict.fromkeys(x["record_no"] for x in all_records)))
        show_df(record_versions(rn),["record_no","version","owner","status","change_reason","created_at","updated_at"])
        show_df(document_versions("record",rn),["version","status","snapshot_hash","created_by","created_at","obsolete_by","obsolete_at","obsolete_reason"])
        if role=="实验员":
            reason=st.text_area("创建修改版原因")
            if st.button("创建新修改版",type="primary"):
                try:create_revision(rn,username,reason);st.success("已创建草稿版本，请回到实验记录修改");st.rerun()
                except Exception as e:st.error(str(e))

elif page=="修改日志":
    header("独立修改记录日志")
    st.info("本页只显示修改、作废、更正和照片替代，不混入查看、下载或普通审批。后台仍保留完整哈希审计链。")
    all_changes=modification_logs()
    entity_options=["全部单据"]+list(dict.fromkeys(x["entity_id"] for x in all_changes if x.get("entity_id")))
    selected_entity=st.selectbox("查看范围",entity_options)
    logs=all_changes if selected_entity=="全部单据" else modification_logs(selected_entity)
    show_df(logs,["id","entity_type","entity_id","field_label","action","old_value","new_value","reason","actor_name","actor_role","created_at"])
    st.download_button(
        "下载修改记录日志 PDF",
        modification_log_pdf(logs,selected_entity),
        f"{'全部单据' if selected_entity=='全部单据' else selected_entity}_修改记录日志.pdf",
        mime="application/pdf",
        type="primary",
        use_container_width=True,
    )

elif page=="SOP与模板版本":
    header("SOP和实验原始记录表受控版本")
    if role!="管理员":st.stop()
    show_df(all_template_versions(),["experiment","doc_type","version","effective_date","status","uploader","uploaded_at","note"])
    methods=list_experiment_methods(True)
    if not methods:st.info("请先建立检测项目");st.stop()
    exp=st.selectbox("实验项目",[x["experiment_name"] for x in methods])
    typ=st.selectbox("文件类型",["SOP","原始记录表"])
    ver=st.text_input("版本号","A/1")
    effective=st.date_input("生效日期",china_today())
    note=st.text_input("变更说明")
    f=st.file_uploader("上传DOCX",type=["docx"])
    if f and st.button("批准并启用文件版本",type="primary"):
        name=f"TPL_{hashlib.sha1((exp+typ+ver+f.name).encode()).hexdigest()[:12]}.docx"
        (TEMPLATE_DIR/name).write_bytes(f.getvalue())
        add_template(exp,typ,name,ver,str(effective),username,note)
        st.success("文件版本已启用。实验配置是否采用该版本，应在“实验配置版本”中确定。")
        st.rerun()

elif page=="实验配置版本":
    header("实验、方法、SOP、记录模板、地点和设备的动态版本配置")
    if role!="管理员":st.stop()
    methods=list_experiment_methods(True)
    method_map={x["experiment_code"]:x for x in methods}
    show_df(current_config_overview(),["experiment_name","method_code","config_version","kind","default_location","equipment_count","status","enabled"])
    if not methods:st.info("请先在检测项目与方法库中新建实验");st.stop()
    selected_code=st.selectbox("选择实验",[x["experiment_code"] for x in methods],format_func=lambda x:f"{method_map[x]['experiment_name']}｜{method_map[x]['method_code']}")
    configs=list_experiment_configs(selected_code)
    tabs=st.tabs(["①版本历史","②新建配置草稿","③编辑草稿信息","④配置设备关系","⑤批准发布"])
    with tabs[0]:
        show_df(configs,["version","experiment_name","method_code","standard","kind","default_location","sop_version","record_template_version","status","effective_date","created_by","approved_by","approved_at","note"])
        current=current_experiment_config(selected_code)
        if current:
            st.subheader(f"现行配置 {current['version']} 的设备关系")
            show_df(config_equipment(current["id"],True),["management_no","equipment_name","model","binding_role","required","lifecycle_status","calibration_time","sort_order","note"])
    with tabs[1]:
        version=st.text_input("新配置版本号","V1.1")
        copy_current=st.checkbox("复制现行配置及其设备关系",value=True)
        if st.button("建立配置草稿",type="primary"):
            try:
                cid=create_experiment_config_version(selected_code,version,username,copy_current)
                st.success(f"已建立草稿，配置ID：{cid}")
                st.rerun()
            except Exception as e:st.error(str(e))
    drafts=[x for x in configs if x["status"]=="草稿"]
    with tabs[2]:
        if not drafts:st.info("暂无草稿，请先新建配置草稿")
        else:
            cid=st.selectbox("选择草稿",[x["id"] for x in drafts],format_func=lambda x:next(f"{c['version']}｜{c['experiment_name']}" for c in drafts if c["id"]==x),key="edit_config")
            cfg=experiment_config(cid)
            sop_versions=[x for x in all_template_versions() if x["experiment"]==cfg["experiment_name"] and x["doc_type"]=="SOP"]
            record_versions0=[x for x in all_template_versions() if x["experiment"]==cfg["experiment_name"] and x["doc_type"]=="原始记录表"]
            with st.form("edit_config_form"):
                a,b,c=st.columns(3)
                exp_name=a.text_input("实验名称",cfg["experiment_name"])
                method=b.text_input("检测方法",cfg["method_code"])
                standard=c.text_input("检测依据/版本",cfg.get("standard","") or "")
                category=a.text_input("实验类别",cfg.get("category","") or "")
                kinds=list(SCHEMAS.keys());kind=b.selectbox("记录数据模板",kinds,index=kinds.index(cfg.get("kind") or "generic") if (cfg.get("kind") or "generic") in kinds else kinds.index("generic"))
                location=c.selectbox("推荐检测地点",[""]+DETECTION_LOCATIONS,index=([""]+DETECTION_LOCATIONS).index(cfg.get("default_location","") or "") if (cfg.get("default_location","") or "") in ([""]+DETECTION_LOCATIONS) else 0)
                sop_options=[""]+list(dict.fromkeys(x["version"] for x in sop_versions));sop=a.selectbox("SOP版本",sop_options,index=sop_options.index(cfg.get("sop_version","") or "") if (cfg.get("sop_version","") or "") in sop_options else 0)
                rec_options=[""]+list(dict.fromkeys(x["version"] for x in record_versions0));rec=b.selectbox("原始记录模板版本",rec_options,index=rec_options.index(cfg.get("record_template_version","") or "") if (cfg.get("record_template_version","") or "") in rec_options else 0)
                software=c.text_input("软件名称/版本",cfg.get("software","") or "")
                effective=a.date_input("计划生效日期",pd.to_datetime(cfg.get("effective_date") or china_today()).date())
                note=st.text_area("配置变更说明",cfg.get("note","") or "")
                if st.form_submit_button("保存配置草稿",type="primary"):
                    try:
                        save_experiment_config(cid,{"experiment_name":exp_name,"method_code":method,"standard":standard,"category":category,"kind":kind,"default_location":location,"sop_version":sop,"record_template_version":rec,"software":software,"effective_date":str(effective),"note":note},username)
                        st.rerun()
                    except Exception as e:st.error(str(e))
    with tabs[3]:
        if not drafts:st.info("暂无可编辑草稿")
        else:
            cid=st.selectbox("选择草稿配置",[x["id"] for x in drafts],format_func=lambda x:next(f"{c['version']}｜{c['experiment_name']}" for c in drafts if c["id"]==x),key="bind_config")
            current_items=config_equipment(cid,True)
            show_df(current_items,["management_no","equipment_name","model","binding_role","required","lifecycle_status","calibration_time","sort_order","note"])
            devices=list_equipment(True)
            dmap={x["management_no"]:x for x in devices}
            device_no=st.selectbox("选择设备/标准器/夹具",[x["management_no"] for x in devices],format_func=lambda x:f"{x}｜{dmap[x]['equipment_name']}｜{dmap[x].get('lifecycle_status','')}")
            existing=next((x for x in current_items if x["management_no"]==device_no),{})
            a,b,c=st.columns(3)
            roles=EQUIPMENT_BINDING_ROLES
            bind_role=a.selectbox("配置角色",roles,index=roles.index(existing.get("binding_role")) if existing.get("binding_role") in roles else 0)
            required=b.checkbox("必需设备",value=bool(existing.get("required",0)))
            order=c.number_input("排序",min_value=0,value=int(existing.get("sort_order",100) or 100))
            note=st.text_area("用途/绑定说明",existing.get("note","") or "")
            x,y=st.columns(2)
            if x.button("保存配置设备关系",type="primary",use_container_width=True):
                try:bind_config_equipment(cid,device_no,bind_role,required,order,note,username);st.rerun()
                except Exception as e:st.error(str(e))
            if y.button("从该草稿解除设备",use_container_width=True):
                try:unbind_config_equipment(cid,device_no,username);st.rerun()
                except Exception as e:st.error(str(e))
    with tabs[4]:
        if not drafts:st.info("暂无可发布草稿")
        else:
            cid=st.selectbox("选择待发布草稿",[x["id"] for x in drafts],format_func=lambda x:next(f"{c['version']}｜{c['experiment_name']}" for c in drafts if c["id"]==x),key="publish_config")
            cfg=experiment_config(cid);show_df([cfg]);show_df(config_equipment(cid,True),["management_no","equipment_name","binding_role","required","lifecycle_status","calibration_time","note"])
            reason=st.text_area("批准/变更原因")
            st.warning("发布后，新建任务将使用该版本；已经创建的任务继续使用原任务快照，不受影响。")
            if st.button("批准并发布为现行配置",type="primary"):
                try:publish_experiment_config(cid,username,reason);st.success("配置已发布");st.rerun()
                except Exception as e:st.error(str(e))

elif page=="设备库":
    header("DLBP-CX-P05-R10设备台账动态管理")
    if role!="管理员":st.stop()
    devices=list_equipment(True);dmap={x["management_no"]:x for x in devices}
    a,b,c,d=st.columns(4)
    a.metric("设备总数",len(devices));b.metric("启用",sum(1 for x in devices if x.get("lifecycle_status")=="启用"));c.metric("维修/停用",sum(1 for x in devices if x.get("lifecycle_status") in ["维修","停用"]));d.metric("报废",sum(1 for x in devices if x.get("lifecycle_status")=="报废"))
    tabs=st.tabs(["①设备台账","②维护已有设备","③新增设备","④使用关系与审计"])
    with tabs[0]:
        show_df(devices,["seq","equipment_name","model","measuring_range","manufacturer","serial_no","management_no","purchase_time","calibration_time","responsible","equipment_class","lifecycle_status","status_note","enabled"])
        master_df=pd.DataFrame(devices)
        st.download_button("下载当前设备台账CSV",master_df.to_csv(index=False).encode("utf-8-sig"),"equipment_master_current.csv","text/csv")
        binding_rows=[]
        for cfg in [x for x in list_experiment_configs() if x["status"]=="现行"]:
            for item in config_equipment(cfg["id"],True):
                binding_rows.append({"实验名称":cfg["experiment_name"],"配置版本":cfg["version"],"默认地点":cfg.get("default_location","") or "","管理编号":item["management_no"],"设备名称":item["equipment_name"],"角色":item["binding_role"],"是否必需":"是" if item["required"] else "否","设备状态":item.get("lifecycle_status","") or "","说明":item.get("note","") or ""})
        st.download_button("下载现行实验配置设备矩阵CSV",pd.DataFrame(binding_rows).to_csv(index=False).encode("utf-8-sig"),"current_experiment_equipment_matrix.csv","text/csv")
    with tabs[1]:
        selected=st.selectbox("选择设备",[x["management_no"] for x in devices],format_func=lambda x:f"{x}｜{dmap[x]['equipment_name']}")
        item=equipment_item(selected) or {}
        with st.form("equipment_edit"):
            a,b,c=st.columns(3)
            seq=a.number_input("序号",min_value=1,value=int(item.get("seq",1) or 1));name=b.text_input("名称",item.get("equipment_name","") or "");model=c.text_input("规格型号",item.get("model","") or "")
            rng=a.text_area("测量范围",item.get("measuring_range","") or "");manufacturer=b.text_input("生产厂家",item.get("manufacturer","") or "");serial=c.text_input("出厂编号",item.get("serial_no","") or "")
            management=a.text_input("管理编号",item.get("management_no","") or "",disabled=True);purchase=b.text_input("购置时间",item.get("purchase_time","") or "");calibration=c.text_input("校准时间",item.get("calibration_time","") or "")
            responsible=a.text_input("责任人",item.get("responsible","") or "");cls=b.selectbox("分类",["A类","B类","C类"],index=["A类","B类","C类"].index(item.get("equipment_class","A类")) if item.get("equipment_class") in ["A类","B类","C类"] else 0);status=c.selectbox("设备状态",EQUIPMENT_LIFECYCLE_STATUSES,index=EQUIPMENT_LIFECYCLE_STATUSES.index(item.get("lifecycle_status","启用")) if item.get("lifecycle_status") in EQUIPMENT_LIFECYCLE_STATUSES else 0)
            status_note=st.text_input("状态说明",item.get("status_note","") or "");notes=st.text_area("备注",item.get("notes","") or "")
            if st.form_submit_button("保存设备资料",type="primary"):
                save_equipment({"seq":seq,"equipment_name":name,"model":model,"measuring_range":rng,"manufacturer":manufacturer,"serial_no":serial,"management_no":management,"purchase_time":purchase,"calibration_time":calibration,"responsible":responsible,"equipment_class":cls,"lifecycle_status":status,"status_note":status_note,"enabled":status=="启用","notes":notes},username);st.rerun()
    with tabs[2]:
        with st.form("equipment_add"):
            a,b,c=st.columns(3)
            management=a.text_input("管理编号");name=b.text_input("名称");seq=c.number_input("序号",min_value=1,value=max([int(x.get("seq",0) or 0) for x in devices]+[0])+1)
            model=a.text_input("规格型号");rng=b.text_area("测量范围");manufacturer=c.text_input("生产厂家")
            serial=a.text_input("出厂编号");purchase=b.text_input("购置时间");calibration=c.text_input("校准时间")
            responsible=a.text_input("责任人");cls=b.selectbox("分类",["A类","B类","C类"]);status=c.selectbox("设备状态",EQUIPMENT_LIFECYCLE_STATUSES)
            status_note=st.text_input("状态说明");notes=st.text_area("备注")
            if st.form_submit_button("新增设备",type="primary"):
                try:save_equipment({"seq":seq,"equipment_name":name,"model":model,"measuring_range":rng,"manufacturer":manufacturer,"serial_no":serial,"management_no":management,"purchase_time":purchase,"calibration_time":calibration,"responsible":responsible,"equipment_class":cls,"lifecycle_status":status,"status_note":status_note,"enabled":status=="启用","notes":notes},username);st.rerun()
                except Exception as e:st.error(str(e))
    with tabs[3]:
        st.info("设备变化不会回写历史任务。历史任务保存的是创建任务时的设备、校准状态和配置版本快照。")
        show_df(audit_logs(),["entity_type","entity_id","action","old_value","new_value","reason","actor","created_at"])

elif page=="电子签名":
    header("电子签名库")
    if role!="管理员":st.stop()
    users0=list_users();u=st.selectbox("人员",[x["username"] for x in users0],format_func=display_user);f=st.file_uploader("上传PDF、PNG或JPG签名",type=["pdf","png","jpg","jpeg"])
    if f and st.button("保存签名",type="primary"):
        ext=Path(f.name).suffix.lower();source=SIG_DIR/f"{u}_source{ext}";source.write_bytes(f.getvalue());image=None
        if ext==".pdf":
            try:
                import fitz;doc=fitz.open(source);pix=doc[0].get_pixmap(matrix=fitz.Matrix(2,2),alpha=True);image=SIG_DIR/f"{u}_signature.png";pix.save(image)
            except Exception as e:st.error("PDF转换失败："+str(e));st.stop()
        else:image=SIG_DIR/f"{u}_signature{ext}";image.write_bytes(f.getvalue())
        save_signature(u,source.name,image.name if image else None,username);st.success("签名已保存")
    show_df([{**x,"签名状态":"已配置" if signature(x["username"]) else "未配置"} for x in users0],["username","display_name","role","签名状态"])

elif page=="用户与权限":
    header("用户与角色权限")
    if role!="管理员":st.stop()
    users_for_admin=list_users()
    show_df(users_for_admin)
    create_tab,password_tab=st.tabs(["创建用户","重置用户密码"])
    with create_tab:
        a,b=st.columns(2);u=a.text_input("用户名");name=b.text_input("姓名");pwd=a.text_input("初始密码",type="password");r=b.selectbox("角色",ROLES)
        if st.button("创建用户",type="primary"):
            try:add_user(u,name,pwd,r);st.rerun()
            except Exception as e:st.error(str(e))
    with password_tab:
        st.warning("密码重置成功后，该用户现有登录会话立即失效，需要使用新密码重新登录。")
        target_user=st.selectbox(
            "选择用户",
            [item["username"] for item in users_for_admin],
            format_func=lambda value:next(
                f"{item['display_name']}｜{item['role']}｜{item['username']}"
                for item in users_for_admin if item["username"]==value
            ),
        )
        new_password=st.text_input("新密码（至少10位，包含英文字母和数字）",type="password")
        confirm_password=st.text_input("再次输入新密码",type="password")
        if st.button("确认重置密码",type="primary"):
            if new_password!=confirm_password:
                st.error("两次输入的密码不一致")
            else:
                try:
                    reset_user_password(target_user,new_password,username)
                    st.success(f"{target_user} 的密码已重置，请通知该用户重新登录。")
                except Exception as e:
                    st.error(str(e))

elif page=="审计追踪":
    header("不可无痕修改的审计记录")
    if role!="管理员":st.stop()
    show_df(audit_logs(),["entity_type","entity_id","actor","action","field_name","old_value","new_value","reason","created_at"])

elif page=="系统初始化":
    header("管理员系统初始化")
    if role!="管理员":st.stop()
    st.error("此操作会永久清空委托、样品流转、实验、照片、报告、异议和历史日志，执行后不能撤销。")
    st.success("保留内容：用户与权限、五角色电子签名、单位信息库、样品基础库、检测方法、设备台账、实验配置、SOP和受控模板。")
    history_counts={
        "委托":one("SELECT COUNT(*) n FROM commissions")["n"],
        "实验任务":one("SELECT COUNT(*) n FROM tasks")["n"],
        "原始记录版本":one("SELECT COUNT(*) n FROM records")["n"],
        "检验报告":one("SELECT COUNT(*) n FROM reports")["n"],
        "照片/附件":one("SELECT COUNT(*) n FROM attachments")["n"],
        "客户异议":one("SELECT COUNT(*) n FROM objections")["n"],
    }
    cols=st.columns(3)
    for index,(label,value) in enumerate(history_counts.items()):
        cols[index%3].metric(label,int(value or 0))
    backup=io.BytesIO()
    with zipfile.ZipFile(backup,"w",zipfile.ZIP_DEFLATED) as archive:
        if DB_PATH.exists():
            archive.writestr("data/bplab_trace_v56.db",DB_PATH.read_bytes())
        if ATTACHMENT_DIR.exists():
            for path in ATTACHMENT_DIR.rglob("*"):
                if path.is_file():
                    archive.writestr(
                        "data/attachments/"+str(path.relative_to(ATTACHMENT_DIR)),
                        path.read_bytes(),
                    )
    st.download_button(
        "初始化前下载数据库与附件备份",
        backup.getvalue(),
        f"BPLab_初始化前备份_{china_now().strftime('%Y%m%d_%H%M%S')}.zip",
        "application/zip",
        use_container_width=True,
    )
    st.divider()
    confirm_check=st.checkbox("我确认已经完成必要备份，并理解该操作不可撤销")
    confirm_text=st.text_input(
        "请输入确认文字：清空全部业务历史",
        placeholder="清空全部业务历史",
    )
    if st.button(
        "执行初始化并清空历史记录",
        type="primary",
        use_container_width=True,
        disabled=not confirm_check or confirm_text.strip()!="清空全部业务历史",
    ):
        try:
            deleted=reset_business_history(username)
            st.session_state.flash_message=(
                "系统初始化完成：业务历史已清空，基础库、配置、模板和电子签名已保留。"
            )
            st.rerun()
        except Exception as error:
            st.error(str(error))
