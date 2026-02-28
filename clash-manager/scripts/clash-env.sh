#!/bin/bash
# Clash 代理环境变量管理
# 用法: source clash-env.sh [enable|disable|status]

ACTION="${1:-enable}"

if [ "$ACTION" = "enable" ] || [ "$ACTION" = "on" ]; then
    export http_proxy="http://127.0.0.1:7890"
    export https_proxy="http://127.0.0.1:7890"
    export HTTP_PROXY="http://127.0.0.1:7890"
    export HTTPS_PROXY="http://127.0.0.1:7890"
    export no_proxy="localhost,127.0.0.1"

    echo "✓ Proxy enabled (port 7890)"

elif [ "$ACTION" = "disable" ] || [ "$ACTION" = "off" ]; then
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy
    echo "✓ Proxy disabled"

elif [ "$ACTION" = "status" ]; then
    if [ -n "$http_proxy" ]; then
        echo "✓ Proxy is enabled: $http_proxy"
    else
        echo "✗ Proxy is disabled"
    fi
else
    echo "Usage: source clash-env.sh [enable|disable|status]"
fi
