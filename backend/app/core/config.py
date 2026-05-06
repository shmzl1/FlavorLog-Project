# backend/app/core/config.py

import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict

# ==========================================
# 绝对路径定位与环境物理检查
# ==========================================
# 获取当前文件的绝对路径，并向上推三层，精准锁定 backend 根目录
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_FILE_PATH = os.path.join(BASE_DIR, ".env")

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
    
    作用：
    利用 Pydantic V2 强类型校验特性，读取 `.env` 中的字符串并转化为 Python 原生类型。
    如果 `.env` 内部的变量名写错、或者类型不匹配，它会在系统启动时立刻阻断，
    保障系统在带病状态下绝不运行。
    """
    
    PROJECT_NAME: str = "FlavorLog"
    PROJECT_ENV: str = "development"
    PROJECT_VERSION: str = "0.1.0"

    # 以下为强依赖项，缺失会导致系统无法连接数据库或无法验证 Token
    DATABASE_URL: str
    JWT_SECRET_KEY: str
    CORS_ALLOW_ORIGINS: str

    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080
    UPLOAD_DIR: str = "backend/uploads"
    MAX_IMAGE_SIZE_MB: int = 10

    # Pydantic V2 配置：强制绑定刚才计算出的绝对路径
    model_config = SettingsConfigDict(
        env_file=ENV_FILE_PATH,
        env_file_encoding="utf-8",
        extra="ignore"
    )

    def get_cors_origins_list(self) -> List[str]:
        """
        动态解析跨域白名单配置。
        
        作用：
        提取 .env 中用逗号分隔的 URL 字符串（如 "http://localhost:3000,http://127.0.0.1:3000"），
        并将其转化为 FastAPI 中间件所需的严格 List[str] 格式。
        这保证了前端在跨域请求时不会被浏览器的同源策略拦截。
        
        Returns:
            List[str]: 清洗过空格的跨域允许列表。
        """
        if not self.CORS_ALLOW_ORIGINS:
            return []
        return [origin.strip() for origin in self.CORS_ALLOW_ORIGINS.split(",")]


# 实例化配置单例，加上类型忽略以兼容静态检查工具
settings = Settings()  # type: ignore