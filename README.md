# Envoy 容器运维自动化配置

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Docker](https://img.shields.io/badge/docker-20.10+-blue.svg)](https://www.docker.com/)

> 为阿里云服务器上的 Envoy 代理容器提供完整的运维自动化解决方案

## 📋 项目概述

本项目为运行在阿里云服务器上的 Envoy 代理容器提供了一套完整的运维自动化配置方案，包括：

- ✅ **自动重启策略** - 容器异常时自动恢复
- ✅ **监控告警系统** - 每5分钟自动检查，异常邮件告警
- ✅ **自动诊断工具** - 10项全面健康检查
- ✅ **完整运维文档** - 详细的操作手册和故障排查指南
- ✅ **健康检查配置** - 实时监控服务状态
- ✅ **Docker Compose** - 标准化容器管理

## 🎯 主要功能

### 1. 自动监控告警
- **检查频率**: 每5分钟
- **监控项目**: 容器状态、端口监听、Envoy接口、重启次数
- **告警方式**: 邮件通知
- **防重复**: 同一问题只告警一次，恢复后重新监控

### 2. 诊断工具
提供10项全面诊断检查：
- 容器存在性和运行状态
- 健康检查状态
- 端口映射和监听状态
- Envoy 管理接口响应
- 资源使用情况
- 日志分析
- 重启次数统计
- 错误检测

### 3. 自动化部署
- 一键部署脚本
- Docker Compose 配置
- 自动权限设置
- 服务验证

## 📁 项目结构

```
.
├── docker-compose.yml      # Docker Compose 配置文件
├── diagnose.sh            # 自动诊断脚本
├── monitor.sh             # 监控告警脚本
├── deploy.sh              # 自动部署脚本
├── upload.ps1             # Windows 上传工具
├── README.md              # 完整运维文档（11KB）
├── DEPLOY.md              # 部署指南
├── PROJECT.md             # 项目说明
├── TROUBLESHOOTING.md     # 故障排查手册
├── 快速参考.md             # 快速参考卡片
├── 部署总结.md             # 部署总结报告
├── 项目完成报告.md         # 完成报告
└── 项目需求                # 原始需求文档
```

## 🚀 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Linux 服务器（CentOS/Ubuntu）
- SMTP 邮件服务（用于告警）

### 安装步骤

#### 1. 上传文件到服务器

**从 Windows 上传**:
```powershell
# 使用提供的上传脚本
.\upload.ps1

# 或手动上传
scp -i "C:\Key\www.qsgl.cn_id_ed25519" *.sh *.yml *.md root@www.qsgl.cn:/root/envoy/
```

**从 Linux/Mac 上传**:
```bash
scp *.sh *.yml *.md root@your-server.com:/root/envoy/
```

#### 2. 登录服务器

```bash
ssh root@your-server.com
cd /root/envoy
```

#### 3. 运行部署脚本

```bash
chmod +x deploy.sh
bash deploy.sh
```

部署脚本会自动：
- ✅ 检查 Docker 环境
- ✅ 安装邮件工具
- ✅ 设置脚本权限
- ✅ 启动容器
- ✅ 配置监控定时任务
- ✅ 运行验证测试

### 手动部署（可选）

如果自动部署失败，可以手动执行：

```bash
# 1. 设置权限
chmod +x diagnose.sh monitor.sh
chmod 644 /etc/envoy/*.key  # 重要！私钥权限

# 2. 启动容器
docker run -d \
  --name envoy-proxy \
  --restart unless-stopped \
  --network host \
  -v /etc/envoy:/etc/envoy \
  envoy-proxy:latest

# 3. 配置监控
crontab -e
# 添加: */5 * * * * /root/envoy/monitor.sh >> /var/log/envoy-monitor.log 2>&1

# 4. 验证
bash diagnose.sh
```

## 📊 使用说明

### 日常运维命令

```bash
# 查看容器状态
docker ps | grep envoy-proxy

# 查看实时日志
docker logs -f envoy-proxy

# 运行诊断
bash /root/envoy/diagnose.sh

# 查看监控日志
tail -f /var/log/envoy-monitor.log

# 重启服务
docker restart envoy-proxy
```

### 监控配置

监控脚本 (`monitor.sh`) 会检查：
- 容器运行状态
- Envoy 就绪接口 (9901/ready)
- 端口监听状态 (443, 9901)
- 重启次数异常（>5次）

发现问题时会发送邮件告警到配置的邮箱。

### 配置文件说明

**docker-compose.yml**:
- 容器名称、镜像、网络配置
- 重启策略：`unless-stopped`
- 卷挂载：/etc/envoy
- 健康检查配置

**monitor.sh**:
- SMTP 服务器配置
- 告警邮箱设置
- 监控检查项目

## 🔧 故障排查

### 容器无法启动

**症状**: 容器状态为 Restarting 或 Exited

**解决方案**:
```bash
# 1. 查看日志
docker logs envoy-proxy --tail 50

# 2. 检查私钥权限（最常见问题）
ls -l /etc/envoy/*.key
chmod 644 /etc/envoy/*.key

# 3. 验证配置
docker run --rm -v /etc/envoy:/etc/envoy envoy-proxy \
  envoy --mode validate -c /etc/envoy/envoy.yaml
```

### HTTPS 无法访问

```bash
# 检查端口监听
netstat -tuln | grep 443

# 检查 Envoy 状态
curl http://localhost:9901/ready

# 测试本地访问
curl -Ik https://localhost
```

### 未收到告警邮件

```bash
# 查看监控日志
tail -20 /var/log/envoy-monitor.log

# 手动运行监控
bash /root/envoy/monitor.sh

# 检查 crontab
crontab -l | grep monitor
```

更多故障排查信息请参考 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## ⚠️ 重要提醒

1. **私钥权限**: 必须设置为 644，否则容器无法启动
   ```bash
   chmod 644 /etc/envoy/*.key
   ```

2. **证书更新**: 更新 SSL 证书后需要重启容器
   ```bash
   docker restart envoy-proxy
   ```

3. **监控日志**: 定期清理监控日志文件
   ```bash
   # 配置 logrotate
   echo "/var/log/envoy-monitor.log {
       daily
       rotate 7
       compress
       missingok
   }" > /etc/logrotate.d/envoy
   ```

4. **定期备份**: 备份配置文件和证书
   ```bash
   tar -czf envoy-backup-$(date +%Y%m%d).tar.gz /etc/envoy /root/envoy
   ```

## 📚 文档

- [完整运维文档](README.md) - 详细的操作手册
- [部署指南](DEPLOY.md) - 分步部署说明
- [故障排查](TROUBLESHOOTING.md) - 常见问题解决
- [快速参考](快速参考.md) - 常用命令速查
- [部署总结](部署总结.md) - 完整部署报告

## 🎓 技术栈

- **容器**: Docker, Docker Compose
- **代理**: Envoy Proxy v1.31
- **脚本**: Bash Shell
- **定时任务**: Cron
- **监控**: 自定义 Shell 脚本
- **告警**: SMTP Email

## 📈 系统要求

- **CPU**: 1核+
- **内存**: 512MB+
- **磁盘**: 1GB+
- **网络**: 公网 IP（用于 HTTPS）

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📝 许可证

MIT License

## 📞 联系方式

- **邮箱**: qsoft@139.com
- **服务器**: www.qsgl.cn

## 🎉 致谢

感谢所有为这个项目做出贡献的人！

---

**最后更新**: 2025-10-24  
**版本**: 1.0.0  
**状态**: ✅ 生产就绪
