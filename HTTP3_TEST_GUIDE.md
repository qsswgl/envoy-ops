# 腾讯云 HTTP/3 (QUIC) 完整测试指南

## 🎯 测试目标

验证腾讯云服务器 (tx.qsgl.net / 43.138.35.183) 的 HTTP/3 (QUIC) 是否正常工作。

## 📋 前置检查清单

在开始测试前，确保以下配置正确：

### 1. 服务器端检查

```bash
# SSH 登录腾讯云
ssh tx.qsgl.net

# 1. 检查 UDP 443 端口监听
netstat -uln | grep 443
# 应该看到: udp 0.0.0.0:443 0.0.0.0:*

# 2. 检查容器运行状态
docker ps | grep envoy
# 应该看到: envoy-proxy, Up, contrib-v1.36.2

# 3. 检查 Envoy 版本（必须是 contrib）
docker logs envoy-proxy 2>&1 | head -20 | grep version
# 应该包含: contrib, BoringSSL

# 4. 查看 QUIC 统计
curl -s http://127.0.0.1:9901/stats | grep -E "quic|http3"
# 关键指标:
# - listener.0.0.0.0_443.http3_downstream_rx_quic_connection_close_error_code_QUIC_NO_ERROR
# - cluster.backend_https_cluster_443.upstream_cx_http3_total
```

### 2. 腾讯云安全组检查

