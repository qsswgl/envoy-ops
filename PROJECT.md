# Envoy 容器运维配置项目

## 📦 项目概述

本项目为阿里云服务器上运行的 Envoy 代理容器提供完整的运维解决方案，包括：
- ✅ 容器自动重启策略
- ✅ 健康检查配置
- ✅ 自动化监控告警（每5分钟检查）
- ✅ 邮件告警推送
- ✅ 自动诊断脚本
- ✅ Docker Compose 管理
- ✅ 完整故障排查文档

## 🎯 功能特性

### 1. 自动重启和健康检查
- 容器异常自动重启
- 开机自动启动
- 每30秒健康检查
- 失败3次后标记为不健康

### 2. 监控告警系统
- 每5分钟自动检查服务状态
- 检测容器运行状态、健康状态、端口监听
- 异常时自动发送邮件到 qsoft@139.com
- 防止重复告警

### 3. 诊断工具
- 一键全面诊断容器状态
- 检查网络、端口、资源使用
- 查看最近日志和错误
- 10大诊断项目

### 4. 完整文档
- 详细故障排查流程
- 常用运维命令
- 部署更新指南
- FAQ 常见问题

## 📁 文件说明

| 文件 | 说明 | 用途 |
|------|------|------|
| `docker-compose.yml` | Docker Compose 配置 | 定义容器配置、重启策略、健康检查 |
| `diagnose.sh` | 诊断脚本 | 全面检查容器状态和服务健康 |
| `monitor.sh` | 监控告警脚本 | 定时检查并发送告警邮件 |
| `deploy.sh` | 自动部署脚本 | 一键完成所有部署配置 |
| `README.md` | 运维文档 | 详细的故障排查和操作指南 |
| `DEPLOY.md` | 部署指南 | 快速部署步骤说明 |
| `upload.ps1` | Windows 上传脚本 | 一键上传所有文件到服务器 |
| `项目需求` | 需求文档 | 原始需求记录 |

## 🚀 快速开始

### Windows 本地操作

#### 方法1: 使用 PowerShell 脚本（推荐）

```powershell
# 在 PowerShell 中执行
cd K:\Envoy
.\upload.ps1
```

脚本会自动：
- ✅ 检查所有文件
- ✅ 上传到服务器
- ✅ 提供下一步操作指引
- ✅ 可选直接登录服务器

#### 方法2: 手动上传

```powershell
cd K:\Envoy

scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" docker-compose.yml root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" diagnose.sh root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" monitor.sh root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" deploy.sh root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" README.md root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" DEPLOY.md root@www.qsgl.cn:/root/envoy/
```

### 服务器端操作

```bash
# 1. 登录服务器
ssh -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" root@www.qsgl.cn

# 2. 运行自动部署（推荐）
cd /root/envoy
chmod +x deploy.sh
bash deploy.sh

# 3. 或手动部署（详见 DEPLOY.md）
```

## 📋 部署检查清单

部署完成后，请确认：

- [ ] 容器运行状态正常: `docker ps | grep envoy-proxy`
- [ ] 健康检查通过: `docker inspect --format='{{.State.Health.Status}}' envoy-proxy`
- [ ] 端口正常监听: `netstat -tuln | grep -E ':(80|443|9901) '`
- [ ] Envoy 接口响应: `curl http://localhost:9901/ready`
- [ ] crontab 已配置: `crontab -l | grep monitor`
- [ ] 监控日志正常: `tail /var/log/envoy-monitor.log`
- [ ] 邮件工具已安装: `which sendemail` 或 `which python3`

## 🔧 配置详情

### 服务器信息
- **地址**: www.qsgl.cn
- **账号**: root
- **私钥**: C:\Key\www.qsgl.cn_id_ed25519
- **容器名**: envoy-proxy

### 监控配置
- **检查频率**: 每5分钟
- **告警邮箱**: qsoft@139.com
- **SMTP服务器**: smtp.139.com:465
- **授权码**: 574a283d502db51ea200

### 容器配置
- **镜像**: 43.138.35.183:5000/envoy:envoy-v1.31-custom
- **重启策略**: unless-stopped
- **健康检查**: 每30秒检查 /ready 接口
- **日志限制**: 3个文件 x 100MB

## 📊 监控项目

监控脚本会检查：
1. ✅ 容器是否存在
2. ✅ 容器运行状态
3. ✅ 健康检查状态
4. ✅ Envoy 就绪接口 (9901/ready)
5. ✅ 端口监听状态 (80, 443)
6. ✅ 重启次数异常

发现异常时自动发送邮件告警，包含：
- 异常详情
- 检测时间
- 建议操作

## 🛠️ 常用命令

```bash
# 查看容器状态
docker ps | grep envoy

# 查看日志
docker logs -f envoy-proxy

# 运行诊断
bash /root/envoy/diagnose.sh

# 查看监控日志
tail -f /var/log/envoy-monitor.log

# 重启服务
cd /root/envoy && docker-compose restart

# 手动监控检查
bash /root/envoy/monitor.sh
```

## 📖 文档导航

- **快速部署**: 查看 `DEPLOY.md`
- **运维指南**: 查看 `README.md`
- **故障排查**: 查看 `README.md` 第三章
- **配置说明**: 查看 `README.md` 第一章

## ⚙️ 技术栈

- Docker & Docker Compose
- Envoy Proxy v1.31
- Shell Script (Bash)
- Cron (定时任务)
- Email (SMTP 告警)
- Linux (CentOS/Ubuntu)

## 📝 维护说明

### 定期维护
1. 检查监控日志: `tail -100 /var/log/envoy-monitor.log`
2. 清理旧日志: 配置 logrotate
3. 更新镜像: `docker pull 43.138.35.183:5000/envoy:envoy-v1.31-custom`
4. 备份配置: `tar -czf envoy-backup.tar.gz /root/envoy`

### 日志位置
- 监控日志: `/var/log/envoy-monitor.log`
- 容器日志: `docker logs envoy-proxy`
- cron 日志: `/var/log/cron` (CentOS) 或 `/var/log/syslog` (Ubuntu)

## 🔒 安全建议

1. ✅ 私钥文件权限设置为 600
2. ✅ 不要将私钥提交到版本控制
3. ✅ 定期更新容器镜像
4. ✅ 限制容器资源使用
5. ✅ 定期检查日志异常

## 📞 支持

遇到问题时：
1. 运行诊断: `bash /root/envoy/diagnose.sh`
2. 查看日志: `docker logs envoy-proxy`
3. 检查监控: `tail /var/log/envoy-monitor.log`
4. 参考文档: `README.md`

## 📅 版本历史

- **v1.0** (2025-10-24)
  - ✅ 初始版本
  - ✅ Docker Compose 配置
  - ✅ 自动重启和健康检查
  - ✅ 监控告警系统
  - ✅ 诊断脚本
  - ✅ 完整文档

## 📄 许可

内部运维项目

---

**维护者**: 运维团队  
**联系邮箱**: qsoft@139.com  
**最后更新**: 2025-10-24
