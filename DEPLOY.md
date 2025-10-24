# Envoy 容器运维部署指南

## 📋 部署清单

本项目包含以下文件：
- `docker-compose.yml` - Docker Compose 配置（含自动重启和健康检查）
- `diagnose.sh` - 容器诊断脚本
- `monitor.sh` - 监控告警脚本（每5分钟检查，邮件告警）
- `deploy.sh` - 自动化部署脚本
- `README.md` - 完整运维文档

## 🚀 快速部署步骤

### 步骤 1: 上传文件到服务器

**在本地 Windows PowerShell 中执行：**

```powershell
# 进入项目目录
cd K:\Envoy

# 上传所有文件
scp -i "C:\Key\www.qsgl.cn_id_ed25519" docker-compose.yml root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_id_ed25519" diagnose.sh root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_id_ed25519" monitor.sh root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_id_ed25519" deploy.sh root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_id_ed25519" README.md root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_id_ed25519" DEPLOY.md root@www.qsgl.cn:/root/envoy/
```

### 步骤 2: 登录服务器

```powershell
ssh -i "C:\Key\www.qsgl.cn_id_ed25519" root@www.qsgl.cn
```

### 步骤 3: 运行部署脚本

```bash
cd /root/envoy
chmod +x deploy.sh
bash deploy.sh
```

部署脚本会自动完成：
- ✅ 检查 Docker 和 Docker Compose
- ✅ 安装邮件发送工具
- ✅ 设置脚本权限
- ✅ 停止现有容器
- ✅ 使用 Docker Compose 启动服务
- ✅ 配置 crontab 定时监控
- ✅ 运行验证测试

## 📝 手动部署（如果自动部署失败）

### 1. 安装邮件工具

```bash
# CentOS/RHEL
yum install -y sendemail

# Ubuntu/Debian
apt-get update && apt-get install -y sendemail
```

### 2. 设置脚本权限

```bash
cd /root/envoy
chmod +x diagnose.sh monitor.sh deploy.sh
```

### 3. 停止现有容器

```bash
docker stop envoy-proxy
```

### 4. 启动服务

```bash
cd /root/envoy
docker-compose up -d
```

### 5. 验证服务

```bash
# 查看容器状态
docker-compose ps

# 运行诊断
bash /root/envoy/diagnose.sh
```

### 6. 配置监控定时任务

```bash
# 编辑 crontab
crontab -e

# 添加以下内容（每5分钟检查一次）
*/5 * * * * /root/envoy/monitor.sh >> /var/log/envoy-monitor.log 2>&1
```

### 7. 测试监控

```bash
# 手动运行监控脚本
bash /root/envoy/monitor.sh

# 查看日志
tail -f /var/log/envoy-monitor.log
```

## ✅ 部署验证

### 检查容器状态

```bash
docker ps | grep envoy-proxy
```

应该看到容器状态为 `Up`。

### 检查健康状态

```bash
docker inspect --format='{{.State.Health.Status}}' envoy-proxy
```

等待约40秒后，应该显示 `healthy`。

### 检查端口监听

```bash
netstat -tuln | grep -E ':(80|443|9901) '
# 或
ss -tuln | grep -E ':(80|443|9901) '
```

应该看到端口 80, 443, 9901 等在监听。

### 测试 Envoy 管理接口

```bash
curl http://localhost:9901/ready
```

应该返回 `LIVE`。

### 查看监控日志

```bash
tail -20 /var/log/envoy-monitor.log
```

应该看到监控检查记录。

## 📊 配置说明

### Docker Compose 配置亮点

- **重启策略**: `unless-stopped` - 开机自启，异常自动重启
- **健康检查**: 每30秒检查 Envoy 就绪状态
- **日志轮转**: 最多3个文件，每个100MB
- **资源限制**: CPU 2核，内存 2GB（可调整）

### 监控告警功能

- **检查频率**: 每5分钟
- **监控项目**:
  - 容器运行状态
  - 健康检查状态
  - Envoy 管理接口响应
  - 关键端口监听 (80, 443)
  - 重启次数异常
- **告警方式**: 邮件发送到 qsoft@139.com
- **防重复告警**: 同一问题只发送一次，恢复后才重新监控

### 诊断脚本功能

- 容器存在性检查
- 运行状态检查
- 健康状态检查
- 端口映射检查
- 网络连接检查
- Envoy 管理接口检查
- 资源使用情况
- 最近日志和错误

## 🔧 常用运维命令

```bash
# 查看容器日志
docker logs -f envoy-proxy

# 重启服务
cd /root/envoy && docker-compose restart

# 停止服务
cd /root/envoy && docker-compose down

# 启动服务
cd /root/envoy && docker-compose up -d

# 运行诊断
bash /root/envoy/diagnose.sh

# 查看监控日志
tail -f /var/log/envoy-monitor.log

# 手动运行监控
bash /root/envoy/monitor.sh
```

## 🔍 故障排查

如遇问题，请参考 `README.md` 中的详细故障排查流程。

常见问题：
1. **容器无法启动** → 检查日志和端口占用
2. **健康检查失败** → 等待启动时间或检查配置
3. **未收到告警** → 检查邮件工具和 crontab
4. **服务不可访问** → 检查防火墙和安全组

## 📧 监控告警

- **告警邮箱**: qsoft@139.com
- **SMTP 服务器**: smtp.139.com
- **检查间隔**: 5分钟
- **日志位置**: /var/log/envoy-monitor.log

## 📚 更多信息

详细的运维文档、故障排查流程、性能优化建议等，请查看：
- `README.md` - 完整运维文档

## ⚠️ 注意事项

1. **确保私钥安全**: 不要泄露 SSH 私钥
2. **定期备份配置**: 使用 `tar -czf envoy-backup.tar.gz /root/envoy`
3. **监控日志大小**: 定期清理 `/var/log/envoy-monitor.log`
4. **更新镜像**: 定期拉取最新镜像以获取安全更新
5. **测试告警**: 部署后测试邮件告警是否正常

## 📞 技术支持

如有问题，请查看：
1. 容器日志: `docker logs envoy-proxy`
2. 诊断报告: `bash /root/envoy/diagnose.sh`
3. 监控日志: `/var/log/envoy-monitor.log`
4. 完整文档: `README.md`

---

**版本**: 1.0  
**日期**: 2025-10-24
