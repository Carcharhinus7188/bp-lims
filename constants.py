# -*- coding: utf-8 -*-
from __future__ import annotations

COMPANY_CN = "大连标普检测有限公司"
COMPANY_EN = "DALIAN BIAOPU TESTING CO., LTD."
SYSTEM_CN = "大连标普实验室样品全过程追溯系统"
SYSTEM_EN = "BPLab Sample Lifecycle Tracking System"
APP_VERSION = "BPLab Trace V9.4.2 任务包接收修复版"
TIMEZONE_NAME = "Asia/Shanghai"

STORAGE_AREAS = ["A区域", "B区域"]
SAMPLE_CONDITIONS = ["完好", "不完好"]
RETURN_CONDITIONS = ["完好", "部分消耗", "已破坏", "全部消耗"]

DETECTION_LOCATIONS = [
    "化学室",
    "无损检测室",
    "性能检测室",
    "显微检测室",
    "制样室",
    "外观检测室",
    "样品室",
]

# 实验员接收任务时，系统按实际检测地点自动锁定唯一温湿度计。
# 制样室尚未提供受控设备编号，因此不做推测性匹配。
LAB_TEMPERATURE_HUMIDITY_EQUIPMENT = {
    "显微检测室": "BPGL-A013",
    "性能检测室": "BPGL-A009",
    "无损检测室": "BPGL-A011",
    "化学室": "BPGL-A014",
    "样品室": "BPGL-A015",
    "外观检测室": "BPGL-A010",
}
TEMPERATURE_HUMIDITY_EQUIPMENT_NOS = {
    f"BPGL-A{index:03d}" for index in range(9, 17)
}


EQUIPMENT_LIFECYCLE_STATUSES = ["启用", "停用", "维修", "报废"]
CONFIG_STATUSES = ["草稿", "现行", "历史"]

ATTACHMENT_TYPES = [
    "设备原始数据文件", "仪器曲线文件", "X射线原始图像",
    "校准/核查文件", "其他原始文件",
]

# 现场照片只能由任务页的平板相机产生。每个节点至少保留一张有效照片；
# 重拍不会覆盖旧照片，只会把旧照片标记为“已替代”。
# CMA要求：温湿度、设备铭牌、状态照等为"证明做了实验"类照片，不强制；
# 只有图像直接参与数值计算或SOP明确规定时才强制留存。
COMMON_PHOTO_CHECKPOINTS = [
    ("ENV", "实验开始温湿度表", False),
    ("SAMPLE_BEFORE", "实验前样品及标签", False),
    ("DEVICE", "设备编号/铭牌", False),
    ("PARAMETERS", "设备参数或软件数据界面", False),
    ("SETUP", "样品安装、装夹或放置状态", False),
    ("RESULT", "最终读数、曲线或结果界面", False),
    ("SAMPLE_AFTER", "实验结束后样品状态", False),
    ("REPORT_PHOTO", "检验报告照片区域用代表性照片", False),
]

# 只有这些节点确实描述单件样品状态，才允许关联实体样品。
# 温湿度表、设备铭牌、软件参数、夹具和结果界面均按整个实验任务留档一次。
SAMPLE_LEVEL_PHOTO_CODES = {
    "SAMPLE_BEFORE", "SAMPLE_AFTER", "DAMAGE",
    "MC_K_VALUE",
    "MEASURE_RESULT", "FINAL_CURVE", "OBSERVER_RESULT", "H1_BASELINE", "H2_BASELINE", "ROI",
    "ROUGH_POINT_1", "ROUGH_POINT_2", "ROUGH_POINT_3", "CTE_PARAMETERS", "COLOR_BEFORE", "COLOR_AFTER", "SHOCK_BEFORE", "SHOCK_AFTER",
    "FIXED_DIST_1", "FIXED_DIST_2", "FIXED_DIST_3",
    "MID_DIST_1", "MID_DIST_2", "MID_DIST_3",
    "FREE_END_1", "FREE_END_2", "FREE_END_3",
}

# 确定报告结论时真正使用的结果证据。报告生成器按此顺序选图，
# REPORT_PHOTO 只作为人工补充，不再是报告照片的唯一来源。
REPORT_DECISIVE_PHOTO_CODES = {
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
}

