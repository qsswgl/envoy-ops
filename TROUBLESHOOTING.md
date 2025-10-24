# Envoy 容器问题修复记录

## 问题描述

**时间**: 2025-10-24  
**症状**: Envoy 容器无法启动，不断重启  
**错误**: `Failed to load incomplete private key from path: /etc/envoy/www.qsgl.cn.key`

## 根本原因

**权限问题**: 私钥文件权限设置为 600 (仅 root 可读)，但 Envoy 容器内进程以非 root 用户运行，导致无法读取私钥文件。

## 解决方案

### 1. 修改私钥文件权限

```bash
chmod 644 /etc/envoy/*.key
```

**说明**: 将私钥文件权限从 600 改为 644，允许所有用户读取。

### 2. 使用正确的镜像

原来正常工作的镜像是：`envoy-proxy:latest` (本地构建镜像)  
而不是：`43.138.35.183:5000/envoy:envoy-v1.31-custom`

### 3. 使用 host 网络模式

```yaml
network_mode: host
```

**原因**: 
- 简化端口配置
- 避免端口映射问题
- 与原容器配置保持一致

## 修复步骤

```bash
# 1. 停止并删除问题容器
docker stop envoy-proxy && docker rm envoy-proxy

# 2. 修改私钥文件权限
chmod 644 /etc/envoy/*.key

# 3. 使用正确配置启动容器
docker run -d \
  --name envoy-proxy \
  --restart unless-stopped \
  --network host \
  -v /etc/envoy:/etc/envoy:ro \
  envoy-proxy:latest
```

## 验证

```bash
# 检查容器状态
docker ps | grep envoy

# 检查服务健康
curl -s http://localhost:9901/ready
# 应返回: LIVE

# 测试 HTTPS 服务
curl -I https://www.qsgl.cn
# 应返回: HTTP/2 200
```

## 相关文件

- 配置文件：`/etc/envoy/envoy.yaml`
- 证书文件：`/etc/envoy/www.qsgl.cn.pem`
- 私钥文件：`/etc/envoy/www.qsgl.cn.key` (权限: 644)
- Docker Compose：`/root/envoy/docker-compose.yml`

## 镜像信息

```bash
docker images | grep envoy
```

可用镜像：
- `envoy-proxy:latest` - 本地构建，**正常工作** ✓
- `43.138.35.183:5000/envoy:envoy-v1.31-custom` - 自定义镜像，权限问题 ✗
- `envoyproxy/envoy:v1.35.3` - 官方镜像

## 教训总结

1. **权限问题很关键**: 
   - 容器内进程通常以非 root 用户运行
   - 挂载的文件必须有适当的读取权限
   - 私钥文件 600 权限在容器环境中会导致问题

2. **镜像选择**:
   - 确认原来使用的镜像版本
   - 不同镜像可能有不同的用户权限设置

3. **网络模式**:
   - host 模式简化了端口管理
   - 但失去了网络隔离

4. **诊断方法**:
   - 查看容器日志：`docker logs`
   - 测试文件权限：`docker run --rm -v ... cat file`
   - 逐步排除问题

## 监控建议

部署后应配置：
- 每5分钟自动监控
- 邮件告警到 qsoft@139.com
- 详见 `/root/envoy/monitor.sh`

## 参考

- Docker Compose 配置：`/root/envoy/docker-compose.yml`
- 诊断脚本：`/root/envoy/diagnose.sh`
- 监控脚本：`/root/envoy/monitor.sh`
- 完整文档：`/root/envoy/README.md`
