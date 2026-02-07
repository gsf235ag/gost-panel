# Docker 部署快速参考

这个文档是 DOCKER.md 的精简版本，提供快速参考。完整文档请查看 [DOCKER.md](./DOCKER.md)。

## 一键部署

```bash
./scripts/docker-start.sh
```

## 手动部署

```bash
# 复制配置
cp .env.example .env

# 编辑配置（修改 JWT_SECRET）
vim .env

# 启动
docker compose up -d --build
```

## 访问

- 地址: http://localhost:8080
- 用户名: admin
- 密码: admin123

**请立即修改默认密码！**

## 常用命令

```bash
# 查看日志
docker compose logs -f

# 停止
docker compose down

# 重启
docker compose restart

# 查看状态
docker compose ps

# 进入容器
docker compose exec panel sh
```

## 使用 Makefile（可选）

```bash
# 查看所有命令
make -f Makefile.docker help

# 一键部署
make -f Makefile.docker docker-start

# 构建
make -f Makefile.docker docker-build

# 查看日志
make -f Makefile.docker docker-logs
```

## 配置文件

.env 配置示例：

```bash
# JWT 密钥（必须修改！）
JWT_SECRET=your-random-secret-here

# 监听端口
LISTEN_PORT=8080

# 调试模式
DEBUG=false
```

生成安全的 JWT_SECRET：

```bash
openssl rand -hex 32
```

## 目录结构

```
.
├── Dockerfile              # Docker 镜像定义
├── docker-compose.yml      # Docker Compose 配置
├── .dockerignore          # 构建忽略文件
├── .env                   # 环境配置（需创建）
├── .env.example           # 配置示例
├── data/                  # 数据目录（自动创建）
│   └── panel.db          # SQLite 数据库
└── scripts/
    └── docker-start.sh    # 一键部署脚本
```

## 故障排查

### 容器无法启动

```bash
# 查看日志
docker compose logs

# 检查端口
netstat -tuln | grep 8080
```

### 数据库问题

```bash
# 删除数据库重新初始化
rm -f data/panel.db*
docker compose restart
```

## 完整文档

详细配置、性能优化、生产部署等信息，请查看：
- [DOCKER.md](./DOCKER.md) - 完整 Docker 部署文档

## 技术特性

- 多阶段构建，镜像体积小（约 30MB）
- 内置健康检查
- 自动日志轮转
- 支持版本信息嵌入
- 数据持久化

## 环境要求

- Docker 20.10+
- Docker Compose 2.0+

## 安全建议

1. 修改默认密码
2. 使用强随机 JWT_SECRET
3. 配置防火墙
4. 生产环境使用 HTTPS
5. 定期备份数据库

## 生产部署

推荐配置：

```yaml
# docker-compose.prod.yml
services:
  panel:
    # ... 基础配置
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

使用生产配置：

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 更新

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker compose up -d --build
```

**更新前请备份数据库！**

```bash
cp data/panel.db data/panel.db.backup
```
