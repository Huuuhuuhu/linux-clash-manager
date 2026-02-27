# WSL Clash Guide

在 WSL2 / Ubuntu 服务器上一键部署和管理 Clash Meta (Mihomo) 代理服务的 Agent Skill。

附带魔改 Yacd 面板（自动认证、动态 URL 检测）。

## 使用方式

将 `clash-manager/` 目录安装为 skill 后，直接对 agent 说：
- "帮我安装 Clash" → 自动完成全部部署
- "Clash 状态怎么样" → 查看运行状态
- "关掉 Clash" / "启动 Clash" → 管理服务
- "订阅链接换成 xxx" → 更新配置

## 网络引导

部署脚本会自动检测网络环境。如果无法访问 GitHub，会提示解决方案：

| 场景 | 解决方式 |
|------|----------|
| WSL2 + Windows 已有 Clash | 在 Windows Clash 中开启 TUN 模式，关闭系统代理，WSL2 自动透明代理 |
| 远程服务器 | 本地 SSH 连接时加 `-R 7890:127.0.0.1:7890` 建立反向隧道 |

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
│   ├── clash-config.yaml   # Clash 配置模板
│   └── yacd-index.html     # 魔改 Yacd 面板
└── references/
    └── setup-guide.md      # 完整部署教程
```

## 致谢

- [Clash Meta (Mihomo)](https://github.com/MetaCubeX/mihomo) - 代理内核
- [Yacd](https://github.com/haishanh/yacd) - Web 管理面板
