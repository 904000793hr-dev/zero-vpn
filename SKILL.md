---
name: vpn-setup
description: 跨境业务代理搭建技能。使用 Vultr VPS + 3X-UI + VLESS/Reality 协议搭建稳定的海外网络代理，适用于跨境电商等合法业务场景。当用户提到 VPN、代理、翻墙、VPS、VLESS、Reality、Clash、3X-UI、海外网络、科学上网、跨境网络时触发此技能。覆盖从购买服务器到客户端配置的完整流程，支持 Mac（Clash Verge Rev）和 iPhone（Streisand）双端。
---

# 跨境业务代理搭建

使用 Vultr VPS 部署 VLESS + Reality 代理，用于跨境电商等合法海外业务场景。

**预算：约 36 元/月（$5/月），支持 Mac + iPhone 同时使用。**

## 工作流程

### 阶段一：服务器准备

1. 指导用户在 [vultr.com](https://www.vultr.com) 注册并充值（支持支付宝）
2. 创建服务器配置：
   - Cloud Compute - Shared CPU
   - Location: Tokyo
   - OS: Debian 12
   - Plan: $5/mo（1 vCPU / 1GB / 25GB SSD）
3. 记录 IP 地址和密码

### 阶段二：服务器部署

提供两种部署方式：

**方式 A：自动脚本（推荐）**

将 `scripts/setup-vps.sh` 上传到服务器执行，一键完成所有配置。

**方式 B：手动操作**

若脚本失败，按 `references/tutorial.md` 中"手动部署"章节逐步操作。

手动操作核心步骤：
```bash
# 系统更新
apt update && apt upgrade -y

# 安装 3X-UI
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# 关闭 SSL
/usr/local/x-ui/x-ui setting -webCertPath "" -webKeyPath ""
x-ui restart

# 开放端口
ufw allow 22/tcp
ufw allow 面板端口/tcp
ufw allow 代理端口/tcp
ufw --force enable
```

### 阶段三：配置 VLESS + Reality

在 3X-UI 面板中：
1. Add Inbound → 协议选 vless
2. 端口设 443 或自定义
3. 传输：tcp，安全：reality
4. SNI：www.amazon.com
5. 生成密钥对（Get new certificate + Realistic Key pair）
6. 生成 UUID
7. uTLS fingerprint：chrome
8. 保存后通过 ⋮ 菜单 → 导出链接获取 `vless://...`

### 阶段四：Mac 客户端

```bash
brew install --cask clash-verge-rev
```

配置方式（二选一）：
- 在订阅页面导入 `vless://...` 链接
- 或使用 `assets/clash-config-template.yaml` 模板（替换占位符后导入）

激活后在设置中开启 **系统代理**。

### 阶段五：iPhone 客户端

1. App Store 下载 Streisand
2. 复制 `vless://...` 链接
3. 从剪贴板导入 → 允许 VPN 配置 → 连接

## 关键注意事项

- **防火墙**：必须开放 SSH(22)、面板端口、代理端口
- **SSL 问题**：面板 SSL 关闭，用 HTTP 访问，避免证书报错
- **YAML 格式**：缩进用空格不用 Tab，空的 `flow:` 字段要删掉
- **计费**：Vultr 按小时计费，关机不停费，只有销毁才停
- **多设备**：Mac 和 iPhone 可同时连接同一节点

## 资源文件

| 文件 | 用途 |
|------|------|
| `scripts/setup-vps.sh` | 服务器一键部署脚本 |
| `references/tutorial.md` | 完整图文教程（含每一步详细操作） |
| `references/troubleshooting.md` | 常见问题排查指南 |
| `assets/clash-config-template.yaml` | Clash Verge Rev 配置模板 |

遇到问题时先查阅 `references/troubleshooting.md`。
