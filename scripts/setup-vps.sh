#!/bin/bash
# VLESS + Reality 一键部署脚本
# 适用于 Debian 12 / Ubuntu 22.04+
# 使用方法：bash setup-vps.sh

set -e

# ========== 颜色定义 ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ========== 参数配置 ==========
PANEL_PORT=""        # 3X-UI 面板端口，留空则自动随机
PANEL_PATH=""        # 面板路径，留空则自动随机
PROXY_PORT=443       # VLESS 代理端口
SNI="www.amazon.com" # Reality 伪装域名
DEST="www.amazon.com:443"

# ========== 交互式收集参数 ==========
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  VLESS + Reality 一键部署脚本${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

read -p "请输入 3X-UI 面板端口（直接回车随机生成）: " PANEL_PORT
if [ -z "$PANEL_PORT" ]; then
    PANEL_PORT=$(shuf -i 10000-60000 -n 1)
fi

read -p "请输入面板登录路径（直接回车随机生成）: " PANEL_PATH
if [ -z "$PANEL_PATH" ]; then
    PANEL_PATH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi

read -p "请输入面板管理员用户名 [admin]: " PANEL_USER
PANEL_USER=${PANEL_USER:-admin}

read -sp "请输入面板管理员密码（直接回车随机生成）: " PANEL_PASS
echo ""
if [ -z "$PANEL_PASS" ]; then
    PANEL_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
fi

read -p "请输入代理端口 [443]: " PROXY_PORT
PROXY_PORT=${PROXY_PORT:-443}

echo ""
info "配置确认："
info "  面板端口: $PANEL_PORT"
info "  面板路径: /$PANEL_PATH"
info "  管理员: $PANEL_USER / $PANEL_PASS"
info "  代理端口: $PROXY_PORT"
echo ""
read -p "确认以上配置？[Y/n] " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
    error "用户取消"
fi

# ========== 1. 系统更新 ==========
info "正在更新系统..."
apt update && apt upgrade -y

# ========== 2. 安装依赖 ==========
info "正在安装依赖..."
apt install -y curl wget unzip ufw socat

# ========== 3. 安装 3X-UI ==========
info "正在安装 3X-UI 面板..."
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) <<EOF
y
$PANEL_PORT
$PANEL_USER
$PANEL_PASS
EOF

# ========== 4. 配置面板路径 ==========
info "正在配置面板路径..."
/usr/local/x-ui/x-ui setting -webBasePath "/$PANEL_PATH"
x-ui restart

# ========== 5. 关闭面板 SSL（避免证书问题）==========
info "关闭面板 SSL（使用 HTTP 访问）..."
/usr/local/x-ui/x-ui setting -webCertPath "" -webKeyPath ""
x-ui restart

# ========== 6. 配置防火墙 ==========
info "正在配置 UFW 防火墙..."
ufw allow 22/tcp
ufw allow "$PANEL_PORT"/tcp
ufw allow "$PROXY_PORT"/tcp
ufw --force enable

# ========== 7. 生成 Reality 密钥对 ==========
info "正在生成 Reality 密钥对..."
# 安装 xray 用于生成密钥
XRAY_BIN="/usr/local/x-ui/bin/xray-linux-amd64"
if [ ! -f "$XRAY_BIN" ]; then
    XRAY_BIN=$(which xray 2>/dev/null || echo "")
fi

if [ -n "$XRAY_BIN" ] && [ -f "$XRAY_BIN" ]; then
    KEY_OUTPUT=$("$XRAY_BIN" x25519 2>/dev/null || echo "")
    PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public" | awk '{print $3}')
else
    warn "未找到 xray 二进制，使用 API 生成密钥对..."
    KEY_OUTPUT=$(curl -s https://api.x25519.org/ 2>/dev/null || echo "")
    PRIVATE_KEY=$(echo "$KEY_OUTPUT" | jq -r '.private_key' 2>/dev/null || echo "")
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | jq -r '.public_key' 2>/dev/null || echo "")
fi

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    error "无法生成 Reality 密钥对，请手动在 3X-UI 面板中生成"
fi

SHORT_ID=$(openssl rand -hex 4)
UUID=$(cat /proc/sys/kernel/random/uuid)

info "密钥信息："
info "  UUID: $UUID"
info "  Private Key: $PRIVATE_KEY"
info "  Public Key: $PUBLIC_KEY"
info "  Short ID: $SHORT_ID"

# ========== 8. 通过 API 添加 VLESS 入站 ==========
info "正在通过 API 添加 VLESS+Reality 入站..."

PANEL_URL="http://127.0.0.1:$PANEL_PATH"
LOGIN_RESP=$(curl -s -c /tmp/xui_cookie -X POST "http://127.0.0.1:$PANEL_PORT/$PANEL_PATH/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$PANEL_USER&password=$PANEL_PASS")

