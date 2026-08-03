# -*- coding: utf-8 -*-
from __future__ import annotations
from datetime import datetime, timedelta, date
from pathlib import Path
from zoneinfo import ZoneInfo
from typing import Any, Iterable
import base64, calendar, hashlib, json, os, re, secrets, sqlite3

ROOT = Path(__file__).parent
DB_PATH = ROOT / "data" / "bplab_trace_v56.db"
ATTACHMENT_DIR = ROOT / "data" / "attachments"
SIGNATURE_DIR = ROOT / "data" / "signatures"
CHINA_TZ = ZoneInfo("Asia/Shanghai")


def china_now() -> datetime:
    return datetime.now(CHINA_TZ).replace(tzinfo=None)


def china_today() -> date:
    return china_now().date()


def now() -> str:
    return china_now().isoformat(timespec="seconds")


def add_months_to_date(value: date | str, months: int = 1) -> date:
    if isinstance(value, str):
        value = date.fromisoformat(value)
    total = value.year * 12 + value.month - 1 + months
    year, month_idx = divmod(total, 12)
    month = month_idx + 1
    day = min(value.day, calendar.monthrange(year, month)[1])
    return value.replace(year=year, month=month, day=day)


class ClosingConnection(sqlite3.Connection):
    """Commit/rollback like sqlite3.Connection and always release the file handle."""

    def __exit__(self, exc_type, exc_value, traceback):
        try:
            return super().__exit__(exc_type, exc_value, traceback)
        finally:
            self.close()


def connect() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    ATTACHMENT_DIR.mkdir(parents=True, exist_ok=True)
    SIGNATURE_DIR.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(DB_PATH, factory=ClosingConnection)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA foreign_keys=ON")
    return c


def rows(sql: str, args: Iterable[Any] = ()) -> list[dict[str, Any]]:
    with connect() as c:
        return [dict(x) for x in c.execute(sql, tuple(args)).fetchall()]


def one(sql: str, args: Iterable[Any] = ()) -> dict[str, Any] | None:
    with connect() as c:
        r = c.execute(sql, tuple(args)).fetchone()
    return dict(r) if r else None


def _password_hash(password: str) -> str:
    salt = secrets.token_bytes(16)
    iterations = 240_000
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iterations)
    return f"pbkdf2_sha256${iterations}${base64.b64encode(salt).decode()}${base64.b64encode(digest).decode()}"


def _password_verify(password: str, encoded: str) -> bool:
    try:
        method, iterations, salt_b64, digest_b64 = encoded.split("$", 3)
        if method != "pbkdf2_sha256":
            return False
        digest = hashlib.pbkdf2_hmac(
            "sha256", password.encode("utf-8"), base64.b64decode(salt_b64), int(iterations)
        )
        return secrets.compare_digest(base64.b64encode(digest).decode(), digest_b64)
    except Exception:
        return False


def init_db() -> None:
    with connect() as c:
        c.executescript(
            """
CREATE TABLE IF NOT EXISTS users(
  username TEXT PRIMARY KEY, display_name TEXT NOT NULL, password_hash TEXT NOT NULL,
  role TEXT NOT NULL, enabled INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS sessions(
  token TEXT PRIMARY KEY, username TEXT NOT NULL, expires_at TEXT NOT NULL, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS organizations(
  id INTEGER PRIMARY KEY AUTOINCREMENT, org_code TEXT UNIQUE, org_name TEXT NOT NULL UNIQUE,
  short_name TEXT, is_client INTEGER DEFAULT 0, is_manufacturer INTEGER DEFAULT 0,
  is_contract_manufacturer INTEGER DEFAULT 0, address TEXT, contact TEXT, phone TEXT,
  credit_code TEXT, notes TEXT, enabled INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS experiment_methods(
  experiment_code TEXT PRIMARY KEY, experiment_name TEXT NOT NULL UNIQUE,
  method_code TEXT NOT NULL, standard TEXT, category TEXT, kind TEXT,
  enabled INTEGER DEFAULT 1, sort_order INTEGER DEFAULT 0,
  created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS sample_catalog(
  id INTEGER PRIMARY KEY AUTOINCREMENT, sample_code TEXT UNIQUE, sample_name TEXT NOT NULL,
  model TEXT NOT NULL, material_name TEXT NOT NULL,
  process TEXT, material_suffix TEXT, source_sequence TEXT,
  category TEXT, unit TEXT DEFAULT '件', experiment_codes TEXT DEFAULT '[]',
  notes TEXT, enabled INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS device_presets(
  experiment TEXT PRIMARY KEY, equipment_name TEXT, equipment_model TEXT, equipment_no TEXT,
  calibration_certificate TEXT, calibration_due TEXT, software TEXT, default_location TEXT,
  extra_json TEXT DEFAULT '{}', updated_by TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS equipment_registry(
  management_no TEXT PRIMARY KEY, seq INTEGER, equipment_name TEXT NOT NULL,
  model TEXT, measuring_range TEXT, manufacturer TEXT, serial_no TEXT,
  purchase_time TEXT, calibration_time TEXT, responsible TEXT,
  equipment_class TEXT, enabled INTEGER DEFAULT 1, lifecycle_status TEXT DEFAULT '启用',
  status_note TEXT, notes TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS experiment_equipment_bindings(
  experiment TEXT NOT NULL, management_no TEXT NOT NULL, binding_role TEXT NOT NULL,
  required INTEGER DEFAULT 0, sort_order INTEGER DEFAULT 0, note TEXT,
  created_at TEXT, updated_at TEXT,
  PRIMARY KEY(experiment, management_no)
);
CREATE TABLE IF NOT EXISTS experiment_config_versions(
  id INTEGER PRIMARY KEY AUTOINCREMENT, experiment_code TEXT NOT NULL,
  version TEXT NOT NULL, experiment_name TEXT NOT NULL, method_code TEXT NOT NULL,
  standard TEXT, category TEXT, kind TEXT DEFAULT 'generic', default_location TEXT,
  sop_version TEXT, record_template_version TEXT, software TEXT,
  status TEXT DEFAULT '草稿', effective_date TEXT, note TEXT,
  created_by TEXT, created_at TEXT, approved_by TEXT, approved_at TEXT,
  UNIQUE(experiment_code, version)
);
CREATE TABLE IF NOT EXISTS experiment_config_equipment(
  config_id INTEGER NOT NULL, management_no TEXT NOT NULL, binding_role TEXT NOT NULL,
  required INTEGER DEFAULT 0, sort_order INTEGER DEFAULT 0, note TEXT,
  created_at TEXT, updated_at TEXT,
  PRIMARY KEY(config_id, management_no)
);
CREATE TABLE IF NOT EXISTS task_config_snapshots(
  task_no TEXT PRIMARY KEY, config_id INTEGER, config_version TEXT,
  snapshot_json TEXT NOT NULL, snapshot_hash TEXT, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS commissions(
  commission_no TEXT PRIMARY KEY, client_org_id INTEGER NOT NULL, client_name TEXT NOT NULL,
  client_address TEXT, contact TEXT, phone TEXT,
  production_org_id INTEGER NOT NULL, production_org_name TEXT NOT NULL, production_relation TEXT NOT NULL,
  commission_date TEXT, due_date TEXT, subcontract_allowed TEXT, report_medium TEXT,
  conformity_judgment TEXT, uncertainty TEXT, delivery_method TEXT, cnas_mark TEXT,
  capability TEXT, method_choices TEXT DEFAULT '[]', notes TEXT,
  status TEXT DEFAULT '已入库', created_by TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS sample_groups(
  id INTEGER PRIMARY KEY AUTOINCREMENT, group_no TEXT NOT NULL UNIQUE, commission_no TEXT NOT NULL,
  catalog_id INTEGER, sample_name TEXT, model TEXT, material_name TEXT, production_org_id INTEGER,
  production_org_name TEXT, production_relation TEXT, product_no TEXT, quantity INTEGER,
  unit TEXT, condition TEXT, condition_note TEXT, storage_area TEXT, notes TEXT,
  status TEXT DEFAULT '待分配', is_void INTEGER DEFAULT 0, void_by TEXT, void_at TEXT,
  void_reason TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS samples(
  sample_no TEXT PRIMARY KEY, group_id INTEGER NOT NULL, group_no TEXT NOT NULL,
  commission_no TEXT NOT NULL, sample_name TEXT, model TEXT, material_name TEXT,
  condition TEXT, condition_note TEXT, current_location TEXT, current_holder TEXT,
  status TEXT DEFAULT '待分配', created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS requested_tests(
  id INTEGER PRIMARY KEY AUTOINCREMENT, group_id INTEGER NOT NULL,
  experiment_code TEXT NOT NULL, experiment TEXT NOT NULL,
  method_code TEXT NOT NULL, standard TEXT, status TEXT DEFAULT '待分配', task_no TEXT,
  UNIQUE(group_id, experiment_code)
);
CREATE TABLE IF NOT EXISTS task_packages(
  package_no TEXT PRIMARY KEY, commission_no TEXT NOT NULL, group_id INTEGER NOT NULL,
  group_no TEXT NOT NULL, assignee TEXT NOT NULL, reviewer TEXT NOT NULL,
  quality_inspector TEXT,
  material_name TEXT, sample_nos TEXT, experiment_codes TEXT, experiments TEXT, status TEXT DEFAULT '待接收',
  assigned_by TEXT, assigned_at TEXT, notified_at TEXT, accepted_at TEXT,
  detection_location TEXT, acceptance_result TEXT, acceptance_note TEXT,
  return_submitted_at TEXT, return_confirmed_at TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS tasks(
  task_no TEXT PRIMARY KEY, package_no TEXT NOT NULL, commission_no TEXT NOT NULL,
  group_id INTEGER NOT NULL, group_no TEXT NOT NULL, sample_nos TEXT,
  experiment_code TEXT NOT NULL, experiment TEXT,
  method_code TEXT, standard TEXT, material_name TEXT, assignee TEXT, reviewer TEXT,
  quality_inspector TEXT,
  status TEXT DEFAULT '待接收', detection_location TEXT,
  experiment_started_at TEXT, experiment_ended_at TEXT,
  created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS records(
  id INTEGER PRIMARY KEY AUTOINCREMENT, record_no TEXT NOT NULL, task_no TEXT NOT NULL,
  version INTEGER NOT NULL, experiment TEXT, owner TEXT, status TEXT, payload TEXT,
  template_version TEXT, sop_version TEXT, change_reason TEXT,
  tester_signed_at TEXT, reviewer_signed_at TEXT, quality_signed_at TEXT,
  created_at TEXT, updated_at TEXT,
  UNIQUE(record_no, version)
);
CREATE TABLE IF NOT EXISTS reviews(
  id INTEGER PRIMARY KEY AUTOINCREMENT, record_no TEXT, version INTEGER, reviewer TEXT,
  decision TEXT, comment TEXT, reviewed_at TEXT
);
CREATE TABLE IF NOT EXISTS package_loans(
  id INTEGER PRIMARY KEY AUTOINCREMENT, package_no TEXT NOT NULL, sample_no TEXT NOT NULL,
  borrower TEXT, borrowed_at TEXT, purpose TEXT, detection_location TEXT, issue_note TEXT,
  return_condition TEXT, return_note TEXT, returned_by TEXT, returned_at TEXT,
  return_status TEXT DEFAULT '未归还', confirmed_by TEXT, confirmed_at TEXT,
  confirmed_location TEXT, UNIQUE(package_no, sample_no)
);
CREATE TABLE IF NOT EXISTS attachments(
  id INTEGER PRIMARY KEY AUTOINCREMENT, attachment_id TEXT UNIQUE, commission_no TEXT,
  package_no TEXT, task_no TEXT, sample_no TEXT, attachment_type TEXT, original_name TEXT,
  stored_name TEXT, relative_path TEXT, sha256 TEXT, captured_at TEXT, uploader TEXT,
  description TEXT, is_original INTEGER DEFAULT 1,
  parent_attachment_id TEXT, capture_source TEXT DEFAULT 'file',
  checkpoint_code TEXT, checkpoint_label TEXT, device_id TEXT,
  evidence_status TEXT DEFAULT '有效', server_captured_at TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS reports(
  report_no TEXT PRIMARY KEY, commission_no TEXT NOT NULL, task_no TEXT UNIQUE,
  status TEXT DEFAULT '待质量审核',
  tester TEXT, verifier TEXT, quality_inspector TEXT, approver TEXT,
  source_versions TEXT DEFAULT '{}', validity_status TEXT DEFAULT '有效',
  supersedes_report_no TEXT, report_category TEXT, sample_statement TEXT,
  conclusion TEXT, notes TEXT, tester_signed_at TEXT, verifier_signed_at TEXT,
  quality_signed_at TEXT, approver_signed_at TEXT, publish_date TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS report_actions(
  id INTEGER PRIMARY KEY AUTOINCREMENT, report_no TEXT, actor TEXT, action TEXT,
  comment TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS signatures(
  username TEXT PRIMARY KEY, source_file TEXT, image_file TEXT, uploaded_by TEXT, uploaded_at TEXT
);
CREATE TABLE IF NOT EXISTS template_versions(
  id INTEGER PRIMARY KEY AUTOINCREMENT, experiment TEXT, doc_type TEXT, file_name TEXT,
  version TEXT, effective_date TEXT, status TEXT, uploader TEXT, uploaded_at TEXT, note TEXT
);
CREATE TABLE IF NOT EXISTS audit_logs(
  id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT, entity_id TEXT, actor TEXT,
  actor_name TEXT, actor_role TEXT, action TEXT, field_name TEXT, old_value TEXT,
  new_value TEXT, reason TEXT, client_time TEXT, device_id TEXT, session_token TEXT,
  snapshot_hash TEXT, previous_hash TEXT, entry_hash TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS sample_events(
  id INTEGER PRIMARY KEY AUTOINCREMENT, sample_no TEXT, actor TEXT, action TEXT,
  from_status TEXT, to_status TEXT, from_location TEXT, to_location TEXT,
  details TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS document_versions(
  id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
  version INTEGER NOT NULL, status TEXT NOT NULL, snapshot_json TEXT NOT NULL,
  snapshot_hash TEXT NOT NULL, created_by TEXT NOT NULL, created_at TEXT NOT NULL,
  obsolete_by TEXT, obsolete_at TEXT, obsolete_reason TEXT,
  UNIQUE(entity_type,entity_id,version)
);
CREATE TABLE IF NOT EXISTS objections(
  objection_no TEXT PRIMARY KEY, report_no TEXT NOT NULL, commission_no TEXT NOT NULL,
  client_name TEXT, contact TEXT, submitted_at TEXT, description TEXT,
  evidence_note TEXT, status TEXT DEFAULT '已登记', pathway TEXT,
  investigation TEXT, trace_conclusion TEXT, quality_inspector TEXT,
  disputed_items TEXT, involved_samples TEXT, application_channel TEXT,
  quality_evidence TEXT, quality_method_check TEXT, quality_equipment_check TEXT,
  quality_environment_check TEXT, quality_operation_check TEXT,
  quality_calculation_check TEXT, impact_scope TEXT, treatment_suggestion TEXT,
  admin_decision TEXT, customer_retest_decision TEXT, retest_note TEXT,
  customer_contact_at TEXT, customer_contact_method TEXT,
  retest_task_no TEXT, replacement_report_no TEXT,
  response_text TEXT, response_method TEXT, response_receipt TEXT,
  registered_by TEXT, investigated_at TEXT,
  approved_by TEXT, approved_at TEXT, sent_by TEXT, sent_at TEXT,
  archived_at TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS objection_actions(
  id INTEGER PRIMARY KEY AUTOINCREMENT, objection_no TEXT NOT NULL, actor TEXT,
  action TEXT, comment TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS report_deliveries(
  id INTEGER PRIMARY KEY AUTOINCREMENT, report_no TEXT NOT NULL, client_name TEXT,
  delivery_method TEXT, recipient TEXT, recipient_contact TEXT, delivered_at TEXT,
  receipt_status TEXT, receipt_note TEXT, operator TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS notifications(
  id INTEGER PRIMARY KEY AUTOINCREMENT, recipient TEXT NOT NULL, title TEXT NOT NULL,
  message TEXT NOT NULL, entity_type TEXT, entity_id TEXT,
  read_at TEXT, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS hazardous_waste_records(
  disposal_no TEXT PRIMARY KEY, commission_no TEXT, task_no TEXT, task_nos TEXT DEFAULT '[]', sample_no TEXT,
  waste_type TEXT NOT NULL, waste_name TEXT NOT NULL, quantity REAL NOT NULL, unit TEXT,
  hazard_category TEXT, disposal_method TEXT NOT NULL, container_no TEXT,
  handler TEXT NOT NULL, occurred_at TEXT NOT NULL, status TEXT DEFAULT '已登记',
  note TEXT, created_by TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
);
"""
        )
        # Non-destructive migration for databases created by V5.7 and earlier.
        task_columns = {
            item[1] for item in c.execute("PRAGMA table_info(tasks)").fetchall()
        }
        for column_name, column_type in (
            ("detection_location", "TEXT"),
            ("experiment_started_at", "TEXT"),
            ("experiment_ended_at", "TEXT"),
            ("quality_inspector", "TEXT"),
        ):
            if column_name not in task_columns:
                c.execute(f"ALTER TABLE tasks ADD COLUMN {column_name} {column_type}")
        package_columns = {item[1] for item in c.execute("PRAGMA table_info(task_packages)").fetchall()}
        if "quality_inspector" not in package_columns:
            c.execute("ALTER TABLE task_packages ADD COLUMN quality_inspector TEXT")
        attachment_columns = {item[1] for item in c.execute("PRAGMA table_info(attachments)").fetchall()}
        for column_name, column_type in (
            ("capture_source", "TEXT DEFAULT 'file'"), ("checkpoint_code", "TEXT"),
            ("checkpoint_label", "TEXT"), ("device_id", "TEXT"),
            ("evidence_status", "TEXT DEFAULT '有效'"), ("server_captured_at", "TEXT"),
        ):
            if column_name not in attachment_columns:
                c.execute(f"ALTER TABLE attachments ADD COLUMN {column_name} {column_type}")
        report_columns = {item[1] for item in c.execute("PRAGMA table_info(reports)").fetchall()}
        for column_name, column_type in (
            ("task_no", "TEXT"), ("quality_inspector", "TEXT"),
            ("source_versions", "TEXT DEFAULT '{}'"),
            ("validity_status", "TEXT DEFAULT '有效'"), ("supersedes_report_no", "TEXT"),
            ("quality_signed_at", "TEXT"),
        ):
            if column_name not in report_columns:
                c.execute(f"ALTER TABLE reports ADD COLUMN {column_name} {column_type}")
        record_columns = {item[1] for item in c.execute("PRAGMA table_info(records)").fetchall()}
        for column_name, column_type in (
            ("tester_signed_at", "TEXT"), ("reviewer_signed_at", "TEXT"),
            ("quality_signed_at", "TEXT"),
        ):
            if column_name not in record_columns:
                c.execute(f"ALTER TABLE records ADD COLUMN {column_name} {column_type}")
        catalog_columns = {item[1] for item in c.execute("PRAGMA table_info(sample_catalog)").fetchall()}
        for column_name in ("process", "material_suffix", "source_sequence"):
            if column_name not in catalog_columns:
                c.execute(f"ALTER TABLE sample_catalog ADD COLUMN {column_name} TEXT")
        waste_columns = {item[1] for item in c.execute("PRAGMA table_info(hazardous_waste_records)").fetchall()}
        if "task_nos" not in waste_columns:
            c.execute("ALTER TABLE hazardous_waste_records ADD COLUMN task_nos TEXT DEFAULT '[]'")
        audit_columns = {item[1] for item in c.execute("PRAGMA table_info(audit_logs)").fetchall()}
        for column_name, column_type in (
            ("actor_name", "TEXT"), ("actor_role", "TEXT"), ("client_time", "TEXT"),
            ("device_id", "TEXT"), ("session_token", "TEXT"), ("snapshot_hash", "TEXT"),
            ("previous_hash", "TEXT"), ("entry_hash", "TEXT"),
        ):
            if column_name not in audit_columns:
                c.execute(f"ALTER TABLE audit_logs ADD COLUMN {column_name} {column_type}")
        objection_columns = {item[1] for item in c.execute("PRAGMA table_info(objections)").fetchall()}
        for column_name,column_type in (
            ("retest_task_no","TEXT"),("replacement_report_no","TEXT"),
            ("disputed_items","TEXT"),("involved_samples","TEXT"),
            ("application_channel","TEXT"),("quality_evidence","TEXT"),
            ("quality_method_check","TEXT"),("quality_equipment_check","TEXT"),
            ("quality_environment_check","TEXT"),("quality_operation_check","TEXT"),
            ("quality_calculation_check","TEXT"),("impact_scope","TEXT"),
            ("treatment_suggestion","TEXT"),("customer_contact_at","TEXT"),
            ("customer_contact_method","TEXT"),("response_method","TEXT"),
            ("response_receipt","TEXT"),
        ):
            if column_name not in objection_columns:
                c.execute(f"ALTER TABLE objections ADD COLUMN {column_name} {column_type}")
        # Older demos used an administrator confirmation step. Migrate them to
        # the V8.1 role flow without requiring any manual administrator action.
        c.execute(
            """UPDATE objections
               SET status=CASE
                   WHEN pathway IN ('检测方法或实验室实施问题','是我们的问题','是我方问题') THEN '待客户确认重测'
                   ELSE '待异议回复'
               END,updated_at=?
               WHERE status='待管理员确认'""",
            (now(),),
        )
        c.execute("UPDATE objections SET pathway='是我方问题' WHERE pathway='是我们的问题'")
        c.execute("UPDATE objections SET pathway='样品问题' WHERE pathway IN ('不是我们的问题','样品自身问题')")
        c.execute(
            """UPDATE objections SET customer_retest_decision=NULL,
               status='待客户确认重测',updated_at=?
               WHERE customer_retest_decision='待处理'""",
            (now(),),
        )
        c.execute("UPDATE users SET role='实验员' WHERE role='实验人员'")
        c.execute("UPDATE users SET role='复核员' WHERE role='复核实验员'")
        c.execute("UPDATE users SET role='管理员' WHERE role='批准人'")
        # V7.1 approval simplification: reviewer approval now locks the raw record;
        # quality only previews the report and does not sign it.
        c.execute("UPDATE records SET status='已锁定' WHERE status='待质量确认'")
        c.execute(
            """UPDATE tasks SET status='已复核'
               WHERE status='待质量确认'
               AND EXISTS(
                 SELECT 1 FROM records r
                 WHERE r.task_no=tasks.task_no AND r.status='已锁定'
               )"""
        )
        c.execute("UPDATE reports SET status='待质量审核' WHERE status='待复核员审核'")
        demo_users = [
            ("admin", "系统管理员", "admin123", "管理员"),
            ("receiver", "样品管理员王工", "receive123", "样品管理员"),
            ("store", "样品管理员赵工", "store123", "样品管理员"),
            ("tester", "实验员张工", "test123", "实验员"),
            ("reviewer", "复核员李工", "review123", "复核员"),
            ("quality", "质量检测员周工", "quality123", "质量检测员"),
            ("approver", "管理员刘工", "approve123", "管理员"),
        ]
        for username, name, password, role in demo_users:
            if not c.execute("SELECT 1 FROM users WHERE username=?", (username,)).fetchone():
                c.execute(
                    "INSERT INTO users VALUES(?,?,?,?,1,?)",
                    (username, name, _password_hash(password), role, now()),
                )
        c.execute(
            """INSERT INTO organizations(
               org_code,org_name,short_name,is_client,is_manufacturer,
               is_contract_manufacturer,address,contact,phone,credit_code,notes,
               enabled,created_at,updated_at
               ) VALUES(
               'ORG-DEFAULT','测试委托客户（预设）','测试客户',1,0,0,
               '辽宁省大连市测试地址','测试联系人','13800000000','',
               '用于系统流程测试，可在单位信息库中修改或停用',1,?,?
               )
               ON CONFLICT(org_code) DO UPDATE SET
               org_name=excluded.org_name,short_name=excluded.short_name,
               is_client=1,is_manufacturer=0,is_contract_manufacturer=0,
               address=excluded.address,contact=excluded.contact,phone=excluded.phone,
               notes=excluded.notes,enabled=1,updated_at=excluded.updated_at""",
            (now(), now()),
        )
        c.execute(
            """INSERT INTO organizations(
               org_code,org_name,short_name,is_client,is_manufacturer,
               is_contract_manufacturer,address,contact,phone,credit_code,notes,
               enabled,created_at,updated_at
               ) VALUES(
               'ORG-TEST-MFR','测试生产单位（预设）','测试生产单位',0,1,0,
               '辽宁省大连市测试生产地址','生产联系人','13900000000','',
               '用于系统流程测试，可在单位信息库中修改或停用',1,?,?
               )
               ON CONFLICT(org_code) DO UPDATE SET
               org_name=excluded.org_name,short_name=excluded.short_name,
               is_client=0,is_manufacturer=1,is_contract_manufacturer=0,
               address=excluded.address,contact=excluded.contact,phone=excluded.phone,
               notes=excluded.notes,enabled=1,updated_at=excluded.updated_at""",
            (now(), now()),
        )
        from constants import EXPERIMENTS
        for order, (experiment_name, cfg) in enumerate(EXPERIMENTS.items(), 1):
            c.execute(
                """INSERT INTO experiment_methods(
                   experiment_code,experiment_name,method_code,standard,category,kind,enabled,
                   sort_order,created_at,updated_at
                   ) VALUES(?,?,?,?,?,?,1,?,?,?)
                   ON CONFLICT(experiment_code) DO NOTHING""",
                (cfg["key"], experiment_name, cfg["method"], cfg["std"], cfg["category"],
                 cfg["kind"], order, now(), now()),
            )
        from equipment_registry import (
            EQUIPMENT_CATALOG, EXPERIMENT_EQUIPMENT_BINDINGS
        )
        for item in EQUIPMENT_CATALOG:
            c.execute(
                """INSERT INTO equipment_registry(
                   management_no,seq,equipment_name,model,measuring_range,manufacturer,
                   serial_no,purchase_time,calibration_time,responsible,equipment_class,
                   enabled,lifecycle_status,status_note,notes,created_at,updated_at
                   ) VALUES(?,?,?,?,?,?,?,?,?,?,?,1,'启用','','',?,?)
                   ON CONFLICT(management_no) DO NOTHING""",
                (
                    item["management_no"], item["seq"], item["name"], item.get("model", ""),
                    item.get("range", ""), item.get("manufacturer", ""),
                    item.get("serial_no", ""), item.get("purchase_time", ""),
                    item.get("calibration_time", ""), item.get("responsible", ""),
                    item.get("class", ""), now(), now(),
                ),
            )
        binding_count = c.execute("SELECT COUNT(*) FROM experiment_equipment_bindings").fetchone()[0]
        if binding_count == 0:
            for experiment_name, items in EXPERIMENT_EQUIPMENT_BINDINGS.items():
                for order, item in enumerate(items, 1):
                    c.execute(
                        """INSERT INTO experiment_equipment_bindings(
                           experiment,management_no,binding_role,required,sort_order,note,
                           created_at,updated_at
                           ) VALUES(?,?,?,?,?,?,?,?)
                           ON CONFLICT(experiment,management_no) DO NOTHING""",
                        (
                            experiment_name, item["management_no"], item["role"],
                            int(bool(item.get("required"))), order, item.get("note", ""),
                            now(), now(),
                        ),
                    )

        from equipment_registry import EXPERIMENT_DEFAULT_LOCATIONS
        for experiment_name, cfg in EXPERIMENTS.items():
            current = c.execute(
                "SELECT id FROM experiment_config_versions WHERE experiment_code=? AND status='现行'",
                (cfg["key"],),
            ).fetchone()
            if current:
                continue
            cur = c.execute(
                """INSERT INTO experiment_config_versions(
                   experiment_code,version,experiment_name,method_code,standard,category,kind,
                   default_location,sop_version,record_template_version,software,status,
                   effective_date,note,created_by,created_at,approved_by,approved_at
                   ) VALUES(?,?,?,?,?,?,?,?,?,?,?,'现行',?,'初始受控配置','system',?,'system',?)""",
                (
                    cfg["key"], "V1.0", experiment_name, cfg["method"], cfg["std"],
                    cfg["category"], cfg.get("kind") or "generic",
                    EXPERIMENT_DEFAULT_LOCATIONS.get(experiment_name, ""),
                    "A/0", "A/0", "", str(china_today()), now(), now(),
                ),
            )
            config_id = cur.lastrowid
            for row in c.execute(
                """SELECT management_no,binding_role,required,sort_order,note
                   FROM experiment_equipment_bindings WHERE experiment=? ORDER BY sort_order""",
                (experiment_name,),
            ).fetchall():
                c.execute(
                    """INSERT OR IGNORE INTO experiment_config_equipment(
                       config_id,management_no,binding_role,required,sort_order,note,created_at,updated_at
                       ) VALUES(?,?,?,?,?,?,?,?)""",
                    (config_id,row[0],row[1],row[2],row[3],row[4],now(),now()),
                )

        # Seed the exact controlled SOP and original-record versions during database
        # initialization. This makes task snapshots deterministic even before the
        # Streamlit UI performs its idempotent seed pass.
        for experiment_name, cfg in EXPERIMENTS.items():
            for doc_type, file_name in (("原始记录表", cfg.get("template")), ("SOP", cfg.get("sop"))):
                if not file_name:
                    continue
                c.execute(
                    """INSERT INTO template_versions(
                       experiment,doc_type,file_name,version,effective_date,status,uploader,uploaded_at,note
                       ) SELECT ?,?,?, 'A/0', ?, '现行', 'system', ?, '初始化'
                       WHERE NOT EXISTS(
                         SELECT 1 FROM template_versions WHERE experiment=? AND doc_type=? AND version='A/0'
                       )""",
                    (experiment_name, doc_type, file_name, str(china_today()), now(), experiment_name, doc_type),
                )

        test_experiments = [
            EXPERIMENTS["表面粗糙度试验"]["key"],
            EXPERIMENTS["弯曲性能试验"]["key"],
            EXPERIMENTS["维氏硬度试验"]["key"],
        ]
        c.execute(
            """INSERT INTO sample_catalog(
               sample_code,sample_name,model,material_name,category,unit,experiment_codes,
               notes,enabled,created_at,updated_at
               ) VALUES(
               'S-DEFAULT','测试金属试样（预设）','25 mm×2 mm×2 mm','钴铬合金',
               '金属试样','件',?,
               '测试预设：已关联表面粗糙度、弯曲性能和维氏硬度试验',1,?,?
               )
               ON CONFLICT(sample_code) DO UPDATE SET
               sample_name=excluded.sample_name,model=excluded.model,
               material_name=excluded.material_name,category=excluded.category,
               unit=excluded.unit,experiment_codes=excluded.experiment_codes,
               notes=excluded.notes,enabled=1,updated_at=excluded.updated_at""",
            (json.dumps(test_experiments, ensure_ascii=False), now(), now()),
        )
        seed_file = ROOT / "sample_catalog_seed.json"
        if seed_file.exists():
            for item in json.loads(seed_file.read_text(encoding="utf-8")):
                c.execute(
                    """INSERT INTO sample_catalog(
                       sample_code,sample_name,model,material_name,process,material_suffix,
                       source_sequence,category,unit,experiment_codes,notes,enabled,created_at,updated_at
                       ) VALUES(?,?,?,?,?,?,?,?,?,'[]',?,1,?,?)
                       ON CONFLICT(sample_code) DO UPDATE SET
                       sample_name=excluded.sample_name,model=excluded.model,
                       material_name=excluded.material_name,process=excluded.process,
                       material_suffix=excluded.material_suffix,source_sequence=excluded.source_sequence,
                       category=excluded.category,unit=excluded.unit,notes=excluded.notes,
                       enabled=1,updated_at=excluded.updated_at""",
                    (
                        item["sample_code"], item["sample_name"], item["model"],
                        item["material_name"], item.get("process", ""),
                        item.get("material_suffix", ""), item.get("source_sequence", ""),
                        item.get("category", ""), item.get("unit", "件"),
                        item.get("notes", ""), now(), now(),
                    ),
                )


