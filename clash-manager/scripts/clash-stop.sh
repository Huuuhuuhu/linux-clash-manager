#!/bin/bash
# Clash 停止脚本

CLASH_PID_FILE="/tmp/clash.pid"
CLASH_SERVICE="/etc/systemd/system/clash.service"

echo "→ Stopping Clash..."

# 优先使用 systemctl
if [ -f "$CLASH_SERVICE" ] && command -v systemctl &>/dev/null; then
    if systemctl is-active --quiet clash; then
        sudo systemctl stop clash
        echo "✓ Clash stopped (systemd)"
    else
        echo "⚠ Clash was not running (systemd)"
    fi
    # 也清理可能残留的手动启动进程
    if pgrep -x "clash" > /dev/null 2>&1; then
        pkill -x "clash"
        echo "✓ Stopped additional Clash processes"
    fi
    rm -f "$CLASH_PID_FILE"
else
    # fallback: 手动停止
    STOPPED=false

    if [ -f "$CLASH_PID_FILE" ]; then
        PID=$(cat "$CLASH_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID" 2>/dev/null
            sleep 1
            if ! ps -p "$PID" > /dev/null 2>&1; then
                echo "✓ Clash stopped (PID: $PID)"
                STOPPED=true
            else
                kill -9 "$PID" 2>/dev/null
                echo "✓ Clash force stopped (PID: $PID)"
                STOPPED=true
            fi
        fi
        rm -f "$CLASH_PID_FILE"
    fi

    if pgrep -x "clash" > /dev/null 2>&1; then
        pkill -x "clash"
        echo "✓ Stopped additional Clash processes"
        STOPPED=true
    fi

    if [ "$STOPPED" = false ]; then
        echo "⚠ Clash was not running"
    fi
fi

echo ""
echo "Proxy is now disabled."
