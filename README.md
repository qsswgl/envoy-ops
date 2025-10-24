# Envoy 代理服务运维文档

## 服务器信息
- **服务器地址**: www.qsgl.cn
- **登录账号**: root
- **私钥文件**: `C:\Key\www.qsgl.cn_id_ed25519`
- **容器名称**: envoy-proxy
- **镜像**: 43.138.35.183:5000/envoy:envoy-v1.31-custom

## 快速登录
```bash
ssh -i "C:\Key\www.qsgl.cn_id_ed25519" root@www.qsgl.cn
```

---

## 一、配置说明

### 1.1 Docker Compose 配置
文件位置: `/root/envoy/docker-compose.yml`

**主要配置项**:
- **重启策略**: `unless-stopped` - 除非手动停止，否则自动重启
- **健康检查**: 每30秒检查一次 Envoy 就绪接口 (9901/ready)
- **日志管理**: 最多保留3个日志文件，每个最大100MB
- **端口映射**: 80, 443, 8443, 99, 5002, 9901, 30000

### 1.2 监控告警配置
- **监控脚本**: `/root/envoy/monitor.sh`
- **检查频率**: 每5分钟
- **告警邮箱**: qsoft@139.com
- **监控日志**: `/var/log/envoy-monitor.log`

**监控内容**:
- 容器运行状态
- 健康检查状态
- Envoy 管理接口响应
- 关键端口监听状态 (80, 443)
- 重启次数监控

### 1.3 诊断脚本
文件位置: `/root/envoy/diagnose.sh`

**检查项目**:
- 容器存在性和运行状态
- 健康状态
- 端口映射和监听
- Envoy 管理接口
- 资源使用情况
- 最近日志和错误

---

## 二、常用命令

### 2.1 容器管理
```bash
# 查看容器状态
docker ps -a | grep envoy-proxy

# 查看容器详细信息
docker inspect envoy-proxy

# 查看容器日志
docker logs envoy-proxy
docker logs -f envoy-proxy          # 实时跟踪
docker logs --tail 100 envoy-proxy  # 最近100行

# 重启容器
docker restart envoy-proxy

# 停止容器
docker stop envoy-proxy

# 启动容器
docker start envoy-proxy
```

### 2.2 Docker Compose 管理
```bash
# 进入配置目录
cd /root/envoy

# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f
```

### 2.3 诊断和监控
```bash
# 运行完整诊断
bash /root/envoy/diagnose.sh

# 手动运行监控检查
bash /root/envoy/monitor.sh

# 查看监控日志
tail -f /var/log/envoy-monitor.log

# 检查 Envoy 管理接口
curl http://localhost:9901/ready
curl http://localhost:9901/stats
curl http://localhost:9901/config_dump
```

---

## 三、故障排查流程

### 3.1 容器无法启动

**症状**: 容器状态为 Exited 或 Restarting

**排查步骤**:
1. 查看容器日志
   ```bash
   docker logs envoy-proxy --tail 200
   ```

2. 检查退出代码
   ```bash
   docker inspect --format='{{.State.ExitCode}}' envoy-proxy
   ```

3. 检查配置文件
   ```bash
   # 进入容器检查配置（如果能启动）
   docker exec -it envoy-proxy sh
   ```

4. 检查端口占用
   ```bash
   netstat -tuln | grep -E ':(80|443|9901) '
   ss -tuln | grep -E ':(80|443|9901) '
   ```

**常见解决方案**:
- 端口被占用: 停止占用端口的进程或修改端口映射
- 配置文件错误: 检查 Envoy 配置文件语法
- 镜像损坏: 重新拉取镜像
  ```bash
  docker pull 43.138.35.183:5000/envoy:envoy-v1.31-custom
  ```

### 3.2 健康检查失败

**症状**: 容器运行但健康状态为 unhealthy

**排查步骤**:
1. 手动测试健康检查命令
   ```bash
   docker exec envoy-proxy curl -f http://localhost:9901/ready
   ```

2. 检查 Envoy 进程
   ```bash
   docker exec envoy-proxy ps aux | grep envoy
   ```

3. 查看详细健康检查日志
   ```bash
   docker inspect --format='{{json .State.Health}}' envoy-proxy | python3 -m json.tool
   ```

**解决方案**:
- 增加健康检查等待时间: 修改 `docker-compose.yml` 中的 `start_period`
- 检查 Envoy 配置: 确保管理端口正确配置
- 重启容器: `docker restart envoy-proxy`

### 3.3 服务不可访问

**症状**: 外部无法访问 80/443 端口

**排查步骤**:
1. 检查容器端口映射
   ```bash
   docker port envoy-proxy
   ```

2. 检查防火墙规则
   ```bash
   # CentOS/RHEL
   firewall-cmd --list-ports
   
   # Ubuntu
   ufw status
   
   # iptables
   iptables -L -n | grep -E '(80|443)'
   ```

3. 检查阿里云安全组
   - 登录阿里云控制台
   - 检查 ECS 安全组规则
   - 确保 80/443 端口已开放

4. 测试本地连接
   ```bash
   curl -I http://localhost
   curl -Ik https://localhost
   ```

**解决方案**:
- 开放防火墙端口
  ```bash
  firewall-cmd --add-port=80/tcp --permanent
  firewall-cmd --add-port=443/tcp --permanent
  firewall-cmd --reload
  ```
- 配置阿里云安全组: 添加入方向规则 80/443

### 3.4 容器频繁重启

**症状**: RestartCount 数值很高

**排查步骤**:
1. 检查重启次数和原因
   ```bash
   docker inspect --format='{{.RestartCount}}' envoy-proxy
   docker logs --since 1h envoy-proxy | grep -i "error\|fatal"
   ```

