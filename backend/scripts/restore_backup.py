"""
从数据库 dump 一键恢复（删旧库 → 建空库 → 导入 → 校验）

用法:
    cd backend && ..\\.venv\\Scripts\\python.exe -X utf8 scripts\\restore_backup.py

说明:
- 数据库连接参数读取项目根目录 `.env`（DB_HOST / DB_PORT / DB_USER / DB_PASSWORD / DB_NAME）。
- 导入文件默认为项目根目录 `bplab_dump.sql`（可用环境变量 `DUMP_FILE` 覆盖）。
- 若目标数据库已存在：先终止其活动连接，再 `DROP DATABASE`，然后 `CREATE DATABASE` 重建。
- dump 为 PostgreSQL 18.4 纯文本格式（pg_dump，`--no-owner`），含
  `\\restrict` / `\\unrestrict` psql 元命令与 `COPY ... FROM stdin` 数据块、sequence setval。
  脚本逐条解析执行：psql 元命令被跳过，COPY 数据块用 `copy_expert` 流式导入，
  因此**不依赖目标机器 psql 版本**（PG14 ~ PG18 均可），也无需手工建库。
"""
from __future__ import annotations

import io
import os
import sys
from pathlib import Path

import psycopg2
from psycopg2 import sql

# 确保 backend 在 sys.path 中，以便读取 app.config.settings（含 .env）
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings  # noqa: E402

# Windows 控制台默认 GBK，强制 UTF-8 输出避免 emoji / 中文报错
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).parent.parent.parent
DUMP_PATH = Path(os.getenv("DUMP_FILE", str(ROOT / "bplab_dump.sql")))


def _admin_conn() -> psycopg2.extensions.connection:
    """连接默认 postgres 库（用于 DROP / CREATE DATABASE）"""
    return psycopg2.connect(
        host=settings.DB_HOST,
        port=settings.DB_PORT,
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
        dbname="postgres",
    )


def _target_conn() -> psycopg2.extensions.connection:
    """连接目标业务库"""
    return psycopg2.connect(
        host=settings.DB_HOST,
        port=settings.DB_PORT,
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
        dbname=settings.DB_NAME,
    )


def drop_and_recreate_db() -> None:
    """检测同名数据库：存在则终止连接并删除，再创建空库"""
    conn = _admin_conn()
    conn.autocommit = True
    cur = conn.cursor()
    dbname = settings.DB_NAME

    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (dbname,))
    exists = cur.fetchone() is not None

    if exists:
        print(f"ℹ️  检测到同名数据库 '{dbname}'，终止其活动连接后删除...")
        cur.execute(
            "SELECT pg_terminate_backend(pid) FROM pg_stat_activity "
            "WHERE datname = %s AND pid <> pg_backend_pid()",
            (dbname,),
        )
        cur.execute(sql.SQL("DROP DATABASE {}").format(sql.Identifier(dbname)))
        print(f"🗑️  已删除旧库 '{dbname}'")
    else:
        print(f"ℹ️  未检测到同名数据库 '{dbname}'，直接新建")

    cur.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(dbname)))
    print(f"✅ 已创建空库 '{dbname}'")

    cur.close()
    conn.close()


def import_dump() -> None:
    """逐条解析并导入 dump 文件"""
    if not DUMP_PATH.exists():
        print(f"❌ 找不到 dump 文件: {DUMP_PATH}")
        sys.exit(1)

    raw = DUMP_PATH.read_bytes().decode("utf-8")
    # 统一换行符（dump 内字段值中的换行已被 pg_dump 转义，直接替换安全）
    text = raw.replace("\r\n", "\n")
    lines = text.split("\n")

    conn = _target_conn()
    cur = conn.cursor()

    i, n = 0, len(lines)
    buf: list[str] = []
    stmt_count = 0
    copy_count = 0

    def flush() -> None:
        nonlocal buf, stmt_count
        stmt = "\n".join(buf).strip()
        buf = []
        if not stmt or stmt.startswith("\\"):
            return
        cur.execute(stmt)
        stmt_count += 1

    while i < n:
        line = lines[i]
        stripped = line.strip()

        # 注释 / 空行
        if stripped == "" or stripped.startswith("--"):
            i += 1
            continue
        # psql 元命令（PG18 的 \restrict / \unrestrict）
        if stripped.startswith("\\restrict") or stripped.startswith("\\unrestrict"):
            i += 1
            continue

        # COPY ... FROM stdin; 数据块
        if stripped.upper().startswith("COPY ") and " FROM stdin;" in stripped:
            copy_sql = stripped
            data_lines: list[str] = []
            i += 1
            while i < n and lines[i].strip() != "\\.":
                data_lines.append(lines[i])
                i += 1
            i += 1  # 跳过 \.
            if data_lines:
                cur.copy_expert(copy_sql, io.StringIO("\n".join(data_lines) + "\n"))
            # 空表（无数据行）直接跳过，不执行 COPY
            copy_count += 1
            continue

        # 普通语句：按分号结尾 flush
        buf.append(line)
        if stripped.endswith(";"):
            flush()
        i += 1

    flush()

    conn.commit()
    cur.close()
    conn.close()
    print(f"✅ 导入完成：执行语句 {stmt_count} 条，导入数据块 {copy_count} 个")


def verify() -> None:
    """校验导入结果"""
    conn = _target_conn()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
    tables = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM equipment_registry")
    equipment = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM sample_catalog")
    catalog = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM users")
    users = cur.fetchone()[0]
    cur.close()
    conn.close()
    print("  - 表数量:", tables)
    print("  - 设备库:", equipment, "台")
    print("  - 样品资料库:", catalog, "条")
    print("  - 用户:", users, "个")


def main() -> None:
    print("=" * 60)
    print("BPLab 数据库一键恢复")
    print(f"  目标: {settings.DB_USER}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}")
    print(f"  dump: {DUMP_PATH}")
    print("=" * 60)

    print("\n[1/3] 检测并重建数据库...")
    drop_and_recreate_db()

    print("\n[2/3] 导入 dump 数据...")
    import_dump()

    print("\n[3/3] 校验导入结果...")
    verify()

    print("\n🎉 数据库恢复完成！")


if __name__ == "__main__":
    main()
