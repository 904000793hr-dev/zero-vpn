# 故障排除指南

## 连接类问题

### 面板打不开

**症状：** 浏览器访问面板地址无响应

**排查步骤：**
1. 确认服务器状态为 Running（Vultr 后台查看）
2. 检查 UFW 防火墙是否开放了面板端口：
   ```bash
   ufw status
   # 如果面板端口不在列表中：
   ufw allow 面板端口/tcp
   ```
3. 确认 3X-UI 服务正在运行：
   ```bash
   x-ui status
   # 如果未运行：
   x-ui restart
   ```

### ERR_SSL_PROTOCOL_ERROR

**原因：** 面板启用了 SSL 但没有有效证书

**解决：**
```bash
/usr/local/x-ui/x-ui setting -webCertPath "" -webKeyPath ""
x-ui restart
```
然后使用 **http://** （不是 https）访问面板。

### Let's Encrypt 证书申请失败

**原因：** UFW 防火墙阻止了 80 端口的 ACME 验证

**解决：**
```bash
ufw allow 80/tcp
```
然后重新申请证书。或直接关闭 SSL 使用 HTTP 访问面板（推荐，面板只是管理用）。

---

## 代理类问题

### 代理连不上（超时）

**排查步骤：**
1. 确认代理端口在 UFW 中已开放：
   ```bash
   ufw allow 443/tcp
   # 或你的自定义端口
   ufw allow 50480/tcp
   ```
2. 确认 Xray 服务正常：
   ```bash
   x-ui status
   ```
3. 检查入站配置是否正确（在面板中查看）
4. 测试端口是否通：
   ```bash
   # 在本地 Mac 执行
   nc -zv 服务器IP 代理端口
   ```

### Clash Verge Rev 不激活自定义配置

**症状：** 导入了 YAML 配置但代理页面只显示 GLOBAL/DIRECT/REJECT

**解决：**
1. 在**订阅页面**，左键单击配置项（不是右键菜单）
2. 确认左侧出现绿色/蓝色激活标记
3. 重启 Clash Verge Rev

如果仍不生效，尝试：
1. 删除已导入的配置
2. 点击 **导入** 按钮
3. 直接粘贴 `vless://...` 链接
4. 让 Clash Verge Rev 自动转换

### YAML 格式错误

**常见问题：**
- 缩进必须用空格，不能用 Tab
- `flow:` 字段为空时不要写（删掉这行）
- 验证 YAML 格式：
  ```bash
  python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"
  ```

---

## 客户端问题

### Mac 系统代理设置后仍无法访问

1. 确认 Clash Verge Rev 正在运行且配置已激活
2. 检查系统代理设置中 HTTP/HTTPS/SOCKS 代理都指向 `127.0.0.1:7897`
3. 或直接在 Clash Verge Rev 设置中开启 **系统代理** 开关（自动配置）

### iPhone Streisand 连接失败

1. 确认服务器代理端口已开放（UFW）
2. 重新复制 VLESS 链接导入
3. 确认链接中的参数完整（server、port、uuid、pbk、sni、sid）
4. 尝试切换到其他网络环境测试（如 4G）

---

## 服务器管理

### 重启 3X-UI

```bash
x-ui restart
```

### 查看 3X-UI 状态

```bash
x-ui status
```

### 查看端口监听

```bash
ss -tlnp
```

### 查看防火墙规则

```bash
ufw status verbose
```

### 修改面板设置

```bash
# 修改端口
/usr/local/x-ui/x-ui setting -webPort 新端口

# 修改路径
/usr/local/x-ui/x-ui setting -webBasePath "/新路径"

# 修改用户名密码
/usr/local/x-ui/x-ui setting -username 新用户名 -password 新密码

# 应用更改
x-ui restart
```

### 更换 IP

如果当前 IP 被特定服务屏蔽：
1. Vultr 后台销毁当前服务器
2. 重新创建（会分配新 IP）
3. 重新执行部署脚本
