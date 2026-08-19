"""
应用数据库延迟改动（在恢复 backup.sql 之后运行）
用法: cd backend && .venv/Scripts/python.exe scripts/apply_deferred_changes.py

内容:
  A. schema: task_packages/tasks 增加 sample_name 列 + 回填；补执行 002_phase4_columns.sql
  B. 编号:   存量 BAG-BP…-Pnn-Tnn 一次性重编号为 BP…-Tnn（组内全局序号），
             报告号同步 R…-Tnn，同步所有引用表与记录 payload 内 _photos 的 URL
"""
from __future__ import annotations

import io
import json
import os
import re
import sys
from pathlib import Path

import psycopg2

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

BACKEND = Path(__file__).parent.parent


def _conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "123456"),
        dbname=os.getenv("DB_NAME", "bplab"),
    )


def _col_exists(cur, table: str, column: str) -> bool:
    cur.execute(
        "SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=%s AND column_name=%s",
        (table, column),
    )
    return cur.fetchone() is not None


def phase_a_schema(cur) -> None:
    print("── Phase A: schema ──")
    # 1) sample_name 列
    for t in ("task_packages", "tasks"):
        if not _col_exists(cur, t, "sample_name"):
            cur.execute(f'ALTER TABLE {t} ADD COLUMN sample_name TEXT')
            print(f"  + {t}.sample_name")
        else:
            print(f"  = {t}.sample_name 已存在")
    cur.execute(
        "UPDATE task_packages tp SET sample_name = sg.sample_name "
        "FROM sample_groups sg WHERE tp.group_no = sg.group_no AND tp.sample_name IS NULL"
    )
    cur.execute(
        "UPDATE tasks t SET sample_name = sg.sample_name "
        "FROM sample_groups sg WHERE t.group_no = sg.group_no AND t.sample_name IS NULL"
    )
    print("  ✓ sample_name 回填完成")

    # 2) 002_phase4_columns.sql
    sql_002 = (BACKEND / "migrations" / "002_phase4_columns.sql").read_text("utf-8")
    cur.execute(sql_002)
    print("  ✓ 002_phase4_columns.sql 已应用")


def _build_task_map(cur) -> dict[str, str]:
    cur.execute("SELECT task_no, group_no FROM tasks ORDER BY group_no, package_no, task_no")
    mapping: dict[str, str] = {}
    seq_by_group: dict[str, int] = {}
    for old, group in cur.fetchall():
        if not old.startswith("BAG-"):
            mapping[old] = old  # 已是新格式，保持不变
            continue
        seq = seq_by_group.get(group, 0) + 1
        seq_by_group[group] = seq
        mapping[old] = f"{group}-T{seq:02d}"
    return mapping


def _apply_map(cur, table: str, column: str, mapping: dict[str, str], where_extra: str = "") -> int:
    n = 0
    for old, new in mapping.items():
        if old == new:
            continue
        cond = f"{column} = %s"
        if where_extra:
            cond += f" AND {where_extra}"
        cur.execute(f"UPDATE {table} SET {column} = %s WHERE {cond}", (new, old))
        n += cur.rowcount
    return n


