---
name: clash-manager
description: Manage Clash Meta (Mihomo) proxy service for WSL/Ubuntu. Use when user wants to install/deploy Clash from scratch, start, stop, check status, or toggle the Clash proxy service. Also use when user asks about proxy status, enabling/disabling proxy, configuring subscription URL, troubleshooting proxy connectivity, accessing Clash web panel, or testing network connectivity to blocked sites like Google.
---

# Clash Manager

**重要：与用户交互时必须使用中文。所有提示、说明、错误信息均用中文输出。**

Manage and deploy Clash Meta (Mihomo) proxy service in WSL/Ubuntu environments.

## End-to-End Setup Workflow

When user asks to install/deploy Clash, follow the sequence below. The setup script auto-detects the environment (WSL2 vs Ubuntu server) and provides tailored guidance.

### Bootstrap: Solving the Chicken-and-Egg Problem

Installing Clash requires downloading from GitHub, but the user may not have network access yet. The setup script auto-detects in this order:

1. **Local port probe** (127.0.0.1:7890/7897) — covers SSH reverse tunnel and existing local proxy
2. **Direct connection test** — covers TUN mode and overseas servers
3. **Environment detection** — detects WSL2 (via `/proc/version` containing "microsoft"/"WSL") vs Ubuntu server
4. **TCP/DNS diagnostics** — if ping succeeds but curl fails, further tests TCP connectivity to distinguish between TUN not enabled (TCP blocked) and DNS/TLS issues

If network is blocked, the script provides environment-specific guidance:
- **WSL2**: Enable TUN mode in Windows Clash client, disable system proxy
- **Ubuntu server**: SSH with reverse tunnel from local machine
- **Unknown environment**: Shows both options

### Setup Sequence

Follow these steps and provide clear guidance to the user at each stage:

1. **Run setup script:**
```bash
bash <skill-dir>/scripts/clash-setup.sh
```

2. **Ask user for their subscription URL, then configure it:**
```bash
bash <skill-dir>/scripts/clash-config-sub.sh "USER_PROVIDED_URL"
```

3. **Start Clash:**
```bash
bash <skill-dir>/scripts/clash-start.sh
```

4. **After starting Clash, immediately tell the user how to access the Web panel:**

