#!/bin/bash
# Clash Meta (Mihomo) 一键部署脚本
# 用法: bash clash-setup.sh [--proxy http://host:port]
set -e

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLASH_DIR="$HOME/.config/clash"

# 从配置模板读取端口（部署前用模板，部署后用实际配置）
get_clash_port() {
    local config="${CLASH_DIR}/config.yaml"
    [ -f "$config" ] || config="${SKILL_DIR}/assets/clash-config.yaml"
    grep '^mixed-port:' "$config" 2>/dev/null | awk '{print $2}' || echo "7890"
}
CLASH_PORT=$(get_clash_port)

# 解析参数：允许用户手动指定代理
BOOTSTRAP_PROXY=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --proxy) BOOTSTRAP_PROXY="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# 自动检测网络状况
# 返回值通过全局变量: NETWORK_STATUS = "proxy" | "direct" | "blocked" | "dns_broken"
# 如果是 proxy，PROXY 会被设置
detect_network() {
    PROXY=""
    NETWORK_STATUS="blocked"

    # 用户手动指定的优先
    if [ -n "$BOOTSTRAP_PROXY" ]; then
        PROXY="$BOOTSTRAP_PROXY"
        NETWORK_STATUS="proxy"
        return
    fi
    # 检测 1: 本地端口（SSH -R 反向隧道 或 已有本地代理）
    for port in 7890 7897; do
        if curl -s --connect-timeout 2 --proxy "http://127.0.0.1:${port}" https://www.google.com > /dev/null 2>&1; then
            PROXY="http://127.0.0.1:${port}"
            NETWORK_STATUS="proxy"
            return
        fi
    done
    # 检测 2: 直连测试（TUN 模式 / 海外服务器）
    if curl -s --connect-timeout 10 https://www.google.com > /dev/null 2>&1; then
        NETWORK_STATUS="direct"
        return
    fi
    # 检测 3: DNS 诊断 — ping 能通但 curl 超时，说明 TUN 生效但 DNS 解析有问题
    if ping -c 1 -W 3 github.com > /dev/null 2>&1; then
        NETWORK_STATUS="dns_broken"
        return
    fi
}

echo "=== Clash Meta WSL/Ubuntu 一键部署 ==="
echo ""
echo "→ 检测网络环境..."

detect_network

case "$NETWORK_STATUS" in
    proxy)
        echo "✓ 检测到可用代理: $PROXY"
        export http_proxy="$PROXY"
        export https_proxy="$PROXY"
        ;;
    direct)
        echo "✓ 直连可用（TUN 模式 / 海外服务器）"
        ;;
    dns_broken)
        echo ""
        echo "✗ 检测到 TUN 模式已生效（ping 通），但 curl DNS 解析超时"
        echo ""
        echo "这通常是 WSL 的 /etc/resolv.conf 指向了内网 DNS 导致的。"
        echo "请执行以下命令修复："
        echo ""
        echo "  # 1. 禁止 WSL 自动生成 resolv.conf"
        echo "  sudo bash -c 'grep -q \"\\[network\\]\" /etc/wsl.conf && sed -i \"/\\[network\\]/a generateResolvConf = false\" /etc/wsl.conf || echo -e \"\\n[network]\\ngenerateResolvConf = false\" >> /etc/wsl.conf'"
        echo ""
        echo "  # 2. 替换 DNS 为公共 DNS"
        echo "  sudo rm /etc/resolv.conf"
        echo "  sudo bash -c 'echo -e \"nameserver 8.8.8.8\\nnameserver 8.8.4.4\" > /etc/resolv.conf'"
        echo ""
        echo "  # 3. 验证"
        echo "  curl -sI --connect-timeout 5 https://github.com | head -3"
        echo ""
        echo "修复后重新运行本脚本。"
        exit 1
        ;;
    blocked)
        echo ""
        echo "✗ 网络不可用：无法访问 GitHub"
        echo ""
        echo "安装 Clash 需要从 GitHub 下载文件，请先解决网络问题："
        echo ""
        echo "  【WSL2 用户】"
        echo "    在 Windows 端的 Clash 客户端中开启 TUN 模式，关闭系统代理"
        echo "    开启后 WSL2 的所有流量会自动透明代理，无需额外配置"
        echo "    然后重新运行本脚本"
        echo ""
        echo "  【远程服务器用户】"
        echo "    从你的本地电脑（有代理的那台）用以下命令连接服务器："
        echo "    ssh -R ${CLASH_PORT}:127.0.0.1:${CLASH_PORT} user@your-server"
        echo "    这会把服务器的 127.0.0.1:${CLASH_PORT} 转发到你本地的代理端口"
        echo "    然后重新运行本脚本，会自动检测到隧道代理"
        echo ""
        exit 1
        ;;
esac
echo ""

# 1. 确保 ~/.local/bin 在 PATH 中
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# 2. 下载 Clash 二进制（通过 GitHub API 获取正确的下载链接）
if command -v clash &>/dev/null; then
    echo "✓ Clash 已安装: $(clash -v 2>&1 | head -1)"
else
    echo "→ 下载 Clash Meta..."
    DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | python3 -c "
