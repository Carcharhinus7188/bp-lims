-- BPLab Trace LIMS — 去硬编码、配置驱动化改造（迁移 004）
--
-- 为 experiment_config_versions 增加 extra_json 列，用于承载：
--   camera_hints / report_decisive_photo_codes / record_template_file / constants
-- 参照 device_presets.extra_json 的 JSONB 先例。
--
-- 执行方式（幂等）:
--   psql -U postgres -d bplab -f backend/migrations/004_config_driven.sql
-- 或由 backend/scripts/backfill_extra_json.py 自动应用。

ALTER TABLE experiment_config_versions
    ADD COLUMN IF NOT EXISTS extra_json JSONB DEFAULT '{}';
