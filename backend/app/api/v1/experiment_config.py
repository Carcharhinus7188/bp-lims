"""实验配置版本管理 API

保持实验过程可定制 — DB驱动的配置系统:
  1. 硬编码默认值 (experiment_schemas.py) — 安全网
  2. 数据库驱动配置 (experiment_config_versions + 6个配置子表) — 运行时权威来源
  3. 任务级快照 (task_config_snapshots) — 审计追溯
"""
from __future__ import annotations

import hashlib
import json
import os
import sys
from typing import Annotated, Any

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.deps import get_current_user, get_db, require_role

# ── 硬编码 schema 回退 ──
from app.core.experiment_schemas import SCHEMAS
from app.core.calc_formulas import rules_for_kind, rules_by_column
from app.core.field_synonyms import match_field_key, normalize_label

router = APIRouter(prefix="/config", tags=["实验配置"])


# ── 配置列表与详情 ──

@router.get("/methods")
async def list_experiment_methods(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """列出所有检测项目（含当前配置版本信息）"""
    result = await db.execute(
        text("""
            SELECT em.experiment_code, em.experiment_name, em.method_code, em.standard,
                   em.category, em.kind, em.enabled,
                   (SELECT ecv.version FROM experiment_config_versions ecv
                    WHERE ecv.experiment_code = em.experiment_code AND ecv.status = '现行'
                    LIMIT 1) AS current_version,
                   (SELECT count(*) FROM experiment_standards es
                    WHERE es.experiment_code = em.experiment_code AND es.enabled = TRUE) AS standard_count
            FROM experiment_methods em
            WHERE em.enabled = TRUE
            ORDER BY em.sort_order, em.experiment_code
        """)
    )
    methods = [
        {
            "experiment_code": r[0], "experiment_name": r[1], "method_code": r[2],
            "standard": r[3], "category": r[4], "kind": r[5], "enabled": r[6],
            "current_version": r[7], "standard_count": r[8],
        }
        for r in result.fetchall()
    ]

    # 标准变体（父标准 + 已启用变体）——供样品库「检验依据」下拉选择
    std_result = await db.execute(
        text("SELECT experiment_code, standard FROM experiment_standards "
             "WHERE enabled=TRUE ORDER BY sort_order, id")
    )
    variants: dict[str, list[str]] = {}
    for ec, std in std_result.fetchall():
        variants.setdefault(ec, []).append(std)

    for m in methods:
        standards: list[str] = []
        if m["standard"]:
            standards.append(m["standard"])
        standards.extend(variants.get(m["experiment_code"], []))
        m["standards"] = standards

    return methods


def _normalize_db_fields(db_fields: list[dict]) -> list[dict]:
    """将 DB 列名映射为前端期望的简写格式"""
    out = []
    for f in db_fields:
        out.append({
            "key": f.get("field_key", ""),
            "label": f.get("field_label", ""),
            "type": f.get("field_type", "text"),
            "default": _parse_default(f.get("field_default")),
            "options": _parse_options(f.get("field_options")),
            "readonly": bool(f.get("is_readonly")),
            "required": bool(f.get("is_required")),
            "actual": bool(f.get("is_actual")),
            "section_title": f.get("section_title", ""),
            "section_order": f.get("section_order", 0),
        })
    return out


def _parse_calc_expression(raw) -> Any | None:
    """把 calc_expression（TEXT 存 JSON）解析为对象；空 / 非法 JSON 返回 None。"""
    if raw is None or raw == "":
        return None
    if isinstance(raw, (dict, list)):
        return raw
    s = str(raw).strip()
    try:
        return json.loads(s)
    except (json.JSONDecodeError, TypeError):
        return None


def _normalize_db_columns(db_cols: list[dict]) -> list[dict]:
    out = []
    for c in db_cols:
        col_type = c.get("column_type", "number")
        col_default_raw = c.get("column_default", "")
        col_default_parsed = _parse_default(col_default_raw)

        # Reconstruct select:opts format so the frontend getColumnOptions()
        # can extract choices — the seed script stores options in column_default
        # and strips them from column_type.
        if col_type == "select" and col_default_raw:
            if "|" in col_default_raw:
                col_type = f"select:{col_default_raw}"
                # The actual default for a select column is the first option.
                options = col_default_raw.split("|")
                col_default_parsed = options[0] if options else ""
            else:
                # 单一选项 select（如「委托要求」）
                col_type = f"select:{col_default_raw}"
                col_default_parsed = col_default_raw

        out.append({
            "column_key": c.get("column_key", ""),
            "column_label": c.get("column_label", ""),
            "column_type": col_type,
            "column_default": col_default_parsed,
            "calc_expression": _parse_calc_expression(c.get("calc_expression")),
            "calc_precision": c.get("calc_precision", 3),
        })
    return out


def _normalize_db_photos(db_photos: list[dict]) -> list[dict]:
    return [{
        "code": p.get("checkpoint_code", ""),
        "label": p.get("checkpoint_label", ""),
        "required": p.get("is_required", True) if isinstance(p.get("is_required"), bool) else (p.get("is_required") != False),
        "is_sample_level": bool(p.get("is_sample_level", False)),
        "checkpoint_group": p.get("checkpoint_group") or "",
    } for p in db_photos]


def _normalize_db_prechecks(db_prechecks: list[dict]) -> list[dict]:
    return [{
        "label": p.get("precheck_label", p.get("check_name", "")),
    } for p in db_prechecks]


def _parse_default(val):
    """将字符串默认值转为合适的 Python 类型"""
    if val is None or val == "":
        return ""
    if isinstance(val, (int, float)):
        return val
    s = str(val).strip()
    # 数字
    try:
        if "." in s:
            return float(s)
        return int(s)
    except ValueError:
        pass
    # JSON array
    if s.startswith("[") and s.endswith("]"):
        try:
            return json.loads(s)
        except (json.JSONDecodeError, TypeError):
            pass
    return s


def _parse_options(val):
    """将 DB 中存储的 options 字符串转为列表"""
    if val is None or val == "":
        return []
    if isinstance(val, list):
        return val
    s = str(val).strip()
    if s.startswith("[") and s.endswith("]"):
        try:
            return json.loads(s)
        except (json.JSONDecodeError, TypeError):
            pass
    # 分号或逗号分隔
    if ";" in s:
        return [x.strip() for x in s.split(";")]
    if "," in s:
        return [x.strip() for x in s.split(",")]
    return [s]


# ═══════════════════════════════════════════════════════════════
# 硬编码拍照节点（对齐 streamlit-legacy constants.py V9.4.2）
# ═══════════════════════════════════════════════════════════════

# CMA要求：温湿度、设备铭牌、状态照等为"证明做了实验"类照片，不强制；
# 只有图像直接参与数值计算或SOP明确规定时才强制留存。
# 因此 COMMON photos 全部 required=False。

# ── SAMPLE_LEVEL_PHOTO_CODES ──
# 只有这些节点确实描述单件样品状态，才允许关联实体样品。
# 温湿度表、设备铭牌、软件参数、夹具和结果界面均按整个实验任务留档一次。
_SAMPLE_LEVEL_PHOTO_CODES: set[str] = {
    "SAMPLE_BEFORE", "SAMPLE_AFTER", "DAMAGE",
    "BEND_REPORT",
    "MC_K_VALUE", "MC_REPORT",
    "MEASURE_RESULT", "FINAL_CURVE", "OBSERVER_RESULT",
    "H1_BASELINE", "H2_BASELINE", "ROI",
    "HV_REPORT_1", "HV_REPORT_2",
    "ROUGH_POINT_1", "ROUGH_POINT_2", "ROUGH_POINT_3",
    "CTE_PARAMETERS",
    "COLOR_BEFORE", "COLOR_AFTER",
    "SHOCK_BEFORE", "SHOCK_AFTER",
    "FIXED_DIST_1", "FIXED_DIST_2", "FIXED_DIST_3",
    "MID_DIST_1", "MID_DIST_2", "MID_DIST_3",
    "FREE_END_1", "FREE_END_2", "FREE_END_3",
    "THICK_REPORT",
}

# ── CAMERA_HINTS ──
# 拍摄提示词：指导实验员如何正确拍摄每个节点。
# 未列出节点使用 checkpoint_label 作为默认说明。
_CAMERA_HINTS: dict[str, str] = {
    # ── 通用节点 ──
    "ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数",
    "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读",
    "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰",
    "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见",
    "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触",
    "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览",
    "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写",
    "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告",

    # ── 翘曲变形试验 ──
    "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。",
    "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。",
    "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。",
    "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。",
    "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。",

    # ── 表面粗糙度试验 ──
    "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。",
    "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。",
    "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。",
    "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。",

    # ── 维氏硬度试验 ──
    "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。",
    "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。",
    "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。",

    # ── 金属-陶瓷结合裂纹萌生试验 ──
    "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。",
    "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。",

    # ── 弯曲性能试验 ──
    "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。",

    # ── 热膨胀系数试验 ──
    "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。",
    "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。",

    # ── 陶瓷牙耐急冷急热试验 ──
    "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。",
    "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。",

    # ── 增材制造金属试样厚度测量 ──
    "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。",
    "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。",
    "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。",
    "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。",
    "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。",
    "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。",
    "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。",
    "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。",
    "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。",
    "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。",

    # ── 牙科材料色稳定性试验（抗灰暗）──
    "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。",
    "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。",

    # ── 保留的旧版提示（兼容 X射线／急冷急热 等实验）──
    "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放",
    "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面",
    "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺",
    "ROI": "拍摄ROI框选位置及对应的灰度读数列表",
    "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）",
    "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）",
    "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数",
    "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度",
    "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）",
    "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度",
    "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）",
    "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）",
    "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注",
    "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面",
    "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示",
    "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）",
    "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰",
    "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置",
    "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕",
    "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果",
    "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值",
    "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面",
    "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）",
    "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）",
    "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间",
    "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间",
    "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较",
    "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表",

    # ── 激光选区熔化金属材料密度试验 ──
    "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。",
    "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。",

    # ── 金属材料抗晦暗性能试验 ──
    "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。",
    "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。",
    "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。",
    "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。",
}

# ── COMMON_PHOTO_CHECKPOINTS ──
# CMA不强制"证明做了实验"类照片 → required=False
_COMMON_PHOTO_CHECKPOINTS = [
    {"code": "ENV", "label": "实验开始温湿度表", "required": False, "is_sample_level": False, "checkpoint_group": "环境与设备"},
    {"code": "SAMPLE_BEFORE", "label": "实验前样品及标签", "required": False, "is_sample_level": True, "checkpoint_group": "样品状态"},
    {"code": "DEVICE", "label": "设备编号/铭牌", "required": False, "is_sample_level": False, "checkpoint_group": "环境与设备"},
    {"code": "PARAMETERS", "label": "设备参数或软件数据界面", "required": False, "is_sample_level": False, "checkpoint_group": "环境与设备"},
    {"code": "SETUP", "label": "样品安装、装夹或放置状态", "required": False, "is_sample_level": True, "checkpoint_group": "样品状态"},
    {"code": "RESULT", "label": "最终读数、曲线或结果界面", "required": False, "is_sample_level": False, "checkpoint_group": "结果界面"},
    {"code": "SAMPLE_AFTER", "label": "实验结束后样品状态", "required": False, "is_sample_level": True, "checkpoint_group": "样品状态"},
    {"code": "REPORT_PHOTO", "label": "检验报告照片区域用代表性照片", "required": False, "is_sample_level": False, "checkpoint_group": "报告归档"},
]

# kind → 实验中文名映射
_KIND_TO_NAME = {
    "rough": "表面粗糙度试验",
    "mc_crack": "金属-陶瓷结合裂纹萌生试验",
    "xray": "金属内部质量X射线灰度分析",
    "warp": "翘曲变形试验",
    "cte": "热膨胀系数试验",
    "shock": "陶瓷牙耐急冷急热试验",
    "bend": "弯曲性能试验",
    "hv": "维氏硬度试验",
    "thickness": "增材制造金属试样厚度测量",
    "color": "牙科材料色稳定性试验",
    "fixed_denture": "定制式固定义齿检验",
    "removable_denture": "定制式活动义齿检验",
    "density": "激光选区熔化金属材料密度试验",
    "tarnish": "金属材料抗晦暗性能试验",
}

# ── 原始记录模板文件名映射 (kind → DOCX filename) ──
_TEMPLATE_FILE_MAP: dict[str, str] = {
    "rough": "R001_表面粗糙度试验_CMA原始记录表.docx",
    "mc_crack": "R004_金属-陶瓷结合裂纹萌生试验_CMA原始记录表.docx",
    "xray": "R005_金属内部质量X射线灰度分析_CMA原始记录表.docx",
    "warp": "R006_翘曲变形试验_CMA原始记录表.docx",
    "cte": "R007_热膨胀系数试验_CMA原始记录表.docx",
    "shock": "R009_陶瓷牙耐急冷急热试验_CMA原始记录表.docx",
    "bend": "R010_弯曲性能试验_CMA原始记录表.docx",
    "hv": "R011_维氏硬度试验_CMA原始记录表.docx",
    "color": "R012_牙科材料色稳定性试验_CMA原始记录表.docx",
    "thickness": "R013_增材制造金属试样厚度测量_CMA原始记录表.docx",
    "fixed_denture": "R014_定制式固定义齿检验_CMA原始记录表.docx",
    "removable_denture": "R015_定制式活动义齿检验_CMA原始记录表.docx",
    "density": "R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx",
    "tarnish": "R017_金属材料抗晦暗性能试验_CMA原始记录表.docx",
}

# ── EXPERIMENT_PHOTO_CHECKPOINTS（对齐 reference V9.4.2）──
# 实验名 → 专属拍照节点
# 粗糙度/裂纹萌生/热膨胀/硬度/厚度/弯曲 按受控流程使用精简后的专属节点，不叠加通用照片
_EXPERIMENT_PHOTO_CHECKPOINTS = {
    "表面粗糙度试验": [
        {"code": "ROUGH_POINT_1", "label": "测量点①拍照", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "ROUGH_POINT_2", "label": "测量点②拍照", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "ROUGH_POINT_3", "label": "测量点③拍照", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "ROUGH_CURVE_RESULT", "label": "测量曲线、计算设置与结果界面", "required": True, "is_sample_level": False, "checkpoint_group": "结果界面"},
    ],
    "金属-陶瓷结合裂纹萌生试验": [
        {"code": "MC_K_VALUE", "label": "试样K值拍照", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "MC_REPORT", "label": "报告拍照", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "金属内部质量X射线灰度分析": [
        {"code": "IQI_POSITION", "label": "样品与孔形像质计摆放", "required": False, "is_sample_level": False, "checkpoint_group": "装夹与核查"},
        {"code": "EXPOSURE", "label": "曝光参数界面", "required": False, "is_sample_level": False, "checkpoint_group": "环境与设备"},
        {"code": "RADIOGRAPH", "label": "原始X射线成像画面", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "ROI", "label": "ROI位置及灰度值", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "翘曲变形试验": [
        {"code": "H1_BASELINE", "label": "切割前基准线到自由端中点距离", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "H2_BASELINE", "label": "切割后基准线到自由端中点距离", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "WARP_REPORT_1", "label": "试验报告拍照①", "required": True, "is_sample_level": False, "checkpoint_group": "结果界面"},
        {"code": "WARP_REPORT_2", "label": "试验报告拍照②", "required": True, "is_sample_level": False, "checkpoint_group": "结果界面"},
        {"code": "WARP_REPORT_3", "label": "试验报告拍照③", "required": True, "is_sample_level": False, "checkpoint_group": "结果界面"},
    ],
    "热膨胀系数试验": [
        {"code": "CTE_PARAM_SET", "label": "试验参数设定拍照", "required": True, "is_sample_level": False, "checkpoint_group": "环境与设备"},
        {"code": "CTE_REPORT", "label": "样品试验报告拍照", "required": True, "is_sample_level": False, "checkpoint_group": "结果界面"},
    ],
    "陶瓷牙耐急冷急热试验": [
        {"code": "SHOCK_BEFORE", "label": "试验前试样拍照", "required": True, "is_sample_level": True, "checkpoint_group": "样品状态"},
        {"code": "SHOCK_AFTER", "label": "试验后试样拍照", "required": True, "is_sample_level": True, "checkpoint_group": "样品状态"},
        {"code": "OVEN_TEMP", "label": "烘箱100±2℃实测温度", "required": False, "is_sample_level": False, "checkpoint_group": "环境与设备"},
        {"code": "ICE_TEMP_START", "label": "试验前冰水1±1℃温度", "required": False, "is_sample_level": False, "checkpoint_group": "环境与设备"},
        {"code": "ICE_TEMP_PROCESS", "label": "试验中每15分钟冰水复测读数", "required": False, "is_sample_level": False, "checkpoint_group": "环境与设备"},
        {"code": "FIRST_HEAT", "label": "第一次加热开始/结束时间与温度", "required": False, "is_sample_level": False, "checkpoint_group": "过程记录"},
        {"code": "TRANSFER_COLD", "label": "急冷转移、浸没状态与时间", "required": False, "is_sample_level": False, "checkpoint_group": "过程记录"},
        {"code": "SECOND_HEAT", "label": "第二次加热时间与温度", "required": False, "is_sample_level": False, "checkpoint_group": "过程记录"},
        {"code": "COOL_TEMP", "label": "自然冷却后样品表面23±2℃", "required": False, "is_sample_level": False, "checkpoint_group": "过程记录"},
        {"code": "INSPECTION_LIGHT", "label": "外观检查光照度≥1000 lx", "required": False, "is_sample_level": False, "checkpoint_group": "核查与设备"},
        {"code": "DAMAGE", "label": "逐颗裂纹、崩瓷或破损检查结果", "required": False, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "弯曲性能试验": [
        {"code": "BEND_REPORT", "label": "报告拍照", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "维氏硬度试验": [
        {"code": "HV_LOAD_TIME", "label": "载荷和保荷时间", "required": True, "is_sample_level": False, "checkpoint_group": "环境与设备"},
        {"code": "HV_REPORT_1", "label": "报告拍照①", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "HV_REPORT_2", "label": "报告拍照②", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "增材制造金属试样厚度测量": [
        {"code": "FIXED_DIST_1", "label": "固定端距离拍照①", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "FIXED_DIST_2", "label": "固定端距离拍照②", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "FIXED_DIST_3", "label": "固定端距离拍照③", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "MID_DIST_1", "label": "中间距离拍照①", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "MID_DIST_2", "label": "中间距离拍照②", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "MID_DIST_3", "label": "中间距离拍照③", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "FREE_END_1", "label": "自由端拍照①", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "FREE_END_2", "label": "自由端拍照②", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "FREE_END_3", "label": "自由端拍照③", "required": True, "is_sample_level": True, "checkpoint_group": "测量点"},
        {"code": "THICK_REPORT", "label": "报告拍照", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "牙科材料色稳定性试验": [
        {"code": "COLOR_BEFORE", "label": "试验前试样拍照", "required": True, "is_sample_level": True, "checkpoint_group": "样品状态"},
        {"code": "COLOR_AFTER", "label": "试验后试样拍照", "required": True, "is_sample_level": True, "checkpoint_group": "样品状态"},
    ],
    "定制式固定义齿检验": [
        {"code": "DESIGN_TRACE", "label": "设计单、模型及原材料追溯核查", "required": True, "is_sample_level": False, "checkpoint_group": "装夹与核查"},
        {"code": "FIXED_DENTURE_RESULT", "label": "表面、适合性、咬合及尺寸综合检验结果", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "MICRO_RESULT", "label": "粗糙度或孔隙度显微检查结果", "required": False, "is_sample_level": False, "checkpoint_group": "结果界面"},
    ],
    "定制式活动义齿检验": [
        {"code": "DESIGN_TRACE", "label": "设计单、模型及原材料追溯核查", "required": True, "is_sample_level": False, "checkpoint_group": "装夹与核查"},
        {"code": "REMOVABLE_DENTURE_RESULT", "label": "外形、适合性、厚度及咬合综合检验结果", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "XRAY_RESULT", "label": "金属内部质量X射线结果", "required": False, "is_sample_level": True, "checkpoint_group": "结果界面"},
        {"code": "COLOR_RESULT", "label": "色泽检查结果", "required": False, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "激光选区熔化金属材料密度试验": [
        {"code": "DENSITY_CALIBRATION", "label": "天平校准与密度系统核查", "required": True, "is_sample_level": False, "checkpoint_group": "装夹与核查"},
        {"code": "DENSITY_RESULT", "label": "逐试样自动密度数据/打印件", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
    "金属材料抗晦暗性能试验": [
        {"code": "TARNISH_BEFORE", "label": "浸泡与对照试样试验前表面", "required": True, "is_sample_level": True, "checkpoint_group": "样品状态"},
        {"code": "TARNISH_SOLUTION", "label": "三批试验溶液配制记录", "required": True, "is_sample_level": False, "checkpoint_group": "装夹与核查"},
        {"code": "TARNISH_AFTER", "label": "72小时试验后表面", "required": True, "is_sample_level": True, "checkpoint_group": "样品状态"},
        {"code": "TARNISH_COMPARE", "label": "前后/对照比较及擦拭后状态", "required": True, "is_sample_level": True, "checkpoint_group": "结果界面"},
    ],
}

# ── REPORT_DECISIVE_PHOTO_CODES ──
# 确定报告结论时真正使用的结果证据。报告生成器按此顺序选图，
# REPORT_PHOTO 只作为人工补充，不再是报告照片的唯一来源。
_REPORT_DECISIVE_PHOTO_CODES: dict[str, list[str]] = {
    "表面粗糙度试验": ["ROUGH_POINT_1", "ROUGH_CURVE_RESULT"],
    "金属-陶瓷结合裂纹萌生试验": ["MC_K_VALUE", "MC_REPORT"],
    "金属内部质量X射线灰度分析": ["RADIOGRAPH", "ROI"],
    "翘曲变形试验": ["H1_BASELINE", "H2_BASELINE", "WARP_REPORT_1"],
    "热膨胀系数试验": ["CTE_PARAM_SET", "CTE_REPORT"],
    "陶瓷牙耐急冷急热试验": ["DAMAGE"],
    "弯曲性能试验": ["BEND_REPORT"],
    "维氏硬度试验": ["HV_REPORT_1"],
    "增材制造金属试样厚度测量": ["FIXED_DIST_1", "MID_DIST_1", "FREE_END_1", "THICK_REPORT"],
    "牙科材料色稳定性试验": ["COLOR_BEFORE", "COLOR_AFTER"],
    "激光选区熔化金属材料密度试验": ["DENSITY_RESULT", "DENSITY_CALIBRATION"],
    "金属材料抗晦暗性能试验": ["TARNISH_BEFORE", "TARNISH_AFTER", "TARNISH_COMPARE"],
}

# ── 照片组装策略 ──
# 粗糙度/裂纹萌生/热膨胀/硬度/厚度/弯曲：按受控流程使用精简后的专属节点，不叠加通用照片
# 其他实验：通用照片 + 专属照片
_KINDS_ONLY_SPECIFIC_PHOTOS = {"rough", "mc_crack", "cte", "hv", "thickness", "bend", "density"}


def _get_photo_checkpoints(kind: str, experiment_name: str | None = None) -> list[dict]:
    """获取拍照节点：对齐 reference photo_checkpoints() 逻辑"""
    name = experiment_name or _KIND_TO_NAME.get(kind, "")
    specific = _EXPERIMENT_PHOTO_CHECKPOINTS.get(name, [])
    if not specific:
        return list(_COMMON_PHOTO_CHECKPOINTS)
    # 精简模式：仅返回专属节点，不叠加通用照片
    if kind in _KINDS_ONLY_SPECIFIC_PHOTOS:
        return specific
    # 叠加模式：通用 + 专属
    return _COMMON_PHOTO_CHECKPOINTS + specific


# ── 实验编码 → kind 的静态映射（无需 DB 查询）──
_EXPERIMENT_CODE_TO_KIND: dict[str, str] = {}

def _resolve_kind(experiment_code: str) -> str | None:
    """将 experiment_code 映射到 kind（先从缓存查，再从 SCHEMAS 推断）"""
    if experiment_code in _EXPERIMENT_CODE_TO_KIND:
        return _EXPERIMENT_CODE_TO_KIND[experiment_code]
    # 尝试通过 SCHEMAS 的 kind 字段反向匹配（kind 与 experiment_code 可能相同）
    for kind, schema in SCHEMAS.items():
        if schema.get("experiment_code") == experiment_code:
            _EXPERIMENT_CODE_TO_KIND[experiment_code] = kind
            return kind
    # 如果 experiment_code 本身就是 kind (罕见情况)
    if experiment_code in SCHEMAS:
        return experiment_code
    return None

def _build_fallback_config(experiment_code: str, kind_hint: str | None = None) -> dict | None:
    """从硬编码 SCHEMAS 构建前端可用配置（无 DB 版本时的安全网）。

    kind_hint：新建检测项目时由表单直接给出 kind，绕过 experiment_code→kind 的反向解析。
    """
    # SCHEMAS keyed by kind, not experiment_code — resolve kind from experiment_methods or known mapping
    kind = kind_hint or _resolve_kind(experiment_code)
    schema = SCHEMAS.get(kind) if kind else None
    if not schema:
        return None

    fields = []
    for si, section in enumerate(schema.get("sections", [])):
        section_title = section.get("title", "")
        for fi, f in enumerate(section.get("fields", [])):
            fields.append({
                "key": f.get("key", ""),
                "label": f.get("label", ""),
                "type": f.get("type", "text"),
                "default": f.get("default", ""),
                "options": f.get("options", []),
                "readonly": f.get("readonly", False),
                "section_title": section_title,
                "section_order": si,
            })

    columns = []
    raw_columns = schema.get("columns", [])
    calc_by_key = rules_by_column(rules_for_kind(kind))
    for i, col in enumerate(raw_columns):
        if isinstance(col, (list, tuple)) and len(col) >= 3:
            entry = {
                "column_key": col[0],
                "column_label": col[1],
                "column_type": col[2],
                "column_default": "",
                "calc_expression": calc_by_key.get(col[0]) if col[2] == "calc" else None,
                "calc_precision": 3,
            }
            columns.append(entry)
        elif isinstance(col, dict):
            columns.append(col)

    kind = schema.get("kind", experiment_code)
    exp_name = _KIND_TO_NAME.get(kind, "")
    return {
        "experiment_code": experiment_code,
        "kind": kind,
        "fields": fields,
        "columns": columns,
        "photo_checkpoints": _get_photo_checkpoints(kind),
        "camera_hints": _CAMERA_HINTS,
        "report_decisive_photo_codes": _REPORT_DECISIVE_PHOTO_CODES.get(exp_name, []),
        "record_template_file": _TEMPLATE_FILE_MAP.get(kind, ""),
        "prechecks": schema.get("prechecks", []),
        "validation_rules": [],
        "equipment": [],
        "row_expansion": schema.get("row_expansion"),
        "face_labels": schema.get("face_labels"),
        "_source": "hardcoded",
    }


def _apply_config_extras(config_dict: dict[str, Any], kind_resolved: str) -> dict[str, Any]:
    """DB 优先、硬编码兜底：camera_hints / report_decisive_photo_codes / record_template_file。

    extra_json 为 JSONB，可能为 None 或 dict；只取这三个键，缺失回退硬编码常量。
    """
    extra = config_dict.get("extra_json") or {}
    if not isinstance(extra, dict):
        extra = {}

    config_dict["camera_hints"] = extra.get("camera_hints") or _CAMERA_HINTS

    exp_name_db = config_dict.get("experiment_name") or _KIND_TO_NAME.get(kind_resolved, "")
    config_dict["report_decisive_photo_codes"] = (
        extra.get("report_decisive_photo_codes")
        or _REPORT_DECISIVE_PHOTO_CODES.get(exp_name_db, [])
    )

    config_dict["record_template_file"] = (
        extra.get("record_template_file") or _TEMPLATE_FILE_MAP.get(kind_resolved, "")
    )

    # 透出原始 extra_json，便于配置编辑器读写（含 constants 等 P3 键）
    config_dict["extra_json"] = extra
    return config_dict


async def resolve_record_template_file(
    db: AsyncSession, experiment_code: str | None
) -> str:
    """导出路径复用：返回 DB 配置的 record_template_file（extra_json 优先），无则返回空串。

    空串表示「无 DB 覆盖」，调用方应保留引擎原有的 kind 推断逻辑，绝不改变现有兜底行为。
    """
    if not experiment_code:
        return ""
    row = await db.execute(
        text(
            "SELECT extra_json FROM experiment_config_versions "
            "WHERE experiment_code=:ec AND status='现行' "
            "ORDER BY effective_date DESC LIMIT 1"
        ),
        {"ec": experiment_code},
    )
    r = row.fetchone()
    extra = r[0] if r and r[0] else None
    if isinstance(extra, dict):
        return extra.get("record_template_file") or ""
    return ""


async def load_mapping_registry(
    db: AsyncSession, experiment_code: str | None, task_no: str | None = None
) -> dict[str, Any]:
    """导出路径复用：加载受控模板映射的 DB 权威值（坐标 + 常量）。

    返回结构直接注入 `apply_controlled_mapping(..., registry=...)`：
      {"db_mappings": [template_field_mappings 行…], "extra_json": {…}}

    传入 task_no 时优先读任务配置快照（检测期间锁定），保证历史记录按当时配置导出；
    无快照或无现行版本时返回空结构，映射注册表回退到硬编码兜底（逐格一致）。
    """
    result: dict[str, Any] = {"db_mappings": [], "extra_json": {}}
    # 优先任务级快照
    if task_no:
        srow = await db.execute(
            text("SELECT snapshot_json FROM task_config_snapshots WHERE task_no=:t"),
            {"t": task_no},
        )
        sr = srow.fetchone()
        if sr and sr[0]:
            snap = sr[0] if isinstance(sr[0], dict) else (json.loads(sr[0]) if sr[0] else {})
            result["db_mappings"] = snap.get("db_mappings", [])
            result["extra_json"] = snap.get("extra_json") or {}
            return result
    if not experiment_code:
        return result
    row = await db.execute(
        text(
            "SELECT id, extra_json FROM experiment_config_versions "
            "WHERE experiment_code=:ec AND status='现行' "
            "ORDER BY effective_date DESC LIMIT 1"
        ),
        {"ec": experiment_code},
    )
    r = row.fetchone()
    if not r:
        return result
    config_id, extra_json = r[0], r[1]
    if isinstance(extra_json, dict):
        result["extra_json"] = extra_json
    mrow = await db.execute(
        text(
            "SELECT field_key, table_index, row_index, col_index, transform, checkbox_selection "
            "FROM template_field_mappings WHERE config_id=:cid ORDER BY sort_order"
        ),
        {"cid": config_id},
    )
    result["db_mappings"] = [dict(zip(mrow.keys(), x)) for x in mrow.fetchall()]
    return result


async def snapshot_task_config(
    db: AsyncSession, task_no: str, experiment_code: str | None
) -> dict | None:
    """锁定任务级配置快照：把当前「现行」版本写入 task_config_snapshots。

    在实验员接收任务包/开始检测时调用，保证检测期间配置不漂移；
    导出路径 `load_mapping_registry(..., task_no=…)` 优先读该快照。
    无现行版本时返回 None（不写快照，导出回退硬编码兜底）。
    """
    if not experiment_code:
        return None
    row = await db.execute(
        text(
            "SELECT id, version, extra_json FROM experiment_config_versions "
            "WHERE experiment_code=:ec AND status='现行' "
            "ORDER BY effective_date DESC LIMIT 1"
        ),
        {"ec": experiment_code},
    )
    r = row.fetchone()
    if not r:
        return None
    config_id, config_version, extra_json = r[0], r[1], r[2]
    extra = extra_json if isinstance(extra_json, dict) else {}

    mrow = await db.execute(
        text(
            "SELECT field_key, table_index, row_index, col_index, transform, checkbox_selection "
            "FROM template_field_mappings WHERE config_id=:cid ORDER BY sort_order"
        ),
        {"cid": config_id},
    )
    db_mappings = [dict(zip(mrow.keys(), x)) for x in mrow.fetchall()]

    frow = await db.execute(
        text("SELECT * FROM experiment_config_fields WHERE config_id=:cid ORDER BY sort_order"),
        {"cid": config_id},
    )
    fields = [dict(zip(frow.keys(), x)) for x in frow.fetchall()]
    crow = await db.execute(
        text("SELECT * FROM experiment_config_columns WHERE config_id=:cid ORDER BY sort_order"),
        {"cid": config_id},
    )
    columns = [dict(zip(crow.keys(), x)) for x in crow.fetchall()]

    snapshot = {
        "db_mappings": db_mappings,
        "extra_json": extra,
        "fields": fields,
        "columns": columns,
    }
    snapshot_str = json.dumps(snapshot, ensure_ascii=False, default=str)
    snapshot_hash = hashlib.sha256(snapshot_str.encode("utf-8")).hexdigest()

    await db.execute(
        text("""
            INSERT INTO task_config_snapshots (task_no, config_id, config_version, snapshot_json, snapshot_hash, created_at)
            VALUES (:t, :cid, :cv, CAST(:snap AS jsonb), :hash, localtimestamp)
            ON CONFLICT (task_no) DO UPDATE SET
                config_id=EXCLUDED.config_id, config_version=EXCLUDED.config_version,
                snapshot_json=EXCLUDED.snapshot_json, snapshot_hash=EXCLUDED.snapshot_hash,
                created_at=localtimestamp
        """),
        {
            "t": task_no, "cid": config_id, "cv": config_version,
            "snap": snapshot_str, "hash": snapshot_hash,
        },
    )
    return {"config_id": config_id, "config_version": config_version, "snapshot_hash": snapshot_hash}


async def _config_fingerprint(db: AsyncSession, config_id: int) -> str:
    """计算配置内容指纹（SHA-256）：字段/列/照片/预检/验证规则/设备/坐标映射/extra_json。

    执行界面据此轮询检测「同版本内就地修改」等任意内容变更 —— config_id 不变时也能感知。
    """
    payload: dict[str, Any] = {}

    extra_row = await db.execute(
        text("SELECT extra_json FROM experiment_config_versions WHERE id=:cid"),
        {"cid": config_id},
    )
    er = extra_row.fetchone()
    extra = er[0] if er and er[0] is not None else {}
    if isinstance(extra, str):
        try:
            extra = json.loads(extra)
        except (json.JSONDecodeError, TypeError):
            extra = {"_raw": extra}
    payload["extra_json"] = extra

    for table, order_by in [
        ("experiment_config_fields", "sort_order, id"),
        ("experiment_config_columns", "sort_order, id"),
        ("experiment_config_photo_checkpoints", "sort_order, id"),
        ("experiment_config_prechecks", "sort_order, id"),
        ("experiment_config_validation_rules", "id"),
        ("experiment_config_equipment", "sort_order, management_no"),
        ("template_field_mappings", "sort_order, id"),
    ]:
        r = await db.execute(
            text(f"SELECT * FROM {table} WHERE config_id=:cid ORDER BY {order_by}"),
            {"cid": config_id},
        )
        payload[table] = [dict(zip(r.keys(), row)) for row in r.fetchall()]

    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, default=str)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


@router.get("/{experiment_code}/current-version")
async def get_current_version_info(
    experiment_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """轻量接口：返回某实验当前「现行」配置版本 + 内容指纹（供执行界面轮询实时刷新）"""
    row = await db.execute(
        text("""
            SELECT id, version FROM experiment_config_versions
            WHERE experiment_code=:ec AND status='现行'
            ORDER BY effective_date DESC LIMIT 1
        """),
        {"ec": experiment_code},
    )
    r = row.fetchone()
    if not r:
        return {"experiment_code": experiment_code, "version": None, "config_id": None, "fingerprint": None}
    return {
        "experiment_code": experiment_code,
        "version": r[1],
        "config_id": r[0],
        "fingerprint": await _config_fingerprint(db, r[0]),
    }


@router.get("/{experiment_code}")
async def get_current_config(
    experiment_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """获取某个实验的当前有效配置（含所有子组件）"""
    # 查当前生效版本
    config_result = await db.execute(
        text("""
            SELECT * FROM experiment_config_versions
            WHERE experiment_code = :ec AND status = '现行'
            ORDER BY effective_date DESC LIMIT 1
        """),
        {"ec": experiment_code},
    )
    config = config_result.fetchone()
    if not config:
        # ── 硬编码 schema 回退 ──
        # 先查 kind（experiment_methods 表）
        method_result = await db.execute(
            text("SELECT experiment_name, kind FROM experiment_methods WHERE experiment_code=:ec"),
            {"ec": experiment_code},
        )
        method_row = method_result.fetchone()
        if method_row:
            exp_name = method_row[0]
            kind = method_row[1] or experiment_code
            # 注册到缓存
            _EXPERIMENT_CODE_TO_KIND[experiment_code] = kind
        else:
            exp_name = experiment_code
            kind = experiment_code

        fb = _build_fallback_config(experiment_code)
        if fb:
            equip_result = await db.execute(
                text("""
                    SELECT eeb.*, er.equipment_name, er.model,
                           er.measuring_range, er.manufacturer, er.serial_no,
                           er.calibration_time, er.equipment_class, er.responsible
                    FROM experiment_equipment_bindings eeb
                    LEFT JOIN equipment_registry er ON eeb.management_no = er.management_no
                    WHERE eeb.experiment = :exp
                    ORDER BY eeb.sort_order
                """),
                {"exp": exp_name},
            )
            rows = equip_result.fetchall()
            fb["equipment"] = [dict(zip(equip_result.keys(), r)) for r in rows]
            fb["record_template_file"] = _TEMPLATE_FILE_MAP.get(kind, "")
            return fb
        return {"experiment_code": experiment_code, "message": "无现行配置版本，使用硬编码默认值"}

    config_dict = dict(zip(config_result.keys(), config))
    config_id = config_dict["id"]

    # 解析 kind（用于 fallback 和 report_decisive_photo_codes）
    _kind_resolved = None
    _kind_row = await db.execute(
        text("SELECT kind FROM experiment_methods WHERE experiment_code=:ec"),
        {"ec": experiment_code},
    )
    _kind_val = _kind_row.fetchone()
    _kind_resolved = _kind_val[0] if _kind_val else experiment_code
    # Normalize kind to match SCHEMAS keys (experiment_methods may use longer names)
    _kind_resolved = _resolve_kind(experiment_code) or _kind_resolved

    # 查字段配置 → 标准化
    fields_result = await db.execute(
        text("SELECT * FROM experiment_config_fields WHERE config_id=:cid ORDER BY section_order, sort_order"),
        {"cid": config_id},
    )
    config_dict["fields"] = _normalize_db_fields(
        [dict(zip(fields_result.keys(), r)) for r in fields_result.fetchall()]
    )

    # 查测量列配置 → 标准化
    cols_result = await db.execute(
        text("SELECT * FROM experiment_config_columns WHERE config_id=:cid ORDER BY sort_order"),
        {"cid": config_id},
    )
    config_dict["columns"] = _normalize_db_columns(
        [dict(zip(cols_result.keys(), r)) for r in cols_result.fetchall()]
    )

    # 查拍照节点 → 标准化
    photos_result = await db.execute(
        text("SELECT * FROM experiment_config_photo_checkpoints WHERE config_id=:cid ORDER BY sort_order"),
        {"cid": config_id},
    )
    db_photos = [dict(zip(photos_result.keys(), r)) for r in photos_result.fetchall()]
    config_dict["photo_checkpoints"] = _normalize_db_photos(db_photos)

    # 查预检查项 → 标准化
    prechecks_result = await db.execute(
        text("SELECT * FROM experiment_config_prechecks WHERE config_id=:cid ORDER BY sort_order"),
        {"cid": config_id},
    )
    config_dict["prechecks"] = _normalize_db_prechecks(
        [dict(zip(prechecks_result.keys(), r)) for r in prechecks_result.fetchall()]
    )

    # 查验证规则
    rules_result = await db.execute(
        text("SELECT * FROM experiment_config_validation_rules WHERE config_id=:cid"),
        {"cid": config_id},
    )
    config_dict["validation_rules"] = [dict(zip(rules_result.keys(), r)) for r in rules_result.fetchall()]

    # 查设备绑定
    equip_result = await db.execute(
        text("""
            SELECT ece.*, er.equipment_name, er.model,
                   er.measuring_range, er.manufacturer, er.serial_no,
                   er.calibration_time, er.equipment_class, er.responsible
            FROM experiment_config_equipment ece
            LEFT JOIN equipment_registry er ON ece.management_no = er.management_no
            WHERE ece.config_id = :cid
            ORDER BY ece.sort_order
        """),
        {"cid": config_id},
    )
    config_dict["equipment"] = [dict(zip(equip_result.keys(), r)) for r in equip_result.fetchall()]

    # 如果 DB 配置也没有设备，回退到 experiment_equipment_bindings
    if not config_dict["equipment"]:
        exp_name = config_dict.get("experiment_name")
        exp_code = config_dict.get("experiment_code")
        # 如果 experiment_name 为空，从 experiment_methods 表查询
        if not exp_name and exp_code:
            name_result = await db.execute(
                text("SELECT experiment_name FROM experiment_methods WHERE experiment_code=:ec"),
                {"ec": exp_code},
            )
            name_row = name_result.fetchone()
            exp_name = name_row[0] if name_row else exp_code
        elif not exp_name:
            exp_name = exp_code
        equip_bind_result = await db.execute(
            text("""
                SELECT eeb.*, er.equipment_name, er.model,
                       er.measuring_range, er.manufacturer, er.serial_no,
                       er.calibration_time, er.equipment_class, er.responsible
                FROM experiment_equipment_bindings eeb
                LEFT JOIN equipment_registry er ON eeb.management_no = er.management_no
                WHERE eeb.experiment = :exp
                ORDER BY eeb.sort_order
            """),
            {"exp": exp_name},
        )
        rows = equip_bind_result.fetchall()
        config_dict["equipment"] = [dict(zip(equip_bind_result.keys(), r)) for r in rows]

    # ── DB 照片节点为空时回退到硬编码 ──
    if not config_dict.get("photo_checkpoints"):
        config_dict["photo_checkpoints"] = _get_photo_checkpoints(_kind_resolved)

    # ── DB 配置为空时回退到硬编码 schema ──
    if not config_dict.get("fields") and not config_dict.get("columns"):
        fb = _build_fallback_config(_kind_resolved) or _build_fallback_config(experiment_code)
        if fb:
            fb["_source"] = "hardcoded-fallback"
            fb["experiment_code"] = experiment_code
            if config_dict.get("equipment"):
                fb["equipment"] = config_dict["equipment"]
            fb["record_template_file"] = _TEMPLATE_FILE_MAP.get(_kind_resolved, "")
            return fb

    config_dict["_source"] = "database"
    _apply_config_extras(config_dict, _kind_resolved)
    return config_dict


@router.get("/{experiment_code}/versions/{version}")
async def get_config_version(
    experiment_code: str,
    version: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """获取指定版本的完整配置（含所有子组件）"""
    cfg = await db.execute(
        text("SELECT * FROM experiment_config_versions WHERE experiment_code=:ec AND version=:v"),
        {"ec": experiment_code, "v": version},
    )
    row = cfg.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="配置版本不存在")
    config_dict = dict(zip(cfg.keys(), row))
    config_id = config_dict["id"]

    # 解析 kind（用于 fallback 和 report_decisive_photo_codes）
    _kind_row = await db.execute(text("SELECT kind FROM experiment_methods WHERE experiment_code=:ec"), {"ec": experiment_code})
    _kv = _kind_row.fetchone()
    _kind_resolved = _kv[0] if _kv else experiment_code
    _kind_resolved = _resolve_kind(experiment_code) or _kind_resolved

    # 加载所有子组件
    for table, normalizer, key in [
        ("experiment_config_fields", _normalize_db_fields, "fields"),
        ("experiment_config_columns", _normalize_db_columns, "columns"),
        ("experiment_config_photo_checkpoints", _normalize_db_photos, "photo_checkpoints"),
        ("experiment_config_prechecks", _normalize_db_prechecks, "prechecks"),
    ]:
        r = await db.execute(text(f"SELECT * FROM {table} WHERE config_id=:cid ORDER BY sort_order"), {"cid": config_id})
        config_dict[key] = normalizer([dict(zip(r.keys(), row)) for row in r.fetchall()])

    # 验证规则
    rules = await db.execute(text("SELECT * FROM experiment_config_validation_rules WHERE config_id=:cid"), {"cid": config_id})
    config_dict["validation_rules"] = [dict(zip(rules.keys(), r)) for r in rules.fetchall()]

    # 设备
    equip = await db.execute(
        text("""
            SELECT ece.*, er.equipment_name, er.model,
                   er.measuring_range, er.manufacturer, er.serial_no,
                   er.calibration_time, er.equipment_class, er.responsible
            FROM experiment_config_equipment ece
            LEFT JOIN equipment_registry er ON ece.management_no = er.management_no
            WHERE ece.config_id=:cid ORDER BY ece.sort_order
        """),
        {"cid": config_id},
    )
    config_dict["equipment"] = [dict(zip(equip.keys(), r)) for r in equip.fetchall()]

    # 空字段/列时回退硬编码模板
    if not config_dict.get("fields") and not config_dict.get("columns"):
        fb = _build_fallback_config(_kind_resolved) or _build_fallback_config(experiment_code)
        if fb:
            fb["_source"] = "hardcoded-template"
            fb["experiment_code"] = experiment_code
            fb["version"] = version
            return fb
    if not config_dict.get("photo_checkpoints"):
        config_dict["photo_checkpoints"] = _get_photo_checkpoints(_kind_resolved)

    config_dict["_source"] = "database"
    _apply_config_extras(config_dict, _kind_resolved)
    return config_dict


@router.get("/{experiment_code}/versions")
async def list_config_versions(
    experiment_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """列出某实验的所有配置版本"""
    result = await db.execute(
        text("""
            SELECT id, experiment_code, version, experiment_name, status,
                   effective_date, approved_by, approved_at, created_at
            FROM experiment_config_versions
            WHERE experiment_code = :ec
            ORDER BY created_at DESC
        """),
        {"ec": experiment_code},
    )
    return [dict(zip(result.keys(), r)) for r in result.fetchall()]


# ── 任务配置快照 ──

@router.get("/snapshot/{task_no}")
async def get_task_config_snapshot(
    task_no: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
):
    """获取任务的配置快照（审计追溯用）"""
    result = await db.execute(
        text("SELECT config_id, config_version, snapshot_json, snapshot_hash, created_at FROM task_config_snapshots WHERE task_no=:t"),
        {"t": task_no},
    )
    row = result.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="该任务无配置快照")
    return {
        "task_no": task_no,
        "config_id": row[0],
        "config_version": row[1],
        "snapshot": row[2],
        "snapshot_hash": row[3],
        "created_at": str(row[4]) if row[4] else None,
    }


# ── 配置版本 CRUD（管理员）──

class ConfigVersionCreate(BaseModel):
    experiment_code: str = Field(..., min_length=1)
    version: str = Field(..., min_length=1)
    experiment_name: str = Field(..., min_length=1)
    method_code: str = Field(..., min_length=1)
    standard: str | None = None
    category: str | None = None
    kind: str = "generic"
    default_location: str | None = None
    sop_version: str | None = None
    record_template_version: str | None = None
    software: str | None = None
    effective_date: str | None = None
    note: str | None = None
    # 子配置（可选，创建时一并写入）
    fields: list[dict[str, Any]] = Field(default_factory=list)
    columns: list[dict[str, Any]] = Field(default_factory=list)
    photo_checkpoints: list[dict[str, Any]] = Field(default_factory=list)
    prechecks: list[dict[str, Any]] = Field(default_factory=list)
    validation_rules: list[dict[str, Any]] = Field(default_factory=list)
    equipment: list[dict[str, Any]] = Field(default_factory=list)
    extra_json: dict[str, Any] = Field(default_factory=dict)


@router.post("/{experiment_code}/versions", status_code=201)
async def create_config_version(
    experiment_code: str,
    body: ConfigVersionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[dict, Depends(require_role("管理员"))],
):
    """创建新的实验配置版本（管理员）"""
    # 验证 experiment_code 在 URL 和 body 中一致
    if body.experiment_code != experiment_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="URL 中的 experiment_code 与请求体不一致",
        )

    # 检查 experiment_code 是否存在于 experiment_methods
    method = await db.execute(
        text("SELECT 1 FROM experiment_methods WHERE experiment_code=:ec"),
        {"ec": experiment_code},
    )
    if not method.fetchone():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"实验编码 {experiment_code} 不存在于方法库",
        )

    # 检查版本是否已存在
    existing = await db.execute(
        text("SELECT 1 FROM experiment_config_versions WHERE experiment_code=:ec AND version=:v"),
        {"ec": experiment_code, "v": body.version},
    )
    if existing.fetchone():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"版本 {body.version} 已存在",
        )

    # 插入主配置
    result = await db.execute(
        text("""
            INSERT INTO experiment_config_versions
              (experiment_code, version, experiment_name, method_code, standard,
               category, kind, default_location, sop_version, record_template_version,
               software, status, effective_date, note, created_by)
            VALUES (:ec, :v, :en, :mc, :st, :cat, :kd, :dl, :sv, :rtv, :sw, '草稿', :ed, :nt, :cb)
            RETURNING id
        """),
        {
            "ec": experiment_code, "v": body.version, "en": body.experiment_name,
            "mc": body.method_code, "st": body.standard, "cat": body.category,
            "kd": body.kind, "dl": body.default_location, "sv": body.sop_version,
            "rtv": body.record_template_version, "sw": body.software,
            "ed": body.effective_date, "nt": body.note, "cb": current_user["username"],
        },
    )
    config_id = result.fetchone()[0]

    # 写入 extra_json（camera_hints / report_decisive_photo_codes / record_template_file / constants）
    if body.extra_json:
        await db.execute(
            text("UPDATE experiment_config_versions SET extra_json = CAST(:ej AS jsonb) WHERE id = :cid"),
            {"ej": json.dumps(body.extra_json, ensure_ascii=False), "cid": config_id},
        )

    # 插入子配置
    await _insert_config_children(db, config_id, body)

    return {
        "message": f"配置版本 {body.version} 创建成功",
        "config_id": config_id,
        "experiment_code": experiment_code,
        "version": body.version,
        "status": "草稿",
    }


@router.post("/import-docx", status_code=201)
async def import_method_docx(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[dict, Depends(require_role("管理员"))],
    experiment_code: str = Form(...),
    experiment_name: str = Form(...),
    method_code: str = Form(...),
    standard: str | None = Form(None),
    category: str | None = Form(None),
    kind: str = Form("generic"),
    record_template: UploadFile | None = File(None),
    sop_file: UploadFile | None = File(None),
):
    """一键导入检测项目（管理员）：新建方法 + 保存 Word 模板/SOP + 生成配置版本 V1.0。

    - 记录模板(.docx) 保存为 RECORD_{code}_{name}.docx，并解析填空/勾选格自动匹配字段编码，
      写入 experiment_config_fields + template_field_mappings（版本控制相关内容）。
    - SOP(.docx) 保存为 SOP_{code}_{name}.docx。
    - 列/拍照节点/预检项/设备按 kind 回退硬编码 SCHEMAS 兜底生成。
    """
    experiment_code = (experiment_code or "").strip()
    experiment_name = (experiment_name or "").strip()
    method_code = (method_code or "").strip()
    if not experiment_code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="实验编码不能为空")
    if not experiment_name:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="实验名称不能为空")
    if not method_code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="方法编号不能为空")

    # 1. 方法库去重
    existing = await db.execute(
        text("SELECT 1 FROM experiment_methods WHERE experiment_code=:ec"), {"ec": experiment_code}
    )
    if existing.fetchone():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="实验编码已存在，请直接编辑或停用后重试")

    # 2. 保存模板文件到 TEMPLATE_DIR
    template_dir = _Path(settings.TEMPLATE_DIR)
    template_dir.mkdir(parents=True, exist_ok=True)

    def _safe(name: str) -> str:
        return _re.sub(r'[\\/:*?"<>|]', "_", name)

    record_filename = ""
    if record_template and record_template.filename:
        if not record_template.filename.lower().endswith(".docx"):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="原始记录模板仅支持 .docx 文件")
        record_filename = f"RECORD_{_safe(experiment_code)}_{_safe(experiment_name)}.docx"
        (template_dir / record_filename).write_bytes(await record_template.read())

    sop_filename = ""
    if sop_file and sop_file.filename:
        if not sop_file.filename.lower().endswith(".docx"):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="SOP 仅支持 .docx 文件")
        sop_filename = f"SOP_{_safe(experiment_code)}_{_safe(experiment_name)}.docx"
        (template_dir / sop_filename).write_bytes(await sop_file.read())

    # 3. 新建方法
    seq_result = await db.execute(text("SELECT COALESCE(MAX(sort_order), 0) + 1 FROM experiment_methods"))
    next_seq = seq_result.fetchone()[0]
    await db.execute(
        text("""
            INSERT INTO experiment_methods (experiment_code, experiment_name, method_code,
              standard, category, kind, template_code, sop_file, enabled, sort_order, created_at, updated_at)
            VALUES (:ec, :en, :mc, :st, :ct, :kd, :tc, :sf, TRUE, :so, localtimestamp, localtimestamp)
        """),
        {"ec": experiment_code, "en": experiment_name, "mc": method_code,
         "st": standard, "ct": category, "kd": kind,
         "tc": record_filename or None, "sf": sop_filename or None, "so": next_seq},
    )

    # 4. 生成配置版本 V1.0（草稿）
    version = "V1.0"
    ver_exists = await db.execute(
        text("SELECT 1 FROM experiment_config_versions WHERE experiment_code=:ec AND version=:v"),
        {"ec": experiment_code, "v": version},
    )
    if ver_exists.fetchone():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=f"配置版本 {version} 已存在")

    fb = _build_fallback_config(experiment_code, kind_hint=(kind if kind != "generic" else None))  # 已知 kind 提供列/拍照/预检兜底

    result = await db.execute(
        text("""
            INSERT INTO experiment_config_versions
              (experiment_code, version, experiment_name, method_code, standard,
               category, kind, default_location, sop_version, record_template_version,
               software, status, effective_date, note, created_by)
            VALUES (:ec, :v, :en, :mc, :st, :cat, :kd, NULL, :sv, :rtv, NULL, '草稿', NULL, NULL, :cb)
            RETURNING id
        """),
        {"ec": experiment_code, "v": version, "en": experiment_name, "mc": method_code,
         "st": standard, "cat": category, "kd": kind,
         "sv": sop_filename or None, "rtv": record_filename or None,
         "cb": current_user["username"]},
    )
    config_id = result.fetchone()[0]

    # 4a. extra_json：记录模板文件名 + 拍照提示/决定性照片（fallback 兜底）
    extra: dict[str, Any] = {}
    if record_filename:
        extra["record_template_file"] = record_filename
    if fb:
        if fb.get("camera_hints"):
            extra["camera_hints"] = fb["camera_hints"]
        if fb.get("report_decisive_photo_codes"):
            extra["report_decisive_photo_codes"] = fb["report_decisive_photo_codes"]
    if extra:
        await db.execute(
            text("UPDATE experiment_config_versions SET extra_json = CAST(:ej AS jsonb) WHERE id = :cid"),
            {"ej": json.dumps(extra, ensure_ascii=False), "cid": config_id},
        )

    # 4b. 字段：优先从 Word 模板自动匹配，否则用 fallback 字段
    fields: list[dict[str, Any]] = []
    mappings: list[dict[str, Any]] = []
    if record_filename:
        record_path = template_dir / record_filename
        for i, f in enumerate(_parse_template_docx(record_path)):
            fk = match_field_key(f["label"]) or f"field_{i + 1}"
            input_type = f.get("input_type") or "text"
            fields.append({
                "section_title": f["section"], "section_order": int(f.get("table", 0)) + 1,
                "field_key": fk, "field_label": f["label"],
                "field_type": "checkbox" if input_type == "checkbox" else "text",
                "field_default": "", "field_options": "", "is_required": False,
                "is_readonly": False, "is_actual": False, "sort_order": i,
            })
            mappings.append({
                "field_source": "static", "field_key": fk, "template_name": record_filename,
                "table_index": int(f.get("table", 0)), "row_index": int(f.get("row", 0)),
                "col_index": int(f.get("col", 0)),
                "transform": "checkbox" if input_type == "checkbox" else "text",
                "checkbox_selection": _checkbox_selection(f.get("template_text", "")) if input_type == "checkbox" else "",
                "sort_order": i,
            })
    elif fb and fb.get("fields"):
        for i, f in enumerate(fb["fields"]):
            fields.append({
                "section_title": f.get("section_title", ""),
                "section_order": f.get("section_order", 1),
                "field_key": f.get("key", f"field_{i}"),
                "field_label": f.get("label", f"字段 {i+1}"),
                "field_type": f.get("type", "text"),
                "field_default": f.get("default", ""),
                "field_options": f.get("options", []),
                "is_required": False, "is_readonly": f.get("readonly", False),
                "is_actual": False, "sort_order": i,
            })

    if fields:
        await _insert_fields(db, config_id, fields)
    for m in mappings:
        await db.execute(
            text("""
                INSERT INTO template_field_mappings
                  (config_id, field_source, field_key, template_name,
                   table_index, row_index, col_index, transform, checkbox_selection, sort_order)
                VALUES (:cid, :field_source, :field_key, :template_name,
                        :table_index, :row_index, :col_index, :transform, :checkbox_selection, :sort_order)
            """),
            {"cid": config_id, **m},
        )

    # 4c. 列 / 拍照 / 预检 / 设备（来自 fallback，形状归一化）
    if fb:
        if fb.get("columns"):
            cols = []
            for i, c in enumerate(fb["columns"]):
                cols.append({
                    "column_key": c.get("column_key", c.get("key", f"col_{i}")),
                    "column_label": c.get("column_label", c.get("label", f"列 {i+1}")),
                    "column_type": c.get("column_type", c.get("type", "number")),
                    "is_required": c.get("is_required", False),
                    "column_default": c.get("column_default", c.get("default", "")),
                    "calc_expression": c.get("calc_expression"),
                    "calc_precision": c.get("calc_precision", 3),
                    "sort_order": i,
                })
            await _insert_columns(db, config_id, cols)

        if fb.get("photo_checkpoints"):
            photos = []
            for i, p in enumerate(fb["photo_checkpoints"]):
                photos.append({
                    "checkpoint_code": p.get("code", p.get("checkpoint_code", f"photo_{i}")),
                    "checkpoint_label": p.get("label", p.get("checkpoint_label", f"拍照节点 {i+1}")),
                    "is_required": p.get("required", p.get("is_required", True)),
                    "is_sample_level": p.get("is_sample_level", False),
                    "checkpoint_group": p.get("checkpoint_group"),
                    "sort_order": i,
                })
            await _insert_photo_checkpoints(db, config_id, photos)

        if fb.get("prechecks"):
            pres = []
            for i, p in enumerate(fb["prechecks"]):
                pres.append({
                    "precheck_code": p.get("precheck_code", f"precheck_{i}"),
                    "precheck_label": p.get("label", p.get("precheck_label", p.get("check_name", f"预检查项 {i+1}"))),
                    "is_required": p.get("is_required", True),
                    "sort_order": i,
                })
            await _insert_prechecks(db, config_id, pres)

        if fb.get("equipment"):
            await _insert_equipment(db, config_id, fb["equipment"])

    return {
        "message": "检测项目一键导入成功",
        "experiment_code": experiment_code,
        "method_created": True,
        "record_template": record_filename or None,
        "sop_file": sop_filename or None,
        "version": version,
        "config_id": config_id,
        "fields_written": len(fields),
    }


class ConfigVersionUpdate(BaseModel):
    """更新配置版本（草稿/现行状态下可修改）"""
    experiment_name: str | None = None
    method_code: str | None = None
    standard: str | None = None
    category: str | None = None
    kind: str | None = None
    default_location: str | None = None
    sop_version: str | None = None
    record_template_version: str | None = None
    software: str | None = None
    effective_date: str | None = None
    note: str | None = None
    fields: list[dict[str, Any]] | None = None
    columns: list[dict[str, Any]] | None = None
    photo_checkpoints: list[dict[str, Any]] | None = None
    prechecks: list[dict[str, Any]] | None = None
    validation_rules: list[dict[str, Any]] | None = None
    equipment: list[dict[str, Any]] | None = None
    field_mappings: list[dict[str, Any]] | None = None
    extra_json: dict[str, Any] | None = None


@router.put("/{experiment_code}/versions/{version}")
async def update_config_version(
    experiment_code: str,
    version: str,
    body: ConfigVersionUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[dict, Depends(require_role("管理员"))],
):
    """更新实验配置版本（草稿/现行状态可修改）"""
    # 查找配置
    cfg = await db.execute(
        text("SELECT id, status FROM experiment_config_versions WHERE experiment_code=:ec AND version=:v"),
        {"ec": experiment_code, "v": version},
    )
    row = cfg.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="配置版本不存在")

    config_id, current_status = row[0], row[1]
    if current_status not in ("草稿", "现行"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"仅草稿/现行状态可修改，当前状态：{current_status}",
        )

    # 更新主配置中的非空字段
    updatable = {
        "experiment_name", "method_code", "standard", "category", "kind",
        "default_location", "sop_version", "record_template_version",
        "software", "effective_date", "note",
    }
    set_clauses = []
    params: dict[str, Any] = {"cid": config_id}
    for field_name in updatable:
        val = getattr(body, field_name, None)
        if val is not None:
            set_clauses.append(f"{field_name}=:{field_name}")
            params[field_name] = val
    if set_clauses:
        await db.execute(
            text(f"UPDATE experiment_config_versions SET {', '.join(set_clauses)} WHERE id=:cid"),
            params,
        )

    # 如果提供了子配置，先删后插
    if body.fields is not None:
        await db.execute(text("DELETE FROM experiment_config_fields WHERE config_id=:cid"), {"cid": config_id})
        await _insert_fields(db, config_id, body.fields)
    if body.columns is not None:
        await db.execute(text("DELETE FROM experiment_config_columns WHERE config_id=:cid"), {"cid": config_id})
        await _insert_columns(db, config_id, body.columns)
    if body.photo_checkpoints is not None:
        await db.execute(text("DELETE FROM experiment_config_photo_checkpoints WHERE config_id=:cid"), {"cid": config_id})
        await _insert_photo_checkpoints(db, config_id, body.photo_checkpoints)
    if body.prechecks is not None:
        await db.execute(text("DELETE FROM experiment_config_prechecks WHERE config_id=:cid"), {"cid": config_id})
        await _insert_prechecks(db, config_id, body.prechecks)
    if body.validation_rules is not None:
        await db.execute(text("DELETE FROM experiment_config_validation_rules WHERE config_id=:cid"), {"cid": config_id})
        await _insert_validation_rules(db, config_id, body.validation_rules)
    if body.equipment is not None:
        await db.execute(text("DELETE FROM experiment_config_equipment WHERE config_id=:cid"), {"cid": config_id})
        await _insert_equipment(db, config_id, body.equipment)

    # 模板坐标映射（配置编辑器「标签→编码」自动匹配后回传）：按 field_key 覆盖写
    if body.field_mappings is not None:
        actual_path = _resolve_template_path(experiment_code)
        template_name = actual_path.name if actual_path else ""
        for i, fm in enumerate(body.field_mappings):
            fk = (fm.get("field_key") or "").strip()
            if not fk:
                continue
            table_idx = int(fm.get("table", 0))
            row_idx = int(fm.get("row", 0))
            col_idx = int(fm.get("col", 0))
            transform = fm.get("transform") or "text"
            await db.execute(
                text("DELETE FROM template_field_mappings WHERE config_id=:cid AND field_key=:fk"),
                {"cid": config_id, "fk": fk},
            )
            await db.execute(
                text("""
                    INSERT INTO template_field_mappings
                      (config_id, field_source, field_key, template_name,
                       table_index, row_index, col_index, transform, checkbox_selection, sort_order)
                    VALUES (:cid, 'static', :fk, :tn, :ti, :ri, :ci, :tr, '', :srt)
                """),
                {
                    "cid": config_id, "fk": fk, "tn": template_name,
                    "ti": table_idx, "ri": row_idx, "ci": col_idx,
                    "tr": transform, "srt": i,
                },
            )

    if body.extra_json is not None:
        await db.execute(
            text("UPDATE experiment_config_versions SET extra_json = CAST(:ej AS jsonb) WHERE id = :cid"),
            {"ej": json.dumps(body.extra_json, ensure_ascii=False), "cid": config_id},
        )

    return {"message": f"配置版本 {version} 已更新", "config_id": config_id}


class ActivateVersionRequest(BaseModel):
    status: str = Field(..., pattern=r"^(现行|历史)$")


@router.put("/{experiment_code}/versions/{version}/status")
async def set_config_version_status(
    experiment_code: str,
    version: str,
    body: ActivateVersionRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[dict, Depends(require_role("管理员"))],
):
    """激活/归档配置版本（管理员）

    - 设为「现行」: 先将该实验所有现行版本归档为「历史」, 再将目标版本设为「现行」
    - 设为「历史」: 直接归档
    """
    cfg = await db.execute(
        text("SELECT id, status FROM experiment_config_versions WHERE experiment_code=:ec AND version=:v"),
        {"ec": experiment_code, "v": version},
    )
    row = cfg.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="配置版本不存在")

    config_id, current_status = row[0], row[1]

    if body.status == "现行":
        # 先将该实验所有现行版本归档
        await db.execute(
            text("""
                UPDATE experiment_config_versions
                SET status='历史', approved_by=:cb, approved_at=localtimestamp
                WHERE experiment_code=:ec AND status='现行'
            """),
            {"ec": experiment_code, "cb": current_user["username"]},
        )
        # 激活目标版本
        await db.execute(
            text("""
                UPDATE experiment_config_versions
                SET status='现行', effective_date=CURRENT_DATE, approved_by=:cb, approved_at=localtimestamp
                WHERE id=:cid
            """),
            {"cid": config_id, "cb": current_user["username"]},
        )
    else:
        # 归档
        await db.execute(
            text("UPDATE experiment_config_versions SET status='历史' WHERE id=:cid"),
            {"cid": config_id},
        )

    return {"message": f"配置版本 {version} 状态已更新为「{body.status}」"}


@router.delete("/{experiment_code}/versions/{version}")
async def delete_config_version(
    experiment_code: str,
    version: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[dict, Depends(require_role("管理员"))],
):
    """删除配置版本（仅草稿状态可删除，管理员）"""
    cfg = await db.execute(
        text("SELECT id, status FROM experiment_config_versions WHERE experiment_code=:ec AND version=:v"),
        {"ec": experiment_code, "v": version},
    )
    row = cfg.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="配置版本不存在")

    config_id, current_status = row[0], row[1]
    if current_status != "草稿":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"仅草稿状态可删除，当前状态：{current_status}",
        )

    # CASCADE 会删除子表记录
    await db.execute(text("DELETE FROM experiment_config_versions WHERE id=:cid"), {"cid": config_id})
    return {"message": f"配置版本 {version} 已删除"}


# ── 辅助函数 ──

async def _insert_config_children(db: AsyncSession, config_id: int, body: ConfigVersionCreate) -> None:
    """批量插入子配置"""
    if body.fields:
        await _insert_fields(db, config_id, body.fields)
    if body.columns:
        await _insert_columns(db, config_id, body.columns)
    if body.photo_checkpoints:
        await _insert_photo_checkpoints(db, config_id, body.photo_checkpoints)
    if body.prechecks:
        await _insert_prechecks(db, config_id, body.prechecks)
    if body.validation_rules:
        await _insert_validation_rules(db, config_id, body.validation_rules)
    if body.equipment:
        await _insert_equipment(db, config_id, body.equipment)


async def _insert_fields(db: AsyncSession, config_id: int, items: list[dict[str, Any]]) -> None:
    for i, f in enumerate(items):
        await db.execute(
            text("""
                INSERT INTO experiment_config_fields
                  (config_id, section_title, section_order, field_key, field_label,
                   field_type, field_default, field_options, is_required, is_readonly, is_actual, sort_order)
                VALUES (:cid, :st, :so, :fk, :fl, :ft, :fd, :fo, :ir, :iro, :ia, :srt)
            """),
            {
                "cid": config_id, "st": f.get("section_title", ""),
                "so": f.get("section_order", 1), "fk": f.get("field_key", f"field_{i}"),
                "fl": f.get("field_label", f"字段 {i+1}"), "ft": f.get("field_type", "text"),
                "fd": str(f.get("field_default", "")), "fo": str(f.get("field_options", "")),
                "ir": f.get("is_required", False), "iro": f.get("is_readonly", False),
                "ia": f.get("is_actual", False), "srt": f.get("sort_order", i),
            },
        )


async def _insert_columns(db: AsyncSession, config_id: int, items: list[dict[str, Any]]) -> None:
    for i, c in enumerate(items):
        ce = c.get("calc_expression")
        if isinstance(ce, (dict, list)):
            ce = json.dumps(ce, ensure_ascii=False)
        elif ce is None:
            ce = ""
        await db.execute(
            text("""
                INSERT INTO experiment_config_columns
                  (config_id, column_key, column_label, column_type, is_required,
                   column_default, calc_expression, calc_precision, sort_order)
                VALUES (:cid, :ck, :cl, :ct, :ir, :cd, :ce, :cp, :srt)
            """),
            {
                "cid": config_id, "ck": c.get("column_key", f"col_{i}"),
                "cl": c.get("column_label", f"列 {i+1}"), "ct": c.get("column_type", "number"),
                "ir": c.get("is_required", False), "cd": str(c.get("column_default", "")),
                "ce": ce, "cp": c.get("calc_precision", 3),
                "srt": c.get("sort_order", i),
            },
        )


async def _insert_photo_checkpoints(db: AsyncSession, config_id: int, items: list[dict[str, Any]]) -> None:
    for i, p in enumerate(items):
        await db.execute(
            text("""
                INSERT INTO experiment_config_photo_checkpoints
                  (config_id, checkpoint_code, checkpoint_label, is_required, is_sample_level, checkpoint_group, sort_order)
                VALUES (:cid, :cc, :cl, :ir, :isl, :cg, :srt)
            """),
            {
                "cid": config_id, "cc": p.get("checkpoint_code", f"photo_{i}"),
                "cl": p.get("checkpoint_label", f"拍照节点 {i+1}"),
                "ir": p.get("is_required", True), "isl": p.get("is_sample_level", False),
                "cg": p.get("checkpoint_group"), "srt": p.get("sort_order", i),
            },
        )


async def _insert_prechecks(db: AsyncSession, config_id: int, items: list[dict[str, Any]]) -> None:
    for i, p in enumerate(items):
        await db.execute(
            text("""
                INSERT INTO experiment_config_prechecks
                  (config_id, precheck_code, precheck_label, is_required, sort_order)
                VALUES (:cid, :pc, :pl, :ir, :srt)
            """),
            {
                "cid": config_id, "pc": p.get("precheck_code", f"precheck_{i}"),
                "pl": p.get("precheck_label", f"预检查项 {i+1}"),
                "ir": p.get("is_required", True), "srt": p.get("sort_order", i),
            },
        )


async def _insert_validation_rules(db: AsyncSession, config_id: int, items: list[dict[str, Any]]) -> None:
    for r in items:
        await db.execute(
            text("""
                INSERT INTO experiment_config_validation_rules
                  (config_id, rule_type, target_field, rule_value, error_message, is_row_level)
                VALUES (:cid, :rt, :tf, :rv, :em, :irl)
            """),
            {
                "cid": config_id, "rt": r.get("rule_type", "range"),
                "tf": r.get("target_field", ""), "rv": r.get("rule_value", ""),
                "em": r.get("error_message"), "irl": r.get("is_row_level", False),
            },
        )


async def _insert_equipment(db: AsyncSession, config_id: int, items: list[dict[str, Any]]) -> None:
    for i, e in enumerate(items):
        await db.execute(
            text("""
                INSERT INTO experiment_config_equipment
                  (config_id, management_no, binding_role, required, sort_order, note)
                VALUES (:cid, :mn, :br, :req, :srt, :nt)
            """),
            {
                "cid": config_id, "mn": e.get("management_no", ""),
                "br": e.get("binding_role", "primary"), "req": e.get("required", False),
                "srt": e.get("sort_order", i), "nt": e.get("note"),
            },
        )


# ── Template manifest ──
import re as _re
from pathlib import Path as _Path
from docx import Document as _Document

# kind → template code mapping
_KIND_TO_TEMPLATE_CODE = {
    "rough": "R001", "mc_crack": "R004", "xray": "R005",
    "warp": "R006", "cte": "R007", "shock": "R009",
    "bend": "R010", "hv": "R011", "color": "R012", "thickness": "R013",
    "fixed_denture": "R014", "removable_denture": "R015",
    "density": "R016", "tarnish": "R017",
}

_BLANK_PATTERN = _re.compile(r"[_]{2,}|\.{2,}")


def _contains_marker(text: str) -> bool:
    return any(m in text for m in ("□", "☐", "☑")) or bool(_BLANK_PATTERN.search(text))


def _infer_input_type(text: str) -> str:
    if "□" in text or "☐" in text or "☑" in text:
        return "checkbox"
    if _BLANK_PATTERN.search(text):
        return "text"
    return "text"


def _table_section_name(table, fallback: str) -> str:
    """Try to find a section name from the first row or preceding paragraph."""
    name = fallback
    if table.rows:
        first = table.rows[0]
        cell_texts = []
        for cell in first.cells:
            txt = cell.text.strip()
            if txt and not txt.startswith("□") and not _BLANK_PATTERN.search(txt):
                cell_texts.append(txt)
        if cell_texts:
            name = " — ".join(cell_texts[:2])
    return name


def _resolve_template_path(experiment_code: str, template_name: str | None = None) -> _Path | None:
    """解析模板 DOCX 绝对路径：显式 template_name 优先，否则按 kind→模板代码扫描。"""
    from app.config import Settings
    settings = Settings()
    template_dir = _Path(settings.TEMPLATE_DIR)
    if not template_dir.exists():
        return None

    # 显式指定文件名（含或不含 .docx）
    if template_name:
        direct = template_dir / template_name
        if direct.exists() and direct.suffix == ".docx":
            return direct
        if not direct.suffix:
            candidate = _Path(str(direct) + ".docx")
            if candidate.exists():
                return candidate
        # 前缀匹配
        prefix = template_name[:-5] if template_name.endswith(".docx") else template_name
        for f in template_dir.iterdir():
            if f.suffix == ".docx" and f.name.startswith(prefix):
                return f
        return None

    # 未指定：按 kind → 模板代码扫描（RECORD 优先，SOP 兜底）
    kind = _resolve_kind(experiment_code)
    if kind is None:
        kind = experiment_code
    template_code = _KIND_TO_TEMPLATE_CODE.get(kind, kind)
    rec_patterns = [f"RECORD_{template_code}", f"{template_code}_", f"{template_code}."]
    sop_patterns = [f"SOP_{template_code}"]
    if template_code != experiment_code:
        rec_patterns.insert(0, f"RECORD_{experiment_code}")
        rec_patterns.append(f"{experiment_code}_")
        rec_patterns.append(f"{experiment_code}.")
        sop_patterns.append(f"SOP_{experiment_code}")
    for f in template_dir.iterdir():
        if f.suffix != ".docx":
            continue
        if any(f.name.startswith(p) for p in rec_patterns):
            return f
    for f in template_dir.iterdir():
        if f.suffix != ".docx":
            continue
        if any(f.name.startswith(p) for p in sop_patterns):
            return f
    return None


def _parse_template_docx(path: _Path) -> list[dict[str, Any]]:
    """解析模板 DOCX，返回含坐标/标签/输入类型的填空与勾选框清单。"""
    doc = _Document(str(path))
    fields: list[dict[str, Any]] = []
    for table_idx, table in enumerate(doc.tables):
        section = _table_section_name(table, f"表{table_idx + 1}")
        seen_cells = set()
        for row_idx, row in enumerate(table.rows):
            for col_idx, cell in enumerate(row.cells):
                if cell._tc in seen_cells:
                    continue
                seen_cells.add(cell._tc)
                text = cell.text.strip()
                if not _contains_marker(text):
                    continue
                label = f"{section}-R{row_idx + 1}C{col_idx + 1}"
                row_label = ""
                for c in row.cells[:col_idx]:
                    ct = c.text.strip()
                    if ct and not _contains_marker(ct):
                        row_label = ct
                        break
                if row_label:
                    label = row_label
                fields.append({
                    "key": f"t{table_idx}_r{row_idx}_c{col_idx}",
                    "section": section,
                    "label": label,
                    "position": f"表{table_idx + 1}-R{row_idx + 1}C{col_idx + 1}",
                    "template_text": text,
                    "input_type": _infer_input_type(text),
                    "table": table_idx,
                    "row": row_idx,
                    "col": col_idx,
                })
    return fields


def _checkbox_selection(text: str) -> str:
    """从勾选框单元格文本提取选项文案（去 □/☐/☑ 符号后拼接）。"""
    parts = [p.strip() for p in _re.split(r"[□☐☑]", text) if p.strip()]
    return " ".join(parts)


@router.get("/{experiment_code}/template-manifest")
async def get_template_manifest(experiment_code: str):
    """Return template supplement fields for the given experiment code.

    严格对齐原始记录模板：复用受控记录引擎 record_word_engine.template_manifest 作为唯一权威解析，
    使 ⑤ 母版过程确认的字段、章节名（段落标题）、row_label/col_header、空白标记（＿/…）与导出 DOCX 完全一致。
    """
    from app.services.record_word_engine import template_manifest
    actual_path = _resolve_template_path(experiment_code)
    if not actual_path or not actual_path.exists():
        return {"fields": [], "template_name": None, "note": "未找到模板文件，请上传受控原始记录模板"}
    try:
        fields = template_manifest(actual_path)
        return {
            "fields": fields,
            "template_name": actual_path.name,
            "count": len(fields),
        }
    except Exception as e:
        return {"fields": [], "template_name": str(actual_path.name), "error": str(e)}


class MatchLabelRequest(BaseModel):
    label: str


@router.post("/{experiment_code}/match-label")
async def match_label(
    experiment_code: str,
    body: MatchLabelRequest,
    current_user: Annotated[dict, Depends(require_role("管理员"))],
):
    """配置编辑器「标签 → 编码 + 模板坐标」匹配（逐格解析真实模板）。

    给定一个标签（如「检测前温度」），在真实模板 DOCX 中按归一化标签精确/包含匹配
    一个 manifest 字段，返回其坐标与同义词命中的业务 field_key。未命中坐标时
    `matched=false`，仍返回 `field_key`（若词库命中）供管理员人工补坐标。
    """
    label = (body.label or "").strip()
    if not label:
        return {"matched": False, "field_key": None, "label": "", "reason": "标签为空"}

    actual_path = _resolve_template_path(experiment_code)
    if not actual_path or not actual_path.exists():
        return {
            "matched": False, "field_key": None, "label": label,
            "reason": "未找到模板文件，请先上传受控原始记录模板",
        }

    norm = normalize_label(label)
    fields = _parse_template_docx(actual_path)

    best = None
    if norm:
        for f in fields:
            if normalize_label(f["label"]) == norm:
                best = f
                break
    if best is None and norm:
        for f in fields:
            fl = normalize_label(f["label"])
            if fl and (norm in fl or fl in norm):
                best = f
                break

    fk = match_field_key(norm or label)

    if best is not None:
        return {
            "matched": True,
            "field_key": fk,
            "label": best["label"],
            "position": best["position"],
            "table": best["table"],
            "row": best["row"],
            "col": best["col"],
            "input_type": best["input_type"],
            "synonym_hit": bool(fk),
            "template_name": actual_path.name,
        }

    return {
        "matched": False,
        "field_key": fk,
        "label": label,
        "position": None,
        "table": None,
        "row": None,
        "col": None,
        "input_type": "text",
        "synonym_hit": bool(fk),
        "template_name": actual_path.name,
        "reason": "未在模板中匹配到该标签，请确认标签或手动填写编码/坐标",
    }


# ── 模板自动匹配向导（任务三 P4）──

class AutoMapField(BaseModel):
    table: int = 0
    row: int = 0
    col: int = 0
    label: str = ""
    section: str = ""
    input_type: str = "text"
    field_key: str = ""


class AutoMapRequest(BaseModel):
    template_name: str | None = None
    apply: bool = False
    fields: list[AutoMapField] | None = None


@router.post("/{experiment_code}/versions/{version}/auto-map")
async def auto_map_template(
    experiment_code: str,
    version: str,
    body: AutoMapRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[dict, Depends(require_role("管理员"))],
):
    """模板自动匹配向导：解析模板 DOCX → 同义词匹配 → 生成字段与坐标映射。

    - `apply=false`（预览）：返回解析结果（含 `matched` 标记），不写库。
    - `apply=true`（提交）：按 `fields`（可人工修正 field_key）覆盖写
      `experiment_config_fields` + `template_field_mappings`。

    仅「静态单元格」能自动匹配；动态行/判定逻辑/阈值仍由管理员在编辑器人工补录。
    """
    cfg = await db.execute(
        text("SELECT id, status FROM experiment_config_versions WHERE experiment_code=:ec AND version=:v"),
        {"ec": experiment_code, "v": version},
    )
    row = cfg.fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="配置版本不存在")
    config_id, current_status = row[0], row[1]
    if current_status not in ("草稿", "现行"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"仅草稿/现行状态可自动匹配，当前状态：{current_status}",
        )

    # 模板路径：显式 template_name 优先，否则 extra_json.record_template_file，最后按 kind 扫描
    erow = await db.execute(
        text("SELECT extra_json FROM experiment_config_versions WHERE id=:cid"), {"cid": config_id}
    )
    er = erow.fetchone()
    extra = er[0] if er and isinstance(er[0], dict) else {}
    template_name = body.template_name or ((extra or {}).get("record_template_file") or "")
    actual_path = _resolve_template_path(experiment_code, template_name or None)
    if not actual_path or not actual_path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="未找到模板文件，请先上传受控原始记录模板")

    # 构建带 field_key 的字段列表（预览用；提交时直接取 body.fields）
    if body.fields:
        field_rows = [f.model_dump() for f in body.fields]
    else:
        parsed = _parse_template_docx(actual_path)
        field_rows = []
        for i, f in enumerate(parsed):
            fk = match_field_key(f["label"])
            field_rows.append({
                "table": f["table"], "row": f["row"], "col": f["col"],
                "label": f["label"], "section": f["section"],
                "input_type": f["input_type"], "template_text": f["template_text"],
                "field_key": fk or f"field_{i + 1}",
                "matched": bool(fk),
            })

    # 预览：不写库
    if not body.apply:
        matched_count = sum(1 for f in field_rows if f.get("matched"))
        return {
            "template_name": actual_path.name,
            "count": len(field_rows),
            "matched_count": matched_count,
            "unmatched_count": len(field_rows) - matched_count,
            "fields": field_rows,
        }

    # 提交：重解析模板用于勾选框文案，覆盖写字段 + 坐标映射
    text_by_pos = {(f["table"], f["row"], f["col"]): f["template_text"] for f in _parse_template_docx(actual_path)}

    await db.execute(text("DELETE FROM experiment_config_fields WHERE config_id=:cid"), {"cid": config_id})
    await db.execute(text("DELETE FROM template_field_mappings WHERE config_id=:cid"), {"cid": config_id})

    for i, f in enumerate(field_rows):
        fk = (f.get("field_key") or "").strip() or f"field_{i + 1}"
        label = f.get("label") or ""
        section = f.get("section") or ""
        input_type = f.get("input_type") or "text"
        table_idx = int(f.get("table", 0))
        row_idx = int(f.get("row", 0))
        col_idx = int(f.get("col", 0))

        await db.execute(
            text("""
                INSERT INTO experiment_config_fields
                  (config_id, section_title, section_order, field_key, field_label,
                   field_type, field_default, field_options, is_required, is_readonly, is_actual, sort_order)
                VALUES (:cid, :st, :so, :fk, :fl, :ft, '', '', FALSE, FALSE, FALSE, :srt)
            """),
            {
                "cid": config_id, "st": section, "so": table_idx + 1, "fk": fk,
                "fl": label, "ft": "checkbox" if input_type == "checkbox" else "text",
                "srt": i,
            },
        )

        transform = "checkbox" if input_type == "checkbox" else "text"
        selection = _checkbox_selection(text_by_pos.get((table_idx, row_idx, col_idx), "")) if input_type == "checkbox" else ""
        await db.execute(
            text("""
                INSERT INTO template_field_mappings
                  (config_id, field_source, field_key, template_name,
                   table_index, row_index, col_index, transform, checkbox_selection, sort_order)
                VALUES (:cid, 'static', :fk, :tn, :ti, :ri, :ci, :tr, :sel, :srt)
            """),
            {
                "cid": config_id, "fk": fk, "tn": actual_path.name,
                "ti": table_idx, "ri": row_idx, "ci": col_idx,
                "tr": transform, "sel": selection, "srt": i,
            },
        )

    return {
        "message": "自动匹配完成",
        "config_id": config_id,
        "fields_written": len(field_rows),
        "template_name": actual_path.name,
    }
