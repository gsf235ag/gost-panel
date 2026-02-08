#!/bin/bash
# GOST Panel 安装脚本
# 从 GitHub Releases 下载并安装

set -e

REPO="AliceNetworks/gost-panel"
INSTALL_DIR="/opt/gost-panel"
SERVICE_NAME="gost-panel"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== GOST Panel Installer ===${NC}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

# 检测架构
ARCH=$(uname -m)
case $ARCH in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  armv7l)  ARCH="armv7" ;;
  *)
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    exit 1
    ;;
esac

echo -e "${YELLOW}Detected architecture: $ARCH${NC}"

# 获取最新版本
echo "Fetching latest version..."
LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
  echo -e "${YELLOW}No releases found, using default version v1.0.0${NC}"
  LATEST_VERSION="v1.0.0"
fi

echo -e "${GREEN}Latest version: $LATEST_VERSION${NC}"

# 下载地址
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_VERSION/gost-panel-linux-$ARCH.tar.gz"

# 创建安装目录
mkdir -p $INSTALL_DIR/data

# 停止已有服务
if command -v $INSTALL_DIR/gost-panel &>/dev/null; then
  $INSTALL_DIR/gost-panel service stop 2>/dev/null || true
fi

# 下载并解压
echo "Downloading from $DOWNLOAD_URL ..."
cd /tmp
curl -fsSL -o gost-panel.tar.gz "$DOWNLOAD_URL"

echo "Extracting..."
tar -xzf gost-panel.tar.gz
mv gost-panel-linux-$ARCH $INSTALL_DIR/gost-panel
chmod +x $INSTALL_DIR/gost-panel
rm -f gost-panel.tar.gz

# 生成 JWT Secret (如果环境变量文件不存在)
ENV_FILE="/etc/sysconfig/$SERVICE_NAME"
if [ ! -f "$ENV_FILE" ]; then
  JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p)
  mkdir -p /etc/sysconfig
  cat > "$ENV_FILE" << EOF
DB_PATH=$INSTALL_DIR/data/panel.db
LISTEN_ADDR=:8080
JWT_SECRET=$JWT_SECRET
EOF
  echo -e "${GREEN}Environment file created: $ENV_FILE${NC}"
else
  echo -e "${YELLOW}Environment file already exists, keeping current config${NC}"
fi

# 使用内置命令安装并启动服务
$INSTALL_DIR/gost-panel service install
$INSTALL_DIR/gost-panel service start

# 等待启动
sleep 2

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo -e "Panel URL: ${GREEN}http://$(hostname -I | awk '{print $1}'):8080${NC}"
echo -e "Default credentials: ${YELLOW}admin / admin123${NC}"
echo ""
echo "Commands:"
echo "  $INSTALL_DIR/gost-panel service status"
echo "  $INSTALL_DIR/gost-panel service restart"
echo "  $INSTALL_DIR/gost-panel service stop"
echo "  journalctl -u $SERVICE_NAME -f"
echo ""
echo "Config: $ENV_FILE"
echo ""
echo "Upgrade:"
echo "  curl -fsSL https://raw.githubusercontent.com/$REPO/main/scripts/install.sh | bash"
