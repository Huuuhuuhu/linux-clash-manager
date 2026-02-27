# Clash Meta (Mihomo) WSL 部署指南

## 前置条件

- Windows 10/11 已安装 WSL2
- Ubuntu 或其他 Linux 发行版
- 拥有一个 Clash/V2Ray 订阅链接

## 快速部署

使用 setup 脚本一键部署：

```bash
bash <skill-dir>/scripts/clash-setup.sh
```

脚本会自动完成：下载 Clash 二进制、创建配置目录、复制配置模板、下载 Yacd 面板并应用魔改、下载 GeoIP 数据库。

部署完成后，编辑 `~/.config/clash/config.yaml`，将 `YOUR_SUBSCRIPTION_URL_HERE` 替换为订阅链接。或使用脚本：

```bash
bash <skill-dir>/scripts/clash-config-sub.sh "https://your-subscription-url"
```

## 手动部署步骤

### 1. 下载并安装 Clash

Clash Meta（现名 Mihomo）是支持更多协议的 Clash 分支。

```bash
cd /tmp
wget https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64.gz
gunzip mihomo-linux-amd64.gz
mkdir -p ~/.local/bin
mv mihomo-linux-amd64 ~/.local/bin/clash
chmod +x ~/.local/bin/clash
clash -v
```

### 2. 准备配置文件

```bash
mkdir -p ~/.config/clash/ui

# 复制 Clash 配置模板
cp <skill-dir>/assets/clash-config.yaml ~/.config/clash/config.yaml

# 下载 Yacd Web 面板
cd /tmp
wget https://github.com/haishanh/yacd/archive/gh-pages.zip -O yacd.zip
unzip -q yacd.zip
mv yacd-gh-pages/* ~/.config/clash/ui/
rm -rf yacd-gh-pages yacd.zip

# 用魔改 index.html 覆盖
cp <skill-dir>/assets/yacd-index.html ~/.config/clash/ui/index.html

# 下载 GeoIP 数据库
cd ~/.config/clash
wget https://cdn.jsdelivr.net/gh/Dreamacro/maxmind-geoip@release/Country.mmdb
wget https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat
```

### 3. 配置订阅链接

编辑 `~/.config/clash/config.yaml`，将 `YOUR_SUBSCRIPTION_URL_HERE` 替换为真实订阅链接。

### 4. 启动 Clash

```bash
clash -d ~/.config/clash
```

看到以下输出表示成功：
```
INFO[0000] RESTful API listening at: [::]:9090
INFO[0000] Mixed(http+socks) proxy listening at: [::]:7890
```

### 5. 访问 Web 面板

```bash
# 获取 WSL IP
ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1

# 在 Windows 浏览器中访问 http://<WSL_IP>:9090/ui
```

### 6. 验证代理

```bash
curl --proxy http://127.0.0.1:7890 -I https://google.com
```

## 核心改进说明

### CORS 跨域配置
`config.yaml` 中启用 CORS，允许浏览器跨域访问 API。

### 动态后端地址检测
修改 Yacd 的 `index.html`，自动从浏览器地址栏获取 API Base URL，不再硬编码 `127.0.0.1`。

### 自动认证注入
在 Yacd 中注入脚本，自动为所有 API 请求添加 `Authorization: Bearer` 头，自动为 WebSocket 添加 token 参数。

### 预设配置保存
自动将 API URL 和 Secret 保存到浏览器 localStorage，刷新页面后无需重新配置。

## 注意事项

1. **WSL IP 会变化**：每次重启 WSL 后 IP 可能改变，使用 `clash-url` 脚本获取最新地址
2. **Windows 防火墙**：确保允许访问 WSL 的 9090 端口
3. **订阅链接安全**：不要将包含真实 token 的订阅链接上传到公共仓库
4. **Secret 同步**：`clash-config.yaml` 和 `yacd-index.html` 中的 Secret 默认都是 `MySuperSecret123`，修改一个必须同步修改另一个
