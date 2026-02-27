# WSL Clash Guide

在 WSL2 / Ubuntu 服务器上一键部署和管理 Clash Meta (Mihomo) 代理服务的 Agent Skill。

## 使用方式

将 `clash-manager/` 目录安装为 skill 后，直接对 agent 说：
- "帮我安装 Clash" → 自动完成全部部署
- "Clash 状态怎么样" → 查看运行状态
- "关掉 Clash" / "启动 Clash" → 管理服务
- "订阅链接换成 xxx" → 更新配置

## 网络引导

部署脚本会自动检测网络环境：

| 场景 | 脚本行为 |
|------|----------|
| Clash 已在运行 | 提示已安装，无需重复部署 |
| 检测到本地代理端口（非 Clash 进程） | 通过该代理（如 SSH -R 隧道）下载安装 |
| 直连可用（TUN / 海外服务器） | 直连下载安装 |
| 无网络 + ping 通（DNS 问题） | 自动检测并提示修复 `/etc/resolv.conf` |
| 无网络 + WSL2 环境 | 提示在 Windows Clash 中开启 TUN 模式 |
| 无网络 + 远程服务器 | 提示用 SSH `-R` 建立反向隧道 |
| 无网络 + 无法判断环境 | 同时展示 WSL2 和服务器两种方案 |

## 仓库结构

```
clash-manager/
├── SKILL.md                # 技能说明（Agent 入口）
├── scripts/                # 管理脚本
│   ├── clash-setup.sh      # 一键部署
│   ├── clash-start.sh      # 启动
│   ├── clash-stop.sh       # 停止
│   ├── clash-status.sh     # 查看状态
│   ├── clash-toggle.sh     # 切换开关
│   ├── clash-url.sh        # 获取访问地址
│   ├── clash-env.sh        # 环境变量管理
│   └── clash-config-sub.sh # 配置订阅链接
├── assets/
│   └── clash-config.yaml   # Clash 配置模板
└── references/
    └── setup-guide.md      # 完整部署教程
```

## 致谢

- [Clash Meta (Mihomo)](https://github.com/MetaCubeX/mihomo) - 代理内核
- [Yacd](https://github.com/haishanh/yacd) - Web 管理面板