def audit(
    entity_type: str, entity_id: str, actor: str, action: str,
    field_name: str = "", old_value: Any = "", new_value: Any = "",
    reason: str = "", client_time: str = "", device_id: str = "",
    session_token: str = "", snapshot: Any = None,
) -> None:
    """Append-only, hash-chained audit entry.

    The database exposes no update/delete helper for audit rows. Every business
    correction creates another entry and, where relevant, a document snapshot.
    """
    created_at = now()
    actor_row = one("SELECT display_name,role FROM users WHERE username=?", (actor,)) or {}
    previous = one("SELECT entry_hash FROM audit_logs ORDER BY id DESC LIMIT 1") or {}
    previous_hash = previous.get("entry_hash", "")
    snapshot_text = json.dumps(snapshot, ensure_ascii=False, sort_keys=True, default=str) if snapshot is not None else ""
    snapshot_hash = hashlib.sha256(snapshot_text.encode("utf-8")).hexdigest() if snapshot_text else ""
    canonical = json.dumps({
        "entity_type": entity_type, "entity_id": entity_id, "actor": actor,
        "actor_name": actor_row.get("display_name", actor),
        "actor_role": actor_row.get("role", "系统" if actor == "system" else ""),
        "action": action, "field_name": field_name, "old_value": str(old_value),
        "new_value": str(new_value), "reason": reason, "client_time": client_time,
        "device_id": device_id, "session_token": session_token,
        "snapshot_hash": snapshot_hash, "previous_hash": previous_hash,
        "created_at": created_at,
    }, ensure_ascii=False, sort_keys=True)
    entry_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    with connect() as c:
        c.execute(
            """INSERT INTO audit_logs(
               entity_type,entity_id,actor,actor_name,actor_role,action,field_name,
               old_value,new_value,reason,client_time,device_id,session_token,
               snapshot_hash,previous_hash,entry_hash,created_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                entity_type, entity_id, actor, actor_row.get("display_name", actor),
                actor_row.get("role", "系统" if actor == "system" else ""), action,
                field_name, str(old_value), str(new_value), reason, client_time,
                device_id, session_token, snapshot_hash, previous_hash, entry_hash,
                created_at,
            ),
        )


def freeze_document_version(
    entity_type: str, entity_id: str, version: int, status: str,
    snapshot: Any, actor: str,
) -> None:
    snapshot_json = json.dumps(snapshot, ensure_ascii=False, sort_keys=True, default=str)
    snapshot_hash = hashlib.sha256(snapshot_json.encode("utf-8")).hexdigest()
    with connect() as c:
        c.execute(
            """INSERT INTO document_versions(
               entity_type,entity_id,version,status,snapshot_json,snapshot_hash,
               created_by,created_at
               ) VALUES(?,?,?,?,?,?,?,?)
               ON CONFLICT(entity_type,entity_id,version) DO UPDATE SET
               status=excluded.status,snapshot_json=excluded.snapshot_json,
               snapshot_hash=excluded.snapshot_hash""",
            (entity_type, entity_id, version, status, snapshot_json, snapshot_hash, actor, now()),
        )
    audit(entity_type, entity_id, actor, "冻结版本", new_value=f"V{version}|{status}", snapshot=snapshot)


def create_notification(
    recipient: str, title: str, message: str,
    entity_type: str = "", entity_id: str = "",
) -> None:
    if not recipient:
        return
    with connect() as c:
        c.execute(
            """INSERT INTO notifications(
               recipient,title,message,entity_type,entity_id,created_at
               ) VALUES(?,?,?,?,?,?)""",
            (recipient, title, message, entity_type, entity_id, now()),
        )


def unread_notifications(recipient: str) -> list[dict[str, Any]]:
    return rows(
        """SELECT * FROM notifications WHERE recipient=? AND read_at IS NULL
           ORDER BY id""",
        (recipient,),
    )


def mark_notifications_read(recipient: str, ids: list[int] | None = None) -> None:
    with connect() as c:
        if ids:
            placeholders = ",".join("?" for _ in ids)
            c.execute(
                f"UPDATE notifications SET read_at=? WHERE recipient=? AND id IN ({placeholders})",
                (now(), recipient, *ids),
            )
        else:
            c.execute(
                "UPDATE notifications SET read_at=? WHERE recipient=? AND read_at IS NULL",
                (now(), recipient),
            )


def obsolete_prior_versions(entity_type: str, entity_id: str, active_version: int, actor: str, reason: str) -> None:
    with connect() as c:
        c.execute(
            """UPDATE document_versions SET status='历史作废',obsolete_by=?,
               obsolete_at=?,obsolete_reason=?
               WHERE entity_type=? AND entity_id=? AND version<? AND status!='历史作废'""",
            (actor, now(), reason, entity_type, entity_id, active_version),
        )
    audit(entity_type, entity_id, actor, "历史版本作废", new_value=f"V{active_version}以前", reason=reason)


def document_versions(entity_type: str, entity_id: str) -> list[dict[str, Any]]:
    return rows(
        "SELECT * FROM document_versions WHERE entity_type=? AND entity_id=? ORDER BY version",
        (entity_type, entity_id),
    )


def authenticate(username: str, password: str) -> dict[str, Any] | None:
    r = one("SELECT username,display_name,password_hash,role,enabled FROM users WHERE username=?", (username.strip(),))
    if r and r["enabled"] and _password_verify(password, r["password_hash"]):
        return {k: r[k] for k in ("username", "display_name", "role")}
    return None


def create_session(username: str, days: int = 7) -> str:
    token = secrets.token_urlsafe(28)
    with connect() as c:
        c.execute(
            "INSERT INTO sessions VALUES(?,?,?,?)",
            (token, username, (china_now() + timedelta(days=days)).isoformat(timespec="seconds"), now()),
        )
    return token


def session_user(token: str) -> dict[str, Any] | None:
    if not token:
        return None
    return one(
        """SELECT u.username,u.display_name,u.role FROM sessions s JOIN users u ON u.username=s.username
           WHERE s.token=? AND s.expires_at>? AND u.enabled=1""",
        (token, now()),
    )


def delete_session(token: str) -> None:
    with connect() as c:
        c.execute("DELETE FROM sessions WHERE token=?", (token,))


def list_users() -> list[dict[str, Any]]:
    return rows("SELECT username,display_name,role,enabled,created_at FROM users ORDER BY username")


def add_user(username: str, display_name: str, password: str, role: str) -> None:
    if not username or not display_name or not password:
        raise ValueError("用户名、姓名和密码不能为空")
    with connect() as c:
        c.execute(
            "INSERT INTO users VALUES(?,?,?,?,1,?)",
            (username.strip(), display_name.strip(), _password_hash(password), role, now()),
        )
    audit("user", username, "admin", "创建用户")


# ---------------------- Master data ----------------------
def list_organizations(include_disabled: bool = False) -> list[dict[str, Any]]:
    q = "SELECT * FROM organizations"
    if not include_disabled:
        q += " WHERE enabled=1"
    return rows(q + " ORDER BY org_name")


def add_organization(data: dict[str, Any], actor: str) -> None:
    if not data.get("org_name", "").strip():
        raise ValueError("单位名称不能为空")
    with connect() as c:
        c.execute(
            """INSERT INTO organizations(org_code,org_name,short_name,is_client,is_manufacturer,
               is_contract_manufacturer,address,contact,phone,credit_code,notes,enabled,created_at,updated_at)
               VALUES(?,?,?,?,?,?,?,?,?,?,?,1,?,?)""",
            (
                data.get("org_code") or None, data["org_name"].strip(), data.get("short_name", ""),
                int(bool(data.get("is_client"))), int(bool(data.get("is_manufacturer"))),
                int(bool(data.get("is_contract_manufacturer"))), data.get("address", ""),
                data.get("contact", ""), data.get("phone", ""), data.get("credit_code", ""),
                data.get("notes", ""), now(), now(),
            ),
        )
    audit("organization", data["org_name"], actor, "新增单位")


def list_experiment_methods(include_disabled: bool = False) -> list[dict[str, Any]]:
    q = "SELECT * FROM experiment_methods"
    if not include_disabled:
        q += " WHERE enabled=1"
    return rows(q + " ORDER BY sort_order,experiment_name")


def experiment_method(experiment_code: str) -> dict[str, Any] | None:
    """Internal lookup retained for relational integrity; not shown to users."""
    return one("SELECT * FROM experiment_methods WHERE experiment_code=?", (experiment_code,))


def experiment_method_by_name(experiment_name: str) -> dict[str, Any] | None:
    return one("SELECT * FROM experiment_methods WHERE experiment_name=?", (experiment_name,))


def _next_internal_experiment_key() -> str:
    existing = rows("SELECT experiment_code FROM experiment_methods")
    used = []
    for item in existing:
        match = re.fullmatch(r"I(\d+)", str(item.get("experiment_code", "")))
        if match:
            used.append(int(match.group(1)))
    return f"I{(max(used) if used else 0) + 1:03d}"


def save_experiment_method(data: dict[str, Any], actor: str) -> None:
    name = str(data.get("experiment_name", "")).strip()
    method = str(data.get("method_code", "")).strip()
    if not name or not method:
        raise ValueError("实验名称和检测方法不能为空")
    if method == "其他方法":
        raise ValueError("检测方法库不允许使用“其他方法”")
    existing = experiment_method_by_name(name)
    internal_key = existing["experiment_code"] if existing else _next_internal_experiment_key()
    with connect() as c:
        c.execute(
            """INSERT INTO experiment_methods(
               experiment_code,experiment_name,method_code,standard,category,kind,enabled,
               sort_order,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?)
               ON CONFLICT(experiment_code) DO UPDATE SET
               experiment_name=excluded.experiment_name,method_code=excluded.method_code,
               standard=excluded.standard,category=excluded.category,kind=excluded.kind,
               enabled=excluded.enabled,sort_order=excluded.sort_order,updated_at=excluded.updated_at""",
            (
                internal_key, name, method, data.get("standard", ""),
                data.get("category", ""), data.get("kind", "generic") or "generic",
                int(bool(data.get("enabled", True))),
                int(data.get("sort_order", 0) or 0), now(), now(),
            ),
        )
    audit(
        "experiment_method", name, actor, "保存检测项目与方法",
        new_value=f"{name}｜{method}",
    )


def list_catalog(include_disabled: bool = False) -> list[dict[str, Any]]:
    q = "SELECT * FROM sample_catalog"
    if not include_disabled:
        q += " WHERE enabled=1"
    result = rows(q + " ORDER BY sample_name,model")
    mapping = {x["experiment_code"]: x for x in list_experiment_methods(True)}
    for x in result:
        x["experiment_codes_list"] = json.loads(x.get("experiment_codes") or "[]")
        x["experiment_labels"] = [
            f"{mapping[code]['experiment_name']}｜{mapping[code]['method_code']}"
            for code in x["experiment_codes_list"] if code in mapping
        ]
    return result


def add_catalog(data: dict[str, Any], actor: str) -> None:
    for field in ("sample_name", "model", "material_name"):
        if not str(data.get(field, "")).strip():
            raise ValueError(f"{field}不能为空")
    codes = list(dict.fromkeys(data.get("experiment_codes", [])))
    enabled_codes = {x["experiment_code"] for x in list_experiment_methods()}
    invalid = [x for x in codes if x not in enabled_codes]
    if invalid:
        raise ValueError("存在无效或停用的检测项目")
    with connect() as c:
        c.execute(
            """INSERT INTO sample_catalog(
               sample_code,sample_name,model,material_name,process,material_suffix,
               source_sequence,category,unit,experiment_codes,notes,enabled,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,1,?,?)""",
            (data.get("sample_code") or None,data["sample_name"].strip(),data["model"].strip(),
             data["material_name"].strip(),data.get("process",""),data.get("material_suffix",""),
             data.get("source_sequence",""),data.get("category",""),data.get("unit","件"),
             json.dumps(codes,ensure_ascii=False),data.get("notes",""),now(),now()),
        )
    audit("sample_catalog", data["sample_name"], actor, "新增样品资料", new_value="、".join(codes))

def list_equipment(include_disabled: bool = False) -> list[dict[str, Any]]:
    q = "SELECT * FROM equipment_registry"
    if not include_disabled:
        q += " WHERE enabled=1"
    return rows(q + " ORDER BY seq,management_no")


def equipment_item(management_no: str) -> dict[str, Any] | None:
    return one("SELECT * FROM equipment_registry WHERE management_no=?", (management_no,))


def save_equipment(data: dict[str, Any], actor: str) -> None:
    management_no = str(data.get("management_no", "")).strip()
    equipment_name = str(data.get("equipment_name", "")).strip()
    if not management_no or not equipment_name:
        raise ValueError("管理编号和设备名称不能为空")
    old = equipment_item(management_no)
    with connect() as c:
        c.execute(
            """INSERT INTO equipment_registry(
               management_no,seq,equipment_name,model,measuring_range,manufacturer,
               serial_no,purchase_time,calibration_time,responsible,equipment_class,
               enabled,lifecycle_status,status_note,notes,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
               ON CONFLICT(management_no) DO UPDATE SET
               seq=excluded.seq,equipment_name=excluded.equipment_name,
               model=excluded.model,measuring_range=excluded.measuring_range,
               manufacturer=excluded.manufacturer,serial_no=excluded.serial_no,
               purchase_time=excluded.purchase_time,calibration_time=excluded.calibration_time,
               responsible=excluded.responsible,equipment_class=excluded.equipment_class,
               enabled=excluded.enabled,lifecycle_status=excluded.lifecycle_status,
               status_note=excluded.status_note,notes=excluded.notes,
               updated_at=excluded.updated_at""",
            (
                management_no, int(data.get("seq", 0) or 0), equipment_name,
                data.get("model", ""), data.get("measuring_range", ""),
                data.get("manufacturer", ""), data.get("serial_no", ""),
                data.get("purchase_time", ""), data.get("calibration_time", ""),
                data.get("responsible", ""), data.get("equipment_class", ""),
                int(bool(data.get("enabled", True))), data.get("lifecycle_status", "启用"),
                data.get("status_note", ""), data.get("notes", ""),
                old.get("created_at", now()) if old else now(), now(),
            ),
        )
    audit(
        "equipment", management_no, actor, "保存设备资料",
        old_value=json.dumps(old or {}, ensure_ascii=False),
        new_value=json.dumps(data, ensure_ascii=False),
    )


def list_experiment_equipment(experiment: str) -> list[dict[str, Any]]:
    return rows(
        """SELECT b.experiment,b.management_no,b.binding_role,b.required,
           b.sort_order,b.note,e.seq,e.equipment_name,e.model,e.measuring_range,
           e.manufacturer,e.serial_no,e.purchase_time,e.calibration_time,
           e.responsible,e.equipment_class,e.enabled
           FROM experiment_equipment_bindings b
           JOIN equipment_registry e ON e.management_no=b.management_no
           WHERE b.experiment=? AND e.enabled=1
           ORDER BY b.sort_order,e.seq,e.management_no""",
        (experiment,),
    )


def list_all_equipment_bindings() -> list[dict[str, Any]]:
    return rows(
        """SELECT b.experiment,b.management_no,b.binding_role,b.required,b.sort_order,
           b.note,e.equipment_name,e.model,e.equipment_class
           FROM experiment_equipment_bindings b
           JOIN equipment_registry e ON e.management_no=b.management_no
           ORDER BY b.experiment,b.sort_order,e.seq"""
    )


def bind_equipment(
    experiment: str, management_no: str, binding_role: str,
    required: bool, sort_order: int, note: str, actor: str,
) -> None:
    if not equipment_item(management_no):
        raise ValueError("设备不存在")
    if not experiment_method_by_name(experiment):
        raise ValueError("实验项目不存在")
    with connect() as c:
        c.execute(
            """INSERT INTO experiment_equipment_bindings(
               experiment,management_no,binding_role,required,sort_order,note,
               created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?)
               ON CONFLICT(experiment,management_no) DO UPDATE SET
               binding_role=excluded.binding_role,required=excluded.required,
               sort_order=excluded.sort_order,note=excluded.note,
               updated_at=excluded.updated_at""",
            (
                experiment, management_no, binding_role, int(bool(required)),
                int(sort_order or 0), note, now(), now(),
            ),
        )
    audit(
        "equipment_binding", f"{experiment}|{management_no}", actor,
        "保存实验设备绑定", new_value=f"{binding_role}|必需={bool(required)}|{note}",
    )


def unbind_equipment(experiment: str, management_no: str, actor: str) -> None:
    with connect() as c:
        c.execute(
            "DELETE FROM experiment_equipment_bindings WHERE experiment=? AND management_no=?",
            (experiment, management_no),
        )
    audit(
        "equipment_binding", f"{experiment}|{management_no}",
        actor, "解除实验设备绑定",
    )


def device_preset(experiment: str) -> dict[str, Any]:
    """Compatibility summary generated from the published configuration version."""
    method = experiment_method_by_name(experiment)
    config = current_experiment_config(method["experiment_code"]) if method else None
    items = config_equipment(config["id"], True) if config else []
    preferred_roles = {"主设备", "成像设备", "测量设备", "位移测量", "温度测量"}
    primary = [x for x in items if x["binding_role"] in preferred_roles]
    if not primary:
        primary = [x for x in items if x["required"]]
    if not primary:
        primary = items[:1]
    def unique_join(values: list[str]) -> str:
        return "；".join(dict.fromkeys(x for x in values if str(x).strip()))
    return {
        "experiment": experiment,
        "equipment_name": unique_join([x["equipment_name"] for x in primary]),
        "equipment_model": unique_join([x["model"] for x in primary]),
        "equipment_no": unique_join([x["management_no"] for x in primary]),
        "calibration_certificate": "",
        "calibration_due": unique_join([x["calibration_time"] for x in primary]),
        "software": config.get("software", "") if config else "",
        "default_location": config.get("default_location", "") if config else "",
        "extra": {
            "config_version": config.get("version", "") if config else "",
            "bound_equipment": items,
            "equipment_count": len(items),
            "required_count": sum(1 for x in items if x["required"]),
        },
    }


def save_device_preset(experiment: str, data: dict[str, Any], actor: str) -> None:
    """Retained only for storing optional software/version notes."""
    with connect() as c:
        c.execute(
            """INSERT INTO device_presets(
               experiment,equipment_name,equipment_model,equipment_no,
               calibration_certificate,calibration_due,software,default_location,
               extra_json,updated_by,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?)
               ON CONFLICT(experiment) DO UPDATE SET
               software=excluded.software,updated_by=excluded.updated_by,
               updated_at=excluded.updated_at""",
            (
                experiment, "", "", "", "", "", data.get("software", ""),
                data.get("default_location", ""), "{}", actor, now(),
            ),
        )
    audit("device_preset", experiment, actor, "更新实验软件预设")


# ---------------------- Numbering and intake ----------------------
def next_commission_no() -> str:
    prefix = china_now().strftime("WT%Y%m%d")
    r = one("SELECT commission_no FROM commissions WHERE commission_no LIKE ? ORDER BY commission_no DESC LIMIT 1", (prefix + "%",))
    seq = int(r["commission_no"][-3:]) + 1 if r and r["commission_no"][-3:].isdigit() else 1
    return f"{prefix}{seq:03d}"


def next_sample_base() -> str:
    prefix = china_now().strftime("BP%Y%m%d")
    result = rows("SELECT group_no FROM sample_groups WHERE group_no LIKE ?", (prefix + "%",))
    seqs = []
    for x in result:
        m = re.fullmatch(re.escape(prefix) + r"(\d{3})", x["group_no"])
        if m:
            seqs.append(int(m.group(1)))
    return f"{prefix}{max(seqs or [0]) + 1:03d}"


def create_commission(data: dict[str, Any], groups: list[dict[str, Any]], actor: str) -> str:
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,))
    if not actor_row or actor_row["role"] != "样品管理员":
        raise ValueError("只有样品管理员可以建立委托和完成收样入库")
    if not groups:
        raise ValueError("至少添加一个样品组")
    missing_lots = [
        str(item.get("group_no", ""))
        for item in groups if not str(item.get("product_no", "")).strip()
    ]
    if missing_lots:
        raise ValueError("产品编号/批号为必填项：" + "、".join(missing_lots))
    commission_no = data["commission_no"].strip().upper().replace(" ", "")
    if not data.get("production_org_id"):
        raise ValueError("必须统一选择生产单位或受委托生产企业")
    ts = now()
    selected_methods: list[str] = []
    with connect() as c:
        c.execute(
            """INSERT INTO commissions(
               commission_no,client_org_id,client_name,client_address,contact,phone,
               production_org_id,production_org_name,production_relation,
               commission_date,due_date,subcontract_allowed,report_medium,conformity_judgment,
               uncertainty,delivery_method,cnas_mark,capability,method_choices,notes,status,
               created_by,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'已入库',?,?,?)""",
            (commission_no,data["client_org_id"],data["client_name"],data.get("client_address",""),
             data.get("contact",""),data.get("phone",""),data["production_org_id"],
             data["production_org_name"],data["production_relation"],str(data["commission_date"]),
             str(data["due_date"]),data.get("subcontract_allowed","否"),data.get("report_medium","电子档"),
             data.get("conformity_judgment","是"),data.get("uncertainty","否"),
             data.get("delivery_method","Email"),data.get("cnas_mark","否"),
             data.get("capability","完全满足"),"[]",data.get("notes",""),actor,ts,ts),
        )
        mapping = {x["experiment_code"]: x for x in list_experiment_methods()}
        for group_data in groups:
            group_no = group_data["group_no"].strip().upper().replace(" ", "")
            qty = int(group_data["quantity"])
            if qty < 1 or qty > 99:
                raise ValueError("每个样品组数量应为1～99")
            codes = list(dict.fromkeys(group_data.get("experiment_codes", [])))
            if not codes:
                raise ValueError(f"样品组{group_no}未选择检测项目与方法")
            missing = [code for code in codes if code not in mapping]
            if missing:
                raise ValueError("存在无效或已停用的检测项目")
            c.execute(
                """INSERT INTO sample_groups(
                   group_no,commission_no,catalog_id,sample_name,model,material_name,
                   production_org_id,production_org_name,production_relation,product_no,quantity,
                   unit,condition,condition_note,storage_area,notes,status,created_at,updated_at
                   ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, '待分配',?,?)""",
                (group_no,commission_no,group_data.get("catalog_id"),group_data["sample_name"],
                 group_data["model"],group_data["material_name"],data["production_org_id"],
                 data["production_org_name"],data["production_relation"],group_data.get("product_no",""),
                 qty,group_data.get("unit","件"),group_data.get("condition","完好"),
                 group_data.get("condition_note",""),group_data.get("storage_area","A区域"),
                 group_data.get("notes",""),ts,ts),
            )
            group_id = c.execute("SELECT last_insert_rowid()").fetchone()[0]
            for i in range(1, qty + 1):
                sample_no = f"{group_no}-S{i:02d}"
                c.execute(
                    """INSERT INTO samples(
                       sample_no,group_id,group_no,commission_no,sample_name,model,material_name,
                       condition,condition_note,current_location,current_holder,status,created_at,updated_at
                       ) VALUES(?,?,?,?,?,?,?,?,?,?,?,'待分配',?,?)""",
                    (sample_no,group_id,group_no,commission_no,group_data["sample_name"],group_data["model"],
                     group_data["material_name"],group_data.get("condition","完好"),
                     group_data.get("condition_note",""),group_data.get("storage_area","A区域"),actor,ts,ts),
                )
                c.execute(
                    """INSERT INTO sample_events(
                       sample_no,actor,action,from_status,to_status,from_location,to_location,details,created_at
                       ) VALUES(?,?,?,'','待分配','',?,?,?)""",
                    (sample_no,actor,"样品接收并入库",group_data.get("storage_area","A区域"),
                     f"委托编号:{commission_no};生产单位:{data['production_org_name']};关系:{data['production_relation']};"
                     f"样品状态:{group_data.get('condition','完好')};备注:{group_data.get('condition_note','')}",ts),
                )
            for code in codes:
                item = mapping[code]
                selected_methods.append(item["method_code"])
                c.execute(
                    """INSERT INTO requested_tests(
                       group_id,experiment_code,experiment,method_code,standard,status
                       ) VALUES(?,?,?,?,?,'待分配')""",
                    (group_id,code,item["experiment_name"],item["method_code"],item.get("standard","")),
                )
        method_choices = list(dict.fromkeys(selected_methods))
        c.execute("UPDATE commissions SET method_choices=?,updated_at=? WHERE commission_no=?",
                  (json.dumps(method_choices,ensure_ascii=False),ts,commission_no))
    audit("commission", commission_no, actor, "新建委托并入库", new_value=len(groups))
    return commission_no

def list_commissions() -> list[dict[str, Any]]:
    return rows("SELECT * FROM commissions ORDER BY created_at DESC")


def commission(commission_no: str) -> dict[str, Any] | None:
    r = one("SELECT * FROM commissions WHERE commission_no=?", (commission_no,))
    if r:
        r["method_choices_list"] = json.loads(r.get("method_choices") or "[]")
    return r


def commission_groups(commission_no: str, include_void: bool = False) -> list[dict[str, Any]]:
    q = "SELECT * FROM sample_groups WHERE commission_no=?"
    args: list[Any] = [commission_no]
    if not include_void:
        q += " AND is_void=0"
    return rows(q + " ORDER BY group_no", args)


def group(group_id: int) -> dict[str, Any] | None:
    return one("SELECT * FROM sample_groups WHERE id=?", (group_id,))


def group_samples(group_id: int) -> list[dict[str, Any]]:
    return rows("SELECT * FROM samples WHERE group_id=? ORDER BY sample_no", (group_id,))


def commission_samples(commission_no: str) -> list[dict[str, Any]]:
    return rows("SELECT s.* FROM samples s JOIN sample_groups g ON g.id=s.group_id WHERE s.commission_no=? AND g.is_void=0 ORDER BY s.sample_no", (commission_no,))


def requested_tests(group_id: int) -> list[dict[str, Any]]:
    return rows("SELECT * FROM requested_tests WHERE group_id=? ORDER BY experiment_code", (group_id,))


def void_group(group_id: int, actor: str, reason: str) -> None:
    g = group(group_id)
    if not g:
        raise ValueError("样品组不存在")
    if one("SELECT COUNT(*) n FROM task_packages WHERE group_id=?", (group_id,))["n"]:
        raise ValueError("该样品组已下发任务，不能删除，只能作废并另行处理")
    with connect() as c:
        c.execute("UPDATE sample_groups SET is_void=1,void_by=?,void_at=?,void_reason=?,status='已删除',updated_at=? WHERE id=?", (actor, now(), reason, now(), group_id))
        c.execute("UPDATE samples SET status='已删除',updated_at=? WHERE group_id=?", (now(), group_id))
    audit("sample_group", str(group_id), actor, "删除错误入库", reason=reason)



# ---------------------- Configurable experiment versions ----------------------
def list_experiment_configs(experiment_code: str | None = None) -> list[dict[str, Any]]:
    q = "SELECT * FROM experiment_config_versions"
    args: list[Any] = []
    if experiment_code:
        q += " WHERE experiment_code=?"; args.append(experiment_code)
    return rows(q + " ORDER BY experiment_name,id DESC", args)


def experiment_config(config_id: int) -> dict[str, Any] | None:
    return one("SELECT * FROM experiment_config_versions WHERE id=?", (config_id,))


def current_experiment_config(experiment_code: str) -> dict[str, Any] | None:
    return one(
        "SELECT * FROM experiment_config_versions WHERE experiment_code=? AND status='现行' ORDER BY id DESC LIMIT 1",
        (experiment_code,),
    )


def config_equipment(config_id: int, include_unavailable: bool = True) -> list[dict[str, Any]]:
    q = """SELECT ce.config_id,ce.management_no,ce.binding_role,ce.required,ce.sort_order,ce.note,
           e.seq,e.equipment_name,e.model,e.measuring_range,e.manufacturer,e.serial_no,
           e.purchase_time,e.calibration_time,e.responsible,e.equipment_class,e.enabled,
           e.lifecycle_status,e.status_note
           FROM experiment_config_equipment ce
           JOIN equipment_registry e ON e.management_no=ce.management_no
           WHERE ce.config_id=?"""
    if not include_unavailable:
        q += " AND e.enabled=1 AND e.lifecycle_status='启用'"
    return rows(q + " ORDER BY ce.sort_order,e.seq,e.management_no", (config_id,))


def create_experiment_config_version(
    experiment_code: str, version: str, actor: str, copy_current: bool = True,
) -> int:
    method = experiment_method(experiment_code)
    if not method:
        raise ValueError("实验项目不存在")
    version = str(version or "").strip()
    if not version:
        raise ValueError("配置版本号不能为空")
    current = current_experiment_config(experiment_code) if copy_current else None
    source = current or {
        "experiment_name": method["experiment_name"], "method_code": method["method_code"],
        "standard": method.get("standard", ""), "category": method.get("category", ""),
        "kind": method.get("kind") or "generic", "default_location": "",
        "sop_version": "", "record_template_version": "", "software": "", "note": "",
    }
    with connect() as c:
        cur = c.execute(
            """INSERT INTO experiment_config_versions(
               experiment_code,version,experiment_name,method_code,standard,category,kind,
               default_location,sop_version,record_template_version,software,status,
               effective_date,note,created_by,created_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,'草稿','',?,?,?)""",
            (
                experiment_code,version,source["experiment_name"],source["method_code"],
                source.get("standard", ""),source.get("category", ""),
                source.get("kind") or "generic",source.get("default_location", ""),
                source.get("sop_version", ""),source.get("record_template_version", ""),
                source.get("software", ""),source.get("note", ""),actor,now(),
            ),
        )
        config_id = int(cur.lastrowid)
        if current:
            for item in config_equipment(current["id"], True):
                c.execute(
                    """INSERT INTO experiment_config_equipment(
                       config_id,management_no,binding_role,required,sort_order,note,created_at,updated_at
                       ) VALUES(?,?,?,?,?,?,?,?)""",
                    (config_id,item["management_no"],item["binding_role"],item["required"],
                     item["sort_order"],item.get("note", ""),now(),now()),
                )
    audit("experiment_config", str(config_id), actor, "创建配置草稿", new_value=version)
    return config_id


def save_experiment_config(config_id: int, data: dict[str, Any], actor: str) -> None:
    current = experiment_config(config_id)
    if not current:
        raise ValueError("配置版本不存在")
    if current["status"] != "草稿":
        raise ValueError("只有草稿配置可以修改")
    location = str(data.get("default_location", "")).strip()
    from constants import DETECTION_LOCATIONS
    if location and location not in DETECTION_LOCATIONS:
        raise ValueError("检测地点不在受控地点库中")
    with connect() as c:
        c.execute(
            """UPDATE experiment_config_versions SET
               experiment_name=?,method_code=?,standard=?,category=?,kind=?,default_location=?,
               sop_version=?,record_template_version=?,software=?,effective_date=?,note=?
               WHERE id=?""",
            (
                str(data.get("experiment_name", "")).strip(),
                str(data.get("method_code", "")).strip(),data.get("standard", ""),
                data.get("category", ""),data.get("kind", "generic") or "generic",
                location,data.get("sop_version", ""),data.get("record_template_version", ""),
                data.get("software", ""),data.get("effective_date", ""),
                data.get("note", ""),config_id,
            ),
        )
    audit("experiment_config", str(config_id), actor, "保存配置草稿", new_value=json.dumps(data,ensure_ascii=False))


def bind_config_equipment(
    config_id: int, management_no: str, binding_role: str, required: bool,
    sort_order: int, note: str, actor: str,
) -> None:
    config = experiment_config(config_id)
    if not config or config["status"] != "草稿":
        raise ValueError("只能修改草稿配置的设备关系")
    device = equipment_item(management_no)
    if not device:
        raise ValueError("设备不存在")
    with connect() as c:
        c.execute(
            """INSERT INTO experiment_config_equipment(
               config_id,management_no,binding_role,required,sort_order,note,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?)
               ON CONFLICT(config_id,management_no) DO UPDATE SET
               binding_role=excluded.binding_role,required=excluded.required,
               sort_order=excluded.sort_order,note=excluded.note,updated_at=excluded.updated_at""",
            (config_id,management_no,binding_role,int(bool(required)),int(sort_order or 0),note,now(),now()),
        )
    audit("experiment_config_equipment", f"{config_id}|{management_no}", actor, "保存配置设备关系")


def unbind_config_equipment(config_id: int, management_no: str, actor: str) -> None:
    config = experiment_config(config_id)
    if not config or config["status"] != "草稿":
        raise ValueError("只能修改草稿配置的设备关系")
    with connect() as c:
        c.execute("DELETE FROM experiment_config_equipment WHERE config_id=? AND management_no=?", (config_id,management_no))
    audit("experiment_config_equipment", f"{config_id}|{management_no}", actor, "解除配置设备关系")


def publish_experiment_config(config_id: int, actor: str, reason: str = "") -> None:
    config = experiment_config(config_id)
    if not config or config["status"] != "草稿":
        raise ValueError("只能发布草稿配置")
    if not str(config.get("experiment_name", "")).strip() or not str(config.get("method_code", "")).strip():
        raise ValueError("实验名称和检测方法不能为空")
    equipment = config_equipment(config_id, True)
    required = [x for x in equipment if x["required"]]
    unavailable = [x for x in required if not x["enabled"] or x.get("lifecycle_status") != "启用"]
    if unavailable:
        raise ValueError("存在已停用、维修或报废的必需设备，不能发布")
    with connect() as c:
        c.execute(
            "UPDATE experiment_config_versions SET status='历史' WHERE experiment_code=? AND status='现行'",
            (config["experiment_code"],),
        )
        c.execute(
            """UPDATE experiment_config_versions SET status='现行',approved_by=?,approved_at=?,
               effective_date=CASE WHEN COALESCE(effective_date,'')='' THEN ? ELSE effective_date END
               WHERE id=?""",
            (actor,now(),str(china_today()),config_id),
        )
        c.execute(
            """UPDATE experiment_methods SET experiment_name=?,method_code=?,standard=?,category=?,kind=?,
               enabled=1,updated_at=? WHERE experiment_code=?""",
            (config["experiment_name"],config["method_code"],config.get("standard", ""),
             config.get("category", ""),config.get("kind") or "generic",now(),config["experiment_code"]),
        )
    audit("experiment_config", str(config_id), actor, "批准并发布配置", new_value=config["version"], reason=reason)


def _equipment_snapshot_row(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "management_no": item["management_no"], "equipment_name": item["equipment_name"],
        "model": item.get("model", ""), "measuring_range": item.get("measuring_range", ""),
        "manufacturer": item.get("manufacturer", ""), "serial_no": item.get("serial_no", ""),
        "calibration_time": item.get("calibration_time", ""), "responsible": item.get("responsible", ""),
        "equipment_class": item.get("equipment_class", ""), "lifecycle_status": item.get("lifecycle_status", ""),
        "binding_role": item.get("binding_role", ""), "required": int(bool(item.get("required"))),
        "sort_order": item.get("sort_order", 0), "note": item.get("note", ""),
    }


def build_experiment_config_snapshot(experiment_code: str) -> dict[str, Any]:
    config = current_experiment_config(experiment_code)
    if not config:
        raise ValueError("该实验尚未发布现行配置版本")
    equipment = config_equipment(config["id"], True)
    required_unavailable = [
        x for x in equipment if x["required"] and (not x["enabled"] or x.get("lifecycle_status") != "启用")
    ]
    if required_unavailable:
        raise ValueError("该实验现行配置存在不可用的必需设备，请先建立并发布新配置")
    sop = template_for_version(config["experiment_name"], "SOP", config.get("sop_version") or "") if config.get("sop_version") else active_version(config["experiment_name"], "SOP")
    record_tpl = template_for_version(config["experiment_name"], "原始记录表", config.get("record_template_version") or "") if config.get("record_template_version") else active_version(config["experiment_name"], "原始记录表")
    # Defensive fallback for a newly created database or an interrupted migration.
    if not sop or not record_tpl:
        from constants import EXPERIMENTS
        base = EXPERIMENTS.get(config["experiment_name"], {})
        if not sop and base.get("sop"):
            sop = {"version": config.get("sop_version") or "A/0", "file_name": base.get("sop")}
        if not record_tpl and base.get("template"):
            record_tpl = {"version": config.get("record_template_version") or "A/0", "file_name": base.get("template")}
    snapshot = {
        "config_id": config["id"], "config_version": config["version"],
        "experiment_code": config["experiment_code"], "experiment_name": config["experiment_name"],
        "method_code": config["method_code"], "standard": config.get("standard", ""),
        "category": config.get("category", ""), "kind": config.get("kind") or "generic",
        "default_location": config.get("default_location", ""), "software": config.get("software", ""),
        "sop_version": (sop or {}).get("version", config.get("sop_version", "")),
        "sop_file": (sop or {}).get("file_name", ""),
        "record_template_version": (record_tpl or {}).get("version", config.get("record_template_version", "")),
        "record_template_file": (record_tpl or {}).get("file_name", ""),
        "equipment": [_equipment_snapshot_row(x) for x in equipment],
        "published_at": config.get("approved_at", ""), "snapshot_created_at": now(),
    }
    raw = json.dumps(snapshot, ensure_ascii=False, sort_keys=True, default=str)
    snapshot["snapshot_hash"] = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    return snapshot


def task_config_snapshot(task_no: str) -> dict[str, Any]:
    item = one("SELECT * FROM task_config_snapshots WHERE task_no=?", (task_no,))
    if not item:
        task_item = task(task_no)
        return build_experiment_config_snapshot(task_item["experiment_code"]) if task_item else {}
    snapshot = json.loads(item.get("snapshot_json") or "{}")
    snapshot["snapshot_hash"] = item.get("snapshot_hash", snapshot.get("snapshot_hash", ""))
    return snapshot


def current_config_overview() -> list[dict[str, Any]]:
    result = []
    for method in list_experiment_methods(True):
        config = current_experiment_config(method["experiment_code"])
        result.append({
            "experiment_name": method["experiment_name"], "method_code": method["method_code"],
            "enabled": method["enabled"], "config_version": config.get("version", "未发布") if config else "未发布",
            "kind": config.get("kind", method.get("kind", "generic")) if config else method.get("kind", "generic"),
            "default_location": config.get("default_location", "") if config else "",
            "equipment_count": len(config_equipment(config["id"], True)) if config else 0,
            "status": config.get("status", "未发布") if config else "未发布",
        })
    return result

# ---------------------- Task packages ----------------------
def available_groups_for_assignment() -> list[dict[str, Any]]:
    return rows(
        """SELECT g.*,COUNT(CASE WHEN r.status='待分配' THEN 1 END) pending_count
           FROM sample_groups g JOIN requested_tests r ON r.group_id=g.id
           WHERE g.is_void=0 GROUP BY g.id HAVING pending_count>0 ORDER BY g.created_at"""
    )


def _next_package_no(group_no: str) -> str:
    r = one("SELECT package_no FROM task_packages WHERE group_no=? ORDER BY package_no DESC LIMIT 1", (group_no,))
    seq = int(r["package_no"].rsplit("P", 1)[-1]) + 1 if r else 1
    return f"{group_no}-P{seq:02d}"


def _auto_match_user(role: str, exclude: set[str] | None = None) -> str:
    exclude = exclude or set()
    candidates = rows(
        """SELECT u.username,
           (SELECT COUNT(*) FROM tasks t
            WHERE (t.reviewer=u.username OR t.quality_inspector=u.username)
              AND t.status NOT IN ('已完成','历史作废')) AS workload
           FROM users u WHERE u.role=? AND u.enabled=1
           ORDER BY workload,u.username""",
        (role,),
    )
    available = [x for x in candidates if x["username"] not in exclude]
    if not available:
        raise ValueError(f"没有可用的{role}，请管理员先维护人员授权")
    return available[0]["username"]


def create_task_package(
    group_id: int, experiment_codes: list[str], assignee: str,
    actor: str, reviewer: str | None = None,
) -> str:
    if not experiment_codes:
        raise ValueError("至少选择一个实验")
    g = group(group_id)
    if not g or g["is_void"]:
        raise ValueError("样品组不可用")
    available = {
        x["experiment_code"]: x
        for x in requested_tests(group_id)
        if x["status"] == "待分配"
    }
    missing = [x for x in experiment_codes if x not in available]
    if missing:
        raise ValueError("部分实验已分配或不属于该样品组")
    package_no = _next_package_no(g["group_no"])
    reviewer = reviewer or _auto_match_user("复核员", {assignee})
    quality_inspector = _auto_match_user("质量检测员", {assignee, reviewer})
    sample_nos = [x["sample_no"] for x in group_samples(group_id)]
    selected = [available[key] for key in experiment_codes]
    config_snapshots = {x["experiment_code"]: build_experiment_config_snapshot(x["experiment_code"]) for x in selected}
    experiment_names = [config_snapshots[x["experiment_code"]]["experiment_name"] for x in selected]
    existing_task_count = one(
        "SELECT COUNT(*) n FROM tasks WHERE group_no=?", (g["group_no"],)
    )["n"]
    ts = now()
    with connect() as c:
        c.execute(
            """INSERT INTO task_packages(
               package_no,commission_no,group_id,group_no,assignee,reviewer,quality_inspector,material_name,
               sample_nos,experiment_codes,experiments,status,assigned_by,assigned_at,
               notified_at,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,'待接收',?,?,?,?,?)""",
            (
                package_no, g["commission_no"], group_id, g["group_no"],
                assignee, reviewer, quality_inspector, g["material_name"],
                json.dumps(sample_nos, ensure_ascii=False),
                json.dumps(experiment_codes, ensure_ascii=False),
                json.dumps(experiment_names, ensure_ascii=False),
                actor, ts, ts, ts, ts,
            ),
        )
        for index, req in enumerate(selected, 1):
            task_no = f"{g['group_no']}-T{existing_task_count + index:02d}"
            snap = config_snapshots[req["experiment_code"]]
            c.execute(
                """INSERT INTO tasks(
                   task_no,package_no,commission_no,group_id,group_no,sample_nos,
                   experiment_code,experiment,method_code,standard,material_name,
                   assignee,reviewer,quality_inspector,status,created_at,updated_at
                   ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,'待接收',?,?)""",
                (
                    task_no, package_no, g["commission_no"], group_id, g["group_no"],
                    json.dumps(sample_nos, ensure_ascii=False),
                    req["experiment_code"], snap["experiment_name"], snap["method_code"],
                    snap["standard"], g["material_name"], assignee, reviewer,
                    quality_inspector, ts, ts,
                ),
            )
            c.execute(
                """INSERT INTO task_config_snapshots(
                   task_no,config_id,config_version,snapshot_json,snapshot_hash,created_at
                   ) VALUES(?,?,?,?,?,?)""",
                (task_no,snap["config_id"],snap["config_version"],
                 json.dumps(snap,ensure_ascii=False,default=str),snap["snapshot_hash"],ts),
            )
            c.execute(
                "UPDATE requested_tests SET status='已分配',task_no=? WHERE id=?",
                (task_no, req["id"]),
            )
        c.execute(
            "UPDATE sample_groups SET status='等待实验员接收',updated_at=? WHERE id=?",
            (ts, group_id),
        )
        c.execute(
            "UPDATE samples SET status='等待实验员接收',updated_at=? WHERE group_id=?",
            (ts, group_id),
        )
        for sample_no in sample_nos:
            current = one(
                "SELECT current_location FROM samples WHERE sample_no=?",
                (sample_no,),
            ) or {}
            c.execute(
                """INSERT INTO sample_events(
                   sample_no,actor,action,from_status,to_status,from_location,
                   to_location,details,created_at
                   ) VALUES(?,?,'任务包下发','待分配','等待实验员接收',?,?,?,?)""",
                (
                    sample_no, actor, current.get("current_location", ""),
                    current.get("current_location", ""),
                    f"任务包:{package_no};实验:{'、'.join(experiment_names)};实验员:{assignee}",
                    ts,
                ),
            )
    audit(
        "task_package", package_no, actor, "下发任务包",
        new_value="、".join(experiment_names),
    )
    create_notification(
        assignee, "收到新实验任务",
        f"样品管理员已下发任务包 {package_no}，请接收并开展实验。",
        "task_package", package_no,
    )
    create_notification(
        reviewer, "收到待复核任务",
        f"任务包 {package_no} 已分配，实验员提交后请进行原始记录复核。",
        "task_package", package_no,
    )
    create_notification(
        quality_inspector, "收到质量确认任务",
        f"任务包 {package_no} 已分配，原始记录复核通过后请进行质量确认。",
        "task_package", package_no,
    )
    return package_no


def list_packages(role: str | None = None, username: str | None = None, statuses: list[str] | None = None) -> list[dict[str, Any]]:
    q = "SELECT * FROM task_packages WHERE 1=1"
    args: list[Any] = []
    if role == "实验员" and username:
        q += " AND assignee=?"; args.append(username)
    elif role == "复核员" and username:
        q += " AND reviewer=?"; args.append(username)
    elif role == "质量检测员" and username:
        q += " AND quality_inspector=?"; args.append(username)
    if statuses:
        q += " AND status IN (" + ",".join("?" * len(statuses)) + ")"; args.extend(statuses)
    result = rows(q + " ORDER BY updated_at DESC", args)
    for x in result:
        x["sample_nos_list"] = json.loads(x.get("sample_nos") or "[]")
        x["experiment_codes_list"] = json.loads(x.get("experiment_codes") or "[]")
        x["experiments_list"] = json.loads(x.get("experiments") or "[]")
    return result


def package(package_no: str) -> dict[str, Any] | None:
    r = one("SELECT * FROM task_packages WHERE package_no=?", (package_no,))
    if r:
        r["sample_nos_list"] = json.loads(r.get("sample_nos") or "[]")
        r["experiment_codes_list"] = json.loads(r.get("experiment_codes") or "[]")
        r["experiments_list"] = json.loads(r.get("experiments") or "[]")
    return r


def package_tasks(package_no: str) -> list[dict[str, Any]]:
    result = rows("SELECT * FROM tasks WHERE package_no=? ORDER BY task_no", (package_no,))
    for x in result:
        x["sample_nos_list"] = json.loads(x.get("sample_nos") or "[]")
    return result


def task(task_no: str) -> dict[str, Any] | None:
    r = one("SELECT * FROM tasks WHERE task_no=?", (task_no,))
    if r:
        r["sample_nos_list"] = json.loads(r.get("sample_nos") or "[]")
    return r


def accept_package(
    package_no: str,
    actor: str,
    result: str,
    detection_locations: dict[str, str] | str,
    note: str,
) -> None:
    p = package(package_no)
    if not p or p["assignee"] != actor:
        raise ValueError("只能由被指定的实验员接收任务包")
    if p["status"] != "待接收":
        raise ValueError("任务包当前状态不能接收")
    if result != "样品已收到，确认完好":
        with connect() as c:
            c.execute("UPDATE task_packages SET status='接收异常',accepted_at=?,acceptance_result=?,acceptance_note=?,updated_at=? WHERE package_no=?", (now(), result, note, now(), package_no))
        audit("task_package", package_no, actor, "接收异常", reason=note)
        return
    task_rows = package_tasks(package_no)
    if isinstance(detection_locations, str):
        location_map = {item["task_no"]: detection_locations for item in task_rows}
    else:
        location_map = {
            str(task_no): str(location or "").strip()
            for task_no, location in detection_locations.items()
        }
    from constants import DETECTION_LOCATIONS
    missing = [item["experiment"] for item in task_rows if not location_map.get(item["task_no"])]
    if missing:
        raise ValueError("请为每个实验选择检测位置：" + "、".join(missing))
    invalid = [
        location_map[item["task_no"]]
        for item in task_rows
        if location_map[item["task_no"]] not in DETECTION_LOCATIONS
    ]
    if invalid:
        raise ValueError("检测位置不在受控地点清单中：" + "、".join(dict.fromkeys(invalid)))

    ts = now()
    purpose = "、".join(p["experiments_list"])
    unique_locations = list(dict.fromkeys(location_map.values()))
    location_summary = unique_locations[0] if len(unique_locations) == 1 else "多地点流转"
    with connect() as c:
        c.execute(
            """UPDATE task_packages SET status='检测中',accepted_at=?,detection_location=?,
               acceptance_result=?,acceptance_note=?,updated_at=? WHERE package_no=?""",
            (ts, location_summary, result, note, ts, package_no),
        )
        for item in task_rows:
            task_no = item["task_no"]
            location = location_map[task_no]
            c.execute(
                """UPDATE tasks SET status='检测中',detection_location=?,updated_at=?
                   WHERE task_no=?""",
                (location, ts, task_no),
            )
            snapshot_row = c.execute(
                "SELECT snapshot_json FROM task_config_snapshots WHERE task_no=?",
                (task_no,),
            ).fetchone()
            if snapshot_row:
                snapshot = json.loads(snapshot_row[0] or "{}")
                snapshot["selected_detection_location"] = location
                raw = json.dumps(snapshot, ensure_ascii=False, sort_keys=True, default=str)
                snapshot_hash = hashlib.sha256(raw.encode("utf-8")).hexdigest()
                snapshot["snapshot_hash"] = snapshot_hash
                c.execute(
                    """UPDATE task_config_snapshots
                       SET snapshot_json=?,snapshot_hash=? WHERE task_no=?""",
                    (
                        json.dumps(snapshot, ensure_ascii=False, default=str),
                        snapshot_hash,
                        task_no,
                    ),
                )
        c.execute("UPDATE sample_groups SET status='检测中',updated_at=? WHERE id=?", (ts, p["group_id"]))
        for sample_no in p["sample_nos_list"]:
            old = one("SELECT status,current_location FROM samples WHERE sample_no=?", (sample_no,)) or {}
            c.execute("UPDATE samples SET status='检测中',current_location=?,current_holder=?,updated_at=? WHERE sample_no=?", (location_summary, actor, ts, sample_no))
            c.execute(
                """INSERT OR REPLACE INTO package_loans(package_no,sample_no,borrower,borrowed_at,purpose,
                   detection_location,issue_note,return_status) VALUES(?,?,?,?,?,?,?,'未归还')""",
                (package_no, sample_no, actor, ts, purpose, location_summary, note),
            )
            c.execute(
                """INSERT INTO sample_events(sample_no,actor,action,from_status,to_status,from_location,
                   to_location,details,created_at) VALUES(?,?,'实验员领用',?,'检测中',?,?,?,?)""",
                (sample_no, actor, old.get("status", ""), old.get("current_location", ""), location_summary, f"任务包:{package_no};用途:{purpose};{note}", ts),
            )
    audit(
        "task_package",
        package_no,
        actor,
        "确认领用",
        new_value=json.dumps(location_map, ensure_ascii=False),
    )


def mark_task_experiment_time(task_no: str, actor: str, action: str, system_auto: bool = False) -> dict[str, Any]:
    """Record experiment start/end as immutable timeline events, not manual text."""
    item = task(task_no)
    if not item:
        raise ValueError("实验任务不存在")
    if item.get("assignee") != actor:
        raise ValueError("只能由该任务的实验员记录实验时间")
    if item.get("status") not in ("检测中", "退回修改"):
        raise ValueError("当前任务状态不能记录实验时间")
    ts = now()
    if action == "开始":
        if item.get("experiment_started_at"):
            return item
        with connect() as c:
            c.execute(
                """UPDATE tasks SET experiment_started_at=?,updated_at=?
                   WHERE task_no=?""",
                (ts, ts, task_no),
            )
        audit("task", task_no, actor, "系统自动开始实验" if system_auto else "实验开始", new_value=ts)
    elif action == "结束":
        if not item.get("experiment_started_at"):
            raise ValueError("请先记录实验开始时间")
        if item.get("experiment_ended_at"):
            return item
        with connect() as c:
            c.execute(
                """UPDATE tasks SET experiment_ended_at=?,updated_at=?
                   WHERE task_no=?""",
                (ts, ts, task_no),
            )
        audit("task", task_no, actor, "实验结束", new_value=ts)
    else:
        raise ValueError("未知的时间轴操作")
    return task(task_no) or {}


# ---------------------- Records and review ----------------------
def latest_record(task_no: str) -> dict[str, Any] | None:
    r = one("SELECT * FROM records WHERE task_no=? ORDER BY version DESC LIMIT 1", (task_no,))
    if r:
        r["payload"] = json.loads(r.get("payload") or "{}")
    return r


def record(record_no: str, version: int) -> dict[str, Any] | None:
    r = one("SELECT * FROM records WHERE record_no=? AND version=?", (record_no, version))
    if r:
        r["payload"] = json.loads(r.get("payload") or "{}")
    return r


def record_versions(record_no: str) -> list[dict[str, Any]]:
    result = rows("SELECT * FROM records WHERE record_no=? ORDER BY version", (record_no,))
    for x in result:
        x["payload"] = json.loads(x.get("payload") or "{}")
    return result


def _flatten(value: Any, prefix: str = "") -> dict[str, Any]:
    out: dict[str, Any] = {}
    if isinstance(value, dict):
        for k, v in value.items():
            out.update(_flatten(v, f"{prefix}.{k}" if prefix else k))
    elif isinstance(value, list):
        for i, v in enumerate(value):
            out.update(_flatten(v, f"{prefix}[{i}]"))
    else:
        out[prefix] = value
    return out


def save_record(task_no: str, version: int, payload: dict[str, Any], owner: str, status: str, template_version: str = "A/0", sop_version: str = "A/0", reason: str = "", compare_payload: dict[str, Any] | None = None) -> None:
    t = task(task_no)
    if not t:
        raise ValueError("任务不存在")
    if "待复核" in status:
        from constants import photo_checkpoints
        if not bool(payload.get("tester_self_check")):
            raise ValueError("实验员必须完成提交前自查确认")
        if not t.get("experiment_started_at") or not t.get("experiment_ended_at"):
            raise ValueError("请先在实验记录顶部完成实验开始和结束时间记录")
        if not mandatory_camera_complete(task_no, photo_checkpoints(t["experiment"])):
            raise ValueError("强制现场照片尚未完成，不能提交复核")
    ts = now()
    existing = record(task_no, version)
    audit_base = existing["payload"] if existing else compare_payload
    with connect() as c:
        c.execute(
            """INSERT INTO records(record_no,task_no,version,experiment,owner,status,payload,
               template_version,sop_version,change_reason,tester_signed_at,created_at,updated_at)
               VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(record_no,version) DO UPDATE SET
               owner=excluded.owner,status=excluded.status,payload=excluded.payload,
               template_version=excluded.template_version,sop_version=excluded.sop_version,
               change_reason=excluded.change_reason,
               tester_signed_at=COALESCE(excluded.tester_signed_at,records.tester_signed_at),
               updated_at=excluded.updated_at""",
            (
                task_no, task_no, version, t["experiment"], owner, status,
                json.dumps(payload, ensure_ascii=False, default=str), template_version, sop_version,
                reason, ts if "待复核" in status else None, ts, ts,
            ),
        )
        c.execute("UPDATE tasks SET status=?,updated_at=? WHERE task_no=?", (status if status != "草稿" else "检测中", ts, task_no))
    if audit_base is not None:
        old, new = _flatten(audit_base), _flatten(payload)
        for field in sorted(set(old) | set(new)):
            if str(old.get(field, "")) != str(new.get(field, "")):
                audit("record", task_no, owner, "字段修改", field, old.get(field, ""), new.get(field, ""), reason)
    audit(
        "record", task_no, owner,
        "提交复核" if "待复核" in status else "保存草稿",
        reason=reason, snapshot=payload,
    )
    if "待复核" in status:
        create_notification(
            t.get("reviewer", ""), "原始记录待复核",
            f"实验员已提交 {task_no} V{version} 原始记录，请复核。",
            "record", task_no,
        )


def pending_reviews(username: str | None = None) -> list[dict[str, Any]]:
    q = """SELECT r.*,t.package_no,t.commission_no,t.group_no,t.sample_nos,t.experiment,t.reviewer
           FROM records r JOIN tasks t ON t.task_no=r.task_no
           WHERE r.status IN ('待复核','更正待复核')"""
    args: list[Any] = []
    if username:
        q += " AND t.reviewer=?"; args.append(username)
    result = rows(q + " ORDER BY r.updated_at", args)
    for x in result:
        x["payload"] = json.loads(x.get("payload") or "{}")
    return result


def review_record(record_no: str, version: int, reviewer: str, decision: str, comment: str) -> None:
    r = record(record_no, version)
    if not r:
        raise ValueError("记录不存在")
    if r.get("status") not in ("待复核", "更正待复核"):
        raise ValueError("该版本已经处理，不能重复复核")
    t = task(record_no)
    if t and t["reviewer"] != reviewer:
        raise ValueError("当前人员不是该任务的复核人")
    if decision == "退回" and not comment.strip():
        raise ValueError("退回实验员修改时必须填写复核意见")
    ts = now()
    status = "已锁定" if decision == "通过" else "复核退回"
    next_version = version + 1
    with connect() as c:
        c.execute(
            """UPDATE records SET status=?,reviewer_signed_at=?,updated_at=?
               WHERE record_no=? AND version=?""",
            (status, ts if decision == "通过" else None, ts, record_no, version),
        )
        c.execute("INSERT INTO reviews(record_no,version,reviewer,decision,comment,reviewed_at) VALUES(?,?,?,?,?,?)", (record_no, version, reviewer, decision, comment, ts))
        c.execute("UPDATE tasks SET status=?,updated_at=? WHERE task_no=?", ("已复核" if decision == "通过" else "退回修改", ts, record_no))
        if decision == "退回":
            latest_version=c.execute(
                "SELECT COALESCE(MAX(version),0) n FROM records WHERE record_no=?",
                (record_no,),
            ).fetchone()["n"]
            next_version=max(version+1,int(latest_version)+1)
            c.execute(
                """INSERT INTO records(
                   record_no,task_no,version,experiment,owner,status,payload,
                   template_version,sop_version,change_reason,
                   created_at,updated_at
                   ) VALUES(?,?,?,?,?,'草稿',?,?,?,?,?,?)""",
                (
                    record_no,record_no,next_version,r.get("experiment",""),
                    r.get("owner",""),json.dumps(r.get("payload") or {},ensure_ascii=False,default=str),
                    r.get("template_version") or "A/0",r.get("sop_version") or "A/0",
                    f"复核退回二次编辑：{comment}",ts,ts,
                ),
            )
    audit("record", record_no, reviewer, "复核" + decision, reason=comment)
    if decision == "通过" and t:
        freeze_document_version("record", record_no, version, "实验员自查及复核员审核锁定", r["payload"], reviewer)
        ensure_report_for_task(record_no)
        _refresh_package_and_report(t["package_no"], t["commission_no"])
    elif t:
        freeze_document_version(
            "record",record_no,version,"复核退回历史版本",r["payload"],reviewer,
        )
        audit(
            "record",record_no,reviewer,"创建修改版（复核退回）",
            old_value=f"V{version}",new_value=f"V{next_version}",
            reason=comment,snapshot=r["payload"],
        )
        create_notification(
            t.get("assignee", ""), "原始记录已退回",
            f"{record_no} V{version} 已被复核员退回；复核意见：{comment}。系统已保留全部数据并生成二次编辑草稿 V{next_version}，请进入实验记录修改。",
            "record", record_no,
        )


def pending_record_quality_reviews(username: str | None = None) -> list[dict[str, Any]]:
    query = """SELECT r.*,t.package_no,t.commission_no,t.group_no,t.sample_nos,
               t.experiment,t.quality_inspector
               FROM records r JOIN tasks t ON t.task_no=r.task_no
               WHERE r.status='待质量确认'"""
    args: list[Any] = []
    if username:
        query += " AND t.quality_inspector=?"
        args.append(username)
    result = rows(query + " ORDER BY r.updated_at", args)
    for item in result:
        item["payload"] = json.loads(item.get("payload") or "{}")
    return result


def quality_review_record(
    record_no: str, version: int, inspector: str, decision: str, comment: str,
) -> None:
    item = record(record_no, version)
    task_row = task(record_no)
    if not item or item.get("status") != "待质量确认":
        raise ValueError("该原始记录当前不在质量确认阶段")
    if not task_row or task_row.get("quality_inspector") != inspector:
        raise ValueError("当前人员不是该任务的质量检测员")
    ts = now()
    passed = decision == "通过"
    with connect() as c:
        c.execute(
            """UPDATE records SET status=?,quality_signed_at=?,updated_at=?
               WHERE record_no=? AND version=?""",
            ("已锁定" if passed else "退回修改", ts if passed else None, ts, record_no, version),
        )
        c.execute(
            "UPDATE tasks SET status=?,updated_at=? WHERE task_no=?",
            ("已复核" if passed else "退回修改", ts, record_no),
        )
        c.execute(
            """INSERT INTO reviews(record_no,version,reviewer,decision,comment,reviewed_at)
               VALUES(?,?,?,?,?,?)""",
            (record_no, version, inspector, "质量确认" + decision, comment, ts),
        )
    audit("record", record_no, inspector, "质量确认" + decision, reason=comment)
    if passed:
        freeze_document_version("record", record_no, version, "三级签审锁定", item["payload"], inspector)
        ensure_report_for_task(record_no)
        _refresh_package_and_report(task_row["package_no"], task_row["commission_no"])
    else:
        create_notification(
            task_row.get("assignee", ""), "原始记录质量确认退回",
            f"{record_no} V{version} 已由质量检测员退回，请进入修改中心处理。",
            "record", record_no,
        )


def _refresh_package_and_report(package_no: str, commission_no: str) -> None:
    unfinished = one("SELECT COUNT(*) n FROM tasks WHERE package_no=? AND status NOT IN ('已复核','已完成')", (package_no,))["n"]
    if unfinished == 0:
        with connect() as c:
            c.execute("UPDATE task_packages SET status='待归还',updated_at=? WHERE package_no=?", (now(), package_no))
    commission_unfinished = one("SELECT COUNT(*) n FROM tasks WHERE commission_no=? AND status NOT IN ('已复核','已完成')", (commission_no,))["n"]
    requested_unassigned = one("""SELECT COUNT(*) n FROM requested_tests r JOIN sample_groups g ON g.id=r.group_id
                                  WHERE g.commission_no=? AND g.is_void=0 AND r.status='待分配'""", (commission_no,))["n"]
    # The report is created after the physical return is confirmed. Keeping this check here
    # only advances the package to "待归还"; report reconciliation is triggered on return.


def create_revision(record_no: str, actor: str, reason: str) -> int:
    if not reason.strip():
        raise ValueError("修改原因不能为空")
    versions = record_versions(record_no)
    if not versions or versions[-1]["status"] != "已锁定":
        raise ValueError("只有已锁定记录可以创建修改版")
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if actor_row.get("role") != "实验员" or versions[-1].get("owner") != actor:
        raise ValueError("只有该任务实验员可以在报告签发前创建修改版")
    published = one(
        "SELECT report_no FROM reports WHERE task_no=? AND status='已发布'",
        (record_no,),
    )
    if published:
        raise ValueError(f"报告{published['report_no']}已经签发，不能直接修改原始记录；请由管理员启动报告作废/更正流程")
    base = versions[-1]
    version = base["version"] + 1
    save_record(record_no, version, base["payload"], actor, "草稿", base.get("template_version") or "A/0", base.get("sop_version") or "A/0", reason, base["payload"])
    return version


def audit_logs(entity_id: str | None = None) -> list[dict[str, Any]]:
    if entity_id:
        return rows("SELECT * FROM audit_logs WHERE entity_id=? ORDER BY id", (entity_id,))
    return rows("SELECT * FROM audit_logs ORDER BY id DESC LIMIT 500")


def modification_logs(entity_id: str | None = None) -> list[dict[str, Any]]:
    """Return only business mutations, excluding ordinary workflow/read events."""
    mutation_actions = (
        "字段修改", "历史版本作废", "创建修改版", "报告作废", "启动报告更正",
        "更正并重新签发", "直接作废", "更新", "修改", "替代旧照片",
    )
    clauses = ["(" + " OR ".join("action LIKE ?" for _ in mutation_actions) + ")"]
    args: list[Any] = [f"%{action}%" for action in mutation_actions]
    if entity_id:
        clauses.append("entity_id=?")
        args.append(entity_id)
    result = rows(
        "SELECT * FROM audit_logs WHERE " + " AND ".join(clauses) + " ORDER BY created_at,id",
        args,
    )
    # Present the field in human language while retaining the exact technical path.
    labels: dict[str, str] = {}
    try:
        from experiment_schemas import SCHEMAS
        for definition in SCHEMAS.values():
            for section in definition.get("sections", []):
                for field in section.get("fields", []):
                    labels[field.get("key", "")] = f"{section.get('title','')} / {field.get('label','')}"
            for key, label, _type in definition.get("columns", []):
                labels[key] = f"原始测量数据 / {label}"
    except Exception:
        labels = {}
    for item in result:
        path = str(item.get("field_name") or "")
        match = re.search(r"(?:parameters|rows\[\d+\])\.([A-Za-z0-9_]+)$", path)
        key = match.group(1) if match else path.rsplit(".", 1)[-1]
        item["field_label"] = (
            f"{labels.get(key, key or '单据级')}（{path}）" if path else "单据级"
        )
    return result


# ---------------------- Return ----------------------
def return_candidates(username: str) -> list[dict[str, Any]]:
    return list_packages("实验员", username, ["待归还"])


def package_loan_rows(package_no: str) -> list[dict[str, Any]]:
    return rows("SELECT * FROM package_loans WHERE package_no=? ORDER BY sample_no", (package_no,))


def submit_package_return(package_no: str, actor: str, items: list[dict[str, Any]]) -> None:
    p = package(package_no)
    if not p or p["assignee"] != actor or p["status"] != "待归还":
        raise ValueError("当前任务包不能提交归还")
    ts = now()
    with connect() as c:
        for item in items:
            sample_no = item["sample_no"]
            c.execute(
                """UPDATE package_loans SET return_condition=?,return_note=?,returned_by=?,returned_at=?,
                   return_status='待回库确认' WHERE package_no=? AND sample_no=?""",
                (item.get("condition", "完好"), item.get("note", ""), actor, ts, package_no, sample_no),
            )
            old = one("SELECT status,current_location FROM samples WHERE sample_no=?", (sample_no,)) or {}
            c.execute("UPDATE samples SET status='待回库确认',current_location='回库交接区',current_holder='',updated_at=? WHERE sample_no=?", (ts, sample_no))
            c.execute(
                """INSERT INTO sample_events(sample_no,actor,action,from_status,to_status,from_location,to_location,details,created_at)
                   VALUES(?,?,'实验员归还',?,'待回库确认',?,'回库交接区',?,?)""",
                (sample_no, actor, old.get("status", ""), old.get("current_location", ""), f"任务包:{package_no};状态:{item.get('condition','')};备注:{item.get('note','')}", ts),
            )
        c.execute("UPDATE task_packages SET status='待回库确认',return_submitted_at=?,updated_at=? WHERE package_no=?", (ts, ts, package_no))
    audit("task_package", package_no, actor, "提交整组样品归还")


def pending_return_packages() -> list[dict[str, Any]]:
    return list_packages(statuses=["待回库确认"])


def confirm_package_return(package_no: str, actor: str, items: list[dict[str, Any]]) -> None:
    p = package(package_no)
    if not p or p["status"] != "待回库确认":
        raise ValueError("任务包不在待回库确认状态")
    ts = now()
    with connect() as c:
        for item in items:
            sample_no, location = item["sample_no"], item["location"]
            loan = one("SELECT return_condition FROM package_loans WHERE package_no=? AND sample_no=?", (package_no, sample_no)) or {}
            c.execute(
                """UPDATE package_loans SET return_status='已回库',confirmed_by=?,confirmed_at=?,confirmed_location=?
                   WHERE package_no=? AND sample_no=?""",
                (actor, ts, location, package_no, sample_no),
            )
            status = "全部消耗，记录归档" if loan.get("return_condition") == "全部消耗" else "留样保存"
            c.execute("UPDATE samples SET status=?,current_location=?,current_holder=?,updated_at=? WHERE sample_no=?", (status, location, actor, ts, sample_no))
            c.execute(
                """INSERT INTO sample_events(sample_no,actor,action,from_status,to_status,from_location,to_location,details,created_at)
                   VALUES(?,?,'回库确认','待回库确认',?,'回库交接区',?,?,?)""",
                (sample_no, actor, status, location, package_no, ts),
            )
        c.execute("UPDATE task_packages SET status='已回库',return_confirmed_at=?,updated_at=? WHERE package_no=?", (ts, ts, package_no))
        c.execute("UPDATE sample_groups SET status='留样保存',updated_at=? WHERE id=?", (ts, p["group_id"]))
    audit("task_package", package_no, actor, "确认整组样品回库")
    reconcile_eligible_reports()


# ---------------------- Attachments ----------------------
def _safe_name(name: str) -> str:
    stem = re.sub(r"[^A-Za-z0-9._-]+", "_", Path(name).name)
    return stem[:160] or "file"


def save_attachment(meta: dict[str, Any], content: bytes, actor: str) -> str:
    sha = hashlib.sha256(content).hexdigest()
    prefix = china_now().strftime("ATT%Y%m%d")
    last = one("SELECT attachment_id FROM attachments WHERE attachment_id LIKE ? ORDER BY attachment_id DESC LIMIT 1", (prefix + "%",))
    seq = int(last["attachment_id"][-4:]) + 1 if last else 1
    attachment_id = f"{prefix}{seq:04d}"
    task_part = _safe_name(meta.get("task_no") or "unassigned")
    folder = ATTACHMENT_DIR / task_part
    folder.mkdir(parents=True, exist_ok=True)
    stored = f"{sha[:12]}_{_safe_name(meta.get('original_name','file'))}"
    path = folder / stored
    path.write_bytes(content)
    try:
        relative = path.relative_to(ROOT).as_posix()
    except ValueError:
        relative = path.as_posix()
    with connect() as c:
        c.execute(
            """INSERT INTO attachments(attachment_id,commission_no,package_no,task_no,sample_no,
               attachment_type,original_name,stored_name,relative_path,sha256,captured_at,uploader,
               description,is_original,parent_attachment_id,capture_source,checkpoint_code,
               checkpoint_label,device_id,evidence_status,server_captured_at,created_at)
               VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                attachment_id, meta.get("commission_no"), meta.get("package_no"), meta.get("task_no"),
                meta.get("sample_no"), meta.get("attachment_type"), meta.get("original_name"), stored,
                relative, sha, str(meta.get("captured_at") or now()), actor,
                meta.get("description", ""), int(bool(meta.get("is_original", True))),
                meta.get("parent_attachment_id"), meta.get("capture_source", "file"),
                meta.get("checkpoint_code", ""), meta.get("checkpoint_label", ""),
                meta.get("device_id", ""), meta.get("evidence_status", "有效"),
                meta.get("server_captured_at", now()), now(),
            ),
        )
    audit("attachment", attachment_id, actor, "上传附件", new_value=meta.get("original_name", ""))
    return attachment_id


