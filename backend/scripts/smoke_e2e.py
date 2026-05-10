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


def main() -> None:
    base_url = os.getenv("SMOKE_BASE_URL", "http://127.0.0.1:8000/api/v1").rstrip("/")
    timeout = float(os.getenv("SMOKE_TIMEOUT", "10"))

    suffix = uuid4().hex[:8]
    username = f"smoke_{suffix}"
    email = f"smoke_{suffix}@example.com"
    password = "123456"

    _ok(f"Base URL = {base_url}")

    s = requests.Session()

    register_payload = {
        "username": username,
        "email": email,
        "password": password,
        "nickname": "smoke",
    }
    r = s.post(f"{base_url}/auth/register", json=register_payload, timeout=timeout)
    if r.status_code not in (200, 201):
        _fail(f"register http={r.status_code} body={r.text[:500]}")
    reg_json = r.json()
    if reg_json.get("code") != 0:
        _fail(f"register code!=0 body={reg_json}")
    _ok("auth/register")

    login_payload = {"account": email, "password": password}
    r = s.post(f"{base_url}/auth/login", json=login_payload, timeout=timeout)
    if r.status_code != 200:
        _fail(f"login http={r.status_code} body={r.text[:500]}")
    login_json = r.json()
    if login_json.get("code") != 0:
        _fail(f"login code!=0 body={login_json}")
    token = _pick_data(login_json).get("access_token")
    if not token:
        _fail(f"login missing access_token body={login_json}")
    s.headers.update({"Authorization": f"Bearer {token}"})
    _ok("auth/login + token")

    r = s.get(f"{base_url}/auth/me", timeout=timeout)
    if r.status_code != 200:
        _fail(f"me http={r.status_code} body={r.text[:500]}")
    me_json = r.json()
    if me_json.get("code") != 0:
        _fail(f"me code!=0 body={me_json}")
    _ok("auth/me")

    tiny_png = bytes.fromhex(
        "89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C489"
        "0000000A49444154789C6360000002000154A24F5D0000000049454E44AE426082"
    )
    files = {"file": ("menu.png", tiny_png, "image/png")}
    data = {"scene": "menu"}
    r = s.post(f"{base_url}/uploads/image", files=files, data=data, timeout=timeout)
    if r.status_code != 200:
        _fail(f"uploads/image http={r.status_code} body={r.text[:500]}")
    up_json = r.json()
    if up_json.get("code") != 0:
        _fail(f"uploads/image code!=0 body={up_json}")
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
    r = s.post(f"{base_url}/recommendations/recipes", json=rec_payload, timeout=timeout)
    if r.status_code != 200:
        _fail(f"recommendations/recipes http={r.status_code} body={r.text[:500]}")
    submit_json = r.json()
    if submit_json.get("code") != 0:
        _fail(f"recommendations/recipes code!=0 body={submit_json}")
    task_id = _pick_data(submit_json).get("task_id")
    if not task_id:
        _fail(f"recommendations/recipes missing task_id body={submit_json}")
    _ok(f"recommendations/recipes task_id={task_id}")

    for _ in range(10):
        r = s.get(f"{base_url}/recommendations/tasks/{task_id}", timeout=timeout)
        if r.status_code != 200:
            _fail(f"recommendations/tasks http={r.status_code} body={r.text[:500]}")
        task_json = r.json()
        if task_json.get("code") != 0:
            _fail(f"recommendations/tasks code!=0 body={task_json}")
        status_ = _pick_data(task_json).get("status")
        if status_ == "success":
            _ok("recommendations/tasks success")
            break
        if status_ == "failed":
            _fail(f"recommendations/tasks failed body={task_json}")
        time.sleep(0.3)
    else:
        _fail("recommendations/tasks timeout waiting success")

    ms_payload = {
        "file_id": file_id,
        "health_goal": "lose_fat",
        "avoid_ingredients": ["花生"],
    }
    r = s.post(f"{base_url}/recommendations/menu-scan", json=ms_payload, timeout=timeout)
    if r.status_code != 200:
        _fail(f"recommendations/menu-scan http={r.status_code} body={r.text[:500]}")
    ms_json = r.json()
    if ms_json.get("code") != 0:
        _fail(f"recommendations/menu-scan code!=0 body={ms_json}")
    _ok("recommendations/menu-scan")

    fridge_item_payload = {
        "name": "鸡胸肉",
        "category": "meat",
        "quantity": 1,
        "unit": "piece",
        "expiration_date": "2026-05-10T00:00:00+08:00",
    }
    r = s.post(f"{base_url}/fridge/items/", json=fridge_item_payload, timeout=timeout)
    if r.status_code not in (200, 201):
        _fail(f"fridge/items create http={r.status_code} body={r.text[:500]}")
    item_json = r.json()
    if item_json.get("code") != 0:
        _fail(f"fridge/items create code!=0 body={item_json}")
    _ok("fridge/items create")

    fridge_task_payload = {
        "target": "high_protein",
        "avoid_ingredients": ["花生", "牛奶"],
        "preferred_cuisine": "chinese",
        "max_calories": 600,
        "use_expiring_first": True,
    }
    r = s.post(f"{base_url}/fridge/recipe-tasks", json=fridge_task_payload, timeout=timeout)
    if r.status_code != 200:
        _fail(f"fridge/recipe-tasks http={r.status_code} body={r.text[:500]}")
    ft_json = r.json()
    if ft_json.get("code") != 0:
        _fail(f"fridge/recipe-tasks code!=0 body={ft_json}")
    fridge_task_id = _pick_data(ft_json).get("task_id")
    if not fridge_task_id:
        _fail(f"fridge/recipe-tasks missing task_id body={ft_json}")
    _ok(f"fridge/recipe-tasks task_id={fridge_task_id}")

    for _ in range(10):
        r = s.get(f"{base_url}/fridge/recipe-tasks/{fridge_task_id}", timeout=timeout)
        if r.status_code != 200:
            _fail(f"fridge/recipe-tasks get http={r.status_code} body={r.text[:500]}")
        gt_json = r.json()
        if gt_json.get("code") != 0:
            _fail(f"fridge/recipe-tasks get code!=0 body={gt_json}")
        status_ = _pick_data(gt_json).get("status")
        if status_ == "success":
            _ok("fridge/recipe-tasks success")
            break
        if status_ == "failed":
            _fail(f"fridge/recipe-tasks failed body={gt_json}")
        time.sleep(0.3)
    else:
        _fail("fridge/recipe-tasks timeout waiting success")

    r = s.get(f"{base_url}/recommendations/history?page=1&page_size=10", timeout=timeout)
    if r.status_code != 200:
        _fail(f"recommendations/history http={r.status_code} body={r.text[:500]}")
    hist_json = r.json()
    if hist_json.get("code") != 0:
        _fail(f"recommendations/history code!=0 body={hist_json}")
    items = _pick_data(hist_json).get("items") or []
    if not items:
        _fail(f"recommendations/history empty body={hist_json}")
    _ok("recommendations/history")

    recipe_id = items[0].get("id")
    if not recipe_id:
        _fail(f"recommendations/history missing id body={items[0]}")
    r = s.get(f"{base_url}/recommendations/recipes/{recipe_id}", timeout=timeout)
    if r.status_code != 200:
        _fail(f"recommendations/recipes/{recipe_id} http={r.status_code} body={r.text[:500]}")
    detail_json = r.json()
    if detail_json.get("code") != 0:
        _fail(f"recommendations/recipes/{recipe_id} code!=0 body={detail_json}")
    _ok("recommendations/recipes/{id}")

    r = s.get(f"{base_url}/recommendations/dashboard", timeout=timeout)
    if r.status_code != 200:
        _fail(f"recommendations/dashboard http={r.status_code} body={r.text[:500]}")
    dash_json = r.json()
    if dash_json.get("code") != 0:
        _fail(f"recommendations/dashboard code!=0 body={dash_json}")
    _ok("recommendations/dashboard")

    _cleanup_uploaded_file(file_url)
    _cleanup_user(email)
    _ok("SMOKE E2E PASSED")


if __name__ == "__main__":
    try:
        main()
    except requests.RequestException as e:
        _fail(f"network error: {e}")
