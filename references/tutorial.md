# 海外业务代理搭建完整教程

## 概述

使用 Vultr VPS + 3X-UI + VLESS/Reality 搭建稳定的海外网络代理，用于跨境电商等合法业务场景。支持 Mac + iPhone 双端使用。

**预算：约 36 元/月（$5/月），年费约 432 元。**

---

## 第一步：购买 Vultr VPS

### 1.1 注册账号

1. 访问 [vultr.com](https://www.vultr.com)
2. 点击 Sign Up 注册（支持邮箱或 GitHub 登录）

### 1.2 充值

1. 登录后进入 Billing → Make Payment
2. 支付方式选 **Alipay（支付宝）**，最低充值 $10
3. 手机端支付宝扫码付款（桌面端可能失败）

### 1.3 创建服务器

1. 点击 **Deploy New Server**
2. 配置选择：
   - **Cloud Compute - Shared CPU**
   - **Location: Tokyo**（延迟低，约 40-80ms）
   - **Image: Debian 12**
   - **Plan: $5/mo（Regular Cloud Compute，1 vCPU / 1GB / 25GB SSD / 1TB bandwidth）**
   - 其他保持默认
3. 点击 **Deploy Now**
4. 等待状态变为 **Running**（约 2-3 分钟）

### 1.4 记录服务器信息

在服务器详情页记录：
- **IP Address**（如 207.148.110.235）
- **Password**（点击眼睛图标显示）

---

## 第二步：连接服务器并部署

### 2.1 SSH 连接

**Mac 终端：**
```bash
ssh root@你的服务器IP
# 输入密码（粘贴时不会显示，直接回车）
```

### 2.2 一键部署

将 `scripts/setup-vps.sh` 上传到服务器后执行：
```bash
bash setup-vps.sh
```

脚本会自动完成：
- 系统更新
- 3X-UI 面板安装
- VLESS + Reality 协议配置
- UFW 防火墙配置
- 生成连接信息和配置文件

部署完成后会输出：
- 面板登录地址
- VLESS 连接链接
- Clash 配置 YAML
- iPhone 连接说明

所有配置保存在服务器 `/root/vpn-config/` 目录。

### 2.3 手动部署（备选）

如果自动脚本失败，可手动操作：

```bash
# 1. 更新系统
apt update && apt upgrade -y

# 2. 安装 3X-UI
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
# 按提示设置端口、用户名、密码

# 3. 关闭 SSL（避免证书问题）
/usr/local/x-ui/x-ui setting -webCertPath "" -webKeyPath ""
x-ui restart

# 4. 开放防火墙端口
ufw allow 22/tcp
ufw allow 面板端口/tcp
ufw allow 代理端口/tcp
ufw --force enable
```

### 2.4 配置 VLESS + Reality 入站

1. 浏览器打开面板地址（如 `http://IP:端口/路径`）
2. 登录后进入 **Inbounds（入站列表）**
3. 点击 **Add Inbound**
4. 配置：
   - **协议：vless**
   - **端口：443**（或其他）
   - **传输：tcp**
   - **安全：reality**
   - **SNI（servername）：www.amazon.com**
   - 点击 **Get new certificate** 获取 dest
   - 点击 **Realistic Key pair** 生成密钥对
   - 点击 **Generate UUID** 生成用户 ID
   - Short ID 留空或自动生成
   - **uTLS fingerprint：chrome**
5. 点击 **Add** 保存

### 2.5 导出连接链接

1. 在入站列表中点击操作列的 **⋮ 菜单**
2. 选择 **导出链接（Export Link）**
3. 复制 `vless://...` 链接

---

## 第三步：Mac 客户端配置

### 3.1 安装 Clash Verge Rev

```bash
brew install --cask clash-verge-rev
```

### 3.2 导入配置

**方式一：导入 YAML 文件**
1. 打开 Clash Verge Rev
2. 左侧切换到 **订阅（Profiles）** 页面
3. 点击 **新建 → Local**
4. 将部署脚本生成的 YAML 内容粘贴或导入
5. 点击保存

**方式二：导入 VLESS 链接**
1. 在订阅页面点击 **导入**
2. 粘贴 `vless://...` 链接
3. 自动转换为配置

### 3.3 激活配置

1. 在订阅页面，**左键单击**导入的配置项
2. 确认左侧出现绿色/蓝色激活标记
3. 切换到 **代理** 页面，确认能看到 `Proxy` 组和 `amazon-biz` 节点

### 3.4 开启系统代理

在 Clash Verge Rev 的 **设置（Settings）** 页面：
- 打开 **系统代理（System Proxy）** 开关

或手动设置：系统设置 → Wi-Fi → 代理：
- HTTP 代理：`127.0.0.1:7897`
- HTTPS 代理：`127.0.0.1:7897`
- SOCKS 代理：`127.0.0.1:7897`

### 3.5 测试

浏览器访问 `google.com` 或 `fast.com` 验证连通性。

---

## 第四步：iPhone 客户端配置

### 4.1 安装 Streisand

App Store 搜索 **Streisand**，下载安装（免费）。

### 4.2 导入配置

1. 复制 `vless://...` 连接链接
2. 打开 Streisand
3. 点击右上角 **"+"**
4. 选择 **从剪贴板导入**
5. iOS 弹出 VPN 配置提示，点击 **允许**

### 4.3 使用

- 点击 **连接** 开启 VPN
- 顶部出现 VPN 图标即表示成功
- 再次点击可断开

---

## 第五步：日常使用和维护

### 同时使用多设备

- Mac 和 iPhone 可以**同时连接**同一节点，互不影响
- 出门用手机，回家用电脑，随意切换

### 测速

- **Clash Verge Rev**：代理页面点击 ⚡ 测速按钮
- **网页测速**：开启代理后访问 fast.com 或 speedtest.net
- **终端测速**：
  ```bash
  curl -o /dev/null -w "速度: %{speed_download} bytes/s\n" https://speed.cloudflare.com/__down?bytes=10000000
  ```

### 预期性能

- 延迟：40-80ms（东京节点）
- 下载速度：50-200Mbps（1Gbps 共享带宽）
- 晚高峰可能降低

### 计费

- Vultr 按小时计费，月度上限 $5
- **关机（Stop）不停止计费**
- **只有销毁（Destroy）才停止计费**
- 销毁后 IP 和数据全部清除

### 安全提醒

- 不要将面板地址、密码、VLESS 链接泄露给他人
- 定期在 3X-UI 面板检查连接日志
- 如发现异常，及时更换 UUID 和密钥
