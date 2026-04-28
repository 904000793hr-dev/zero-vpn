# Dummy VPN

> 傻瓜式 VPN 搭建。不会写代码？没关系，跟着做就行。

一个命令搭好代理服务器，支持 Mac / Windows / iPhone / Android 全平台。

## 要花多少钱？

$5/月（约 36 元/月），支持支付宝。一年 432 元。

## 有多简单？

```bash
# SSH 连上你买的服务器，粘贴这一条命令：
bash <(curl -Ls https://raw.githubusercontent.com/904000793hr-dev/zero-vpn/main/scripts/setup-vps.sh)
```

等 3-5 分钟，完事。脚本会自动帮你装好一切。

## 搭建流程

| 步骤 | 做什么 | 花多久 |
|------|--------|--------|
| 1 | 在 Vultr 租一台服务器（网页操作） | 3 分钟 |
| 2 | SSH 连上去跑一条命令 | 5 分钟 |
| 3 | 电脑装 Clash Verge Rev，粘贴链接 | 3 分钟 |
| 4 | 手机装 App，粘贴链接 | 1 分钟 |

**总共 12 分钟，不需要任何技术背景。**

## 支持的平台

| 平台 | 客户端 | 费用 |
|------|--------|------|
| Mac | Clash Verge Rev | 免费 |
| Windows | Clash Verge Rev | 免费 |
| iPhone | Streisand | 免费 |
| Android | v2rayNG | 免费 |

所有设备可以**同时使用**，互不影响。

## 技术方案

- **VPS：** Vultr 东京节点，$5/月
- **协议：** VLESS + Reality（伪装成正常 HTTPS 流量）
- **面板：** 3X-UI（Web 管理界面）
- **端口：** 443（标准 HTTPS，最稳定）

## 项目结构

```
zero-vpn/
├── SKILL.md                        # Claude Code 技能描述
├── scripts/
│   └── setup-vps.sh               # 服务器一键部署脚本
├── references/
│   ├── tutorial.md                # 完整搭建教程
│   └── troubleshooting.md         # 故障排查指南
└── assets/
    └── clash-config-template.yaml # Clash 客户端配置模板
```

## 一键部署脚本做了什么

- 系统更新
- 安装 3X-UI 管理面板
- 生成 Reality 密钥对
- 创建 VLESS 入站（自动配置）
- 开放防火墙端口（SSH + 面板 + 代理）
- 输出连接链接和客户端配置

脚本执行完后会输出：
- 面板登录地址和密码
- `vless://...` 连接链接（粘贴到手机/电脑客户端即可）
- Clash YAML 配置文件

## 作为 Claude Code Skill 使用

本项目也是一个 Claude Code 技能包。安装后，在对话中提到 VPN、代理、VLESS 等关键词会自动触发引导。

```bash
# 克隆到 Claude Code 技能目录
git clone https://github.com/904000793hr-dev/zero-vpn.git ~/.claude/skills/zero-vpn
```

或者下载 `.skill` 文件直接导入。

## 常见问题

**Q：手机和电脑能同时用吗？**
可以。所有设备独立连接服务器，互不影响。

**Q：电脑关了，手机还能用吗？**
可以。服务运行在云服务器上，7×24 小时，跟你的电脑无关。

**Q：不想用了怎么停费？**
Vultr 后台 Destroy（销毁）服务器就停费。关机不停费，必须销毁。

**Q：搭建过程中遇到问题？**
查看 [故障排查指南](references/troubleshooting.md)。

## 免责声明

本项目仅供跨境电商等合法海外业务场景使用。请遵守当地法律法规，用户需对自己的行为负责。

## License

MIT