def supersede_camera_checkpoint(
    task_no: str, checkpoint_code: str, actor: str, sample_no: str = "",
) -> None:
    prior = rows(
        """SELECT attachment_id FROM attachments
           WHERE task_no=? AND checkpoint_code=? AND capture_source='live_camera'
             AND COALESCE(sample_no,'')=? AND evidence_status='有效'""",
        (task_no, checkpoint_code, sample_no),
    )
    if not prior:
        return
    with connect() as c:
        c.execute(
            """UPDATE attachments SET evidence_status='已替代'
               WHERE task_no=? AND checkpoint_code=? AND capture_source='live_camera'
                 AND COALESCE(sample_no,'')=? AND evidence_status='有效'""",
            (task_no, checkpoint_code, sample_no),
        )
    audit(
        "photo_evidence", task_no, actor, "重拍替代旧照片",
        field_name=checkpoint_code,
        old_value="、".join(x["attachment_id"] for x in prior),
        new_value="等待新照片",
    )


def camera_checkpoint_status(task_no: str, checkpoints: list[tuple[str, str, bool]]) -> list[dict[str, Any]]:
    from constants import SAMPLE_LEVEL_PHOTO_CODES
    task_row = task(task_no) or {}
    required_samples = task_row.get("sample_nos_list") or []
    current = rows(
        """SELECT checkpoint_code,COALESCE(sample_no,'') sample_no,
           COUNT(*) AS photo_count,MAX(server_captured_at) AS captured_at
           FROM attachments WHERE task_no=? AND capture_source='live_camera'
             AND is_original=1 AND evidence_status='有效'
           GROUP BY checkpoint_code,COALESCE(sample_no,'')""",
        (task_no,),
    )
    output = []
    for code, label, required in checkpoints:
        matched = [x for x in current if x["checkpoint_code"] == code]
        captured_samples = {x["sample_no"] for x in matched if x["sample_no"]}
        missing_samples = [
            sample_no for sample_no in required_samples if sample_no not in captured_samples
        ] if code in SAMPLE_LEVEL_PHOTO_CODES else []
        complete = (
            not missing_samples and bool(required_samples)
            if code in SAMPLE_LEVEL_PHOTO_CODES
            else any(not x["sample_no"] for x in matched)
        )
        output.append({
            "checkpoint_code": code, "checkpoint_label": label, "required": required,
            "complete": complete, "photo_count": sum(x["photo_count"] for x in matched),
            "captured_at": max((x["captured_at"] or "" for x in matched), default=""),
            "missing_samples": missing_samples,
        })
    return output


