
# FlavorLog 知味志

## 一、项目简介

FlavorLog（知味志）是一个面向日常饮食管理的 AI 多模态饮食管家系统。

本项目通过 Flutter 移动端 App 采集用户饮食数据，结合 FastAPI 后端、PostgreSQL 数据库、AI 多模态识别、个性化推荐算法和社区互动功能，实现饮食记录、健康分析、食谱推荐和社交分享等功能。

阶段一主要目标是完成 MVP 核心业务功能，并在局域网环境下完成前后端联调演示。

---

## 二、技术栈

### 前端

- Flutter
- Dart
- GetX
- Dio
- SQLite
- Camera / Microphone API

### 后端

- Python 3.11
- Miniconda / conda
- FastAPI
- Uvicorn
- SQLAlchemy
- Pydantic
- PostgreSQL

### AI 与算法

- OpenCV
- YOLOv8
- OCR
- LLM API
- Pandas
- Scikit-learn

### 数据库与部署

- PostgreSQL 16
- Docker Desktop
- Docker Compose

---

## 三、项目目录结构

```text
FlavorLog-Project/
│
├── README.md
├── .gitignore
├── .env.example
├── docker-compose.yml
│
├── docs/
│   ├── 项目规划.md
│   ├── 分工安排.md
│   ├── 接口文档.md
│   ├── 数据库设计.md
│   ├── 技术栈说明.md
│   ├── 环境配置说明.md
│   └── 演示说明.md
│
├── frontend/
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   ├── assets/
│   ├── lib/
│   └── test/
│
└── backend/
    ├── README.md
    ├── requirements.txt
    ├── main.py
    ├── .env.example
    ├── app/
    ├── database/
    ├── tests/
    └── uploads/
```

---

## 四、环境要求

请所有组员尽量保持以下开发环境一致：

| 工具           | 建议版本                   |
| -------------- | -------------------------- |
| Git            | 最新稳定版                 |
| VS Code        | 最新稳定版                 |
| Docker Desktop | 最新稳定版                 |
| Miniconda      | 最新稳定版                 |
| Python         | 3.11，由 conda 环境提供    |
| Flutter        | stable 版本                |
| PostgreSQL     | 16，由 Docker Compose 启动 |

---

## 五、项目初始化

### 1. 克隆项目

```bash
git clone https://github.com/shmzl1/FlavorLog-Project.git
cd FlavorLog-Project
```

### 2. 创建根目录环境变量文件

Windows PowerShell：

```powershell
copy .env.example .env
```

macOS / Linux：

```bash
cp .env.example .env
```

注意：

```text
.env 文件只保存在本地，不要提交到 GitHub。
```

---

## 六、启动 PostgreSQL

本项目使用 Docker Desktop + Docker Compose 启动 PostgreSQL。

启动前先打开 Docker Desktop，并确认 Docker Engine 正在运行。

在项目根目录执行：

```bash
docker compose up -d
```

查看容器是否启动成功：

```bash
docker ps
```

如果看到 `flavorlog-postgres`，说明数据库启动成功。

当前数据库连接信息：

```text
数据库名：flavorlog
用户名：flavorlog_user
密码：flavorlog_password
宿主机端口：5433
容器内端口：5432
```

本地后端连接字符串：

```text
postgresql+psycopg2://flavorlog_user:flavorlog_password@localhost:5433/flavorlog
```

停止数据库：

```bash
docker compose down
```

如果需要删除数据库数据卷并重新初始化数据库：

```bash
docker compose down -v
docker compose up -d
```

---

## 七、后端启动方式

本项目后端使用 Miniconda 创建 Python 环境。

进入后端目录：

```bash
cd backend
```

创建 conda 环境：

```bash
conda create -n flavorlog python=3.11 -y
```

激活 conda 环境：

```bash
conda activate flavorlog
```

安装依赖：

```bash
pip install -r requirements.txt
```

复制后端环境变量文件：

Windows PowerShell：

```powershell
copy .env.example .env
```

macOS / Linux：

```bash
cp .env.example .env
```

启动后端服务：

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

启动成功后访问接口文档：

```text
http://127.0.0.1:8000/docs
```

健康检查接口：

```text
http://127.0.0.1:8000/health
```

---

## 八、前端启动方式

进入前端目录：

```bash
cd frontend
```

安装依赖：

```bash
flutter pub get
```

检查 Flutter 环境：

```bash
flutter doctor
```

运行项目：

```bash
flutter run
```

如果需要在手机上访问后端接口，请确保手机和电脑处于同一局域网下，并将接口地址中的 `127.0.0.1` 改为后端电脑的局域网 IP 地址。

例如：

```text
http://192.168.1.100:8000/api/v1
```

---

## 九、Git 协作规范

### 1. 开发前先拉取最新代码

```bash
git pull
```

### 2. 查看当前修改

```bash
git status
```

### 3. 添加修改

```bash
git add .
```

### 4. 提交修改

```bash
git commit -m "类型: 修改说明"
```

### 5. 推送到 GitHub

```bash
git push
```

---

## 十、提交信息规范

提交信息建议使用以下格式：

```text
类型: 修改内容
```

常用类型：

| 类型     | 含义                 |
| -------- | -------------------- |
| feat     | 新功能               |
| fix      | 修复 bug             |
| docs     | 文档修改             |
| style    | 代码格式调整         |
| refactor | 代码重构             |
| test     | 测试相关             |
| chore    | 构建、依赖、配置修改 |

示例：

```text
feat: 完成用户登录接口
fix: 修复社区页面跳转错误
docs: 更新数据库设计文档
chore: 添加 PostgreSQL Docker 配置
```

---

## 十一、分支管理建议

阶段一可以采用简单分支策略：

```text
main        稳定主分支
frontend    前端开发分支
backend     后端开发分支
```

功能开发时，也可以基于任务创建个人功能分支：

```bash
git checkout -b feat/login-api
```

完成后提交 Pull Request，由组长检查后合并到 `main`。

---

## 十二、注意事项

1. 不要提交 `.env` 文件。
2. 不要提交数据库密码、API Key、Token 等敏感信息。
3. 不要提交 conda 环境目录。
4. 不要提交前端或后端生成的临时文件。
5. 不要直接上传大量图片、视频、音频测试文件。
6. 每次开发前先 `git pull`，避免代码冲突。
7. 修改公共配置文件前，先在群里说明。
8. YAML、Python、SQL、Markdown 文件必须保留正常换行和缩进，不能压成一整行。

---

## 十三、阶段一目标

阶段一主要完成以下内容：

- Flutter 移动端基础页面
- 用户登录注册
- 饮食记录功能
- 图片 / 视频 / 音频上传
- 赛博冰箱基础功能
- 健康数据展示
- 社区动态与互动
- FastAPI 后端接口
- PostgreSQL 数据库设计
- AI 多模态识别基础流程
- LLM 食谱推荐基础流程
- Mock 演示数据构建
- 局域网环境下前后端完整联调

---

## 十四、项目文档

具体文档见 `docs/` 目录：

```text
docs/项目规划.md
docs/分工安排.md
docs/接口文档.md
docs/数据库设计.md
docs/技术栈说明.md
docs/环境配置说明.md
docs/演示说明.md
```
