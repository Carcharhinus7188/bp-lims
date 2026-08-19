"""
初始化 PostgreSQL 数据库 — 创建表结构 + 运行迁移
用法: cd backend && python scripts/init_db.py
"""
from __future__ import annotations

import sys
from pathlib import Path

# 确保 backend 在 sys.path 中
sys.path.insert(0, str(Path(__file__).parent.parent))

import psycopg2
from app.config import settings


def init_database():
    """创建 bplab 数据库和所有表结构"""
    schema_file = Path(__file__).parent.parent / "migrations" / "001_schema.sql"
    if not schema_file.exists():
        print(f"❌ 找不到 schema 文件: {schema_file}")
        sys.exit(1)

    schema_sql = schema_file.read_text("utf-8")

    # 先连接到默认数据库，创建 bplab 数据库（如果不存在）
    try:
        conn = psycopg2.connect(
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            dbname="postgres",
        )
        conn.autocommit = True
        cur = conn.cursor()

        # 检查数据库是否已存在
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (settings.DB_NAME,))
        if cur.fetchone():
            print(f"ℹ️  数据库 '{settings.DB_NAME}' 已存在，跳过创建")
        else:
            cur.execute(f'CREATE DATABASE "{settings.DB_NAME}"')
            print(f"✅ 数据库 '{settings.DB_NAME}' 创建成功")

        cur.close()
        conn.close()
    except psycopg2.Error as e:
        print(f"⚠️  无法连接到 PostgreSQL: {e}")
        print("   请确保 PostgreSQL 服务已启动，且 .env 中配置正确")
        sys.exit(1)

    # 连接到 bplab 数据库并运行 schema
    try:
        conn = psycopg2.connect(
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            dbname=settings.DB_NAME,
        )
        cur = conn.cursor()
        cur.execute(schema_sql)
        conn.commit()
        cur.close()
        conn.close()
        print(f"✅ 数据表创建成功 ({settings.DB_NAME})")
    except psycopg2.Error as e:
        print(f"❌ 创建表结构失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    init_database()
    print("🎉 数据库初始化完成！")