import sys, json
data = json.load(sys.stdin)
for a in data.get('assets', []):
    name = a['name']
    if name.endswith('.gz') and 'linux-amd64' in name and '-compatible' not in name \
       and '-v1-' not in name and '-v2-' not in name and '-v3-' not in name and 'go1' not in name:
        print(a['browser_download_url'])
        break
")
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "✗ 无法获取下载链接，请检查网络或手动下载"
        exit 1
    fi
    echo "  下载地址: $DOWNLOAD_URL"
    cd /tmp
    wget --timeout=60 --tries=2 -q "$DOWNLOAD_URL" -O mihomo-linux-amd64.gz
    gunzip -f mihomo-linux-amd64.gz
    mkdir -p ~/.local/bin
    mv mihomo-linux-amd64 ~/.local/bin/clash
    chmod +x ~/.local/bin/clash
    echo "✓ Clash 已安装到 ~/.local/bin/clash"
fi

# 3. 创建配置目录
mkdir -p "$CLASH_DIR/ui"
mkdir -p "$CLASH_DIR/proxy_providers"

# 4. 复制配置模板（不覆盖已有配置）
if [ -f "$CLASH_DIR/config.yaml" ]; then
    echo "⚠ 配置文件已存在，跳过覆盖: $CLASH_DIR/config.yaml"
else
    cp "$SKILL_DIR/assets/clash-config.yaml" "$CLASH_DIR/config.yaml"
    echo "✓ 配置模板已复制"
fi

# 5. 下载 Yacd 面板（使用 python3 zipfile 解压，不依赖 unzip）
if [ ! -f "$CLASH_DIR/ui/index.html" ] || [ ! -d "$CLASH_DIR/ui/assets" ]; then
    echo "→ 下载 Yacd 面板..."
    cd /tmp
    rm -rf yacd-gh-pages yacd.zip
    wget --timeout=60 --tries=2 -q https://github.com/haishanh/yacd/archive/gh-pages.zip -O yacd.zip
    python3 -c "
import zipfile, shutil, os
with zipfile.ZipFile('/tmp/yacd.zip', 'r') as z:
    z.extractall('/tmp/')
src = '/tmp/yacd-gh-pages'
dst = os.path.expanduser('~/.config/clash/ui')
for item in os.listdir(src):
    s = os.path.join(src, item)
    d = os.path.join(dst, item)
    if os.path.isdir(s):
        shutil.copytree(s, d, dirs_exist_ok=True)
    else:
        shutil.copy2(s, d)
shutil.rmtree(src)
os.remove('/tmp/yacd.zip')
"
    echo "✓ Yacd 面板已下载"
else
    echo "✓ Yacd 面板已存在"
fi

# 6. 下载 GeoIP 数据库
cd "$CLASH_DIR"
if [ ! -f Country.mmdb ]; then
    echo "→ 下载 GeoIP 数据库..."
    wget --timeout=30 --tries=2 -q https://cdn.jsdelivr.net/gh/Dreamacro/maxmind-geoip@release/Country.mmdb || echo "⚠ Country.mmdb 下载失败，可稍后手动下载"
fi
if [ ! -f geosite.dat ]; then
    wget --timeout=30 --tries=2 -q https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat || echo "⚠ geosite.dat 下载失败，可稍后手动下载"
fi
echo "✓ GeoIP 数据库就绪"

# 7. 配置代理环境变量持久化（写入 ~/.bashrc）
PROXY_BLOCK_START="# >>> clash proxy >>>"
PROXY_BLOCK_END="# <<< clash proxy <<<"
if ! grep -q "$PROXY_BLOCK_START" ~/.bashrc 2>/dev/null; then
    echo "→ 写入代理环境变量到 ~/.bashrc..."
    cat >> ~/.bashrc << BASHRC_EOF

# >>> clash proxy >>>
# Clash Meta 代理（由 clash-setup.sh 自动添加）
if pgrep -x clash > /dev/null 2>&1; then
    export http_proxy="http://127.0.0.1:${CLASH_PORT}"
    export https_proxy="http://127.0.0.1:${CLASH_PORT}"
    export HTTP_PROXY="http://127.0.0.1:${CLASH_PORT}"
    export HTTPS_PROXY="http://127.0.0.1:${CLASH_PORT}"
    export no_proxy="localhost,127.0.0.1,::1"
fi
# <<< clash proxy <<<
BASHRC_EOF
    echo "✓ 代理环境变量已写入 ~/.bashrc（Clash 运行时自动生效）"
else
    echo "✓ ~/.bashrc 代理配置已存在"
fi

# 8. 配置 git 全局代理
git config --global http.proxy http://127.0.0.1:${CLASH_PORT}
git config --global https.proxy http://127.0.0.1:${CLASH_PORT}
echo "✓ Git 全局代理已配置"

# 完成
echo ""
echo "=== 部署完成 ==="
echo ""
if grep -q "YOUR_SUBSCRIPTION_URL_HERE" "$CLASH_DIR/config.yaml" 2>/dev/null; then
    echo "⚠ 下一步：配置订阅链接"
    echo "  bash $SCRIPT_DIR/clash-config-sub.sh \"https://your-subscription-url\""
    echo ""
fi
echo "启动 Clash："
echo "  bash $SCRIPT_DIR/clash-start.sh"
