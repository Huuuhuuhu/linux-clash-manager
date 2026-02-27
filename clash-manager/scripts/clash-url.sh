#!/bin/bash
# 获取 WSL IP 并显示访问地址

WSL_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

echo "=========================================="
echo "Clash Web 面板访问信息"
echo "=========================================="
echo ""
echo "方法 1 - 当前 WSL IP（推荐）："
echo "  http://${WSL_IP}:9090/ui"
echo ""
echo "方法 2 - Windows 特殊域名（Windows 11）："
echo "  http://wsl.localhost:9090/ui"
echo ""
echo "API 配置："
echo "  API Base URL: http://${WSL_IP}:9090"
echo "  Secret: MySuperSecret123"
echo ""
echo "=========================================="
echo "要在 Windows 中永久使用，请用管理员权限"
echo "在 C:\Windows\System32\drivers\etc\hosts 添加："
echo ""
echo "${WSL_IP} wsl-clash"
echo ""
echo "然后访问：http://wsl-clash:9090/ui"
echo "=========================================="
