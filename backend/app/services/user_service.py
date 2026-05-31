# backend/app/services/user_service.py

from datetime import date, datetime, time, timedelta

from sqlalchemy import Date, cast, func
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.food_record import FoodRecord
from app.schemas.user import UserCreate, UserUpdate
from app.core.security import pwd_hasher

class UserService:
    """
    用户领域核心业务逻辑类。

    作用：
    作为 Controller (API 路由) 和 Repository (数据库模型) 之间的桥梁。
    封装了所有与用户紧密相关的复杂业务操作（如创建用户、查询用户）。
    将这层逻辑剥离出来，不仅让 API 路由层变得非常薄，也极大方便了后续编写针对核心逻辑的单元测试。
    """

    @staticmethod
    def get_user_by_email(db: Session, email: str) -> User | None:
        """
        根据邮箱精准查询用户。

        作用：
        这是一个非常高频的读取操作，通常用于注册前的唯一性冲突检查，
        或者登录时的账号查找。

        Args:
            db (Session): SQLAlchemy 的数据库会话实例。
            email (str): 待查询的用户邮箱。

        Returns:
            User | None: 如果查到则返回 User 的 ORM 对象，否则返回 None。
        """
        return db.query(User).filter(User.email == email).first()

    @staticmethod
    def get_user_by_username(db: Session, username: str) -> User | None:
        """根据用户名查询用户。"""
        return db.query(User).filter(User.username == username).first()

    @staticmethod
    def get_user_by_phone(db: Session, phone: str) -> User | None:
        """根据手机号查询用户。"""
        return db.query(User).filter(User.phone == phone).first()

    @staticmethod
    def get_user_by_account(db: Session, account: str) -> User | None:
        """支持使用邮箱、用户名或手机号查找用户。"""
        import re
        if re.match(r'^1[3-9]\d{9}$', account):
            return UserService.get_user_by_phone(db, phone=account)
        if "@" in account:
            return UserService.get_user_by_email(db, email=account)
        return UserService.get_user_by_username(db, username=account)

    @staticmethod
    def create_user(db: Session, user_in: UserCreate) -> User:
        """
        执行用户注册的核心创建逻辑。

        作用：
        接收经过 Pydantic 校验的注册请求体，剥离出明文密码进行单向哈希加密。
        随后构建 User ORM 对象，将其挂载到当前数据库事务中，并提交落盘。

        内部流程：
        1. 读取明文密码 -> 2. 生成密文 -> 3. 创建 ORM 对象 -> 4. 提交事务 -> 5. 刷新返回结果

        Args:
            db (Session): 负责控制数据库事务的会话实例。
            user_in (UserCreate): 包含合法注册信息（username, email, password 等）的 Pydantic 模型。

        Returns:
            User: 已经成功写入数据库，并带有最新主键 ID 的用户 ORM 对象。
        """
        # 1. 提取并加密密码
        hashed_pwd = pwd_hasher.get_password_hash(user_in.password)
        
        # 2. 构建数据库 ORM 对象 (注意这里丢弃了原始的明文 password)
        # 手机号注册时 email 字段用占位格式，保证唯一性约束不破坏
        email = user_in.email or f"{user_in.phone}@phone.flavorlog.app"
        db_user = User(
            username=user_in.username,
            email=email,
            phone=user_in.phone,
            password_hash=hashed_pwd,
            nickname=user_in.nickname,
            diet_preference=[],
            allergens=[],
            profile_json={},
        )
        
        # 3. 将对象添加到当前会话
        db.add(db_user)
        
        # 4. 提交事务，真正将数据写入 PostgreSQL
        db.commit()
        
        # 5. 刷新对象，确保 db_user 获取到数据库自动生成的 id 和 created_at 等字段
        db.refresh(db_user)
        
        return db_user
    
    @staticmethod
    def authenticate_user(db: Session, email: str, password: str) -> User | None:
        """
        验证用户登录。
        1. 先根据邮箱找到用户。
        2. 如果用户存在，再验证明文密码与数据库里的密文是否匹配。
        """
        user = UserService.get_user_by_email(db, email=email)
        if not user:
            return None
        
        # 使用我们之前在 security.py 写的 verify_password 方法比对哈希
        if not pwd_hasher.verify_password(password, user.password_hash):
            return None
            
        return user

    @staticmethod
    def authenticate_account(db: Session, account: str, password: str) -> User | None:
        """支持使用邮箱或用户名登录。"""
        user = UserService.get_user_by_account(db, account=account)
        if not user:
            return None
        if not pwd_hasher.verify_password(password, user.password_hash):
            return None
        return user
    
    @staticmethod
    def update_user(db: Session, db_user: User, obj_in: UserUpdate) -> User:
        """
        更新用户信息。
        """
        # 将 Pydantic 对象转为字典，排除未设置的字段
        update_data = obj_in.model_dump(exclude_unset=True)
        
        for field in update_data:
            setattr(db_user, field, update_data[field])
            
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user

    @staticmethod
    def get_user_stats(db: Session, user_id: int) -> dict:
        food_record_count = (
            db.query(func.count(FoodRecord.id))
            .filter(FoodRecord.user_id == user_id)
            .scalar()
            or 0
        )

        record_days = (
            db.query(cast(FoodRecord.record_time, Date))
            .filter(FoodRecord.user_id == user_id)
            .distinct()
            .all()
        )
        day_set = {row[0] for row in record_days if row and row[0]}
        checkin_days = len(day_set)

        today = date.today()
        week_start = today - timedelta(days=today.weekday())
        week_start_dt = datetime.combine(week_start, time.min)
        week_end_dt = datetime.combine(week_start + timedelta(days=6), time.max)
        weekly_record_count = (
            db.query(func.count(FoodRecord.id))
            .filter(
                FoodRecord.user_id == user_id,
                FoodRecord.record_time >= week_start_dt,
                FoodRecord.record_time <= week_end_dt,
            )
            .scalar()
            or 0
        )

        # Streak rule:
        # If today has no record, start counting from yesterday, so
        # the streak does not drop to 0 only because the user has not logged today's meal yet.
        streak_days = 0
        if day_set:
            cursor = today if today in day_set else today - timedelta(days=1)
            while cursor in day_set:
                streak_days += 1
                cursor -= timedelta(days=1)

        return {
            "checkin_days": checkin_days,
            "food_record_count": int(food_record_count),
            "award_count": 0,
            "weekly_record_count": int(weekly_record_count),
            "streak_days": streak_days,
        }
