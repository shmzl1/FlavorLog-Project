# backend/app/core/config.py

import os
from typing import List, Union
from pydantic_settings import BaseSettings, SettingsConfigDict

# ==========================================
# 绝对路径定位与环境物理检查
# ==========================================
# 获取当前文件的绝对路径，并向上推三层，精准锁定 backend 根目录
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_FILE_PATH = os.path.join(BASE_DIR, ".env")

if os.environ.get("DEBUG", "").lower() not in {"", "true", "false", "1", "0", "yes", "no", "on", "off"}:
    os.environ.pop("DEBUG", None)

class EnvironmentError(Exception):
    """
    自定义环境异常类。
    
    作用：
    当系统检测到关键的运行环境（如配置文件缺失）不满足时抛出。
    相比于官方生硬的 KeyError 或 ValidationError，
    它可以向终端输出带有明确指导建议的中文报错信息，极大降低团队协作时的沟通成本。
    """
    pass

# 🌟 工程师防坑机制：在 Pydantic 解析前，进行物理文件拦截
if not os.path.exists(ENV_FILE_PATH):
    raise EnvironmentError(
        f"\n❌ [致命错误] 未找到本地环境变量文件！\n"
        f"📍 预期路径: {ENV_FILE_PATH}\n"
        f"💡 解决方法: 请在 backend 目录下，将 '.env.example' 复制一份并重命名为 '.env'。"
    )


class Settings(BaseSettings):
    """
    全局配置与环境变量校验核心类。
    """
    
    # ==========================================
    # 💡 核心修复：补充 main.py 依赖的基础应用配置
    # ==========================================
    APP_NAME: str = "FlavorLog Backend"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = True
    API_PREFIX: str = "/api/v1"  # 解决你在 main.py 里的 Pylance 报错

    # 项目信息 (保留你原有的结构)
    PROJECT_NAME: str = "FlavorLog"
    PROJECT_ENV: str = "development"
    PROJECT_VERSION: str = "0.1.0"

    # 以下为强依赖项，缺失会导致系统无法连接数据库或无法验证 Token
    DATABASE_URL: str
    JWT_SECRET_KEY: str
    
    # 💡 核心优化：直接使用 Union[str, List[str]]，Pydantic 会自动将逗号字符串解析为列表
    CORS_ALLOW_ORIGINS: Union[str, List[str]] = ["*"]

    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080
    UPLOAD_DIR: str = "backend/uploads"
    MAX_IMAGE_SIZE_MB: int = 10

    # Pydantic V2 配置：强制绑定刚才计算出的绝对路径
    model_config = SettingsConfigDict(
        env_file=ENV_FILE_PATH,
        env_file_encoding="utf-8",
        extra="ignore"  # 忽略 .env 中存在但在本类中未定义的额外变量，防止报错
    )

    def get_cors_origins_list(self) -> List[str]:
        """动态解析跨域白名单配置 (向下兼容你之前的方法)"""
        if isinstance(self.CORS_ALLOW_ORIGINS, list):
            return self.CORS_ALLOW_ORIGINS
        if isinstance(self.CORS_ALLOW_ORIGINS, str):
            return [origin.strip() for origin in self.CORS_ALLOW_ORIGINS.split(",")]
        return ["*"]


# 实例化配置单例，加上类型忽略以兼容静态检查工具
settings = Settings()  # type: ignore
