import os
import sys
import time
from uuid import uuid4

import requests
from sqlalchemy import create_engine, text


def _cleanup_user(email: str) -> None:
    if os.getenv("SMOKE_CLEANUP", "0") != "1":
        return
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        try:
            from app.core.config import settings  # type: ignore

            db_url = settings.DATABASE_URL
        except Exception:
            return
    engine = create_engine(db_url)
    with engine.begin() as conn:
        conn.execute(text("delete from users where email = :email"), {"email": email})

def _cleanup_uploaded_file(file_url: str) -> None:
    if os.getenv("SMOKE_CLEANUP", "0") != "1":
        return
    if not file_url or not file_url.startswith("/uploads/"):
        return
    backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    rel_path = file_url.lstrip("/").replace("/", os.sep)
    abs_path = os.path.abspath(os.path.join(backend_dir, rel_path))
    uploads_root = os.path.abspath(os.path.join(backend_dir, "uploads")) + os.sep
    if not abs_path.startswith(uploads_root):
        return
    try:
        if os.path.exists(abs_path):
            os.remove(abs_path)
    except Exception:
        return


def _fail(msg: str) -> None:
    print(f"[FAIL] {msg}")
    raise SystemExit(1)


def _ok(msg: str) -> None:
    print(f"[OK] {msg}")


def _pick_data(resp_json: dict) -> dict:
    if isinstance(resp_json, dict) and isinstance(resp_json.get("data"), dict):
        return resp_json["data"]
    return {}

def _request_ok(
    s: requests.Session,
    *,
    method: str,
    url: str,
    timeout: float,
    expected_status: tuple[int, ...] = (200,),
    json: dict | None = None,
    files: dict | None = None,
    data: dict | None = None,
) -> dict:
    r = s.request(method, url, json=json, files=files, data=data, timeout=timeout)
    if r.status_code not in expected_status:
        _fail(f"{url} http={r.status_code} body={r.text[:500]}")
    resp_json = r.json()
    if resp_json.get("code") != 0:
        _fail(f"{url} code!=0 body={resp_json}")
    return resp_json


def _poll_task(
    s: requests.Session,
    *,
    url: str,
    timeout: float,
    ok_label: str,
    max_tries: int = 10,
    sleep_seconds: float = 0.3,
) -> dict:
    for _ in range(max_tries):
        resp_json = _request_ok(s, method="GET", url=url, timeout=timeout)
        status_ = _pick_data(resp_json).get("status")
        if status_ == "success":
            _ok(ok_label)
            return resp_json
        if status_ == "failed":
            _fail(f"{url} failed body={resp_json}")
        time.sleep(sleep_seconds)
    _fail(f"{url} timeout waiting success")