def mandatory_camera_complete(task_no: str, checkpoints: list[tuple[str, str, bool]]) -> bool:
    return all(x["complete"] for x in camera_checkpoint_status(task_no, checkpoints) if x["required"])


def list_attachments(task_no: str | None = None, commission_no: str | None = None) -> list[dict[str, Any]]:
    q = "SELECT * FROM attachments WHERE 1=1"; args: list[Any] = []
    if task_no:
        q += " AND task_no=?"; args.append(task_no)
    if commission_no:
        q += " AND commission_no=?"; args.append(commission_no)
    result = rows(q + " ORDER BY created_at DESC", args)
    # Legacy databases may retain an obsolete compatibility column. It is not
    # part of the current attachment-trace model and is never returned to UI/export.
    for item in result:
        item.pop("equipment_" + "software", None)
    return result


def attachment_file(meta: dict[str, Any]) -> Path:
    value = Path(meta["relative_path"])
    return value if value.is_absolute() else ROOT / value


# ---------------------- Events and dashboard ----------------------
def sample_events(sample_no: str) -> list[dict[str, Any]]:
    return rows("SELECT * FROM sample_events WHERE sample_no=? ORDER BY id", (sample_no,))


def list_samples() -> list[dict[str, Any]]:
    return rows("SELECT * FROM samples ORDER BY updated_at DESC")