def phase_b_renumber(cur) -> None:
    print("── Phase B: BAG 编号重编号 ──")
    task_map = _build_task_map(cur)
    report_map: dict[str, str] = {}
    for old, new in task_map.items():
        if old != new:
            report_map[f"R{old}"] = f"R{new[2:]}"  # RBAG-... → R{group_no[2:]}-T{nn}
    print(f"  · 任务映射 {sum(1 for o, n in task_map.items() if o != n)} 条")

    def task_cols(table_cols: list[str]):
        for table, col in table_cols:
            if _col_exists(cur, table, col):
                c = _apply_map(cur, table, col, task_map)
                print(f"  · {table}.{col}: {c} 行")

    # 任务号（PK）与各引用表
    task_cols([
        ("tasks", "task_no"),
        ("records", "record_no"),
        ("records", "task_no"),
        ("reports", "task_no"),
        ("attachments", "task_no"),
        ("requested_tests", "task_no"),
        ("task_config_snapshots", "task_no"),
        ("hazardous_waste_records", "task_no"),
        ("equipment_incidents", "task_no"),
    ])

    # 报告号（PK）与引用表；先临时放开 report_actions 的外键再改 reports.report_no
    cur.execute("ALTER TABLE report_actions DROP CONSTRAINT IF EXISTS report_actions_report_no_fkey")
    for table, col in [("reports", "report_no"), ("report_actions", "report_no"),
                       ("report_deliveries", "report_no"), ("objections", "report_no")]:
        if _col_exists(cur, table, col):
            c = _apply_map(cur, table, col, report_map)
            print(f"  · {table}.{col}: {c} 行")
    cur.execute(
        "ALTER TABLE report_actions ADD CONSTRAINT report_actions_report_no_fkey "
        "FOREIGN KEY (report_no) REFERENCES reports(report_no)"
    )
    print("  · report_actions 外键已恢复")

    # reviews.record_no（等于任务号）
    if _col_exists(cur, "reviews", "record_no"):
        c = _apply_map(cur, "reviews", "record_no", task_map)
        print(f"  · reviews.record_no: {c} 行")

    # attachments.relative_path 首段为任务号目录
    if _col_exists(cur, "attachments", "relative_path"):
        for old, new in task_map.items():
            if old == new:
                continue
            cur.execute(
                "UPDATE attachments SET relative_path = %s || substring(relative_path FROM %s) "
                "WHERE task_no = %s AND relative_path LIKE %s",
                (new, len(old) + 1, new, f"{old}/%"),
            )
        print("  · attachments.relative_path 已更新")

    # 审计/追溯 entity_id（按实体类型区分；task_package 保留 BAG 内部编号）
    if _col_exists(cur, "audit_logs", "entity_id"):
        for old, new in task_map.items():
            if old == new:
                continue
            cur.execute(
                "UPDATE audit_logs SET entity_id = %s WHERE entity_type IN ('task','record') AND entity_id = %s",
                (new, old),
            )
            cur.execute(
                "UPDATE audit_logs SET entity_id = %s WHERE entity_type = 'report' AND entity_id = %s",
                (f"R{new[2:]}", f"R{old}"),
            )
        print("  · audit_logs.entity_id 已更新")
    if _col_exists(cur, "modification_logs", "entity_id"):
        for old, new in task_map.items():
            if old == new:
                continue
            cur.execute(
                "UPDATE modification_logs SET entity_id = %s WHERE entity_type = 'report' AND entity_id = %s",
                (f"R{new[2:]}", f"R{old}"),
            )
        print("  · modification_logs.entity_id 已更新")

    # 记录 payload 内 _photos 的 URL 路径（previewUrl / url）
    cur.execute("SELECT record_no, payload FROM records WHERE payload::text LIKE '%BAG-%'")
    payload_rows = cur.fetchall()
    for record_no, payload in payload_rows:
        changed = False
        photos = payload.get("_photos")
        if isinstance(photos, list):
            for ph in photos:
                if not isinstance(ph, dict):
                    continue
                for key in ("previewUrl", "url"):
                    val = ph.get(key)
                    if isinstance(val, str):
                        newval = val
                        for old, new in task_map.items():
                            if old != new and old in newval:
                                newval = newval.replace(old, new)
                        if newval != val:
                            ph[key] = newval
                            changed = True
        if changed:
            cur.execute("UPDATE records SET payload = %s WHERE record_no = %s",
                        (json.dumps(payload, ensure_ascii=False), record_no))
            print(f"  · records[{record_no}].payload._photos URL 已更新")
    if payload_rows:
        print(f"  · 检查了 {len(payload_rows)} 条含 BAG- 的记录 payload")


def verify(cur) -> None:
    print("── 校验 ──")
    checks = [
        ("tasks 残留 BAG", "SELECT COUNT(*) FROM tasks WHERE task_no LIKE 'BAG-%'"),
        ("records 残留 BAG", "SELECT COUNT(*) FROM records WHERE record_no LIKE 'BAG-%' OR task_no LIKE 'BAG-%'"),
        ("reports 残留 BAG/RBAG", "SELECT COUNT(*) FROM reports WHERE report_no LIKE 'BAG-%' OR report_no LIKE 'RBAG-%' OR task_no LIKE 'BAG-%'"),
        ("attachments 残留 BAG", "SELECT COUNT(*) FROM attachments WHERE task_no LIKE 'BAG-%'"),
        ("audit_logs 残留 BAG", "SELECT COUNT(*) FROM audit_logs WHERE entity_id LIKE 'BAG-%' AND entity_type IN ('task','record')"),
        ("modification_logs 残留 BAG/RBAG", "SELECT COUNT(*) FROM modification_logs WHERE entity_id LIKE 'BAG-%' OR entity_id LIKE 'RBAG-%'"),
        ("sample_name 为空(有样品组的)", "SELECT COUNT(*) FROM tasks WHERE sample_name IS NULL OR sample_name = ''"),
    ]
    ok = True
    for label, sql in checks:
        cur.execute(sql)
        v = cur.fetchone()[0]
        flag = "✓" if v == 0 else "✗"
        if v != 0:
            ok = False
        print(f"  {flag} {label}: {v}")

    cur.execute("SELECT task_no, sample_name FROM tasks ORDER BY task_no LIMIT 5")
    print("  · 抽样 tasks:", cur.fetchall())
    if not ok:
        print("⚠️  存在残留，请检查（可能为预期内，如 task_package 保留 BAG）")


def main() -> None:
    conn = _conn()
    cur = conn.cursor()
    try:
        phase_a_schema(cur)
        conn.commit()
        print("  (Phase A 已提交)")

        phase_b_renumber(cur)
        conn.commit()
        print("  (Phase B 已提交)")

        verify(cur)
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"❌ 失败已回滚: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
