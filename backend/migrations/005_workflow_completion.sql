-- BPLab Trace LIMS — 按流程图完善功能（迁移 005）
--
-- 全量补齐 mermaid-diagram.svg 目标流程中的缺失步骤与门禁：
--   1) 授权签字人角色（users.role CHECK 增加）
--   2) 设备校准有效期门禁（equipment_registry 增 calibration_due/certificate）
--   3) 留样/处置（samples 增保留期与处置列）
--   4) 归档（commissions/reports 增 archived 列）
--   5) 电子签名（reports 增 approver_signature 引用）
--   6) 异议证据冻结（objections 增 evidence 快照列）
--
-- 执行方式（幂等）:
--   psql -U postgres -d bplab -f backend/migrations/005_workflow_completion.sql
-- 或由 backend/scripts/apply_deferred_changes.py 等价应用。

-- ============================================================
-- 1. 授权签字人角色（重建 CHECK 约束）
-- ============================================================
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('管理员','样品管理员','实验员','复核员','质量负责人','授权签字人'));

-- ============================================================
-- 2. 设备校准有效期门禁
-- ============================================================
ALTER TABLE equipment_registry ADD COLUMN IF NOT EXISTS calibration_due TEXT;
ALTER TABLE equipment_registry ADD COLUMN IF NOT EXISTS calibration_certificate TEXT;

-- ============================================================
-- 3. 留样/处置（samples）
-- ============================================================
ALTER TABLE samples ADD COLUMN IF NOT EXISTS retention_period TEXT;   -- 留样期限
ALTER TABLE samples ADD COLUMN IF NOT EXISTS retention_until DATE;
ALTER TABLE samples ADD COLUMN IF NOT EXISTS disposal_method TEXT;    -- 处置/销毁/报废方式
ALTER TABLE samples ADD COLUMN IF NOT EXISTS disposal_date DATE;
ALTER TABLE samples ADD COLUMN IF NOT EXISTS disposal_note TEXT;
ALTER TABLE samples ADD COLUMN IF NOT EXISTS disposed_by TEXT;

-- ============================================================
-- 4. 报告更正（一个任务可有多份报告：已作废 + 更正版本）
--    reports.task_no 原 UNIQUE 阻止更正版本落库，改为非唯一，
--    由应用逻辑保证「一个任务至多一份非作废报告」。
-- ============================================================
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_task_no_key;

-- ============================================================
-- 5. 归档（commissions / reports）
-- ============================================================
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS archived_by TEXT;
ALTER TABLE reports     ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

-- ============================================================
-- 6. 电子签名（reports 增签署人签名引用；signatures 表已存在）
-- ============================================================
ALTER TABLE reports ADD COLUMN IF NOT EXISTS approver_signature TEXT;

-- ============================================================
-- 7. 异议证据冻结（objections 增证据快照）
-- ============================================================
ALTER TABLE objections ADD COLUMN IF NOT EXISTS evidence_frozen_at TIMESTAMPTZ;
ALTER TABLE objections ADD COLUMN IF NOT EXISTS evidence_snapshot JSONB DEFAULT '{}'::jsonb;
