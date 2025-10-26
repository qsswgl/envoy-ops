# 腾讯云开放 UDP 443 安全组配置指南

## 🎯 目标
为腾讯云服务器 tx.qsgl.net (43.138.35.183) 开放 UDP 443 端口，以支持 HTTP/3 QUIC 协议。

---

## 📋 操作步骤

### 方法 1: 通过腾讯云控制台（推荐）

#### 1. 登录腾讯云控制台
- 访问：https://console.cloud.tencent.com/
- 进入**云服务器 CVM** 控制台

#### 2. 找到目标服务器
- 服务器名称：tx.qsgl.net
- 实例 ID：（在实例列表中查找 43.138.35.183）
- 区域：（根据实际选择）

#### 3. 进入安全组配置
1. 点击实例 ID 进入详情页
2. 切换到**安全组**标签
3. 点击关联的安全组（通常显示规则数量）
4. 点击**修改规则** → **入站规则**

#### 4. 添加 UDP 443 规则
点击**添加规则**，填写以下信息：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| 类型 | 自定义 | 或选择"HTTPS (UDP)" |
| 来源 | 0.0.0.0/0 | 允许所有来源（公网访问） |
| 协议端口 | UDP:443 | HTTP/3 QUIC 端口 |
| 策略 | 允许 | 放行流量 |
| 备注 | HTTP/3 QUIC | 方便后续识别 |

#### 5. 保存并验证
- 点击**完成**保存规则
- 等待 1-2 分钟生效
- 使用测试命令验证

---

### 方法 2: 通过 CLI（高级用户）

#### 安装腾讯云 CLI
```bash
pip install tccli
tccli configure
```

#### 查看当前安全组
```bash
# 查询实例关联的安全组
tccli cvm DescribeInstancesSecurityGroups \
  --InstanceIds '["实例ID"]'

# 查看安全组规则
tccli vpc DescribeSecurityGroupPolicies \
  --SecurityGroupId sg-xxxxxxxx
```

#### 添加 UDP 443 规则
```bash
tccli vpc CreateSecurityGroupPolicies \
  --SecurityGroupId sg-xxxxxxxx \
  --SecurityGroupPolicySet '{
    "Ingress": [{
      "Protocol": "UDP",
      "Port": "443",
      "CidrBlock": "0.0.0.0/0",
      "Action": "ACCEPT",
      "PolicyDescription": "HTTP/3 QUIC"
    }]
  }'
```

---

## ✅ 验证方法

### 1. 服务器端监控（SSH 登录后执行）
```bash
# 监听 UDP 443 流量（等待外部连接）
tcpdump -i any -n 'udp port 443' -c 10

# 应该能看到来自外部的 UDP 数据包
# 示例输出：
# 14:30:15.123456 IP 1.2.3.4.12345 > 43.138.35.183.443: UDP, length 1200
```

### 2. 客户端测试（本地 Windows 执行）
```powershell
# 使用 PowerShell 测试 UDP 连通性
Test-NetConnection -ComputerName tx.qsgl.net -Port 443 -InformationLevel Detailed

# 或使用 HTTP/3 客户端
docker run --rm ymuski/curl-http3 curl -I --http3-only https://tx.qsgl.net/
```

### 3. 在线测试工具
访问以下网址进行自动化测试：
- https://http3check.net/?host=tx.qsgl.net
- 应显示 ✅ HTTP/3 supported

### 4. 浏览器测试（Chrome/Edge）
1. 打开 Chrome 浏览器（版本 102+）
2. 启用 HTTP/3：
   ```
   chrome://flags/#enable-quic
   设置为 Enabled，重启浏览器
   ```
3. 访问 https://tx.qsgl.net/
4. 检查连接协议：
   ```
   chrome://net-internals/#http3
   ```
5. 查看是否显示活动的 QUIC 会话

---

## 🔍 故障排查

### 问题 1: 规则添加后仍无法连接
**可能原因**:
- 规则未生效（等待 2-5 分钟）
- 错误地添加到了出站规则（应该是入站规则）
- 服务器内部防火墙拦截

