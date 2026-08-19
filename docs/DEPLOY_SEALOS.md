# 部署到 Sealos（免费，无需国外银行卡）

本项目使用 **Docker 单服务同源部署**（后端 Express + Socket.io 直接托管前端 React 构建产物）。

- 平台：[Sealos](https://cloud.sealos.run)（国内团队，中文界面，**邮箱即可注册，无需信用卡**，升级可用支付宝/微信）
- 镜像托管：GitHub Container Registry（`ghcr.io`，复用你的 GitHub 账号）
- 特性：支持 WebSocket、自动 https 证书、**持久卷（SQLite 数据不丢）**

---

## 一、推送镜像到 GitHub Container Registry（约 5 分钟）

我们的 `Dockerfile` 已经在本地构建验证通过（`hot-monitor:test`），只需把它推到 GHCR。

### 1. 创建 GitHub 个人访问令牌（PAT）

1. 打开 https://github.com/settings/tokens → **Generate new token**（classic 或 fine-grained 均可）
2. 勾选权限：
   - classic 令牌：勾选 **`write:packages`**（会自动带上 `read:packages`）
   - fine-grained：仓库选 `hot_monitor_main`，权限里勾选 **Packages: Read and write**
3. 生成后**复制令牌**（只显示一次）

### 2. 登录 ghcr.io（请在自己的终端里执行，令牌不要发到聊天里）

打开一个本地 PowerShell 窗口，执行：

```powershell
docker login ghcr.io -u moonscx
```

提示 `Password:` 时粘贴刚才的 PAT（粘贴后不显示，直接回车）。

### 3. 推送镜像（告诉我"登录好了"，我来执行）

我会执行（凭据已缓存，无需你再操作）：

```bash
docker tag hot-monitor:test ghcr.io/moonscx/hot_monitor_main:latest
docker push ghcr.io/moonscx/hot_monitor_main:latest
```

### 4. 把包设为公开（否则 Sealos 拉不到）

1. 打开 https://github.com/moonscx/hot_monitor_main → 右侧 **Packages** → 点击 `hot_monitor_main`
2. 右侧 **Package settings** → **Danger Zone** → **Change visibility** → 选 **Public** → 确认

---

## 二、在 Sealos 上部署（约 5 分钟）

### 1. 注册登录

打开 https://cloud.sealos.run → 邮箱注册/登录（也可用手机号）。新用户有免费额度。

### 2. 创建应用

1. 左侧菜单点 **应用管理（Launchpad）** → **创建应用**
2. 填写：
   - **应用名称**：`hot-monitor`
   - **镜像名称**：`ghcr.io/moonscx/hot_monitor_main:latest`
   - **实例数**：1（固定）
   - **计算资源**：建议 CPU 0.5 / 内存 512Mi 起步（免费额度内）
3. **网络配置**：
   - 容器端口：`3001`
   - 对外协议：**https**（socket.io 会通过 https 自动升级 WebSocket；若实时推送异常可改 `wss` 重试）
4. **高级配置**：
   - **环境变量**（逐个添加）：

     | 变量 | 值 | 说明 |
     | --- | --- | --- |
     | `PORT` | `3001` | 容器监听端口 |
     | `DATABASE_URL` | `file:/data/dev.db` | 指向持久卷，数据不丢 |
     | `OPENROUTER_API_KEY` | 你的 `sk-or-v1-...` | AI 分析（必填） |
     | `TWITTER_API_KEY` | （可选） | Twitter 数据源 |
     | `SMTP_HOST` / `SMTP_PORT` / `SMTP_SECURE` / `SMTP_USER` / `SMTP_PASS` / `NOTIFY_EMAIL` | （可选） | 邮件通知 |
     | `CLIENT_URL` | 留空 | 同源部署不需要 |

   - **存储容量（持久卷）**：开启，容量 1Gi，**挂载路径填 `/data`**（SQLite 数据库就存在这里，重启不丢）

5. 点击 **部署**，等待镜像拉取 + 容器启动（首次 1~3 分钟）。

### 3. 访问

部署成功后，应用详情页会给出公网地址（形如 `https://hot-monitor-xxxx.cloud.sealos.io`），打开即用。

---

## 三、免费额度说明

- 新用户注册即送免费额度（金额制，如 $5/月级别），本应用按 CPU/内存/存储/流量计费，轻量配置下消耗很小。
- 免费额度耗尽前，在「费用中心」可查看用量；如需长期稳定运行可考虑小额充值（支持支付宝/微信）。
- 相比 Render 免费档的优势：**数据持久化（SQLite 在持久卷里，重启/更新不丢）**，且国内访问快。

## 四、如何更新

1. 本地：`docker build -t hot-monitor:test .`（或改完代码后构建）
2. `docker tag hot-monitor:test ghcr.io/moonscx/hot_monitor_main:latest && docker push ...`
3. Sealos 应用详情页 → **重新部署/更新镜像**（或把标签改为新版本号再改镜像地址）

## 五、安全提示

- API Key 只通过 Sealos 环境变量配置，**不会写入代码/镜像/仓库**（`.dockerignore` 已排除 `.env`）。
- GitHub PAT 不要发到聊天里；如泄露请在 GitHub 设置中吊销重建。
- 你的 OpenRouter Key 曾在聊天中出现，建议到 [OpenRouter Keys](https://openrouter.ai/settings/keys) 重置后，更新 Sealos 环境变量与本地 `server/.env`。

## 六、本地对照

```bash
# 本地直接跑（同源模式，模拟线上）
cd client && npm run build
cd ../server && npm run build && npm start   # http://localhost:3001

# 数据库（本地）
cd server && npx prisma db push && npx prisma generate
```
