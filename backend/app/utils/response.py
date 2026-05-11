from datetime import datetime, timezone
from typing import Any, List, Optional
from uuid import uuid4


def success_response(data: Any = None, message: str = "success") -> dict:
    return {
        "code": 0,
        "message": message,
        "data": data,
        "request_id": str(uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def error_response(
    code: int = 1,
    message: str = "error",
    data: Any = None,
    errors: Optional[List[dict]] = None,
) -> dict:
    payload = {
        "code": code,
        "message": message,
        "data": data,
        "request_id": str(uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    if errors is not None:
        payload["errors"] = errors
    return payload
