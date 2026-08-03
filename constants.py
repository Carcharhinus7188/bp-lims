# -*- coding: utf-8 -*-
from __future__ import annotations

COMPANY_CN = "大连标普检测有限公司"
COMPANY_EN = "DALIAN BIAOPU TESTING CO., LTD."
SYSTEM_CN = "大连标普实验室样品全过程追溯系统"
SYSTEM_EN = "BPLab Sample Lifecycle Tracking System"
APP_VERSION = "BPLab Trace V6.0 流程重构演示版"
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


EQUIPMENT_LIFECYCLE_STATUSES = ["启用", "停用", "维修", "报废"]
CONFIG_STATUSES = ["草稿", "现行", "历史"]

ATTACHMENT_TYPES = [
    "设备原始数据文件", "仪器曲线文件", "X射线原始图像",
    "校准/核查文件", "其他原始文件",
]

# 现场照片只能由任务页的平板相机产生。每个节点至少保留一张有效照片；
# 重拍不会覆盖旧照片，只会把旧照片标记为“已替代”。
COMMON_PHOTO_CHECKPOINTS = [
    ("ENV", "实验开始温湿度表", True),
    ("SAMPLE_BEFORE", "实验前样品及标签", True),
    ("DEVICE", "设备编号/铭牌", True),
    ("PARAMETERS", "设备参数或软件数据界面", True),
    ("SETUP", "样品安装、装夹或放置状态", True),
    ("RESULT", "最终读数、曲线或结果界面", True),
    ("SAMPLE_AFTER", "实验结束后样品状态", True),
]

EXPERIMENT_PHOTO_CHECKPOINTS = {
    "表面粗糙度试验": [
        ("REFERENCE_CHECK", "标准样块核查读数", True),
        ("STYLUS_POSITION", "触针与试样测量位置", True),
        ("PROFILE", "轮廓曲线及Ra结果", True),
    ],
    "金属-陶瓷结合裂纹萌生试验": [
        ("SPAN_FIXTURE", "三点弯曲夹具和跨距", True),
        ("K_FACTOR", "K系数取值依据", True),
        ("FASTTEST_RESULT", "FastTest的Ffail、k和τb结果界面", True),
        ("CRACK", "裂纹萌生或陶瓷剥离状态", True),
    ],
    "金属内部质量X射线灰度分析": [
        ("IQI_POSITION", "样品与孔形像质计摆放", True),
        ("EXPOSURE", "曝光参数界面", True),
        ("RADIOGRAPH", "原始X射线成像画面", True),
        ("ROI", "ROI位置及灰度值", True),
    ],
    "翘曲变形试验": [
        ("H1", "切割前H1测量界面", True),
        ("CUTTING", "切割装夹和切割后状态", True),
        ("H2", "切割后H2测量界面", True),
    ],
    "热膨胀系数试验": [
        ("SPECIMEN_LENGTH", "试样实际长度及软件输入值", True),
        ("PV_STABLE", "启动前PV值稳定在50～60", True),
        ("CTE_PROGRAM", "终止温度550℃等升温参数", True),
        ("CTE_CURVE", "温度-位移曲线及计算结果", True),
    ],
    "陶瓷牙耐急冷急热试验": [
        ("OVEN_TEMP", "烘箱100±2℃实测温度", True),
        ("ICE_TEMP_START", "试验前冰水1±1℃温度", True),
        ("ICE_TEMP_PROCESS", "试验中每15分钟冰水复测读数", True),
        ("FIRST_HEAT", "第一次加热开始/结束时间与温度", True),
        ("TRANSFER_COLD", "急冷转移、浸没状态与时间", True),
        ("SECOND_HEAT", "第二次加热时间与温度", True),
        ("COOL_TEMP", "自然冷却后样品表面23±2℃", True),
        ("INSPECTION_LIGHT", "外观检查光照度≥1000 lx", True),
        ("DAMAGE", "逐颗裂纹、崩瓷或破损检查结果", True),
    ],
    "弯曲性能试验": [
        ("SENSOR_FACTOR", "传感器校准系数和主机参数", True),
        ("SPAN_FIXTURE", "夹具跨距和试样装夹", True),
        ("DEFLECTOMETER", "挠度计接触与测量状态", True),
        ("ZERO_FORCE", "清零后力值", True),
        ("FORCE_CURVE", "力-位移曲线及Fmax", True),
        ("FRACTURE", "断裂状态", True),
    ],
    "维氏硬度试验": [
        ("SURFACE", "试样表面状态/粗糙度确认", True),
        ("HARDNESS_BLOCK", "标准硬度块核查结果", True),
        ("LOAD_DWELL", "试验力与保持时间参数", True),
        ("INDENT", "各测试面有效压痕及软件测量结果", True),
    ],
    "增材制造金属试样厚度测量": [
        ("GAUGE_BLOCK", "标准量块核查界面", True),
        ("MEASURE_POSITION", "试样固定及测点位置", True),
        ("MEASURE_RESULT", "各截面测量图像和实测值", True),
    ],
    "牙科材料色稳定性试验": [
        ("COVER", "试样遮盖方式", True),
        ("WATER_LEVEL", "试样安装和水位", True),
        ("START_DISPLAY", "开始时温度、照度和时间", True),
        ("END_DISPLAY", "结束时温度、照度和时间", True),
        ("D65_COMPARE", "D65环境下色泽比较状态", True),
        ("OBSERVER_RESULT", "三名观察者独立比较结果", True),
    ],
}


def photo_checkpoints(experiment_name: str):
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
        "template": "RECORD_R013_THICKNESS.docx", "sop": "SOP_R013_THICKNESS.docx",
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

ROLES = ["管理员", "样品管理员", "实验员", "复核员", "质量检测员"]

ROLE_MENUS = {
    "管理员": [
        "首页看板", "单位信息库", "检测项目与方法库", "样品资料库",
        "委托与样品管理", "附件与内部追溯", "单据中心", "报告中心",
        "客户异议", "报告发放登记", "修改追踪", "SOP与模板版本",
        "实验配置版本", "设备库", "电子签名", "用户与权限", "审计追踪",
    ],
    "样品管理员": [
        "首页看板", "单位信息库", "样品资料库", "新建委托与入库",
        "委托与样品管理", "任务包分配", "回库确认",
        "附件与内部追溯", "单据中心", "报告发放登记", "客户异议",
    ],
    "实验员": [
        "首页看板", "我的任务包", "实验记录", "样品归还",
        "附件与内部追溯", "单据中心", "修改追踪",
    ],
    "复核员": [
        "首页看板", "原始记录复核", "附件与内部追溯",
        "单据中心", "修改追踪",
    ],
    "质量检测员": [
        "首页看板", "报告中心", "客户异议", "附件与内部追溯",
        "单据中心", "修改追踪",
    ],
}
