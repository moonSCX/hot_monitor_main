# ===== 构建阶段 =====
FROM node:22-slim AS build

WORKDIR /app

# 安装 openssl（Prisma 引擎检测与运行所需）
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*

# 客户端依赖（利用层缓存）
COPY client/package.json client/package-lock.json ./client/
RUN cd client && npm ci

# 客户端源码 + 构建
COPY client/ ./client/
RUN cd client && npm run build

# 服务端依赖（利用层缓存）
COPY server/package.json server/package-lock.json ./server/
RUN cd server && npm ci

# 服务端源码 + 构建
COPY server/ ./server/
# prisma generate 需要 DATABASE_URL（.env 不会进入镜像，故在构建阶段显式提供）
ENV DATABASE_URL="file:./dev.db"
RUN cd server && npx prisma generate && npm run build

# ===== 运行阶段 =====
FROM node:22-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production

# 安装 openssl（Prisma 查询引擎依赖）
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*

# 仅拷贝运行所需文件（不包含源码与 .env）
COPY --from=build /app/server/package.json /app/server/package-lock.json ./server/
COPY --from=build /app/server/node_modules ./server/node_modules
COPY --from=build /app/server/dist ./server/dist
COPY --from=build /app/server/prisma ./server/prisma
COPY --from=build /app/server/prisma.config.ts ./server/prisma.config.ts
COPY --from=build /app/client/dist ./client/dist

WORKDIR /app/server
EXPOSE 3001

# 启动时自动应用数据库迁移（SQLite 数据文件在免费档为临时存储，重启后重建）
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
