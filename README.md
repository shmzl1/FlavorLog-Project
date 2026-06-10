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

如果是已有数据库（历史数据卷未重建），请额外执行 `backend/database/migrations/` 目录中的字段补齐 SQL（例如 `20260528_add_expiration_date_to_fridge_items.sql`），避免表结构落后导致接口 500。

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

## 前端演示页面（当前）

当前 Flutter 端可直接演示以下页面流程（阶段一 Mock）：

- 登录 / 注册页面（Mock 提交与跳转）
- 首页仪表盘（今日摘要、统计卡片、功能入口、健康建议）
- 饮食记录入口
- 赛博冰箱入口
- 健康报告入口
- 社区动态 Mock 信息流（本地发布与点赞）
- 个人中心 Mock 页面（资料展示与退出登录）

说明：上述登录、社区与个人中心页面目前为前端本地 Mock 交互，尚未接入真实后端接口。

首页营养看板现已支持“真实数据优先”：

- 前端会优先读取当日饮食记录接口（`GET /api/v1/food-records/`）并实时汇总热量、碳水、蛋白质、脂肪进度；
- 首页会查询今日饮食记录并动态计算热量、碳水、蛋白质、脂肪进度；
- 依赖登录状态与饮食记录接口可用性；
- 后端不可用、请求失败或异常时会自动回退显示本地 mock 数据，保证演示可用；
- 接口成功但当日无记录时，会展示“今日 0 记录”的真实看板状态（不回退 mock）；
- 新增、删除、修改饮食记录成功后，会主动刷新首页营养看板。

智能周报现已接入真实饮食记录：

- 日均热量、日均蛋白质、热量走势、风险预警、改善建议均基于本周饮食记录实时计算；
- 周报后端会优先使用 `food_records` 主表 total 字段，并在历史数据 total 为 0 时兼容从 `food_record_items` 明细回退汇总。

## 健康报告联调说明（2026-05-28）

- 餐后反馈提交接口为：`POST /api/v1/health/feedbacks`。
- 提交餐后反馈成功后，前端会自动刷新：反馈列表、红黑榜单、智能周报。
- 红黑榜依赖饮食记录与餐后反馈联合计算；当数据不足时，保留演示 fallback 数据。

## 灵感社区联调说明（2026-05-31）

- 灵感社区已支持真实帖子优先加载，接口为 `GET /api/v1/community/posts`。
- 前端支持发布帖子、查看详情、点赞、转发 / Fork、评论、回复评论和评论点赞。
- 后端不可用、接口失败或暂无真实帖子时，前端会保留本地 mock 数据用于演示。
- 已有数据库需要执行 `backend/database/migrations/20260531_add_community_tables.sql` 补齐社区互动表。

## 个人中心与健康报告联调说明（2026-05-31）

- 个人中心统计已接入实时接口 `GET /api/v1/users/me/stats`。
- 打卡天数、记录饮食、获奖次数优先从后端查询；失败时保留本地 mock fallback。
- 健康报告提交餐后反馈成功后，会自动刷新反馈列表、红黑榜和智能周报。

## 个人中心偏好弹窗修复说明（2026-06-07）

- 个人中心“饮食偏好和过敏原”弹窗已修复输入框控制器生命周期问题。
- 弹窗输入框由独立组件管理，避免关闭弹窗或页面重建后出现 `TextEditingController was used after being disposed`。

## 登录注册页面说明（2026-06-02）

- 登录 / 注册页面已完成移动端视觉优化，采用白底、大留白、品牌标题、简洁表单与胶囊主按钮布局。
- 页面支持登录 / 注册模式切换，并保留真实后端鉴权逻辑。
- 登录 / 注册前需要勾选用户协议、隐私政策和个人信息保护规则。
- 《用户协议》《隐私政策》《个人信息保护规则》目前为前端静态文本，用于课程项目演示。
- 页面支持点击查看《用户协议》《隐私政策》《个人信息保护规则》。
- 本次仅调整前端 UI 与协议展示，不修改后端接口、登录注册接口路径、Token 保存逻辑或 AuthGate 跳转逻辑。

## 灵感社区 UI 修复说明（2026-06-02）

- 灵感社区帖子卡片已调整网格比例和封面高度，降低小屏幕下底部操作区 overflow 的风险。
- 底部发布入口由长文字按钮调整为简洁的圆形“+”按钮，减少遮挡并贴近移动端社区发布入口习惯。
- 发布灵感弹窗改为可滚动布局，并优化输入框样式，避免键盘弹出或字体缩放时出现文字串框。
- 本次仅修复前端 UI 展示问题，不修改社区接口、后端逻辑或 mock fallback 策略。
## 灵感社区列表与详情页 UI 调整说明（2026-06-02）

- 灵感社区列表卡片底部已调整为更简洁的移动端社区样式，仅保留头像、用户标识和点赞数量。
- 列表卡片爱心按钮继续调用真实点赞逻辑；真实帖子走后端接口，mock 帖子走本地演示更新，点赞数量会随状态变化。
- 社区帖子详情页已优化为帖子详情流布局，突出封面、作者信息、标题、正文、标签和底部互动区。
- 本次仅调整社区前端 UI 展示，不修改后端接口、数据库结构或社区业务逻辑。

## 灵感社区多图发帖说明（2026-06-07）

- 灵感社区基础版支持最多 6 张图片发帖。
- 发布帖子时可以从相册多选图片，也可以调用摄像头拍照并追加到已选图片列表。
- 发布前会展示已选图片预览，并支持删除单张图片。
- 图片会先上传到 `POST /api/v1/uploads/image`，上传场景 `scene=community_post`。
- 图片上传成功后，前端会把返回的图片 URL 列表写入社区帖子字段 `image_urls`。
- 新真实帖子初始点赞数、评论数、转发数均为 0。
- 新真实帖子支持打开详情、点赞 / 取消点赞、发表评论。
- 真实帖子的点赞和评论走后端接口；mock 帖子仍作为 fallback 和演示内容保留。
- 当前 `community_posts.image_urls` 已在后端模型和初始化 SQL 中存在，本次无需新增数据库迁移。
