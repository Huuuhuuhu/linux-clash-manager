#!/bin/bash
# 订阅链接配置脚本

CONFIG_FILE="${HOME}/.config/clash/config.yaml"

# 检查参数
if [ $# -eq 0 ]; then
    echo "Usage: $0 <subscription_url>"
    echo "Example: $0 https://user.example.com/api/v1/client/subscribe?token=abc123"
    exit 1
fi

SUB_URL="$1"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "✗ Error: Config file not found at $CONFIG_FILE"
    echo "Please ensure Clash config is installed first."
    exit 1
fi

echo "→ Configuring subscription URL..."

# 检查是否有占位符，如果有则替换
if grep -q "YOUR_SUBSCRIPTION_URL_HERE" "$CONFIG_FILE"; then
    sed -i "s|YOUR_SUBSCRIPTION_URL_HERE|$SUB_URL|g" "$CONFIG_FILE"
    echo "✓ Subscription URL configured (placeholder replaced)"
# 检查是否已配置过相同的链接
elif grep -q "$SUB_URL" "$CONFIG_FILE"; then
    echo "⚠ This subscription URL is already configured"
    exit 0
else
    # 检查是否已有 proxy-providers 配置
    if grep -q "^proxy-providers:" "$CONFIG_FILE"; then
        echo "⚠ Existing proxy-providers found. Please manually edit:"
        echo "  $CONFIG_FILE"
        exit 1
    else
        # 添加新的 proxy-provider
        cat >> "$CONFIG_FILE" << EOF

# Auto-added subscription
proxy-providers:
  subscription:
    type: http
    url: "$SUB_URL"
    interval: 3600
    path: ./proxy_providers/subscription.yaml
    health-check:
      enable: true
      interval: 600
      url: http://www.gstatic.com/generate_204
EOF
        echo "✓ Subscription URL added to config"
    fi
fi

# 验证配置
echo ""
echo "→ Verifying configuration..."
if grep -q "$SUB_URL" "$CONFIG_FILE"; then
    echo "✓ Subscription URL verified in config"
    
    # 检查是否需要重启
    if pgrep -x "clash" > /dev/null 2>&1; then
        echo ""
        echo "⚠ Clash is currently running."
        echo "  Run 'clash-stop && clash-start' to apply changes."
    else
        echo ""
        echo "→ You can now start Clash:"
        echo "  clash-start"
    fi
else
    echo "✗ Failed to configure subscription URL"
    exit 1
fi