2. 检查资源使用
   ```bash
   docker stats envoy-proxy --no-stream
   ```

3. 检查系统资源
   ```bash
   free -h
   df -h
   ```

**解决方案**:
- OOM (内存不足): 增加内存限制或服务器内存
- 配置错误: 修正 Envoy 配置
- 依赖服务问题: 检查后端服务可用性

### 3.5 未收到监控告警

**症状**: 服务异常但未收到邮件

**排查步骤**:
1. 检查监控脚本是否执行
   ```bash
   tail -f /var/log/envoy-monitor.log
   ```

2. 检查 crontab 配置
   ```bash
   crontab -l | grep monitor
   ```

3. 手动测试邮件发送
   ```bash
   bash /root/envoy/monitor.sh
   ```

4. 检查邮件工具
   ```bash
   which sendemail
   which python3
   ```

**解决方案**:
- 安装邮件工具
  ```bash
  # CentOS/RHEL
  yum install -y sendemail
  
  # Ubuntu/Debian
  apt-get install -y sendemail
  ```
- 检查 SMTP 配置: 确认授权码正确
- 查看告警标记: `ls -la /tmp/envoy-alert-sent`

---

## 四、部署和更新流程

### 4.1 初次部署

```bash
# 1. 创建目录
mkdir -p /root/envoy
cd /root/envoy

# 2. 上传文件（在本地执行）
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" docker-compose.yml root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" diagnose.sh root@www.qsgl.cn:/root/envoy/
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" monitor.sh root@www.qsgl.cn:/root/envoy/

# 3. 设置脚本权限（在服务器执行）
chmod +x /root/envoy/diagnose.sh
chmod +x /root/envoy/monitor.sh

# 4. 安装邮件工具
yum install -y sendemail  # 或 apt-get install -y sendemail

# 5. 停止现有容器
docker stop envoy-proxy

# 6. 使用 Docker Compose 启动
cd /root/envoy
docker-compose up -d

# 7. 验证服务
docker-compose ps
bash /root/envoy/diagnose.sh

# 8. 配置监控定时任务
crontab -e
# 添加以下行:
*/5 * * * * /root/envoy/monitor.sh >> /var/log/envoy-monitor.log 2>&1

# 9. 测试监控
bash /root/envoy/monitor.sh
```

### 4.2 更新配置

```bash
# 1. 备份当前配置
cp /root/envoy/docker-compose.yml /root/envoy/docker-compose.yml.bak

# 2. 上传新配置
scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" docker-compose.yml root@www.qsgl.cn:/root/envoy/

# 3. 重新启动
cd /root/envoy
docker-compose down
docker-compose up -d

# 4. 验证
docker-compose ps
bash /root/envoy/diagnose.sh
```

### 4.3 更新镜像

```bash
# 1. 拉取新镜像
docker pull 43.138.35.183:5000/envoy:envoy-v1.31-custom

# 2. 重启服务
cd /root/envoy
docker-compose up -d --force-recreate

# 3. 清理旧镜像
docker image prune -f
```

---

## 五、监控和日志

### 5.1 查看监控日志
```bash
# 实时查看
tail -f /var/log/envoy-monitor.log

# 查看今天的告警
grep "告警" /var/log/envoy-monitor.log | grep "$(date +%Y-%m-%d)"

# 查看最近的检查结果
tail -100 /var/log/envoy-monitor.log
```

### 5.2 查看容器日志
```bash
# 实时日志
docker logs -f envoy-proxy

# 最近错误
docker logs envoy-proxy 2>&1 | grep -i "error\|fatal" | tail -50

# 按时间查看
docker logs --since 1h envoy-proxy
docker logs --since "2025-10-24T10:00:00" envoy-proxy
```

### 5.3 Envoy 统计信息
```bash
# 查看所有统计
curl http://localhost:9901/stats

# 查看连接统计
curl http://localhost:9901/stats | grep -i connection

# 查看请求统计
curl http://localhost:9901/stats | grep -i request

# 导出配置
curl http://localhost:9901/config_dump > envoy-config.json
```

---

## 六、性能优化建议

### 6.1 资源限制
根据实际负载调整 `docker-compose.yml` 中的资源限制：
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

### 6.2 日志管理
- 定期清理旧日志
- 使用日志轮转
```bash
# 配置 logrotate
cat > /etc/logrotate.d/envoy << EOF
/var/log/envoy-monitor.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

### 6.3 健康检查优化
- 根据服务启动时间调整 `start_period`
- 调整检查间隔避免过于频繁

---

## 七、安全建议

1. **定期更新镜像**: 及时应用安全补丁
2. **最小权限原则**: 不要以 root 运行容器内进程
3. **网络隔离**: 使用 Docker 网络隔离
4. **密钥管理**: 保护好 SSH 私钥
5. **日志审计**: 定期检查访问日志

---

## 八、应急联系

- **告警邮箱**: qsoft@139.com
- **服务器**: www.qsgl.cn
- **运维文档**: 本文档

---

## 九、常见问题 FAQ

**Q: 如何临时禁用监控告警？**
```bash
# 暂停 cron 任务
crontab -e  # 注释掉监控行

# 或删除告警标记强制重新发送
rm -f /tmp/envoy-alert-sent
```

**Q: 如何查看容器配置？**
```bash
docker inspect envoy-proxy | less
```

**Q: 如何进入容器调试？**
```bash
docker exec -it envoy-proxy sh
```

**Q: 如何备份配置？**
```bash
tar -czf envoy-backup-$(date +%Y%m%d).tar.gz /root/envoy
```

---

**文档版本**: 1.0  
**更新日期**: 2025-10-24  
**维护者**: 运维团队
