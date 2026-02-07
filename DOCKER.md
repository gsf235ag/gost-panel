# Docker 部署指南

## 快速开始

### 1. 一键部署（推荐）

```bash
# 运行部署脚本
./scripts/docker-start.sh
```

脚本会自动完成以下操作：
- 检查 Docker 环境
- 生成 `.env` 配置文件（如果不存在）
- 创建数据目录
- 构建 Docker 镜像
- 启动容器

### 2. 手动部署

```bash
# 1. 复制配置文件
cp .env.example .env

# 2. 编辑配置（修改 JWT_SECRET）
vim .env

# 3. 创建数据目录
mkdir -p data

# 4. 构建并启动
docker compose up -d --build
```

## 访问面板

部署完成后访问：
- 地址: `http://localhost:8080`（端口可在 .env 中修改）
- 用户名: `admin`
- 密码: `admin123`

**首次登录请立即修改默认密码！**

## 常用命令

### 容器管理

```bash
# 查看容器状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 停止容器
docker compose down

# 重启容器
docker compose restart

# 更新并重启
docker compose up -d --build
```

### 容器操作

```bash
# 进入容器
docker compose exec panel sh

# 查看版本
docker compose exec panel /app/gost-panel -version

# 查看帮助
docker compose exec panel /app/gost-panel -help
```

### 数据管理

```bash
# 备份数据库
cp data/panel.db data/panel.db.backup

# 查看数据库大小
du -sh data/panel.db

# 清理日志
docker compose logs --tail=0 -f > /dev/null
```

## 配置说明

### .env 配置文件

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `JWT_SECRET` | JWT 密钥，用于身份认证 | `change-me-in-production` |
| `LISTEN_PORT` | 宿主机监听端口 | `8080` |
| `ALLOWED_ORIGINS` | CORS 允许的来源（逗号分隔） | 空（允许所有） |
| `DEBUG` | 调试模式 | `false` |
| `VERSION` | 版本号（构建时自动设置） | `dev` |
| `BUILD_TIME` | 构建时间（构建时自动设置） | `unknown` |

### 生成安全的 JWT_SECRET

```bash
# 方法 1: 使用 openssl
openssl rand -hex 32

# 方法 2: 使用 /dev/urandom
head -c 32 /dev/urandom | xxd -p | tr -d '\n'
```

## 目录结构

```
.
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置
├── .dockerignore          # Docker 构建忽略文件
├── .env                   # 环境配置（需手动创建）
├── .env.example           # 配置示例
├── data/                  # 数据目录（自动创建）
│   └── panel.db          # SQLite 数据库
└── scripts/
    └── docker-start.sh    # 一键部署脚本
```

## 高级配置

### 自定义端口

编辑 `.env`:
```bash
LISTEN_PORT=9000
```

重启容器:
```bash
docker compose down
docker compose up -d
```

### 启用调试模式

编辑 `.env`:
```bash
DEBUG=true
```

重启并查看日志:
```bash
docker compose restart
docker compose logs -f
```

### CORS 配置

允许特定域名访问，编辑 `.env`:
```bash
ALLOWED_ORIGINS=http://localhost:3000,https://example.com
```

### 健康检查

Docker 镜像内置健康检查，检测 `/api/health` 端点。

查看健康状态:
```bash
docker compose ps
```

输出示例:
```
NAME          COMMAND                  SERVICE   STATUS                   PORTS
gost-panel    "/app/gost-panel -db…"   panel     Up 5 minutes (healthy)   0.0.0.0:8080->8080/tcp
```

## 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker compose logs

# 检查端口占用
netstat -tuln | grep 8080

# 检查磁盘空间
df -h
```

### 数据库初始化失败

```bash
# 删除损坏的数据库
rm -f data/panel.db*

# 重启容器（自动重新初始化）
docker compose restart
```

### 前端资源加载失败

确保前端已正确构建到镜像中:
```bash
# 进入容器检查
docker compose exec panel ls -la /app/web/dist
```

### 健康检查失败

```bash
# 手动测试健康检查
docker compose exec panel wget -O- http://localhost:8080/api/health

# 如果失败，检查应用日志
docker compose logs -f
```

## 性能优化

### 使用多阶段构建缓存

Docker 会自动缓存中间层，第二次构建会快很多。

清理缓存:
```bash
docker builder prune
```

### 限制日志大小

已在 `docker-compose.yml` 中配置:
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 设置资源限制

编辑 `docker-compose.yml`，添加:
```yaml
services:
  panel:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

## 生产环境建议

1. **安全**
   - 修改默认密码
   - 使用强随机 JWT_SECRET
   - 配置防火墙规则
   - 启用 HTTPS（使用 Nginx 反向代理）

2. **备份**
   - 定期备份 `data/panel.db`
   - 导出配置（面板内置导出功能）

3. **监控**
   - 配置健康检查告警
   - 监控容器资源使用

4. **更新**
   - 定期更新镜像
   - 更新前先备份数据

## 卸载

```bash
# 停止并删除容器
docker compose down

# 删除镜像
docker rmi gost-panel:latest

# 删除数据（谨慎操作！）
rm -rf data/
```

## 技术细节

### Dockerfile 说明

采用多阶段构建，包含三个阶段：

1. **frontend**: 使用 Node.js 构建前端
   - 基础镜像: `node:20-alpine`
   - 使用 `npm ci` 加速安装
   - 构建产物: `/app/web/dist`

2. **backend**: 使用 Go 构建后端
   - 基础镜像: `golang:1.23-alpine`
   - 安装 `gcc musl-dev sqlite-dev`（CGO 依赖）
   - 启用 CGO（SQLite 需要）
   - 嵌入版本信息（通过 ldflags）

3. **运行镜像**: 最小化运行环境
   - 基础镜像: `alpine:3.19`
   - 仅包含必要的运行时依赖
   - 镜像大小: ~30MB

### 构建参数

```bash
docker build \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILD_TIME="2026-02-07 12:00:00 UTC" \
  -t gost-panel:1.0.0 .
```

### 环境变量映射

| Docker 环境变量 | 命令行参数 | 说明 |
|----------------|-----------|------|
| `DB_PATH` | `-db` | 数据库路径 |
| `LISTEN_ADDR` | `-listen` | 监听地址 |
| `DEBUG` | `-debug` | 调试模式 |
| `JWT_SECRET` | 无 | JWT 密钥 |
| `ALLOWED_ORIGINS` | 无 | CORS 配置 |

## 常见问题

### Q: 如何更换数据库路径？

A: 修改 `docker-compose.yml` 中的 volumes 映射:
```yaml
volumes:
  - /path/to/your/data:/app/data
```

### Q: 如何使用外部数据库？

A: 当前版本仅支持 SQLite，暂不支持外部数据库。

### Q: 如何在宿主机访问数据库？

A: 使用 SQLite 客户端:
```bash
sqlite3 data/panel.db
```

### Q: 构建时提示 Node.js 版本过低？

A: Dockerfile 使用 Node.js 20，应该足够新。如果有问题，更新 Docker。

### Q: 如何查看构建时的版本信息？

A:
```bash
docker compose exec panel /app/gost-panel -version
```

## 联系支持

- GitHub: https://github.com/AliceNetworks/gost-panel
- Issues: https://github.com/AliceNetworks/gost-panel/issues