登录 [腾讯云控制台](https://console.cloud.tencent.com/cvm/securitygroup):
- ✅ UDP 443 入站规则：允许所有来源
- ✅ TCP 443 入站规则：允许所有来源

## 🧪 测试方法

### 方法 1: 使用 curl 命令行测试 (推荐)

#### Windows (PowerShell)

```powershell
# 需要 curl 7.66+ 版本
curl.exe --version

# 测试 HTTP/3
curl.exe --http3 -Ik https://tx.qsgl.net

# 期望输出:
# HTTP/3 200
# alt-svc: h3=":443"
# server: envoy
```

如果提示不支持 HTTP/3：
```powershell
# 下载最新版 curl (Windows)
# https://curl.se/windows/
# 或使用 scoop 安装
scoop install curl
```

#### Linux/Mac

```bash
# 检查 curl 是否支持 HTTP/3
curl --version | grep HTTP3

# 如果不支持，需要重新编译 curl 或使用其他工具

# 测试 HTTP/3
curl --http3 -Ik https://tx.qsgl.net

# 详细输出
curl --http3 -v https://tx.qsgl.net 2>&1 | grep -E "QUIC|HTTP/3|h3"
```

### 方法 2: 使用 Chrome 浏览器测试 (最直观)

#### 步骤 1: 启用 QUIC

1. 打开 Chrome 浏览器
2. 地址栏输入: `chrome://flags/#enable-quic`
3. 设置为 **Enabled**
4. 重启浏览器

#### 步骤 2: 访问网站

访问: `https://tx.qsgl.net`

#### 步骤 3: 检查协议

**方法 A: 使用开发者工具**
1. 按 `F12` 打开开发者工具
2. 切换到 **Network** 标签
3. 刷新页面 (`F5`)
4. 查看请求列表
5. 右键列表标题栏 → 勾选 **Protocol**
6. 查看 Protocol 列：
   - ✅ `h3` 或 `h3-29` = HTTP/3 成功
   - ❌ `h2` = 仅使用 HTTP/2
   - ❌ `http/1.1` = 降级到 HTTP/1.1

**方法 B: 使用 Chrome 内部工具**
1. 访问: `chrome://net-internals/#http2`
2. 查看 **QUIC sessions** 或 **HTTP/3 sessions**
3. 应该能看到 `tx.qsgl.net:443` 的 QUIC 连接

#### 步骤 4: 查看详细信息

访问: `chrome://net-internals/#quic`
- 查看 **Active sessions**
- 应该显示到 `43.138.35.183:443` 的 QUIC 连接

### 方法 3: 使用在线测试工具

#### HTTP/3 Check
访问: https://http3check.net/?host=tx.qsgl.net

期望结果:
- ✅ HTTP/3: Supported
- ✅ QUIC: Yes
- ✅ Port 443 UDP: Open

#### Geekflare HTTP/3 Test
访问: https://geekkflare.com/tools/http3-test

输入: `tx.qsgl.net`

期望结果:
- ✅ HTTP/3 is supported

### 方法 4: 使用专业工具测试

#### 使用 h3spec (HTTP/3 规范测试)

```bash
# 安装 h3spec
# https://github.com/kazu-yamamoto/h3spec

# 运行测试
h3spec --host tx.qsgl.net --port 443
```

#### 使用 quiche 客户端

```bash
# https://github.com/cloudflare/quiche

# 克隆仓库
git clone --recursive https://github.com/cloudflare/quiche
cd quiche

# 编译
cargo build --release --examples

# 测试 HTTP/3
./target/release/examples/http3-client https://tx.qsgl.net
```

### 方法 5: 使用 PowerShell 脚本自动测试

创建文件 `test_http3.ps1`:

```powershell
# HTTP/3 自动测试脚本
$domain = "tx.qsgl.net"
$ip = "43.138.35.183"

Write-Host "`n=== 腾讯云 HTTP/3 测试 ===" -ForegroundColor Green

# 1. 测试 UDP 443 端口
Write-Host "`n[1] 测试 UDP 443 端口..." -ForegroundColor Yellow
Test-NetConnection -ComputerName $ip -Port 443
if ($?) {
    Write-Host "✅ TCP 443 端口可达" -ForegroundColor Green
} else {
    Write-Host "❌ TCP 443 端口不可达" -ForegroundColor Red
}

# 2. 测试 HTTPS
Write-Host "`n[2] 测试 HTTPS 连接..." -ForegroundColor Yellow
curl.exe -Ik https://$domain | Select-String -Pattern "HTTP|server|alt-svc"

# 3. 测试 HTTP/3
Write-Host "`n[3] 测试 HTTP/3 连接..." -ForegroundColor Yellow
$http3Test = curl.exe --http3 -Ik https://$domain 2>&1
if ($http3Test -match "HTTP/3") {
    Write-Host "✅ HTTP/3 支持正常！" -ForegroundColor Green
    $http3Test | Select-String -Pattern "HTTP|alt-svc|server"
} else {
    Write-Host "❌ HTTP/3 不支持或 curl 版本过低" -ForegroundColor Red
    Write-Host "提示: 需要 curl 7.66+ 版本" -ForegroundColor Yellow
}

# 4. SSH 检查服务器状态
Write-Host "`n[4] 检查服务器 QUIC 统计..." -ForegroundColor Yellow
ssh tx.qsgl.net "curl -s http://127.0.0.1:9901/stats | grep -E 'http3|quic' | head -10"

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
```

运行:
```powershell
.\test_http3.ps1
```

## 📊 判断标准

### ✅ HTTP/3 工作正常的标志

1. **curl 测试**:
   ```
   HTTP/3 200
   alt-svc: h3=":443"
   ```

2. **Chrome 开发者工具**:
   - Protocol 列显示 `h3`

3. **服务器统计**:
   ```bash
   curl -s http://127.0.0.1:9901/stats | grep http3
   # 应该看到非零值:
   listener.0.0.0.0_443.http3.downstream.rx.quic_connection_close_error_code.QUIC_NO_ERROR: N
   ```

4. **在线测试**:
   - HTTP/3 Check 显示 "Supported"

### ❌ HTTP/3 不工作的标志

1. **curl 测试**:
   ```
   HTTP/2 200  # 降级到 HTTP/2
   或
   curl: (56) Failure when receiving data from the peer
   ```

2. **Chrome 开发者工具**:
   - Protocol 列显示 `h2` 或 `http/1.1`

3. **服务器统计**:
   ```bash
   # 所有 http3 计数器都是 0
   ```

4. **UDP 端口不通**:
   ```bash
   netstat -uln | grep 443
   # 没有输出
   ```

## 🔍 常见问题排查

### 问题 1: curl 不支持 HTTP/3

**症状**: `curl: option --http3: is unknown`

**解决方案**:
```powershell
# Windows - 使用 scoop 安装最新 curl
scoop install curl

# 或下载预编译版本
# https://curl.se/windows/

# Linux - 从源码编译
git clone https://github.com/curl/curl.git
cd curl
./buildconf
./configure --with-openssl --enable-alt-svc
make
sudo make install
```

### 问题 2: Chrome 仍使用 HTTP/2

**可能原因**:
1. QUIC 未启用 → 检查 `chrome://flags/#enable-quic`
2. 之前的连接缓存 → 清除浏览器缓存
3. 防火墙/VPN 阻止 UDP → 检查网络环境

**解决方案**:
```
1. chrome://flags/#enable-quic → Enabled
2. chrome://net-internals/#sockets → Flush socket pools
3. 重启浏览器
4. 关闭 VPN 测试
```

### 问题 3: 在线测试显示不支持

**检查步骤**:
```bash
# 1. SSH 登录服务器
ssh tx.qsgl.net

# 2. 检查 UDP 端口
netstat -uln | grep 443

# 3. 检查容器日志
docker logs envoy-proxy --tail 50 | grep -i "quic\|http3\|error"

# 4. 检查 Envoy 配置
docker exec envoy-proxy cat /etc/envoy/envoy.yaml | grep -A 10 "quic"

# 5. 查看连接统计
curl http://127.0.0.1:9901/stats | grep -E "listener.*443.*quic"
```

### 问题 4: 本地测试成功，外部失败

**可能原因**: 腾讯云安全组未开放 UDP 443

**解决方案**:
1. 登录腾讯云控制台
2. 云服务器 → 安全组
3. 入站规则 → 添加规则
   - 类型: 自定义
   - 协议: **UDP**
   - 端口: 443
   - 来源: 0.0.0.0/0
4. 保存并应用

## 📈 性能对比测试

### 测试脚本

```bash
#!/bin/bash
# 对比 HTTP/2 和 HTTP/3 性能

echo "=== HTTP/2 性能测试 ==="
time curl -Iks https://tx.qsgl.net -o /dev/null

echo -e "\n=== HTTP/3 性能测试 ==="
time curl --http3 -Iks https://tx.qsgl.net -o /dev/null

echo -e "\n=== 多次请求测试 ==="
echo "HTTP/2:"
for i in {1..10}; do
  curl -Iks https://tx.qsgl.net -o /dev/null -w "%{time_total}s\n"
done | awk '{sum+=$1; count++} END {print "平均:", sum/count, "秒"}'

echo "HTTP/3:"
for i in {1..10}; do
  curl --http3 -Iks https://tx.qsgl.net -o /dev/null -w "%{time_total}s\n"
done | awk '{sum+=$1; count++} END {print "平均:", sum/count, "秒"}'
```

## 📝 测试报告模板

```markdown
# HTTP/3 测试报告

**测试时间**: 2025-10-26
**测试域名**: tx.qsgl.net
**测试IP**: 43.138.35.183

## 测试结果

### 1. curl 命令行测试
- [ ] HTTP/3 200 响应
- [ ] alt-svc 头存在
- [ ] 服务器标识: envoy

### 2. Chrome 浏览器测试
- [ ] Protocol 显示 h3
- [ ] chrome://net-internals/#quic 显示活动会话
- [ ] 页面加载正常

### 3. 服务器端检查
- [ ] UDP 443 端口监听
- [ ] QUIC 统计计数器非零
- [ ] 容器使用 contrib 版本

### 4. 在线工具测试
- [ ] HTTP/3 Check: Supported
- [ ] Geekflare: HTTP/3 is supported

## 性能对比
- HTTP/2 平均延迟: ___ms
- HTTP/3 平均延迟: ___ms
- 性能提升: ___%

## 问题记录
1. 
2. 

## 结论
- [ ] HTTP/3 工作正常
- [ ] HTTP/3 不工作，原因: _______
```

## 🎯 快速测试命令总结

```bash
# 服务器端快速检查
ssh tx.qsgl.net "netstat -uln | grep 443 && curl -s http://127.0.0.1:9901/stats | grep http3 | head -5"

# 客户端快速测试
curl --http3 -Ik https://tx.qsgl.net | head -5

# Windows PowerShell 一键测试
curl.exe --http3 -Ik https://tx.qsgl.net; ssh tx.qsgl.net "netstat -uln | grep 443"
```

## 📞 需要帮助？

如果测试过程中遇到问题：
1. 查看完整日志: `docker logs envoy-proxy --tail 100`
2. 检查配置: `tx_envoy_v1.36.2_http3.yaml`
3. 参考文档: `TX_HTTP3_SUCCESS_REPORT.md`
4. GitHub Issues: https://github.com/qsswgl/envoy-ops/issues

---
**最后更新**: 2025-10-26  
**适用版本**: Envoy v1.36.2 contrib
