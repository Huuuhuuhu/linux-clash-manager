---
name: clash-manager
description: Manage Clash Meta (Mihomo) proxy service for WSL/Ubuntu. Use when user wants to install/deploy Clash from scratch, start, stop, check status, or toggle the Clash proxy service. Also use when user asks about proxy status, enabling/disabling proxy, configuring subscription URL, troubleshooting proxy connectivity, accessing Clash web panel, or testing network connectivity to blocked sites like Google.
---

# Clash Manager

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

1. Run setup script:
```bash
bash <skill-dir>/scripts/clash-setup.sh
```
2. Ask user for their subscription URL, then configure it:
```bash
bash <skill-dir>/scripts/clash-config-sub.sh "USER_PROVIDED_URL"
```
3. Start Clash:
```bash
bash <skill-dir>/scripts/clash-start.sh
```
4. Show user the web panel URL and remind them the Secret (default: `MySuperSecret123`):
```bash
bash <skill-dir>/scripts/clash-url.sh
```
5. Verify proxy works:
```bash
curl --proxy http://127.0.0.1:7890 -I https://google.com
```

After this, user opens the web panel URL in browser.

**Important: Yacd first-time use** — The panel may not auto-connect to the backend. If user sees an empty page or "Unauthorized" error:
1. Look for a "切换后端" (Switch Backend) or gear icon in the panel
2. Enter API Base URL and Secret:
   - **WSL environment**: `http://<WSL_IP>:9090` (get IP from `clash-url.sh`)
   - **Remote server**: `http://<SERVER_PUBLIC_IP>:9090` (use server's public IP, NOT `localhost`)
   - **Secret**: `MySuperSecret123`
   - **Why not localhost?** Yacd is a frontend app running in your browser. When you fill `localhost`, it refers to YOUR computer, not the server. Always use the server's actual IP address.
3. Click Add/Connect
4. **If redirected to error page after connecting**, simply revisit the `/ui` URL to reload the panel

Once connected, select a node and proxy is ready.

## Quick Commands

Start: `bash <skill-dir>/scripts/clash-start.sh`
Stop: `bash <skill-dir>/scripts/clash-stop.sh`
Status: `bash <skill-dir>/scripts/clash-status.sh`
Toggle: `bash <skill-dir>/scripts/clash-toggle.sh`
Web panel URL: `bash <skill-dir>/scripts/clash-url.sh`
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

1. **/etc/profile.d/clash-proxy.sh**: Adds conditional proxy env vars for **all users** — when Clash is running, every new shell (including shells spawned by opencode/claude-code) automatically gets `http_proxy`/`https_proxy` set. When Clash is stopped, env vars are not set.
2. **Git global proxy**: `git config --global http.proxy` is set for the user who runs setup (typically root).
3. **Clash daemon**: Runs as background process, persists across terminal sessions. No need to restart when opening new terminals.

**Multi-user setup**: If Clash is installed by root (e.g., via SSH as root), all users can use the proxy through port 7890 and access the web panel on port 9090. However, only root can manage Clash (start/stop/configure). This is the recommended setup for servers.

So: Clash 启动一次就行，新开终端/SSH 会话不需要重新启动。代理环境变量通过 /etc/profile.d/ 自动注入到所有用户。

### Using proxy in opencode/claude-code

All scripts use the fixed proxy port 7890.

Each bash command in opencode runs in a separate shell. Since /etc/profile.d/ is sourced, proxy env vars are available IF Clash is running. For explicit proxy usage:

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
- Run `clash-url.sh` to get correct WSL IP
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
  sudo bash -c 'echo -e "\n[network]\ngenerateResolvConf = false" >> /etc/wsl.conf'
  sudo rm /etc/resolv.conf
  sudo bash -c 'echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf'
  ```

**Yacd panel shows empty / no proxies / "Unauthorized":**
- This is normal on first use. The panel needs to be manually connected to the backend.
- Click "切换后端" (Switch Backend) or the gear icon, enter API Base URL and Secret (`MySuperSecret123`), then click Add.
  - WSL: use `http://<WSL_IP>:9090`
  - Remote server: use `http://<SERVER_PUBLIC_IP>:9090` (NOT `localhost` — Yacd runs in your browser, so `localhost` points to your local machine)
- If the page redirects to an error page after switching backend, revisit `http://<IP>:9090/ui` to reload the panel.

**Ports not accessible:**
- Check `allow-lan: true` and `bind-address: '*'` in config.yaml
- Check logs: `tail -f /tmp/clash.log`
