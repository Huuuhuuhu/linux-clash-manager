#!/bin/bash
# Clash 启动脚本

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLASH_BIN="${HOME}/.local/bin/clash"
CLASH_CONFIG_DIR="${HOME}/.config/clash"
CLASH_PID_FILE="/tmp/clash.pid"

if [ ! -f "$CLASH_BIN" ]; then
    echo "✗ Error: Clash binary not found at $CLASH_BIN"
    echo "Please install Clash first."
    exit 1
fi

if [ ! -d "$CLASH_CONFIG_DIR" ]; then
    echo "✗ Error: Clash config directory not found at $CLASH_CONFIG_DIR"
    exit 1
fi

# Check if already running
if [ -f "$CLASH_PID_FILE" ]; then
    PID=$(cat "$CLASH_PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "⚠ Clash is already running (PID: $PID)"
        echo "  Web panel: http://localhost:9090/ui"
        exit 0
    fi
fi

echo "→ Starting Clash Meta..."
cd "$CLASH_CONFIG_DIR" || exit 1

# Start Clash in background
"$CLASH_BIN" -d "$CLASH_CONFIG_DIR" > /tmp/clash.log 2>&1 &
CLASH_PID=$!

# Save PID
echo $CLASH_PID > "$CLASH_PID_FILE"

# Wait a moment and check if it's running
sleep 2

if ps -p "$CLASH_PID" > /dev/null 2>&1; then
    echo "✓ Clash started successfully (PID: $CLASH_PID)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Web Panel: http://localhost:9090/ui"
    echo "  Secret: MySuperSecret123"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Proxy: 127.0.0.1:7890"
    echo ""
    echo "Quick commands:"
    echo "  Check status:  bash $SCRIPT_DIR/clash-status.sh"
    echo "  Stop proxy:    bash $SCRIPT_DIR/clash-stop.sh"
else
    echo "✗ Failed to start Clash"
    echo "Check logs: /tmp/clash.log"
    rm -f "$CLASH_PID_FILE"
    exit 1
fi