def sample_groups_for_timeline() -> list[dict[str, Any]]:
    return rows(
        """SELECT g.*,c.client_name
           FROM sample_groups g JOIN commissions c ON c.commission_no=g.commission_no
           WHERE g.is_void=0 ORDER BY g.updated_at DESC,g.group_no"""
    )


def sample_group_timeline(group_id: int) -> list[dict[str, Any]]:
    """Return a deduplicated business timeline for one complete sample group."""
    group_row=group(group_id)
    if not group_row:return []
    names={x["username"]:x["display_name"] for x in list_users()}
    events=[]
    def json_list(value):
        if isinstance(value,list):return [str(x) for x in value]
        try:return [str(x) for x in json.loads(value or "[]")]
        except Exception:return []
    def add(at,stage,status="",location="",samples="",actor="",details=""):
        if not at:return
        events.append({
            "时间":str(at).replace("T"," "),"流转环节":stage,"状态变化":status,
            "位置变化":location,"涉及样品":samples,"操作人":names.get(actor,actor or "系统"),
            "说明":details,
        })
    sample_nos=[x["sample_no"] for x in group_samples(group_id)]
    add(
        group_row.get("created_at"),"收样登记与入库",f"建立样品组 → {group_row.get('status','')}",
        group_row.get("storage_area",""),"、".join(sample_nos),group_row.get("created_by",""),
        f"{group_row.get('sample_name','')}｜型号：{group_row.get('model','')}｜批号：{group_row.get('product_no','')}",
    )
    event_rows=rows(
        """SELECT e.created_at,e.action,e.from_status,e.to_status,
                  e.from_location,e.to_location,e.details,e.actor,
                  GROUP_CONCAT(e.sample_no,'、') sample_nos
           FROM sample_events e JOIN samples s ON s.sample_no=e.sample_no
           WHERE s.group_id=?
           GROUP BY e.created_at,e.action,e.from_status,e.to_status,
                    e.from_location,e.to_location,e.details,e.actor
           ORDER BY e.created_at,e.id""",
        (group_id,),
    )
    for item in event_rows:
        add(
            item.get("created_at"),item.get("action","样品流转"),
            f"{item.get('from_status') or '—'} → {item.get('to_status') or '—'}",
            f"{item.get('from_location') or '—'} → {item.get('to_location') or '—'}",
            item.get("sample_nos",""),item.get("actor",""),item.get("details",""),
        )
    packages=rows("SELECT * FROM task_packages WHERE group_id=? ORDER BY created_at",(group_id,))
    for package_row in packages:
        package_samples="、".join(json_list(package_row.get("sample_nos")))
        add(
            package_row.get("assigned_at"),"实验任务派发","待分配 → 待接收","样品库 → 待实验员接收",
            package_samples,package_row.get("assigned_by",""),
            f"{package_row.get('package_no','')}｜实验员：{names.get(package_row.get('assignee'),package_row.get('assignee',''))}",
        )
        add(
            package_row.get("accepted_at"),"实验员接收/领用","待接收 → 检测中",
            f"样品库 → {package_row.get('detection_location') or '检测区域'}",
            package_samples,package_row.get("assignee",""),
            package_row.get("acceptance_result","")+"；"+str(package_row.get("acceptance_note") or ""),
        )
        add(
            package_row.get("return_submitted_at"),"实验员提交归还","检测完成 → 待回库确认",
            f"{package_row.get('detection_location') or '检测区域'} → 样品库待确认",
            package_samples,package_row.get("assignee",""),package_row.get("package_no",""),
        )
        add(
            package_row.get("return_confirmed_at"),"样品管理员确认回库","待回库确认 → 已回库",
            "样品库待确认 → 指定留样位置",package_samples,"",
            package_row.get("package_no",""),
        )
    tasks=rows("SELECT * FROM tasks WHERE group_id=? ORDER BY created_at",(group_id,))
    for task_row in tasks:
        task_samples="、".join(json_list(task_row.get("sample_nos")))
        add(
            task_row.get("experiment_started_at"),"实验开始","检测中",
            task_row.get("detection_location",""),task_samples,task_row.get("assignee",""),
            f"{task_row.get('task_no','')}｜{task_row.get('experiment','')}",
        )
        add(
            task_row.get("experiment_ended_at"),"实验结束","检测中 → 待复核",
            task_row.get("detection_location",""),task_samples,task_row.get("assignee",""),
            f"{task_row.get('task_no','')}｜{task_row.get('experiment','')}",
        )
    review_rows=rows(
        """SELECT rv.*,t.experiment FROM reviews rv
           JOIN tasks t ON t.task_no=rv.record_no WHERE t.group_id=?
           ORDER BY rv.reviewed_at,rv.id""",
        (group_id,),
    )
    for item in review_rows:
        add(
            item.get("reviewed_at"),"原始记录复核",
            f"复核结果：{item.get('decision','')}","",item.get("record_no",""),
            item.get("reviewer",""),f"{item.get('experiment','')}｜{item.get('comment','')}",
        )
    waste_rows=rows(
        "SELECT * FROM hazardous_waste_records WHERE commission_no=? ORDER BY occurred_at",
        (group_row["commission_no"],),
    )
    group_task_nos={x["task_no"] for x in tasks}
    for item in waste_rows:
        if not group_task_nos.intersection(json_list(item.get("task_nos"))):continue
        add(
            item.get("occurred_at"),"废液/废弃样品处置",item.get("status",""),
            item.get("container_no",""),"、".join(sample_nos),item.get("handler",""),
            f"{item.get('waste_name','')}｜{item.get('quantity','')} {item.get('unit','')}｜{item.get('disposal_method','')}",
        )
    events.sort(key=lambda item:item["时间"])
    return events


