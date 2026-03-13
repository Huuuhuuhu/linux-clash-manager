#!/bin/bash
# Clash 启动脚本

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLASH_BIN="${HOME}/.local/bin/clash"
CLASH_CONFIG_DIR="${HOME}/.config/clash"
CLASH_PID_FILE="/tmp/clash.pid"
CLASH_SERVICE="/etc/systemd/system/clash.service"

if [ ! -f "$CLASH_BIN" ]; then
    echo "✗ Error: Clash binary not found at $CLASH_BIN"
    echo "Please install Clash first."
    exit 1
fi

if [ ! -d "$CLASH_CONFIG_DIR" ]; then
    echo "✗ Error: Clash config directory not found at $CLASH_CONFIG_DIR"
    exit 1
fi

# 优先使用 systemctl
if [ -f "$CLASH_SERVICE" ] && command -v systemctl &>/dev/null; then
    if systemctl is-active --quiet clash; then
        echo "⚠ Clash is already running (systemd)"
    else
        echo "→ Starting Clash via systemd..."
        sudo systemctl start clash
        sleep 2
        if systemctl is-active --quiet clash; then
            echo "✓ Clash started successfully (systemd)"
        else
            echo "✗ Failed to start Clash"
            echo "Check logs: journalctl -u clash -n 20"
            exit 1
        fi
    fi
else
    # fallback: 手动后台启动
    if [ -f "$CLASH_PID_FILE" ]; then
        PID=$(cat "$CLASH_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "⚠ Clash is already running (PID: $PID)"
            bash "$SCRIPT_DIR/clash-url.sh"
            exit 0
        fi
    fi

    echo "→ Starting Clash Meta..."
    cd "$CLASH_CONFIG_DIR" || exit 1
    "$CLASH_BIN" -d "$CLASH_CONFIG_DIR" > /tmp/clash.log 2>&1 &
    CLASH_PID=$!
    echo $CLASH_PID > "$CLASH_PID_FILE"
    sleep 2

    if ps -p "$CLASH_PID" > /dev/null 2>&1; then
        echo "✓ Clash started successfully (PID: $CLASH_PID)"
    else
        echo "✗ Failed to start Clash"
        echo "Check logs: /tmp/clash.log"
        rm -f "$CLASH_PID_FILE"
        exit 1
    fi
fi

echo ""
bash "$SCRIPT_DIR/clash-url.sh"