def main() -> None:
    base_url = os.getenv("SMOKE_BASE_URL", "http://127.0.0.1:8000/api/v1").rstrip("/")
    timeout = float(os.getenv("SMOKE_TIMEOUT", "10"))

    suffix = uuid4().hex[:8]
    username = f"smoke_{suffix}"
    email = f"smoke_{suffix}@example.com"
    password = os.getenv("SMOKE_PASSWORD") or f"P@{uuid4().hex[:10]}"

    _ok(f"Base URL = {base_url}")

    s = requests.Session()

    register_payload = {
        "username": username,
        "email": email,
        "password": password,
        "nickname": "smoke",
    }
    _request_ok(
        s,
        method="POST",
        url=f"{base_url}/auth/register",
        json=register_payload,
        timeout=timeout,
        expected_status=(200, 201),
    )
    _ok("auth/register")

    login_payload = {"account": email, "password": password}
    login_json = _request_ok(
        s,
        method="POST",
        url=f"{base_url}/auth/login",
        json=login_payload,
        timeout=timeout,
    )
    token = _pick_data(login_json).get("access_token")
    if not token:
        _fail(f"login missing access_token body={login_json}")
    s.headers.update({"Authorization": f"Bearer {token}"})
    _ok("auth/login + token")

    _request_ok(s, method="GET", url=f"{base_url}/auth/me", timeout=timeout)
    _ok("auth/me")

    tiny_png = bytes.fromhex(
        "89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C489"
        "0000000A49444154789C6360000002000154A24F5D0000000049454E44AE426082"
    )
    files = {"file": ("menu.png", tiny_png, "image/png")}
    data = {"scene": "menu"}
    up_json = _request_ok(
        s,
        method="POST",
        url=f"{base_url}/uploads/image",
        files=files,
        data=data,
        timeout=timeout,
    )
    file_id = _pick_data(up_json).get("file_id")
    file_url = _pick_data(up_json).get("file_url") or ""
    if not file_id:
        _fail(f"uploads/image missing file_id body={up_json}")
    _ok(f"uploads/image file_id={file_id}")

    rec_payload = {
        "goal": "lose_fat",
        "budget_level": "medium",
        "meal_type": "dinner",
        "avoid_ingredients": ["牛奶", "花生"],
        "preferred_ingredients": ["鸡胸肉", "西兰花"],
        "max_calories": 600,
    }
    submit_json = _request_ok(
        s,
        method="POST",
        url=f"{base_url}/recommendations/recipes",
        json=rec_payload,
        timeout=timeout,
    )
    task_id = _pick_data(submit_json).get("task_id")
    if not task_id:
        _fail(f"recommendations/recipes missing task_id body={submit_json}")
    _ok(f"recommendations/recipes task_id={task_id}")

    _poll_task(
        s,
        url=f"{base_url}/recommendations/tasks/{task_id}",
        timeout=timeout,
        ok_label="recommendations/tasks success",
    )

    ms_payload = {
        "file_id": file_id,
        "health_goal": "lose_fat",
        "avoid_ingredients": ["花生"],
    }
    _request_ok(
        s,
        method="POST",
        url=f"{base_url}/recommendations/menu-scan",
        json=ms_payload,
        timeout=timeout,
    )
    _ok("recommendations/menu-scan")

    fridge_item_payload = {
        "name": "鸡胸肉",
        "category": "meat",
        "quantity": 1,
        "unit": "piece",
        "expiration_date": "2026-05-10T00:00:00+08:00",
    }
    _request_ok(
        s,
        method="POST",
        url=f"{base_url}/fridge/items/",
        json=fridge_item_payload,
        timeout=timeout,
        expected_status=(200, 201),
    )
    _ok("fridge/items create")

    fridge_task_payload = {
        "target": "high_protein",
        "avoid_ingredients": ["花生", "牛奶"],
        "preferred_cuisine": "chinese",
        "max_calories": 600,
        "use_expiring_first": True,
    }
    ft_json = _request_ok(
        s,
        method="POST",
        url=f"{base_url}/fridge/recipe-tasks",
        json=fridge_task_payload,
        timeout=timeout,
    )
    fridge_task_id = _pick_data(ft_json).get("task_id")
    if not fridge_task_id:
        _fail(f"fridge/recipe-tasks missing task_id body={ft_json}")
    _ok(f"fridge/recipe-tasks task_id={fridge_task_id}")

    _poll_task(
        s,
        url=f"{base_url}/fridge/recipe-tasks/{fridge_task_id}",
        timeout=timeout,
        ok_label="fridge/recipe-tasks success",
    )

    hist_json = _request_ok(
        s,
        method="GET",
        url=f"{base_url}/recommendations/history?page=1&page_size=10",
        timeout=timeout,
    )
    items = _pick_data(hist_json).get("items") or []
    if not items:
        _fail(f"recommendations/history empty body={hist_json}")
    _ok("recommendations/history")

    recipe_id = items[0].get("id")
    if not recipe_id:
        _fail(f"recommendations/history missing id body={items[0]}")
    _request_ok(
        s,
        method="GET",
        url=f"{base_url}/recommendations/recipes/{recipe_id}",
        timeout=timeout,
    )
    _ok("recommendations/recipes/{id}")

    _request_ok(
        s,
        method="GET",
        url=f"{base_url}/recommendations/dashboard",
        timeout=timeout,
    )
    _ok("recommendations/dashboard")

    _cleanup_uploaded_file(file_url)
    _cleanup_user(email)
    _ok("SMOKE E2E PASSED")


if __name__ == "__main__":
    try:
        main()
    except requests.RequestException as e:
        _fail(f"network error: {e}")
