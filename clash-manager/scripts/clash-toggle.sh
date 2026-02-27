#!/bin/bash
# Clash 一键切换脚本（非交互式，适用于 agent 环境）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLASH_PID_FILE="/tmp/clash.pid"

is_running() {
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

if is_running; then
    bash "$SCRIPT_DIR/clash-stop.sh"
else
    bash "$SCRIPT_DIR/clash-start.sh"
fi
