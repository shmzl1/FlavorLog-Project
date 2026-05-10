import os
import subprocess
from typing import List

from PIL import Image


class OCRRuntimeError(RuntimeError):
    pass


def extract_text(image_path: str, *, provider: str, timeout_seconds: int = 30) -> str:
    provider = (provider or "mock").lower()
    if provider == "mock":
        return "炸鸡排饭\n番茄牛肉饭\n青椒肉丝盖饭\n"
    if provider == "tesseract":
        if not os.path.exists(image_path):
            raise OCRRuntimeError("文件不存在")
        try:
            Image.open(image_path).convert("RGB")
        except Exception:
            raise OCRRuntimeError("文件不是有效图片")
        try:
            proc = subprocess.run(
                ["tesseract", image_path, "stdout", "-l", "chi_sim+eng"],
                capture_output=True,
                text=True,
                timeout=timeout_seconds,
                check=False,
                encoding="utf-8",
                errors="ignore",
            )
        except FileNotFoundError:
            raise OCRRuntimeError("未找到 tesseract 可执行文件")
        if proc.returncode != 0:
            err = (proc.stderr or "").strip()
            raise OCRRuntimeError(err or "tesseract 执行失败")
        return proc.stdout or ""
    raise OCRRuntimeError("不支持的 OCR_PROVIDER")


def parse_menu_names(text: str, *, limit: int = 20) -> List[str]:
    names: List[str] = []
    seen = set()
    for raw in (text or "").splitlines():
        s = raw.strip()
        if not s:
            continue
        if len(s) < 2:
            continue
        if len(s) > 30:
            continue
        if s in seen:
            continue
        seen.add(s)
        names.append(s)
        if len(names) >= limit:
            break
    return names
