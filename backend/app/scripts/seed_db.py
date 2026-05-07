# backend/app/scripts/seed_db.py

import sys
import os

# 将项目根目录加入环境路径，确保能导入 app
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from sqlalchemy.orm import Session
from app.db.session import DatabaseManager
from app.core.config import settings
from app.models.user import User
from app.models.fridge_item import FridgeItem
from app.core.security import pwd_hasher
from datetime import datetime, timedelta

def seed_data():
    """
    一键初始化演示数据。
    作用：自动创建测试账号和冰箱初始食材。
    """
    print("开始初始化演示数据...")
    db_manager = DatabaseManager(settings.DATABASE_URL)
    db = next(db_manager.get_db_session())

    try:
        # 1. 检查用户是否已存在
        user = db.query(User).filter(User.email == "test@example.com").first()
        if not user:
            print("正在创建测试账号: test@example.com")
            user = User(
                username="test_user",
                email="test@example.com",
                password_hash=pwd_hasher.get_password_hash("my_secret_password")
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        
        # 2. 检查冰箱里有没有西瓜
        watermelon = db.query(FridgeItem).filter(FridgeItem.name == "西瓜", FridgeItem.user_id == user.id).first()
        if not watermelon:
            print("正在往冰箱里放西瓜...")
            watermelon = FridgeItem(
                user_id=user.id,
                name="西瓜",
                category="水果",
                quantity=1.0,
                unit="个",
                expiration_date=datetime.now() + timedelta(days=7) # 7天后过期
            )
            db.add(watermelon)
            db.commit()

        print("✅ 数据初始化成功！现在你可以直接去登录了。")

    except Exception as e:
        print(f"❌ 初始化失败: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()