Detect the environment first (check `/proc/version` for "microsoft" or "WSL" to determine if it's WSL2).

Then tell the user in Chinese:

**For WSL environment:**
```
Clash 已启动成功！现在打开浏览器访问 Web 面板：

面板地址：http://localhost:9090/ui

首次使用需要手动连接后端：
1. 点击页面上的「切换后端」或齿轮图标
2. 填入以下信息：
   - API Base URL: http://localhost:9090
   - Secret: MySuperSecret123
3. 点击「添加」或「连接」

连接成功后，选择一个节点即可开始使用代理。
```

**For remote server environment:**
```
Clash 已启动成功！现在打开浏览器访问 Web 面板：

面板地址：http://<服务器公网IP>:9090/ui

首次使用需要手动连接后端：
1. 点击页面上的「切换后端」或齿轮图标
2. 填入以下信息：
   - API Base URL: http://<服务器公网IP>:9090
   - Secret: MySuperSecret123
3. 点击「添加」或「连接」

注意：这里必须填服务器的公网 IP，不能填 localhost（因为 Yacd 面板是在你本地浏览器运行的，localhost 会指向你自己的电脑）

连接成功后，选择一个节点即可开始使用代理。
```

5. **Verify proxy works (optional):**
```bash
curl --proxy http://127.0.0.1:7890 -I https://google.com
```

## Important Notes

- Do NOT rely on script output to convey critical information to the user. Always extract and present key information (URLs, secrets, configuration steps) directly in your response.
- Always detect the environment (WSL vs server) and provide tailored instructions.
- The Web panel connection is a common pain point - make sure to explain it clearly every time.

## Quick Commands

Start: `bash <skill-dir>/scripts/clash-start.sh`
Stop: `bash <skill-dir>/scripts/clash-stop.sh`
Status: `bash <skill-dir>/scripts/clash-status.sh`
Configure subscription: `bash <skill-dir>/scripts/clash-config-sub.sh "URL"`

**Important: After switching subscription URL**, you must delete the cached proxy provider file and restart Clash:
```bash
rm -f ~/.config/clash/proxy_providers/my-proxy.yaml
bash <skill-dir>/scripts/clash-stop.sh
bash <skill-dir>/scripts/clash-start.sh
```
This is because Clash caches the proxy list locally. Without deleting the cache, the old subscription nodes will persist even after config update.

## Proxy Persistence

The setup script automatically configures:

1. **/etc/profile.d/clash-proxy.sh**: Unconditionally sets proxy env vars (`http_proxy`/`https_proxy` etc.) for **all users**. Every new login shell automatically gets proxy environment variables, no conditional check needed (designed to work with autostart).
2. **~/.config/environment.d/clash-proxy.conf**: Sets proxy env vars for **systemd user services** (e.g., openclaw-gateway). Uses `KEY=VALUE` format (no `export`). This ensures services managed by `systemctl --user` inherit proxy settings.
3. **Git global proxy**: `git config --global http.proxy` is set for the user who runs setup.
4. **systemd autostart**: Creates `/etc/systemd/system/clash.service` and enables it. Clash starts automatically on boot. If systemd is not available (e.g., older WSL2), the script will prompt the user to enable systemd in wsl.conf.

**Multi-user setup**: If Clash is installed by root (e.g., via SSH as root), all users can use the proxy through port 7890 and access the web panel on port 9090. However, only root can manage Clash (start/stop/configure). This is the recommended setup for servers.

So: Clash 开机自启，新开终端/SSH 会话不需要任何操作，代理环境变量通过 /etc/profile.d/ 无条件注入到所有用户，systemd user service 通过 environment.d 获取代理变量。

### Using proxy in opencode/claude-code

All scripts use the fixed proxy port 7890.

Each bash command in opencode runs in a separate shell. Since /etc/profile.d/ is sourced, proxy env vars are always available. For explicit proxy usage:

```bash
# curl: use --proxy flag (most reliable)
curl --proxy http://127.0.0.1:7890 -I https://google.com

# wget/git/pip: env vars from /etc/profile.d/ work automatically
```

## Bundled Resources

- `assets/clash-config.yaml` — Clash 配置模板（已启用 CORS、相对路径、订阅占位符）
- `references/setup-guide.md` — 完整手动部署教程

## Troubleshooting

**Cannot access Web Panel from Windows:**
- Check Web panel at `http://localhost:9090/ui`
- Ensure `external-controller` uses `0.0.0.0:9090`
- Check Windows Firewall allows port 9090

**Setup script download fails (no network):**
- The script auto-detects your environment and provides tailored guidance
- WSL2: enable TUN mode in Windows Clash, disable system proxy
- Remote server: SSH with `-R <port>:127.0.0.1:<port>` to create reverse tunnel
- If ping works but curl fails, the script tests TCP connectivity to distinguish:
  - TCP also fails → TUN not enabled (recommends enabling TUN mode)
  - TCP works but HTTPS fails → DNS/TLS issue (recommends fixing resolv.conf)

**TUN mode not enabled (ping works, TCP blocked):**
- The setup script detects this as `no_tun` status
- Recommends enabling TUN mode in Windows Clash client and disabling system proxy
- Alternative: SSH reverse tunnel

**TUN mode enabled but curl times out (DNS issue):**
- The setup script detects this as `dns_broken` (TCP connects but HTTPS fails)
- It will suggest the DNS fix commands automatically
- Manual fix if needed:
  ```bash
  # 幂等写入，不会重复追加 [network] 段
  grep -q '\[network\]' /etc/wsl.conf 2>/dev/null || sudo bash -c 'echo -e "\n[network]\ngenerateResolvConf = false" >> /etc/wsl.conf'
  sudo rm -f /etc/resolv.conf
  sudo bash -c 'echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf'
  ```

**Yacd panel shows empty / no proxies / "Unauthorized":**
- This is normal on first use. The panel needs to be manually connected to the backend.
- Click "切换后端" (Switch Backend) or the gear icon, enter API Base URL and Secret (`MySuperSecret123`), then click Add.
  - WSL: use `http://localhost:9090`
  - Remote server: use `http://<SERVER_PUBLIC_IP>:9090` (NOT `localhost` — Yacd runs in your browser, so `localhost` points to your local machine)
- If the page redirects to an error page after switching backend, revisit `http://<IP>:9090/ui` to reload the panel.

**Ports not accessible:**
- Check `allow-lan: true` and `bind-address: '*'` in config.yaml
- Check logs: `tail -f /tmp/clash.log`
