# backend/test_db.py

from sqlalchemy import create_engine
from app.core.config import settings

class DatabaseTester:
    """
    数据库连通性终极诊断工具类（Windows 免疫版）。

    作用：
    用于独立验证 FastAPI 后端与 PostgreSQL 数据库之间的网络连通性与账号鉴权。
    本类专门拦截并修复了 Windows 系统下的知名缺陷：当数据库拒绝连接时，
    底层抛出的 GBK 中文报错会导致 psycopg2 驱动引发 UnicodeDecodeError 崩溃。
    通过拦截该异常，我们可以向开发者输出真实的“死因”，极大提升本地 Debug 效率。
    """

    def __init__(self, db_url: str):
        """
        初始化诊断器引擎。

        Args:
            db_url (str): 数据库的完整连接字符串（包含账号、密码、端口、库名）。
        """
        self.db_url = db_url
        self.engine = create_engine(self.db_url)

    def test_connection(self) -> None:
        """
        执行核心连接测试，并安全处理跨平台编码崩溃。

        作用：
        尝试建立真实的 TCP 连接。利用 try-except 块精准捕获因目标端口未监听
        （如 Docker 没启动）而引发的编码崩溃，将“乱码天书”转化为人类易读的操作建议。
        """
        print(f"🔍 正在深度测试数据库连接...")
        print(f"🔗 目标: {self.db_url}")
        
        try:
            with self.engine.connect() as connection:
                print("\n✅ 恭喜！数据库连接完全正常！环境彻底跑通！")
        except Exception as e:
            error_msg = str(e)
            print("\n❌ 数据库连接失败！")
            
            # 💡 核心防御逻辑：精准拦截并转译中文报错引发的乱码崩溃
            if "codec can't decode byte" in error_msg:
                print("⚠️ [系统拦截] 检测到 Windows 网络报错乱码 Bug！")
                print("👉 真实死因：目标计算机积极拒绝连接。")
                print("💡 结论：你的 PostgreSQL 容器没有正常运行在 5432 端口，请检查 Docker 状态！")
            else:
                print(f"👉 详细报错:\n{error_msg}")


if __name__ == "__main__":
    tester = DatabaseTester(settings.DATABASE_URL)
    tester.test_connection()