def dashboard_counts() -> dict[str, int]:
    reconcile_eligible_reports()
    return {
        "commissions": one("SELECT COUNT(*) n FROM commissions")["n"],
        "samples": one("SELECT COUNT(*) n FROM samples WHERE status!='已删除'")["n"],
        "packages": one("SELECT COUNT(*) n FROM task_packages WHERE status='待接收'")["n"],
        "testing": one("SELECT COUNT(*) n FROM task_packages WHERE status='检测中'")["n"],
        "reviews": one("SELECT COUNT(*) n FROM records WHERE status IN ('待复核','更正待复核')")["n"],
        "returns": one("SELECT COUNT(*) n FROM task_packages WHERE status='待回库确认'")["n"],
        "reports": one("SELECT COUNT(*) n FROM reports WHERE status!='已发布'")["n"],
    }


# ---------------------- Report ----------------------
def _next_report_no(task_no: str) -> str:
    prefix = china_now().strftime("R%Y%m%d")
    last = one(
        "SELECT report_no FROM reports WHERE report_no LIKE ? ORDER BY report_no DESC LIMIT 1",
        (prefix + "%",),
    )
    seq = 1
    if last:
        match = re.match(r"R\d{8}(\d{3})-", last["report_no"])
        seq = int(match.group(1)) + 1 if match else 1
    task_suffix = re.search(r"-(T\d{2})$", task_no)
    return f"{prefix}{seq:03d}-{task_suffix.group(1) if task_suffix else 'T01'}"