**解决方案**:
```bash
# 检查服务器内部防火墙
iptables -L INPUT -n | grep 443
firewall-cmd --list-all

# 临时关闭防火墙测试（生产环境慎用）
systemctl stop firewalld
```

### 问题 2: 安全组中没有找到相关设置
**可能原因**:
- 使用的是轻量应用服务器（Lighthouse）而非 CVM
- 安全组被删除或未关联

**解决方案**:
- Lighthouse 用户需要在**防火墙**设置中配置
- 检查实例详情 → 安全组 → 重新关联

### 问题 3: UDP 443 与 TCP 443 冲突
**回答**: 不会冲突
- UDP 和 TCP 是独立的传输层协议
- 可以同时监听相同端口号
- HTTP/3 使用 UDP 443，HTTP/2 使用 TCP 443

---

## 📊 安全组规则示例

### 完整的 HTTPS 相关规则
```
入站规则：
┌─────────┬──────────┬──────┬───────────┬────────────────────┐
│ 类型    │ 协议端口 │ 来源 │ 策略      │ 备注               │
├─────────┼──────────┼──────┼───────────┼────────────────────┤
│ HTTPS   │ TCP:443  │ ALL  │ 允许      │ HTTP/1.1, HTTP/2   │
│ 自定义  │ UDP:443  │ ALL  │ 允许      │ HTTP/3 QUIC        │
│ HTTP    │ TCP:80   │ ALL  │ 允许      │ HTTP 重定向        │
│ SSH     │ TCP:22   │ ALL  │ 允许      │ 远程管理           │
└─────────┴──────────┴──────┴───────────┴────────────────────┘
```

---

## 🎯 验证成功的标志

### Envoy Admin 统计（服务器端）
```bash
curl http://127.0.0.1:9901/stats | grep http3

# 成功后应看到：
http.ingress_http3_qsgl_net_443.downstream_cx_http3_total: 5  # > 0 表示有连接
http.ingress_http3_qsgl_net_443.downstream_rq_http3_total: 10 # > 0 表示有请求
```

### tcpdump 抓包（服务器端）
```bash
tcpdump -i any -n 'udp port 443' -A

# 成功后应看到：
# - QUIC 握手包（包含 TLS Client Hello）
# - HTTP/3 HEADERS 帧
# - QPACK 压缩的头部数据
```

### 浏览器开发者工具
```
Network 标签 → Protocol 列显示 "h3" 或 "http/3"
而不是 "h2" (HTTP/2) 或 "http/1.1"
```

---

## 📝 注意事项

### 1. 安全性考虑
- UDP 443 开放给全球（0.0.0.0/0）是安全的
- HTTP/3 本身有 TLS 1.3 加密保护
- 不会引入额外的安全风险

### 2. 兼容性
- 不支持 HTTP/3 的客户端会自动回退到 HTTP/2
- Envoy 同时监听 TCP 443 和 UDP 443，自动协商最佳协议

### 3. 性能影响
- UDP 流量通常比 TCP 更节省带宽
- 防火墙对 UDP 的处理性能较好
- 不会影响现有 HTTP/2 连接

---

## 🔗 相关链接

- **腾讯云安全组文档**: https://cloud.tencent.com/document/product/213/12452
- **HTTP/3 协议规范**: https://datatracker.ietf.org/doc/html/rfc9114
- **QUIC 协议规范**: https://datatracker.ietf.org/doc/html/rfc9000
- **在线测试工具**: https://http3check.net/

---

## 📞 技术支持

遇到问题时的检查清单：
- [ ] 安全组规则已添加（协议 UDP，端口 443）
- [ ] 规则策略设置为"允许"
- [ ] 规则已关联到正确的实例
- [ ] 等待 2-5 分钟使规则生效
- [ ] 服务器 Envoy 容器正常运行
- [ ] UDP 443 端口在服务器上监听（netstat -ulnp | grep 443）

---

**最后更新**: 2025-10-25  
**状态**: ⏸️ 等待安全组配置  
**下一步**: 配置完成后使用 Chrome 测试 HTTP/3 连接