# 拍摄提示词：指导实验员如何正确拍摄每个节点。
# 未列出节点使用 checkpoint_label 作为默认说明。
CAMERA_HINTS = {
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
}

EXPERIMENT_PHOTO_CHECKPOINTS = {
    "表面粗糙度试验": [
        ("ROUGH_POINT_1", "测量点①拍照", True),
        ("ROUGH_POINT_2", "测量点②拍照", True),
        ("ROUGH_POINT_3", "测量点③拍照", True),
        ("ROUGH_CURVE_RESULT", "测量曲线、计算设置与结果界面", True),
    ],
    "金属-陶瓷结合裂纹萌生试验": [
        ("MC_K_VALUE", "试样K值拍照", True),
        ("MC_REPORT", "报告拍照", True),
    ],
    "金属内部质量X射线灰度分析": [
        ("IQI_POSITION", "样品与孔形像质计摆放", False),
        ("EXPOSURE", "曝光参数界面", False),
        ("RADIOGRAPH", "原始X射线成像画面", True),
        ("ROI", "ROI位置及灰度值", True),
    ],
    "翘曲变形试验": [
        ("H1_BASELINE", "切割前基准线到自由端中点距离", True),
        ("H2_BASELINE", "切割后基准线到自由端中点距离", True),
        ("WARP_REPORT_1", "试验报告拍照①", True),
        ("WARP_REPORT_2", "试验报告拍照②", True),
        ("WARP_REPORT_3", "试验报告拍照③", True),
    ],
    "热膨胀系数试验": [
        ("CTE_PARAM_SET", "试验参数设定拍照", True),
        ("CTE_REPORT", "样品试验报告拍照", True),
    ],
    "陶瓷牙耐急冷急热试验": [
        ("SHOCK_BEFORE", "试验前试样拍照", True),
        ("SHOCK_AFTER", "试验后试样拍照", True),
        ("OVEN_TEMP", "烘箱100±2℃实测温度", False),
        ("ICE_TEMP_START", "试验前冰水1±1℃温度", False),
        ("ICE_TEMP_PROCESS", "试验中每15分钟冰水复测读数", False),
        ("FIRST_HEAT", "第一次加热开始/结束时间与温度", False),
        ("TRANSFER_COLD", "急冷转移、浸没状态与时间", False),
        ("SECOND_HEAT", "第二次加热时间与温度", False),
        ("COOL_TEMP", "自然冷却后样品表面23±2℃", False),
        ("INSPECTION_LIGHT", "外观检查光照度≥1000 lx", False),
        ("DAMAGE", "逐颗裂纹、崩瓷或破损检查结果", False),
    ],
    "弯曲性能试验": [
        ("BEND_REPORT", "报告拍照", True),
    ],
    "维氏硬度试验": [
        ("HV_LOAD_TIME", "载荷和保荷时间", True),
        ("HV_REPORT_1", "报告拍照①", True),
        ("HV_REPORT_2", "报告拍照②", True),
    ],
    "增材制造金属试样厚度测量": [
        ("FIXED_DIST_1", "固定端距离拍照①", True),
        ("FIXED_DIST_2", "固定端距离拍照②", True),
        ("FIXED_DIST_3", "固定端距离拍照③", True),
        ("MID_DIST_1", "中间距离拍照①", True),
        ("MID_DIST_2", "中间距离拍照②", True),
        ("MID_DIST_3", "中间距离拍照③", True),
        ("FREE_END_1", "自由端拍照①", True),
        ("FREE_END_2", "自由端拍照②", True),
        ("FREE_END_3", "自由端拍照③", True),
        ("THICK_REPORT", "报告拍照", True),
    ],
    "牙科材料色稳定性试验": [
        ("COLOR_BEFORE", "试验前试样拍照", True),
        ("COLOR_AFTER", "试验后试样拍照", True),
    ],
}


def photo_checkpoints(experiment_name: str):
    # 粗糙度与热膨胀按最新受控流程使用精简后的专属节点，
    # 不再叠加温湿度、设备铭牌、装夹、实验后状态等通用照片。
    if experiment_name in {
        "表面粗糙度试验", "金属-陶瓷结合裂纹萌生试验",
        "热膨胀系数试验", "维氏硬度试验", "增材制造金属试样厚度测量",
        "弯曲性能试验",
    }:
        return EXPERIMENT_PHOTO_CHECKPOINTS.get(experiment_name, [])
    return COMMON_PHOTO_CHECKPOINTS + EXPERIMENT_PHOTO_CHECKPOINTS.get(experiment_name, [])

