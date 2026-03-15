#!/bin/bash
# Clash 状态检查脚本

CLASH_PID_FILE="/tmp/clash.pid"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLASH_SERVICE="/etc/systemd/system/clash.service"

check_clash_running() {
    # systemd 方式
    if [ -f "$CLASH_SERVICE" ] && command -v systemctl &>/dev/null; then
        systemctl is-active --quiet clash && return 0
    fi
    # PID 文件方式
    if [ -f "$CLASH_PID_FILE" ]; then
        PID=$(cat "$CLASH_PID_FILE")
        ps -p "$PID" > /dev/null 2>&1 && return 0
    fi
    # 进程名方式
    pgrep -x "clash" > /dev/null 2>&1 && return 0
    return 1
}

check_ports() {
    if ss -tlnp 2>/dev/null | grep -q ":7890"; then
        return 0
    elif netstat -tlnp 2>/dev/null | grep -q ":7890"; then
        return 0
    fi
    return 1
}

if check_clash_running; then
    echo "✓ Clash is running"
    if [ -f "$CLASH_SERVICE" ] && command -v systemctl &>/dev/null; then
        echo "  Mode: systemd (autostart enabled)"
    fi
    if check_ports; then
        echo "✓ Proxy port 7890 is listening"
        echo "✓ Web panel: http://localhost:9090/ui"
        echo ""
        echo "Proxy: 127.0.0.1:7890"
    else
        echo "⚠ Clash process exists but port 7890 not listening"
    fi
else
    echo "✗ Clash is not running"
    echo ""
    echo "To start: bash $SCRIPT_DIR/clash-start.sh"
fi
