# BPLab Trace — 变更记录 (CHANGELOG)

所有对项目的重要变更均记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [V10.0] — 2026-08-07

### 🔒 新增 — 安全加固（生产就绪）

#### 登录暴力破解防护
- 新增 `login_attempts` 数据库表，追踪每次登录尝试（成功/失败）
- `authenticate()` 现在强制执行 `MAX_LOGIN_ATTEMPTS`（默认 5 次）
- 连续失败 `MAX_LOGIN_ATTEMPTS` 次后，账户被临时锁定 `LOGIN_LOCKOUT_MINUTES` 分钟（默认 15 分钟）
- 新增 `reset_login_attempts()` 函数供管理员手动解锁
- 新增配置项：`LOGIN_LOCKOUT_MINUTES`

#### 密码复杂度策略
- 新增 `_validate_password_strength()` 函数
- 密码最小长度：`PASSWORD_MIN_LENGTH`（默认 8 个字符）
- 必须包含至少一个数字 + 一个字母
- 拒绝常见弱密码（admin123, password, 12345678 等）
- 新增 `PasswordValidationError` 异常类
- `add_user()` 创建用户时强制执行密码强度检查

#### 密码修改功能
- 新增 `change_password(username, old_password, new_password)` 函数
- 新增 `admin_reset_password(admin, target, new_password)` 函数
- 新增"修改密码"页面（所有角色可访问）
- 侧边栏新增"🔒 修改密码"快捷入口
- 密码修改后自动使所有旧会话失效

#### 会话安全增强
- 新增 `last_activity_at` 列到 `sessions` 表
- 新增 `touch_session()` 函数，每次请求更新活跃时间
- 会话不活跃超时：`SESSION_INACTIVITY_TIMEOUT_MINUTES`（默认 1440 分钟 = 24 小时）
- `session_user()` 同时检查过期时间和不活跃超时
- 移除了 URL query param 传递 session token 的遗留代码（安全提升）
- 新增 `list_active_sessions()` 和 `terminate_session()` 函数
- 新增 `cleanup_expired_sessions()` 函数（启动时自动执行）
- 新增 `invalidate_user_sessions()` 函数（密码修改时调用）

#### 配置安全加固
- `DEMO_MODE` 默认值从 `true` 改为 `false` — 生产环境默认安全
- DEMO_MODE 启用时在登录页和侧边栏显示醒目警告横幅
- 启动时自动检查 SECRET_KEY、DEMO_MODE 和 BPLAB_PRODUCTION 配置
- 新增 `BPLAB_PRODUCTION` 环境变量支持

### 🗄 新增 — 数据库管理功能

#### 数据库健康检查
- 新增 `db_health_check()` 函数
- 返回数据库大小、WAL 大小、每表行数、完整性检查、外键检查
- 新增管理员"数据库管理"页面，含健康仪表盘

#### 数据库备份与恢复
- 新增 `backup_database()` — 使用 SQLite online backup API（保证一致性）
- 新增 `restore_database()` — 恢复前自动备份当前数据库
- 新增 `list_backups()` — 列出所有备份文件
- 新增 `export_table_csv()` — 导出任意表为 CSV

#### 数据库维护
- 新增 `db_maintenance()` — 支持 optimize / vacuum / checkpoint
- 管理页面提供一键 VACUUM、WAL Checkpoint、PRAGMA optimize

#### 活跃会话监控
- 管理员"用户与权限"页面新增活跃会话列表
- 显示用户名、角色、登录时间、最后活动、空闲时间
- 一键清理过期会话

### 🔧 修复 — 功能问题

#### 错误处理加固
- 修复 app.py 中多个 `next()` 调用缺少默认值导致的潜在崩溃
- 修复 `experiment_engine.py` 中 `except Exception: pass` 静默吞异常问题（改为记录日志）

#### 审计日志改进
- 新增 `audit_logs_paginated()` 函数，支持分页和过滤查询（实体类型、操作人、操作类型、日期范围）

#### DOCX 预览
- 改进 LibreOffice 进程搜索路径

### 🧪 新增 — 测试覆盖

- 新建 `tests/test_security.py` — 29 个安全测试
  - 暴力破解防护（7 个测试）
  - 密码复杂度验证（6 个测试）
  - 密码修改流程（5 个测试）
  - 管理员密码重置（3 个测试）
  - 会话安全（6 个测试）
  - 演示模式安全（2 个测试）
- 新建 `tests/test_database.py` — 20 个数据库测试
  - 健康检查（5 个测试）
  - 维护操作（4 个测试）
  - 备份恢复（4 个测试）
  - 数据导出（2 个测试）
  - 并发访问（2 个测试）
  - 系统初始化（2 个测试）

### 📝 变更的文件

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `lims_db.py` | 修改 | 新增 20+ 函数，修改 authenticate/create_session/session_user 等 |
| `app.py` | 修改 | 新增密码修改页、数据库管理页、会话监控；修复 next() 调用；会话安全 |
| `config.py` | 修改 | 新增 5 个配置项；DEMO_MODE 默认 false |
| `constants.py` | 修改 | 新增"修改密码"和"数据库管理"菜单项 |
| `experiment_engine.py` | 修改 | 修复静默异常吞没 |
| `tests/test_security.py` | 新建 | 安全测试套件（29 个测试） |
| `tests/test_database.py` | 新建 | 数据库测试套件（20 个测试） |
| `tests/test_bplab_suite.py` | 修改 | 适配 sessions 表新列和密码复杂度 |
| `CHANGELOG.md` | 新建 | 本文档 |

---

## [V9.3] — 2026-08-05（基准版本）

### 初始记录
- Streamlit LIMS 系统，支持 10 种实验类型
- 5 种用户角色：管理员、样品管理员、实验员、复核员、质量负责人
- SQLite 数据库（WAL 模式），26 张业务表
- PBKDF2-SHA256 密码哈希（240,000 次迭代）
- DOCX 受控模板预览（LibreOffice + PyMuPDF）
- 移动摄像头现场拍照（水印）
- 哈希链式审计追踪（SHA-256）
- 三级报告审批流程
- 88 项设备目录
- 26 个受控 DOCX 模板

### 已知 3 个 commits
1. 初始提交（yaha0565/bplab master）
2. V9.3 版本发布
3. Windows 兼容性修复（LibreOffice 路径搜索、临时文件清理）

---

> **变更记录规范**：每次对项目进行代码修改、配置变更、流程调整或新增功能后，请在本文件顶部添加新版本条目。
> 格式：`## [VX.Y] — YYYY-MM-DD`，包含"新增/修复/变更/移除"分类。
