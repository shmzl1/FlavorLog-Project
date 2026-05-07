# FlavorLog Backend

## 一、后端说明

本目录为 FlavorLog 项目的后端部分，主要负责：

- 用户登录注册
- 饮食记录管理
- 赛博冰箱数据管理
- 健康反馈与健康报告
- 社区动态、评论、点赞
- 图片 / 视频 / 音频上传
- PostgreSQL 数据库连接
- AI 多模态识别流程
- LLM 食谱推荐流程
- Mock 演示数据生成

后端采用 FastAPI 框架开发，数据库使用 PostgreSQL。

---

## 二、后端目录结构

```text
backend/
│
├── README.md               # 本文档
├── requirements.txt        # 依赖包列表
├── main.py                 # 🚀 FastAPI 应用入口文件 (包含全局配置与运行脚本)
├── .env                    # ⚠️ 本地环境变量 (千万不要提交到 Git!)
├── .env.example            # 环境变量模板
├── alembic.ini             # Alembic 迁移工具配置文件
│
├── alembic/                # 数据库迁移版本控制目录
│   ├── env.py              # 迁移环境配置 (已导入所有 Models)
│   └── versions/           # 自动生成的数据库变更脚本存放处
│
├── app/                    # 核心业务逻辑代码
│   ├── api/                # Controller 层：API 路由与接口
│   │   ├── deps.py         # 🛡️ 全局依赖 (数据库 Session, Token 保安等)
│   │   ├── router.py       # API 总路由挂载点
│   │   └── v1/             # V1 版本业务接口
│   │       └── users.py    # 用户注册、登录与个人信息接口
│   │
│   ├── core/               # 核心配置与工具
│   │   ├── config.py       # 全局环境变量映射类 (Pydantic Settings)
│   │   └── security.py     # 密码哈希与 JWT 签发工具类
│   │
│   ├── db/                 # 数据库底层交互
│   │   ├── base.py         # SQLAlchemy 声明基类 (Base)
│   │   └── session.py      # 数据库连接池与会话管理器
│   │
│   ├── models/             # ORM 数据库实体模型
│   │   ├── ai_task.py      # AI 异步任务与日志
│   │   ├── community.py    # 社区帖子、点赞、评论
│   │   ├── food_record.py  # 饮食主记录与食物明细
│   │   ├── fridge_item.py  # 赛博冰箱食材库
│   │   ├── health.py       # 餐后健康反馈
│   │   ├── taste.py        # 用户口味向量
│   │   ├── upload.py       # 统一上传资产管理
│   │   └── user.py         # 用户表
│   │
│   ├── schemas/            # Pydantic 数据契约层 (DTO/VO)
│   │   ├── token.py        # Token 响应格式
│   │   └── user.py         # 用户请求与响应格式
│   │
│   └── services/           # Service 层：核心业务逻辑
│       └── user_service.py # 用户模块的具体数据库操作逻辑
│
└── uploads/                # 本地上传文件暂存区
    ├── images/
    ├── videos/
    └── audios/
```

---

## 三、环境要求

建议所有后端成员使用以下环境：


| 工具           | 建议版本   |
| ---------------- | ------------ |
| Python         | 3.11       |
| PostgreSQL     | 16         |
| Docker Desktop | 最新稳定版 |
| VSCode         | 最新稳定版 |

---

## 四、首次启动步骤

### 1. 进入后端目录

```powershell
cd D:\homework\se\project\FlavorLog\backend
```

如果是从项目根目录进入：

```powershell
cd backend
```

---

### 2. 创建 Python 虚拟环境

```powershell
python -m venv .venv
```

---

### 3. 激活虚拟环境

Windows PowerShell：

```powershell
.venv\Scripts\activate
```

如果激活成功，命令行前面会出现类似：

```text
(.venv)
```

---

### 4. 安装依赖

```powershell
pip install -r requirements.txt
```

---

### 5. 创建后端环境变量文件

```powershell
copy .env.example .env
```

注意：

```text
.env 文件只保存在本地，不要提交到 GitHub。
```

---

### 6. 启动 PostgreSQL

PostgreSQL 由项目根目录下的 `docker-compose.yml` 统一启动。

先回到项目根目录：

```powershell
cd D:\homework\se\project\FlavorLog
```

启动数据库：

```powershell
docker compose up -d
```

查看容器是否启动成功：

```powershell
docker ps
```

如果看到 `flavorlog_postgres`，说明 PostgreSQL 已启动。

---

### 7. 启动后端服务

进入后端目录：

```powershell
cd backend
```

启动 FastAPI：

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

启动成功后，访问：

```text
http://127.0.0.1:8000/docs
```

该地址为 FastAPI 自动生成的 Swagger 接口文档。

---

## 五、常用命令

### 启动数据库

在项目根目录执行：

```powershell
docker compose up -d
```

### 停止数据库

```powershell
docker compose down
```

### 删除数据库数据并重新初始化

```powershell
docker compose down -v
docker compose up -d
```

### 启动后端

在 `backend/` 目录下执行：

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 查看后端依赖

```powershell
pip list
```

### 导出当前依赖

```powershell
pip freeze > requirements.txt
```

---

## 六、数据库连接说明

本地开发时，后端默认连接 Docker 中运行的 PostgreSQL。

默认数据库连接信息：

```text
数据库类型：PostgreSQL
主机地址：localhost
端口：5432
数据库名：flavorlog_db
用户名：flavorlog
密码：flavorlog123
```

对应连接字符串：

```text
postgresql://flavorlog:flavorlog123@localhost:5432/flavorlog_db
```

---

## 七、上传文件目录说明

后端上传文件统一存放在：

```text
backend/uploads/
```

其中：

```text
backend/uploads/images/    图片文件
backend/uploads/videos/    视频文件
backend/uploads/audios/    音频文件
```

注意：

```text
上传的真实图片、视频、音频文件不要提交到 GitHub。
```

仓库中只保留 `.gitkeep` 用于维持目录结构。

---

## 八、开发规范

### 1. API 路由

接口文件放在：

```text
app/api/v1/
```

例如：

```text
auth.py
users.py
food.py
fridge.py
health.py
community.py
recommendation.py
upload.py
```

---

### 2. 数据库模型

数据库模型放在：

```text
app/models/
```

---

### 3. 请求和响应结构

Pydantic Schema 放在：

```text
app/schemas/
```

---

### 4. 业务逻辑

业务逻辑放在：

```text
app/services/
```

---

### 5. 算法逻辑

AI 与算法代码放在：

```text
app/algorithms/
```

其中：

```text
vision/        视觉识别相关
multimodal/    多模态处理相关
ocr/           菜单 OCR 相关
llm/           大模型调用相关
apriori/       食物红黑榜相关
matching/      口味匹配相关
ranking/       推荐排序相关
```

---

### 6. Mock 数据脚本

演示数据生成脚本放在：

```text
app/scripts/
```

---

## 九、注意事项

1. 不要提交 `.env` 文件。
2. 不要提交真实 API Key。
3. 不要提交数据库密码、Token 等敏感信息。
4. 不要提交 `.venv/` 虚拟环境目录。
5. 不要提交真实上传的图片、视频、音频文件。
6. 修改公共配置文件前，先在群里说明。
7. 开发前先执行 `git pull`，避免冲突。
