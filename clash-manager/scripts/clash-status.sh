#!/bin/bash
# Clash 状态检查脚本

CLASH_PID_FILE="/tmp/clash.pid"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLASH_CONFIG_DIR="${HOME}/.config/clash"

check_clash_running() {
    if [ -f "$CLASH_PID_FILE" ]; then
        PID=$(cat "$CLASH_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        fi
    fi
    if pgrep -x "clash" > /dev/null 2>&1; then
        return 0
    fi
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
