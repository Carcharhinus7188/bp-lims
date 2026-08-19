"""BPLab Trace LIMS V11 — FastAPI 主入口"""
from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动时
    for d in [settings.UPLOAD_DIR, settings.ATTACHMENT_DIR, settings.SIGNATURE_DIR]:
        Path(d).mkdir(parents=True, exist_ok=True)

    # 首次启动自动填充基础数据（实验方法、配置版本等）
    try:
        from app.core.seed import auto_seed
        result = await auto_seed()
        if any(v > 0 for v in result.values()):
            import logging
            logging.getLogger(__name__).info(
                f"Auto-seed 完成: users={result['users']}, "
                f"methods={result['methods']}, configs={result['configs']}"
            )
    except Exception:
        import logging
        logging.getLogger(__name__).warning("Auto-seed 跳过（数据库可能尚未就绪）")

    yield
    # 关闭时清理连接池
    from app.database import engine
    await engine.dispose()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS — 前端开发服务器
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 路由
app.include_router(api_router, prefix="/api/v1")


@app.get("/api")
async def api_info():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
    }


@app.get("/health")
async def health():
    return {"status": "ok"}


# ── 首页 ──
@app.get("/")
async def root():
    """首页：一体化模式返回 SPA 登录页，开发模式返回 API 信息"""
    if settings.SERVE_FRONTEND:
        from fastapi.responses import FileResponse
        frontend_dist = Path(__file__).resolve().parent.parent.parent / "frontend" / "dist"
        if frontend_dist.exists():
            return FileResponse(frontend_dist / "index.html")
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
    }


# ── 一体化模式：后端直接提供前端静态文件 ──
if settings.SERVE_FRONTEND:
    from fastapi.staticfiles import StaticFiles
    from fastapi.responses import FileResponse

    FRONTEND_DIST = Path(__file__).resolve().parent.parent.parent / "frontend" / "dist"

    if FRONTEND_DIST.exists():
        # 静态资源（带哈希的 JS/CSS/图片）
        assets_dir = FRONTEND_DIST / "assets"
        if assets_dir.exists():
            app.mount("/assets", StaticFiles(directory=assets_dir), name="frontend_assets")

        # SPA 回退：所有非 API/非静态文件路径 → index.html
        # 注意：必须放在所有精确路由之后，否则会拦截 /docs 等路径
        @app.get("/{full_path:path}", include_in_schema=False)
        async def serve_frontend(full_path: str):
            """返回前端 SPA 页面 — API 路径已被上方路由拦截，此处处理前端页面"""
            file_path = FRONTEND_DIST / full_path
            if file_path.exists() and file_path.is_file():
                return FileResponse(file_path)
            return FileResponse(FRONTEND_DIST / "index.html")