def ensure_report_for_task(task_no: str) -> str | None:
    existing = one("SELECT * FROM reports WHERE task_no=?", (task_no,))
    task_row = task(task_no)
    locked = latest_record(task_no)
    if not task_row or task_row["status"] not in ("已复核", "已完成") or not locked or locked["status"] != "已锁定":
        return None
    if existing:
        if existing["status"] in ("质量退回", "复核退回"):
            source_versions = {
                task_no: locked["version"],
                "record_template": locked.get("template_version", ""),
                "sop": locked.get("sop_version", ""),
            }
            payload = locked.get("payload") or {}
            with connect() as c:
                c.execute(
                    """UPDATE reports SET status='待质量审核',source_versions=?,
                       conclusion=?,notes=?,updated_at=? WHERE report_no=?""",
                    (
                        json.dumps(source_versions,ensure_ascii=False),
                        payload.get("report_conclusion",""),payload.get("report_summary",""),
                        now(),existing["report_no"],
                    ),
                )
                c.execute(
                    "INSERT INTO report_actions(report_no,actor,action,comment,created_at) VALUES(?,'system','根据新记录版本重生成初稿',?,?)",
                    (existing["report_no"],f"原始记录V{locked['version']}",now()),
                )
            audit("report",existing["report_no"],"system","根据新记录版本重生成初稿",new_value=f"V{locked['version']}")
        return existing["report_no"]
    report_no = _next_report_no(task_no)
    admin = one("SELECT username FROM users WHERE role='管理员' AND enabled=1 ORDER BY username LIMIT 1")
    payload = locked.get("payload") or {}
    source_versions = {
        task_no: locked["version"],
        "record_template": locked.get("template_version", ""),
        "sop": locked.get("sop_version", ""),
    }
    ts = now()
    with connect() as c:
        c.execute(
            """INSERT INTO reports(
               report_no,commission_no,task_no,status,tester,verifier,quality_inspector,
               approver,source_versions,report_category,sample_statement,conclusion,notes,
               created_at,updated_at
               ) VALUES(?,?,?,'待质量审核',?,?,?,?,?,?,?,?,?,?,?)""",
            (
                report_no, task_row["commission_no"], task_no, task_row["assignee"],
                task_row["reviewer"], task_row.get("quality_inspector", ""),
                admin["username"] if admin else "", json.dumps(source_versions, ensure_ascii=False),
                "委托检验", "", payload.get("report_conclusion", ""),
                payload.get("report_summary", ""), ts, ts,
            ),
        )
        c.execute(
            "INSERT INTO report_actions(report_no,actor,action,comment,created_at) VALUES(?,'system','自动生成报告初稿','原始记录复核通过后自动生成',?)",
            (report_no, ts),
        )
        objection_row = c.execute(
            "SELECT objection_no,report_no FROM objections WHERE retest_task_no=?",
            (task_no,),
        ).fetchone()
        if objection_row:
            c.execute(
                "UPDATE reports SET supersedes_report_no=? WHERE report_no=?",
                (objection_row["report_no"],report_no),
            )
            c.execute(
                "UPDATE objections SET replacement_report_no=?,updated_at=? WHERE objection_no=?",
                (report_no,ts,objection_row["objection_no"]),
            )
    audit("report", report_no, "system", "自动生成报告初稿", new_value=task_no, snapshot=source_versions)
    create_notification(
        task_row.get("quality_inspector", ""), "检验报告待质量确认",
        f"报告 {report_no} 已由完成自查和复核的原始记录自动形成，请在线预览并确认。",
        "report", report_no,
    )
    return report_no


def reconcile_eligible_reports() -> None:
    """Idempotently restore report drafts missed after a successful review."""
    for item in rows("SELECT task_no FROM tasks WHERE status IN ('已复核','已完成')"):
        ensure_report_for_task(item["task_no"])


def report(report_no: str) -> dict[str, Any] | None:
    return one("SELECT * FROM reports WHERE report_no=?", (report_no,))


def list_reports(role: str, username: str) -> list[dict[str, Any]]:
    reconcile_eligible_reports()
    if role == "实验员":
        return rows("SELECT * FROM reports WHERE tester=? ORDER BY updated_at DESC", (username,))
    if role == "复核员":
        return rows("SELECT * FROM reports WHERE verifier=? ORDER BY updated_at DESC", (username,))
    if role == "质量检测员":
        return rows("SELECT * FROM reports WHERE quality_inspector=? ORDER BY updated_at DESC", (username,))
    return rows("SELECT * FROM reports ORDER BY updated_at DESC")


def update_report_roles(report_no: str, tester: str, verifier: str, approver: str, actor: str) -> None:
    with connect() as c:
        c.execute("UPDATE reports SET tester=?,verifier=?,approver=?,updated_at=? WHERE report_no=?", (tester, verifier, approver, now(), report_no))
    audit("report", report_no, actor, "设置签署人员")


def reviewer_review_report(report_no: str, actor: str, decision: str, comment: str) -> None:
    item = report(report_no)
    if not item or item.get("verifier") != actor or item.get("status") != "待复核员审核":
        raise ValueError("当前报告不能由该复核员审核")
    passed = decision == "通过"
    ts = now()
    with connect() as c:
        c.execute(
            """UPDATE reports SET status=?,verifier_signed_at=?,updated_at=?
               WHERE report_no=?""",
            ("待质量审核" if passed else "复核退回", ts if passed else None, ts, report_no),
        )
        c.execute(
            "INSERT INTO report_actions(report_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (report_no, actor, "复核员审核" + decision, comment, ts),
        )
        if not passed and item.get("task_no"):
            c.execute("UPDATE tasks SET status='退回修改',updated_at=? WHERE task_no=?", (ts, item["task_no"]))
    audit("report", report_no, actor, "复核员审核" + decision, reason=comment)
    if passed:
        create_notification(
            item.get("quality_inspector", ""), "检验报告待质量审核",
            f"报告 {report_no} 已通过复核员审核，请进行第二轮质量审核。",
            "report", report_no,
        )
    else:
        create_notification(
            item.get("tester", ""), "检验报告复核退回",
            f"报告 {report_no} 被复核员退回，请修正对应原始记录。",
            "report", report_no,
        )


def quality_review_report(report_no: str, actor: str, decision: str, comment: str) -> None:
    r = report(report_no)
    if not r or r["quality_inspector"] != actor or r["status"] != "待质量审核":
        raise ValueError("当前报告不能由该质量检测员审核")
    status = "待管理员签发" if decision == "通过" else "质量退回"
    with connect() as c:
        c.execute(
            "UPDATE reports SET status=?,quality_signed_at=NULL,updated_at=? WHERE report_no=?",
            (status, now(), report_no),
        )
        c.execute(
            "INSERT INTO report_actions(report_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (report_no, actor, "质量审核" + decision, comment, now()),
        )
        if decision != "通过" and r.get("task_no"):
            c.execute("UPDATE tasks SET status='退回修改',updated_at=? WHERE task_no=?",(now(),r["task_no"]))
    audit("report", report_no, actor, "质量审核" + decision, reason=comment)
    if decision == "通过":
        create_notification(
            r.get("approver", ""), "检验报告待最终签发",
            f"报告 {report_no} 已由质量负责人预览确认，请作为授权签字人最终审核签发。",
            "report", report_no,
        )


def approver_review_report(report_no: str, actor: str, decision: str, comment: str) -> None:
    r = report(report_no)
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if not r or actor_row.get("role") != "管理员" or r["status"] != "待管理员签发":
        raise ValueError("只有管理员可以最终审核、签发报告")
    status = "已发布" if decision == "批准" else "待质量审核"
    with connect() as c:
        c.execute(
            """UPDATE reports SET status=?,approver=?,approver_signed_at=?,
               publish_date=?,validity_status=?,updated_at=? WHERE report_no=?""",
            (
                status, actor, now() if decision == "批准" else None,
                str(china_today()) if decision == "批准" else None,
                "有效" if decision == "批准" else r.get("validity_status","有效"),
                now(), report_no,
            ),
        )
        c.execute("INSERT INTO report_actions(report_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)", (report_no, actor, decision, comment, now()))
    if decision == "批准":
        source = json.loads(r.get("source_versions") or "{}")
        version_row = one(
            """SELECT MAX(version) version FROM document_versions
               WHERE entity_type='report' AND entity_id=?""",
            (report_no,),
        ) or {}
        report_version = int(version_row.get("version") or 0) + 1
        signed_report=report(report_no) or r
        freeze_document_version("report", report_no, report_version, "最终有效", dict(signed_report, source_versions=source), actor)
        obsolete_prior_versions("report", report_no, report_version, actor, "更正报告已正式签发")
        obsolete_prior_versions("record", r.get("task_no", ""), int(source.get(r.get("task_no", ""), 1)), actor, "最终报告已生成")
        with connect() as c:
            c.execute(
                """UPDATE objections SET status='待异议回复',updated_at=?
                   WHERE replacement_report_no=? AND status='重测任务已下发'""",
                (now(),report_no),
            )
            objection_row = c.execute(
                "SELECT report_no FROM objections WHERE replacement_report_no=?",
                (report_no,),
            ).fetchone()
            if objection_row:
                c.execute(
                    """UPDATE reports SET validity_status='已被重测报告替代',
                       updated_at=? WHERE report_no=?""",
                    (now(), objection_row["report_no"]),
                )
    else:
        create_notification(
            r.get("quality_inspector", ""), "报告被授权签字人退回",
            f"报告 {report_no} 已退回质量预览确认，请根据意见处理。",
            "report", report_no,
        )
    audit("report", report_no, actor, decision, reason=comment)


def start_report_void_or_correction(
    report_no: str, actor: str, action: str, reason: str,
) -> None:
    item = report(report_no)
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if actor_row.get("role") != "管理员":
        raise ValueError("只有管理员（授权签字人）可以启动报告作废或更正")
    if not item or item.get("status") != "已发布":
        raise ValueError("只有已经签发的报告可以启动作废或更正")
    if not reason.strip():
        raise ValueError("作废或更正原因不能为空")
    ts = now()
    if action == "直接作废":
        with connect() as c:
            c.execute(
                """UPDATE reports SET status='已作废',validity_status='已作废',
                   notes=CASE WHEN notes='' THEN ? ELSE notes||? END,updated_at=?
                   WHERE report_no=?""",
                ("作废原因："+reason, "\n作废原因："+reason, ts, report_no),
            )
            c.execute(
                "INSERT INTO report_actions(report_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
                (report_no,actor,"管理员启动报告作废",reason,ts),
            )
        audit("report",report_no,actor,"管理员启动报告作废",reason=reason)
        return
    if action != "更正并重新签发":
        raise ValueError("未知的报告处理方式")
    with connect() as c:
        c.execute(
            """UPDATE reports SET status='待质量审核',validity_status='更正中',
               quality_signed_at=NULL,approver_signed_at=NULL,publish_date=NULL,
               report_category='更正报告',updated_at=? WHERE report_no=?""",
            (ts,report_no),
        )
        c.execute(
            "INSERT INTO report_actions(report_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (report_no,actor,"管理员启动报告更正",reason,ts),
        )
    create_notification(
        item.get("quality_inspector",""),"更正报告待预览确认",
        f"管理员已启动报告 {report_no} 的更正流程，请按更正原因预览确认。原因：{reason}",
        "report",report_no,
    )
    audit("report",report_no,actor,"管理员启动报告更正",reason=reason)


def report_actions(report_no: str) -> list[dict[str, Any]]:
    return rows("SELECT * FROM report_actions WHERE report_no=? ORDER BY id", (report_no,))


def next_hazardous_waste_no() -> str:
    prefix = china_now().strftime("D%Y%m%d")
    item = one(
        """SELECT disposal_no FROM hazardous_waste_records
           WHERE disposal_no LIKE ? ORDER BY disposal_no DESC LIMIT 1""",
        (prefix + "%",),
    )
    seq = int(item["disposal_no"][-3:]) + 1 if item else 1
    return f"{prefix}{seq:03d}"


def create_hazardous_waste_record(data: dict[str, Any], actor: str) -> str:
    task_nos = list(dict.fromkeys(
        str(x).strip() for x in (data.get("task_nos") or [data.get("task_no", "")])
        if str(x).strip()
    ))
    if not task_nos:
        raise ValueError("至少选择一个产生该危废的实验任务")
    task_rows = [task(number) for number in task_nos]
    if any(not item or item.get("assignee") != actor for item in task_rows):
        raise ValueError("只能关联本人负责的实验任务")
    commissions = {item["commission_no"] for item in task_rows if item}
    if len(commissions) != 1:
        raise ValueError("同一条危废记录只能关联同一委托下的多个实验任务")
    task_row = task_rows[0]
    waste_name = str(data.get("waste_name", "")).strip()
    method = str(data.get("disposal_method", "")).strip()
    quantity = float(data.get("quantity", 0) or 0)
    if not waste_name or not method or quantity <= 0:
        raise ValueError("危废名称、正数数量和处置方式均为必填项")
    disposal_no = next_hazardous_waste_no()
    ts = now()
    with connect() as c:
        c.execute(
            """INSERT INTO hazardous_waste_records(
               disposal_no,commission_no,task_no,task_nos,sample_no,waste_type,waste_name,
               quantity,unit,hazard_category,disposal_method,container_no,handler,
               occurred_at,status,note,created_by,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,'已登记',?,?,?,?)""",
            (
                disposal_no, task_row["commission_no"], task_row["task_no"],
                json.dumps(task_nos,ensure_ascii=False), "",
                data.get("waste_type", "实验废液"),
                waste_name, quantity, data.get("unit", "mL"),
                data.get("hazard_category", ""), method, data.get("container_no", ""),
                actor, data.get("occurred_at") or ts, data.get("note", ""),
                actor, ts, ts,
            ),
        )
    audit("hazardous_waste", disposal_no, actor, "登记危废处置", snapshot=data)
    return disposal_no


def list_hazardous_waste_records(
    actor: str | None = None, task_no: str | None = None,
) -> list[dict[str, Any]]:
    query = "SELECT * FROM hazardous_waste_records WHERE 1=1"
    args: list[Any] = []
    if actor:
        query += " AND handler=?"
        args.append(actor)
    if task_no:
        query += " AND task_no=?"
        args.append(task_no)
    return rows(query + " ORDER BY occurred_at DESC", args)


def report_records(commission_no: str) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for t in rows("SELECT task_no FROM tasks WHERE commission_no=? ORDER BY task_no", (commission_no,)):
        r = one("SELECT * FROM records WHERE task_no=? AND status='已锁定' ORDER BY version DESC LIMIT 1", (t["task_no"],))
        if r:
            r["payload"] = json.loads(r.get("payload") or "{}")
            result[t["task_no"]] = r
    return result


def report_records_for_report(report_no: str) -> dict[str, dict[str, Any]]:
    report_row = report(report_no)
    if not report_row or not report_row.get("task_no"):
        return {}
    source = json.loads(report_row.get("source_versions") or "{}")
    task_no = report_row["task_no"]
    version = int(source.get(task_no, 0) or 0)
    record_row = record(task_no, version) if version else latest_record(task_no)
    return {task_no: record_row} if record_row else {}


