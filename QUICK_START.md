# 快速使用指南

## 🎯 项目地址

**GitHub**: https://github.com/qsswgl/envoy-ops

## 📥 克隆项目

```bash
# HTTPS
git clone https://github.com/qsswgl/envoy-ops.git

# SSH
git clone git@github.com:qsswgl/envoy-ops.git

cd envoy-ops
```

## 🚀 快速部署

### 阿里云服务器 (www.qsgl.cn)

```bash
# 1. 上传配置
scp aliyun_envoy_current.yaml docker-compose.yml \
    diagnose.sh monitor.sh deploy.sh \
    root@www.qsgl.cn:/root/envoy/

# 2. SSH 登录
ssh root@www.qsgl.cn

# 3. 运行部署
cd /root/envoy
chmod +x deploy.sh diagnose.sh monitor.sh
bash deploy.sh

# 4. 验证
bash diagnose.sh
curl -Ik https://www.qsgl.cn
```

### 腾讯云服务器 (tx.qsgl.net)

```bash
# 1. 配置 SSH 密钥（推荐）
# 在 ~/.ssh/config 添加:
Host tx.qsgl.net
    HostName tx.qsgl.net
    User root
    IdentityFile /path/to/your/key
    IdentitiesOnly yes

# 2. 上传配置
scp tx_envoy_v1.36.2_http3.yaml tx.qsgl.net:/opt/envoy/config/envoy.yaml
scp tx_docker-compose.yml tx.qsgl.net:/opt/envoy/docker-compose.yml

# 3. SSH 登录（无密码）
ssh tx.qsgl.net

# 4. 启动服务
cd /opt/envoy
docker-compose up -d

# 5. 验证
# HTTP/2
curl -Ik https://www.qsgl.net

# HTTP/3
curl --http3 -Ik https://tx.qsgl.net

# SSE 长连接
curl -N --no-buffer https://www.qsgl.net:5002/sse/UsersID/1
```

## 📊 功能对比

| 功能 | 阿里云 | 腾讯云 |
|-----|-------|-------|
| HTTP/1.1 | ✅ | ✅ |
| HTTP/2 | ✅ | ✅ |
| HTTP/3 | ❌ | ✅ |
| SSE 长连接 | ❌ | ✅ |
| 监控告警 | ✅ | ❌ |

## 🔧 日常运维

```bash
# 查看容器状态
docker ps | grep envoy

# 查看日志
docker logs -f envoy-proxy

# 重启服务
docker restart envoy-proxy

# 健康检查
curl http://localhost:9901/ready

# 查看统计
curl http://localhost:9901/stats
```

## 📚 完整文档

- **README.md** - 完整项目文档
- **SSE_PROBLEM_SOLVED.md** - SSE 问题解决
- **TX_HTTP3_SUCCESS_REPORT.md** - HTTP/3 配置指南
- **TROUBLESHOOTING.md** - 故障排查手册

## ⚠️ 重要提醒

1. **证书权限**: `chmod 644 *.key`
2. **UDP 443**: 腾讯云安全组必须开放
3. **域名配置**: 包含端口号变体（如 `domain:5002`）

## 📞 问题反馈

- **GitHub Issues**: https://github.com/qsswgl/envoy-ops/issues
- **邮箱**: qsoft@139.com

---
**最后更新**: 2025-10-26
