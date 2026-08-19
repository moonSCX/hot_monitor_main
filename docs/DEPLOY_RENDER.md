# 部署到 Render（免费档）

本项目的部署方式为 **Docker 单服务同源部署**：后端（Express + Socket.io）直接托管前端（React）构建产物，一个服务搞定全部功能，无需单独部署前端。

- 部署平台：Render（免费档，无需信用卡）
- 服务地址：`https://hot-monitor.onrender.com`（创建后以实际为准）
- 自动部署：每次 push 到 GitHub `main` 分支自动重新构建

---

## 一、准备工作（一次性的）

1. 注册/登录 [Render](https://render.com)（推荐直接用 GitHub 账号登录，无需信用卡）。
2. 确认你的 GitHub 仓库 `moonSCX/hot_monitor_main` 已包含以下文件（已就绪）：
   - `Dockerfile` — 多阶段构建（前端 + 后端）
   - `render.yaml` — Render 蓝图（服务配置 + 环境变量）
   - `server/prisma/migrations/` — 数据库迁移文件

## 二、创建服务（约 5 分钟）

1. 登录 Render 控制台，点击 **New +** → **Blueprint**。
2. 在弹出窗口中选择 GitHub 仓库 **hot_monitor_main**（首次需授权 Render 访问你的 GitHub）。
3. Render 读取 `render.yaml`，自动生成名为 `hot-monitor` 的 Web Service 草稿。
4. 点击 **Apply** 前/后，在 **Environment / 环境变量** 中填写以下密钥（`sync: false` 的变量值不来自仓库，需要手动填）：

   | 变量 | 必填 | 说明 |
   | --- | --- | --- |
   | `OPENROUTER_API_KEY` | ✅ | AI 真假识别/相关性分析/摘要（你的 `sk-or-v1-...` key） |
   | `TWITTER_API_KEY` | 可选 | Twitter 数据源（twitterapi.io），没有则跳过该源 |
   | `SMTP_HOST` / `SMTP_PORT` / `SMTP_SECURE` / `SMTP_USER` / `SMTP_PASS` / `NOTIFY_EMAIL` | 可选 | 邮件通知（QQ 邮箱授权码等） |
   | `CLIENT_URL` | 可选 | 同源部署下可留空；留空不影响 WebSocket |

5. 点击 **Apply** 创建服务，等待构建完成（约 3~5 分钟）。
6. 构建成功后，打开 `https://hot-monitor.onrender.com` 即可使用。

> 健康检查已配置为 `/api/health`，Render 会自动检测服务可用性。

## 三、免费档注意事项（重要）

1. **休眠与冷启动**：免费实例闲置约 15 分钟会自动休眠，下次访问需要 30~60 秒冷启动，属正常现象。
2. **数据会重置**：免费档**没有持久磁盘**，SQLite 数据库（`dev.db`）存在临时存储中。服务每次重启/重新部署后，关键词、热点数据会清空（启动时会自动执行 `prisma migrate deploy` 重建表结构）。仅用于演示/学习没问题。
3. **每月时长**：免费档每月 750 小时，单个服务 24×7 运行约 744 小时，够用。
4. **区域**：免费档仅支持部分区域（默认美国 Oregon），国内访问延迟一般，属正常。

## 四、后续更新

代码有改动后，直接 `git push origin main`，Render 会自动重新构建部署。

## 五、安全提示

- `OPENROUTER_API_KEY` 只在 Render 面板环境变量中配置，**绝不会出现在代码或仓库中**（`server/.env` 已被 `.gitignore` 排除，`.dockerignore` 也排除了 `.env`）。
- 如果你的 API Key 曾在聊天记录等非安全渠道出现过，建议到 [OpenRouter Keys](https://openrouter.ai/settings/keys) 页面**重置/吊销**该 key 并重新生成，然后更新 Render 环境变量。

## 六、本地运行对照

```bash
# 数据库
cd server && npx prisma db push && npx prisma generate

# 后端（端口 3001）
cd server && npm run dev

# 前端（端口 5173，开发模式走 Vite）
cd client && npm install && npm run dev
```

生产模式同源运行（模拟线上）：

```bash
cd client && npm run build
cd server && npm run build && npm start   # 打开 http://localhost:3001
```