# 与当前受控《检验委托单》保持一致，仅使用已批准的方法选项。
METHOD_OPTIONS = [
    "YY/T 1936", "YY 0300", "YY 0621.1", "YY 0621.2", "YY/T 1702",
    "GB 17168", "GB/T 4340.1", "GB/T 3851", "GB/T 18876.1",
    "YY/T 1937", "YY 0270.1", "T/GDMDMA 0003", "YY 0710",
]

# 用户界面只显示“实验名称｜检测方法”。
# key仅用于数据库内部关联，不在界面、任务编号、原始记录或报告中显示。
EXPERIMENTS = {
    "表面粗糙度试验": {
        "key": "I001", "category": "增材制造检测",
        "std": "YY/T 1702-2020；GB/T 10610-2009",
        "method": "YY/T 1702", "kind": "rough",
        "template": "RECORD_R001_ROUGHNESS.docx", "sop": "SOP_R001_ROUGHNESS.docx",
    },
    "金属-陶瓷结合裂纹萌生试验": {
        "key": "I002", "category": "力学性能检测",
        "std": "YY 0621.1-2016 / ISO 9693-1",
        "method": "YY 0621.1", "kind": "mc_crack",
        "template": "RECORD_R004_MC_CRACK.docx",
        "sop": "SOP_R004_MC_CRACK.docx",
    },
    "金属内部质量X射线灰度分析": {
        "key": "I003", "category": "内部质量检测",
        "std": "GB 17168及实验室受控SOP",
        "method": "GB 17168", "kind": "xray",
        "template": "RECORD_R005_XRAY.docx",
        "sop": "SOP_R005_XRAY.docx",
    },
    "翘曲变形试验": {
        "key": "I004", "category": "增材制造检测",
        "std": "YY/T 1702-2020 第7.3.2条",
        "method": "YY/T 1702", "kind": "warp",
        "template": "RECORD_R006_WARPAGE.docx", "sop": "SOP_R006_WARPAGE.docx",
    },
    "热膨胀系数试验": {
        "key": "I005", "category": "物理性能检测",
        "std": "YY 0621.1及实验室受控SOP",
        "method": "YY 0621.1", "kind": "cte",
        "template": "RECORD_R007_CTE.docx", "sop": "SOP_R007_CTE.docx",
    },
    "陶瓷牙耐急冷急热试验": {
        "key": "I006", "category": "陶瓷材料检测",
        "std": "YY 0300-2009 第7.10条",
        "method": "YY 0300", "kind": "shock",
        "template": "RECORD_R009_THERMAL_SHOCK.docx",
        "sop": "SOP_R009_THERMAL_SHOCK.docx",
    },
    "弯曲性能试验": {
        "key": "I007", "category": "力学性能检测",
        "std": "YY/T 1702-2020",
        "method": "YY/T 1702", "kind": "bend",
        "template": "RECORD_R010_BENDING.docx", "sop": "SOP_R010_BENDING.docx",
    },
    "维氏硬度试验": {
        "key": "I008", "category": "力学性能检测",
        "std": "GB/T 4340.1-2024",
        "method": "GB/T 4340.1", "kind": "hv",
        "template": "RECORD_R011_VICKERS.docx", "sop": "SOP_R011_VICKERS.docx",
    },
    "增材制造金属试样厚度测量": {
        "key": "I009", "category": "增材制造检测",
        "std": "YY/T 1702-2020",
        "method": "YY/T 1702", "kind": "thickness",
        "template": "R013_增材制造金属试样厚度测量_CMA原始记录表.docx", "sop": "SOP_R013_THICKNESS.docx",
    },
    "牙科材料色稳定性试验": {
        "key": "I010", "category": "物理性能检测",
        "std": "YY 0710及产品技术要求",
        "method": "YY 0710", "kind": "color",
        "template": "RECORD_R012_COLOR_STABILITY.docx",
        "sop": "SOP_R012_COLOR_STABILITY.docx",
    },
}