if echo "$LOGIN_RESP" | grep -q '"success":true'; then
    info "面板登录成功"
else
    warn "面板 API 登录失败，请手动在面板中添加入站"
fi

INBOUND_JSON=$(cat <<EOJSON
{
    "enable": true,
    "tag": "vless-reality",
    "listen": "",
    "port": $PROXY_PORT,
    "protocol": "vless",
    "settings": {
        "clients": [
            {
                "id": "$UUID",
                "flow": "",
                "email": "user1@biz"
            }
        ],
        "decryption": "none",
        "fallbacks": []
    },
    "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
            "show": false,
            "dest": "$DEST",
            "xver": 0,
            "acceptProxyProtocol": false,
            "privateKey": "$PRIVATE_KEY",
            "shortIds": ["$SHORT_ID"]
        },
        "tcpSettings": {
            "acceptProxyProtocol": false,
            "header": {
                "type": "none"
            }
        }
    },
    "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
    }
}
EOJSON
)

ADD_RESP=$(curl -s -b /tmp/xui_cookie -X POST "http://127.0.0.1:$PANEL_PORT/$PANEL_PATH/panel/inbound/add" \
    -H "Content-Type: application/json" \
    -d "$INBOUND_JSON")

if echo "$ADD_RESP" | grep -q '"success":true'; then
    info "VLESS+Reality 入站添加成功"
else
    warn "API 添加入站失败，请手动在面板中操作"
fi

rm -f /tmp/xui_cookie

# ========== 9. 获取服务器 IP ==========
SERVER_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

# ========== 10. 生成连接信息 ==========
VLESS_LINK="vless://${UUID}@${SERVER_IP}:${PROXY_PORT}/?type=tcp&encryption=none&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=${SNI}&sid=${SHORT_ID}&spx=%2F#amazon-biz"

CLASH_YAML=$(cat <<EOYAML
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
dns:
  enable: true
  enhanced-mode: fake-ip
  nameserver:
    - 223.5.5.5
    - 119.29.29.29
  fallback:
    - 8.8.8.8
    - 1.1.1.1

proxies:
  - name: amazon-biz
    type: vless
    server: ${SERVER_IP}
    port: ${PROXY_PORT}
    uuid: ${UUID}
    network: tcp
    tls: true
    udp: true
    servername: ${SNI}
    reality-opts:
      public-key: ${PUBLIC_KEY}
      short-id: ${SHORT_ID}
    client-fingerprint: chrome

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - amazon-biz
      - DIRECT

rules:
  - GEOIP,CN,DIRECT
  - MATCH,Proxy
EOYAML
)

# ========== 11. 输出结果 ==========
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  部署完成！${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}【3X-UI 管理面板】${NC}"
echo "  地址: http://${SERVER_IP}:${PANEL_PORT}/${PANEL_PATH}"
echo "  用户: ${PANEL_USER}"
echo "  密码: ${PANEL_PASS}"
echo ""
echo -e "${YELLOW}【VLESS 连接链接】${NC}"
echo "  ${VLESS_LINK}"
echo ""
echo -e "${YELLOW}【Clash Verge Rev 配置】${NC}"
echo "  保存以下内容为 .yaml 文件后导入 Clash Verge Rev："
echo ""
echo "$CLASH_YAML"
echo ""
echo -e "${YELLOW}【iPhone 连接】${NC}"
echo "  1. App Store 下载 Streisand"
echo "  2. 复制上面的 VLESS 连接链接"
echo "  3. 在 Streisand 中「从剪贴板导入」"
echo ""
echo -e "${YELLOW}【防火墙已开放端口】${NC}"
echo "  SSH: 22 | 面板: ${PANEL_PORT} | 代理: ${PROXY_PORT}"
echo ""
echo -e "${CYAN}========================================${NC}"

# 保存配置到文件
CONFIG_DIR="/root/vpn-config"
mkdir -p "$CONFIG_DIR"
echo "$VLESS_LINK" > "$CONFIG_DIR/vless-link.txt"
echo "$CLASH_YAML" > "$CONFIG_DIR/clash-config.yaml"
cat > "$CONFIG_DIR/panel-info.txt" <<EOF
面板地址: http://${SERVER_IP}:${PANEL_PORT}/${PANEL_PATH}
用户: ${PANEL_USER}
密码: ${PANEL_PASS}
UUID: ${UUID}
Public Key: ${PUBLIC_KEY}
Private Key: ${PRIVATE_KEY}
Short ID: ${SHORT_ID}
代理端口: ${PROXY_PORT}
EOF

info "配置已保存到 ${CONFIG_DIR}/ 目录"
info "部署完成！"