# ---------------------- Report delivery register ----------------------
def add_report_delivery(data: dict[str, Any], actor: str) -> None:
    report_row = report(data["report_no"])
    if not report_row or report_row["status"] != "已发布":
        raise ValueError("只有已经签发的有效报告可以登记发放")
    commission_row = commission(report_row["commission_no"]) or {}
    recipient = data.get("recipient") or commission_row.get("contact", "")
    recipient_contact = data.get("recipient_contact") or commission_row.get("phone", "")
    if not recipient:
        raise ValueError("委托单未填写委托联系人，不能登记报告发放")
    with connect() as c:
        c.execute(
            """INSERT INTO report_deliveries(
               report_no,client_name,delivery_method,recipient,recipient_contact,
               delivered_at,receipt_status,receipt_note,operator,created_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?)""",
            (
                data["report_no"], data.get("client_name", ""),
                data.get("delivery_method", ""), recipient,
                recipient_contact, data.get("delivered_at", now()),
                data.get("receipt_status", ""), data.get("receipt_note", ""),
                actor, now(),
            ),
        )
    audit("report_delivery", data["report_no"], actor, "登记报告发放", new_value=data.get("delivery_method", ""))


def report_deliveries(report_no: str | None = None) -> list[dict[str, Any]]:
    if report_no:
        return rows("SELECT * FROM report_deliveries WHERE report_no=? ORDER BY id DESC", (report_no,))
    return rows("SELECT * FROM report_deliveries ORDER BY id DESC")


# ---------------------- Customer objections ----------------------
def _next_objection_no() -> str:
    prefix = china_now().strftime("Y%Y%m%d")
    last = one(
        "SELECT objection_no FROM objections WHERE objection_no LIKE ? ORDER BY objection_no DESC LIMIT 1",
        (prefix + "%",),
    )
    seq = int(last["objection_no"][-3:]) + 1 if last else 1
    return f"{prefix}{seq:03d}"


def register_objection(data: dict[str, Any], actor: str) -> str:
    report_row = report(data["report_no"])
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if actor_row.get("role") != "样品管理员":
        raise ValueError("只有样品管理员可以录入客户异议申请")
    if not report_row or report_row.get("status") != "已发布":
        raise ValueError("只能对已经签发的检验报告登记异议")
    if not str(data.get("description") or "").strip():
        raise ValueError("客户异议内容不能为空")
    disputed_items=[
        x.strip() for x in str(data.get("disputed_items") or "").replace("，","、").split("、")
        if x.strip()
    ]
    allowed_items={
        x.get("experiment","") for x in commission_tests(report_row["commission_no"])
        if x.get("experiment")
    }
    if not disputed_items:
        raise ValueError("至少选择一个争议检测项目")
    if any(item not in allowed_items for item in disputed_items):
        raise ValueError("争议检测项目必须来自该委托当时选择的实验项目")
    objection_no = _next_objection_no()
    inspector = report_row.get("quality_inspector") or _auto_match_user("质量检测员")
    ts = now()
    with connect() as c:
        c.execute(
            """INSERT INTO objections(
               objection_no,report_no,commission_no,client_name,contact,submitted_at,
               description,evidence_note,disputed_items,involved_samples,
               application_channel,status,quality_inspector,registered_by,
               created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?, '调查中',?,?,?,?)""",
            (
                objection_no, report_row["report_no"], report_row["commission_no"],
                data.get("client_name", ""), data.get("contact", ""),
                data.get("submitted_at", ts), data.get("description", ""),
                data.get("evidence_note", ""), "、".join(disputed_items),
                data.get("involved_samples", ""), data.get("application_channel", ""),
                inspector, actor, ts, ts,
            ),
        )
        c.execute(
            "INSERT INTO objection_actions(objection_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (objection_no, actor, "登记客户异议", data.get("description", ""), ts),
        )
        c.execute(
            "UPDATE reports SET validity_status='异议处理中',updated_at=? WHERE report_no=?",
            (ts, report_row["report_no"]),
        )
    audit("objection", objection_no, actor, "登记客户异议", new_value=report_row["report_no"])
    create_notification(
        inspector, "客户异议待调查",
        f"样品管理员已登记异议 {objection_no}，关联报告 {report_row['report_no']}，请调取追溯资料并完成责任判定。",
        "objection", objection_no,
    )
    return objection_no


def objections_for_user(role: str, username: str) -> list[dict[str, Any]]:
    if role == "质量检测员":
        return rows("SELECT * FROM objections WHERE quality_inspector=? ORDER BY updated_at DESC", (username,))
    return rows("SELECT * FROM objections ORDER BY updated_at DESC")


def objection(objection_no: str) -> dict[str, Any] | None:
    return one("SELECT * FROM objections WHERE objection_no=?", (objection_no,))


def objection_actions(objection_no: str) -> list[dict[str, Any]]:
    return rows("SELECT * FROM objection_actions WHERE objection_no=? ORDER BY id", (objection_no,))


def quality_submit_objection(
    objection_no: str, actor: str, pathway: str, investigation: str,
    trace_conclusion: str, details: dict[str, Any] | None = None,
) -> None:
    row = objection(objection_no)
    if not row or row["quality_inspector"] != actor or row["status"] != "调查中":
        raise ValueError("当前异议不能由该质量检测员提交调查")
    if pathway not in ("是我方问题", "样品问题"):
        raise ValueError("必须选择两条规定路径之一")
    if not investigation.strip() or not trace_conclusion.strip():
        raise ValueError("调查过程和调查结论均不能为空")
    details = details or {}
    next_status = "待客户确认重测" if pathway == "是我方问题" else "待异议回复"
    report_validity = "异议成立-暂停使用" if pathway == "是我方问题" else "有效"
    ts = now()
    with connect() as c:
        c.execute(
            """UPDATE objections SET pathway=?,investigation=?,trace_conclusion=?,
               quality_evidence=?,quality_method_check=?,quality_equipment_check=?,
               quality_environment_check=?,quality_operation_check=?,
               quality_calculation_check=?,impact_scope=?,treatment_suggestion=?,
               status=?,investigated_at=?,updated_at=?
               WHERE objection_no=?""",
            (
                pathway, investigation, trace_conclusion,
                details.get("quality_evidence", ""), details.get("quality_method_check", ""),
                details.get("quality_equipment_check", ""), details.get("quality_environment_check", ""),
                details.get("quality_operation_check", ""), details.get("quality_calculation_check", ""),
                details.get("impact_scope", ""), details.get("treatment_suggestion", ""),
                next_status, ts, ts, objection_no,
            ),
        )
        c.execute(
            "UPDATE reports SET validity_status=?,updated_at=? WHERE report_no=?",
            (report_validity, ts, row["report_no"]),
        )
        c.execute(
            "INSERT INTO objection_actions(objection_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (objection_no, actor, "提交调查结论", pathway + "｜" + trace_conclusion, ts),
        )
    audit("objection", objection_no, actor, "提交调查结论", new_value=pathway, reason=trace_conclusion)
    receiver = _auto_match_user("样品管理员")
    create_notification(
        receiver, "客户异议待处理",
        (
            f"异议 {objection_no} 已完成质量调查，判定为“{pathway}”。"
            + ("请在系统外联系客户并记录是否需要重测。" if pathway == "是我方问题" else "请拟制并发送异议回复。")
        ),
        "objection", objection_no,
    )


def admin_confirm_objection(objection_no: str, actor: str, decision: str) -> None:
    raise ValueError("V8.1已取消管理员异议确认步骤；质量调查后由样品管理员继续处理")


def record_customer_retest_decision(
    objection_no: str, actor: str, decision: str, note: str,
    contact_at: str = "", contact_method: str = "",
) -> None:
    row = objection(objection_no)
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if actor_row.get("role") != "样品管理员":
        raise ValueError("只有样品管理员可以记录客户重测决定")
    if not row or row["status"] != "待客户确认重测":
        raise ValueError("当前异议不在客户重测确认阶段")
    if decision not in ("需要重测", "不需要重测"):
        raise ValueError("客户决定选项无效")
    status = "待安排重测" if decision == "需要重测" else "待异议回复"
    with connect() as c:
        c.execute(
            """UPDATE objections SET customer_retest_decision=?,retest_note=?,
               customer_contact_at=?,customer_contact_method=?,
               status=?,updated_at=? WHERE objection_no=?""",
            (decision, note, contact_at or now(), contact_method, status, now(), objection_no),
        )
        c.execute(
            "INSERT INTO objection_actions(objection_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (objection_no, actor, "记录客户重测决定", decision + "｜" + note, now()),
        )
    audit("objection", objection_no, actor, "记录客户重测决定", new_value=decision, reason=note)


def dispatch_retained_sample_retest(
    objection_no: str, assignee: str, actor: str,
    selected_sample_nos: list[str] | None = None,
) -> str:
    row = objection(objection_no)
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if actor_row.get("role") != "样品管理员":
        raise ValueError("只有样品管理员可以从样品库下发重测任务")
    if not row or row["status"] != "待安排重测" or row["customer_retest_decision"] != "需要重测":
        raise ValueError("当前异议不能下发留样重测")
    original_report = report(row["report_no"])
    original_task = task(original_report.get("task_no", "") if original_report else "")
    if not original_task:
        raise ValueError("原实验任务不存在")
    g = group(original_task["group_id"])
    samples = group_samples(original_task["group_id"])
    if not samples or all(x["status"] == "全部消耗，记录归档" for x in samples):
        raise ValueError("没有可用于重测的留样；请按重新送样流程建立新委托和新样品组")
    reviewer = _auto_match_user("复核员", {assignee})
    quality_inspector = _auto_match_user("质量检测员", {assignee, reviewer})
    package_no = _next_package_no(g["group_no"])
    task_count = one("SELECT COUNT(*) n FROM tasks WHERE group_no=?", (g["group_no"],))["n"]
    task_no = f"{g['group_no']}-T{task_count + 1:02d}"
    available = {
        x["sample_no"]: x for x in samples
        if x["status"] not in ("全部消耗，记录归档", "已销毁", "已报废")
    }
    sample_nos = list(dict.fromkeys(selected_sample_nos or available.keys()))
    if not sample_nos or any(sample_no not in available for sample_no in sample_nos):
        raise ValueError("所选样品不在原委托可用留样库中")
    original_snapshot = task_config_snapshot(original_task["task_no"])
    snapshot_hash = hashlib.sha256(
        json.dumps(original_snapshot,ensure_ascii=False,sort_keys=True,default=str).encode("utf-8")
    ).hexdigest()
    ts = now()
    with connect() as c:
        c.execute(
            """INSERT INTO task_packages(
               package_no,commission_no,group_id,group_no,assignee,reviewer,quality_inspector,
               material_name,sample_nos,experiment_codes,experiments,status,assigned_by,
               assigned_at,notified_at,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,'待接收',?,?,?,?,?)""",
            (
                package_no,original_task["commission_no"],original_task["group_id"],
                original_task["group_no"],assignee,reviewer,quality_inspector,
                original_task["material_name"],json.dumps(sample_nos,ensure_ascii=False),
                json.dumps([original_task["experiment_code"]],ensure_ascii=False),
                json.dumps([original_task["experiment"]],ensure_ascii=False),
                actor,ts,ts,ts,ts,
            ),
        )
        c.execute(
            """INSERT INTO tasks(
               task_no,package_no,commission_no,group_id,group_no,sample_nos,
               experiment_code,experiment,method_code,standard,material_name,
               assignee,reviewer,quality_inspector,status,created_at,updated_at
               ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,'待接收',?,?)""",
            (
                task_no,package_no,original_task["commission_no"],original_task["group_id"],
                original_task["group_no"],json.dumps(sample_nos,ensure_ascii=False),
                original_task["experiment_code"],original_task["experiment"],
                original_task["method_code"],original_task["standard"],
                original_task["material_name"],assignee,reviewer,quality_inspector,ts,ts,
            ),
        )
        c.execute(
            """INSERT INTO task_config_snapshots(
               task_no,config_id,config_version,snapshot_json,snapshot_hash,created_at
               ) VALUES(?,?,?,?,?,?)""",
            (
                task_no,original_snapshot.get("config_id"),original_snapshot.get("config_version"),
                json.dumps(original_snapshot,ensure_ascii=False,default=str),snapshot_hash,ts,
            ),
        )
        c.execute(
            """UPDATE objections SET retest_task_no=?,status='重测任务已下发',
               retest_note=COALESCE(retest_note,'')||?,updated_at=? WHERE objection_no=?""",
            (task_no,f"；使用留样重测，任务{task_no}",ts,objection_no),
        )
        c.execute(
            "INSERT INTO objection_actions(objection_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (objection_no,actor,"下发留样重测任务",task_no,ts),
        )
        for sample_no in sample_nos:
            old = available[sample_no]
            c.execute(
                """UPDATE samples SET status='待接收重测',current_holder=?,
                   updated_at=? WHERE sample_no=?""",
                (assignee, ts, sample_no),
            )
            c.execute(
                """INSERT INTO sample_events(
                   sample_no,actor,action,from_status,to_status,from_location,
                   to_location,details,created_at
                   ) VALUES(?,?, '异议留样重测派发',?,'待接收重测',?,?,?,?)""",
                (
                    sample_no, actor, old.get("status", ""), old.get("current_location", ""),
                    old.get("current_location", ""), f"异议:{objection_no};任务:{task_no}", ts,
                ),
            )
    audit("objection",objection_no,actor,"下发留样重测任务",new_value=task_no)
    create_notification(
        assignee, "收到异议重测任务",
        f"异议 {objection_no} 已从样品库派发留样，重测任务为 {task_no}，请接收后按原流程检测。",
        "task", task_no,
    )
    return task_no


def sample_manager_prepare_objection_response(
    objection_no: str, actor: str, response_text: str,
    response_method: str = "",
) -> None:
    row = objection(objection_no)
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if not row or actor_row.get("role") != "样品管理员" or row["status"] != "待异议回复":
        raise ValueError("当前异议不能由样品管理员生成回复")
    if not response_text.strip():
        raise ValueError("异议回复正文不能为空")
    with connect() as c:
        c.execute(
            """UPDATE objections SET response_text=?,response_method=?,
               status='待发送',updated_at=? WHERE objection_no=?""",
            (response_text, response_method, now(), objection_no),
        )
        c.execute(
            "INSERT INTO objection_actions(objection_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (objection_no, actor, "生成异议回复单", response_text, now()),
        )
    audit("objection", objection_no, actor, "生成异议回复单", new_value=f"{objection_no}-R")


def send_and_archive_objection(
    objection_no: str, actor: str, note: str, response_method: str = "",
) -> None:
    row = objection(objection_no)
    actor_row = one("SELECT role FROM users WHERE username=?", (actor,)) or {}
    if actor_row.get("role") != "样品管理员":
        raise ValueError("只有样品管理员可以发送异议回复")
    if not row or row["status"] != "待发送":
        raise ValueError("异议回复尚未签发")
    ts = now()
    with connect() as c:
        c.execute(
            """UPDATE objections SET status='已归档',sent_by=?,sent_at=?,
               response_method=COALESCE(NULLIF(?,''),response_method),
               response_receipt=?,archived_at=?,updated_at=? WHERE objection_no=?""",
            (actor, ts, response_method, note, ts, ts, objection_no),
        )
        c.execute(
            "INSERT INTO objection_actions(objection_no,actor,action,comment,created_at) VALUES(?,?,?,?,?)",
            (objection_no, actor, "发送回复并自动归档", note, ts),
        )
    audit("objection", objection_no, actor, "发送回复并自动归档", reason=note)


# ---------------------- Templates/signatures ----------------------
def seed_template(experiment: str, doc_type: str, file_name: str | None, version: str = "A/0") -> None:
    if not file_name:
        return
    with connect() as c:
        if not c.execute("SELECT 1 FROM template_versions WHERE experiment=? AND doc_type=? AND version=?", (experiment, doc_type, version)).fetchone():
            c.execute("INSERT INTO template_versions(experiment,doc_type,file_name,version,effective_date,status,uploader,uploaded_at,note) VALUES(?,?,?,?,?,'现行','system',?,'初始化')", (experiment, doc_type, file_name, version, str(china_today()), now()))


def active_version(experiment: str, doc_type: str) -> dict[str, Any] | None:
    return one("SELECT * FROM template_versions WHERE experiment=? AND doc_type=? AND status='现行' ORDER BY id DESC LIMIT 1", (experiment, doc_type))


def template_for_version(experiment: str, doc_type: str, version: str) -> dict[str, Any] | None:
    return one("SELECT * FROM template_versions WHERE experiment=? AND doc_type=? AND version=? ORDER BY id DESC LIMIT 1", (experiment, doc_type, version))


def all_template_versions() -> list[dict[str, Any]]:
    return rows("SELECT * FROM template_versions ORDER BY experiment,doc_type,id DESC")


def add_template(experiment: str, doc_type: str, file_name: str, version: str, effective_date: str, actor: str, note: str) -> None:
    with connect() as c:
        c.execute("UPDATE template_versions SET status='停用' WHERE experiment=? AND doc_type=? AND status='现行'", (experiment, doc_type))
        c.execute("INSERT INTO template_versions(experiment,doc_type,file_name,version,effective_date,status,uploader,uploaded_at,note) VALUES(?,?,?,?,?,'现行',?,?,?)", (experiment, doc_type, file_name, version, effective_date, actor, now(), note))
    audit("template", experiment + "/" + doc_type, actor, "启用新版本", new_value=version)


def save_signature(username: str, source_file: str, image_file: str | None, actor: str) -> None:
    with connect() as c:
        c.execute("INSERT INTO signatures(username,source_file,image_file,uploaded_by,uploaded_at) VALUES(?,?,?,?,?) ON CONFLICT(username) DO UPDATE SET source_file=excluded.source_file,image_file=excluded.image_file,uploaded_by=excluded.uploaded_by,uploaded_at=excluded.uploaded_at", (username, source_file, image_file, actor, now()))
    audit("signature", username, actor, "更新电子签名")


def signature(username: str) -> dict[str, Any] | None:
    return one("SELECT * FROM signatures WHERE username=?", (username,))


# ---------------------- Document helpers ----------------------
def commission_tasks(commission_no: str) -> list[dict[str, Any]]:
    result = rows("SELECT * FROM tasks WHERE commission_no=? ORDER BY group_no,task_no", (commission_no,))
    for x in result:
        x["sample_nos_list"] = json.loads(x.get("sample_nos") or "[]")
    return result


def commission_tests(commission_no: str) -> list[dict[str, Any]]:
    return rows("""SELECT r.*,g.group_no,g.sample_name,g.model,g.material_name,g.quantity
                   FROM requested_tests r JOIN sample_groups g ON g.id=r.group_id
                   WHERE g.commission_no=? AND g.is_void=0 ORDER BY g.group_no,r.id""", (commission_no,))


def commission_loans(commission_no: str) -> list[dict[str, Any]]:
    return rows("""SELECT l.*,p.commission_no,p.experiments FROM package_loans l JOIN task_packages p ON p.package_no=l.package_no
                   WHERE p.commission_no=? ORDER BY l.borrowed_at,l.sample_no""", (commission_no,))
