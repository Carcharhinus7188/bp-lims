-- BPLab Trace LIMS — 数据库延迟改动（在恢复 backup.sql 之后执行）
--
-- 执行方式: psql -U postgres -d bplab -f backend/migrations/003_deferred_changes.sql
-- 或已由 backend/scripts/apply_deferred_changes.py 自动应用（二者等价，幂等）。
--
-- 内容:
--   A. task_packages/tasks 增加 sample_name 列并从 sample_groups 回填（需求 11）
--   B. 补执行 002_phase4_columns.sql（客户异议/设备故障等模块缺列）
--   C. 存量 BAG-BP…-Pnn-Tnn 一次性重编号为 BP…-Tnn（组内全局序号），
--      报告号同步 R…-Tnn，同步所有引用表与记录 payload 内 _photos 的 URL

BEGIN;

-- ═══════════════════════════════════════════════════════════════
-- A. sample_name 列 + 回填
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE task_packages ADD COLUMN IF NOT EXISTS sample_name TEXT;
ALTER TABLE tasks         ADD COLUMN IF NOT EXISTS sample_name TEXT;

UPDATE task_packages tp
   SET sample_name = sg.sample_name
  FROM sample_groups sg
 WHERE tp.group_no = sg.group_no AND tp.sample_name IS NULL;

UPDATE tasks t
   SET sample_name = sg.sample_name
  FROM sample_groups sg
 WHERE t.group_no = sg.group_no AND t.sample_name IS NULL;

-- ═══════════════════════════════════════════════════════════════
-- B. 002_phase4_columns.sql（等价于 psql -f 002_phase4_columns.sql）
-- ═══════════════════════════════════════════════════════════════
\i 002_phase4_columns.sql

-- ═══════════════════════════════════════════════════════════════
-- C. 存量 BAG- 编号重编号
-- ═══════════════════════════════════════════════════════════════
-- 任务号映射（组内全局两位序号，跨任务包累计）
CREATE TEMP TABLE _task_map ON COMMIT DROP AS
SELECT task_no AS old_task_no,
       group_no || '-T' || lpad(
           (row_number() OVER (PARTITION BY group_no ORDER BY package_no, task_no))::text, 2, '0'
       ) AS new_task_no
FROM tasks
WHERE task_no LIKE 'BAG-%';

-- 报告号映射: R + task_no[2:]（BP…-Tnn → R…-Tnn）
CREATE TEMP TABLE _report_map ON COMMIT DROP AS
SELECT 'R' || old_task_no            AS old_report_no,
       'R' || substring(new_task_no FROM 3) AS new_report_no
FROM _task_map;

-- 任务号（PK）与引用表
UPDATE tasks                 SET task_no = m.new_task_no FROM _task_map m WHERE tasks.task_no = m.old_task_no;
UPDATE records               SET record_no = m.new_task_no FROM _task_map m WHERE records.record_no = m.old_task_no;
UPDATE records               SET task_no   = m.new_task_no FROM _task_map m WHERE records.task_no   = m.old_task_no;
UPDATE reports               SET task_no   = m.new_task_no FROM _task_map m WHERE reports.task_no   = m.old_task_no;
UPDATE attachments           SET task_no   = m.new_task_no,
                                relative_path = m.new_task_no || substring(attachments.relative_path FROM length(m.old_task_no) + 1)
  FROM _task_map m WHERE attachments.task_no = m.old_task_no;
UPDATE requested_tests       SET task_no = m.new_task_no FROM _task_map m WHERE requested_tests.task_no = m.old_task_no;
UPDATE task_config_snapshots SET task_no = m.new_task_no FROM _task_map m WHERE task_config_snapshots.task_no = m.old_task_no;
UPDATE hazardous_waste_records SET task_no = m.new_task_no FROM _task_map m WHERE hazardous_waste_records.task_no = m.old_task_no;
UPDATE equipment_incidents   SET task_no = m.new_task_no FROM _task_map m WHERE equipment_incidents.task_no = m.old_task_no;
UPDATE reviews               SET record_no = m.new_task_no FROM _task_map m WHERE reviews.record_no = m.old_task_no;

-- 报告号（PK）与引用表 — 先临时放开外键再改 reports.report_no
ALTER TABLE report_actions DROP CONSTRAINT IF EXISTS report_actions_report_no_fkey;
UPDATE reports            SET report_no = rm.new_report_no FROM _report_map rm WHERE reports.report_no = rm.old_report_no;
UPDATE report_actions     SET report_no = rm.new_report_no FROM _report_map rm WHERE report_actions.report_no = rm.old_report_no;
UPDATE report_deliveries  SET report_no = rm.new_report_no FROM _report_map rm WHERE report_deliveries.report_no = rm.old_report_no;
UPDATE objections         SET report_no = rm.new_report_no FROM _report_map rm WHERE objections.report_no = rm.old_report_no;
ALTER TABLE report_actions ADD CONSTRAINT report_actions_report_no_fkey
    FOREIGN KEY (report_no) REFERENCES reports(report_no);

-- 审计 / 追溯 entity_id（按实体类型区分；task_package 保留 BAG- 内部编号）
UPDATE audit_logs SET entity_id = m.new_task_no
  FROM _task_map m WHERE audit_logs.entity_type IN ('task','record') AND audit_logs.entity_id = m.old_task_no;
UPDATE audit_logs SET entity_id = rm.new_report_no
  FROM _report_map rm WHERE audit_logs.entity_type = 'report' AND audit_logs.entity_id = rm.old_report_no;
UPDATE modification_logs SET entity_id = rm.new_report_no
  FROM _report_map rm WHERE modification_logs.entity_type = 'report' AND modification_logs.entity_id = rm.old_report_no;

-- 记录 payload 内 _photos 的 URL 路径（previewUrl / url 里的旧任务号）
UPDATE records r
   SET payload = replace(r.payload::text, m.old_task_no, m.new_task_no)::jsonb
  FROM _task_map m
 WHERE r.task_no = m.new_task_no
   AND r.payload::text LIKE '%' || m.old_task_no || '%';

COMMIT;

-- ═══════════════════════════════════════════════════════════════
-- 回滚（如需要）：先备份，再逐表把 new 值换回 old（与上面反向）
-- 建议在迁移前 pg_dump 全量备份。
-- ═══════════════════════════════════════════════════════════════