def experiment_display(experiment_name: str) -> str:
    cfg = EXPERIMENTS.get(experiment_name, {})
    method = cfg.get("method", "")
    return f"{experiment_name}｜{method}" if method else experiment_name

ROLES = ["管理员", "样品管理员", "实验员", "复核员", "质量负责人"]

ROLE_MENUS = {
    "管理员": [
        "首页看板", "单位信息库", "检测项目与方法库", "样品资料库",
        "委托与样品管理", "附件与内部追溯", "一键下载", "单据中心", "报告中心",
        "客户异议", "报告发放登记", "设备故障处置", "修改中心", "修改日志", "SOP与模板版本",
        "实验配置版本", "设备库", "电子签名", "用户与权限", "审计追踪", "系统初始化",
    ],
    "样品管理员": [
        "首页看板", "单位信息库", "样品资料库", "新建委托与入库",
        "委托与样品管理", "任务包分配", "回库确认",
        "附件与内部追溯", "一键下载", "单据中心", "报告发放登记", "客户异议", "设备故障处置",
    ],
    "实验员": [
        "首页看板", "我的任务包", "实验记录", "样品归还",
        "危废处理", "设备故障处置", "附件与内部追溯", "一键下载", "单据中心", "修改中心", "修改日志",
    ],
    "复核员": [
        "首页看板", "原始记录复核", "设备故障处置", "附件与内部追溯",
        "一键下载", "单据中心", "修改中心", "修改日志",
    ],
    "质量负责人": [
        "首页看板", "报告中心", "客户异议", "设备故障处置", "附件与内部追溯",
        "一键下载", "单据中心", "修改中心", "修改日志",
    ],
}

ROLE_NAV_GROUPS = {
    "管理员": [
        ("工作台", ["首页看板", "报告中心", "客户异议", "报告发放登记", "设备故障处置"]),
        ("业务与追溯", ["委托与样品管理", "单据中心", "一键下载", "附件与内部追溯", "修改中心", "修改日志"]),
        ("基础配置", ["单位信息库", "检测项目与方法库", "样品资料库", "SOP与模板版本", "实验配置版本", "设备库"]),
        ("系统管理", ["电子签名", "用户与权限", "审计追踪", "系统初始化"]),
    ],
    "样品管理员": [
        ("工作台", ["首页看板", "新建委托与入库", "任务包分配", "回库确认"]),
        ("业务处理", ["委托与样品管理", "报告发放登记", "客户异议", "设备故障处置"]),
        ("资料与追溯", ["单位信息库", "样品资料库", "附件与内部追溯", "一键下载", "单据中心"]),
    ],
    "实验员": [
        ("工作台", ["首页看板", "我的任务包", "实验记录", "样品归还"]),
        ("业务处理", ["危废处理", "设备故障处置", "修改中心"]),
        ("资料与追溯", ["附件与内部追溯", "一键下载", "单据中心", "修改日志"]),
    ],
    "复核员": [
        ("工作台", ["首页看板", "原始记录复核", "设备故障处置", "修改中心"]),
        ("资料与追溯", ["附件与内部追溯", "一键下载", "单据中心", "修改日志"]),
    ],
    "质量负责人": [
        ("工作台", ["首页看板", "报告中心", "客户异议", "设备故障处置"]),
        ("资料与追溯", ["附件与内部追溯", "一键下载", "单据中心", "修改中心", "修改日志"]),
    ],
}

NAV_ICONS = {
    "首页看板": "◫", "报告中心": "▤", "客户异议": "◇", "报告发放登记": "⇧",
    "委托与样品管理": "▦", "单据中心": "▱", "一键下载": "↓", "附件与内部追溯": "⌁",
    "修改中心": "✎", "修改日志": "≡", "单位信息库": "⌂", "检测项目与方法库": "⌘",
    "样品资料库": "◈", "SOP与模板版本": "▧", "实验配置版本": "⚙", "设备库": "▣",
    "电子签名": "✒", "用户与权限": "♙", "审计追踪": "◎", "系统初始化": "↻",
    "新建委托与入库": "＋", "任务包分配": "⇢", "回库确认": "✓",
    "我的任务包": "▥", "实验记录": "⌗", "样品归还": "↩", "危废处理": "△",
    "原始记录复核": "◉", "设备故障处置": "⚠",
}
