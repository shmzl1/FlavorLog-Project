from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


API_PREFIX = "/api/v1"


def success_response(data: Any = None, message: str = "success") -> dict:
    return {
        "code": 0,
        "message": message,
        "data": data,
        "request_id": str(uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


app = FastAPI(
    title="FlavorLog Backend API",
    description="知味志 FlavorLog 后端接口文档。所有业务接口以 /api/v1 开头。",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return success_response(
        data={
            "name": "FlavorLog Backend",
            "version": "0.1.0",
            "docs": "/docs",
            "api_prefix": API_PREFIX,
        }
    )


@app.get("/health")
def health_check():
    return success_response(
        data={
            "status": "ok",
            "service": "flavorlog-backend",
        }
    )


@app.get(f"{API_PREFIX}/health")
def api_health_check():
    return success_response(
        data={
            "status": "ok",
            "service": "flavorlog-backend",
            "api_prefix": API_PREFIX,
        }
    )