#!/bin/bash
# Clash 停止脚本

CLASH_PID_FILE="/tmp/clash.pid"

echo "→ Stopping Clash..."

STOPPED=false

# Try to stop by PID file
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

# Also kill any remaining clash processes
if pgrep -x "clash" > /dev/null 2>&1; then
    pkill -x "clash"
    echo "✓ Stopped additional Clash processes"
    STOPPED=true
fi

if [ "$STOPPED" = true ]; then
    echo ""
    echo "Proxy is now disabled."
else
    echo "⚠ Clash was not running"
fi
