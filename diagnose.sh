#!/bin/bash

# Envoy 容器诊断脚本
# 用途: 检查 Envoy 容器状态、日志和网络连接

CONTAINER_NAME="envoy-proxy"
LOG_FILE="/var/log/envoy-diagnose.log"

echo "======================================"
echo "Envoy 容器诊断报告"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================"

# 1. 检查容器是否存在
echo ""
echo "[1] 检查容器是否存在..."
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✓ 容器 ${CONTAINER_NAME} 存在"
else
    echo "✗ 容器 ${CONTAINER_NAME} 不存在"
    exit 1
fi

# 2. 检查容器运行状态
echo ""
echo "[2] 检查容器运行状态..."
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' ${CONTAINER_NAME})
echo "容器状态: ${CONTAINER_STATUS}"

if [ "$CONTAINER_STATUS" == "running" ]; then
    echo "✓ 容器正在运行"
    
    # 检查运行时长
    UPTIME=$(docker inspect --format='{{.State.StartedAt}}' ${CONTAINER_NAME})
    echo "启动时间: ${UPTIME}"
else
    echo "✗ 容器未运行"
    
    # 检查退出代码
    EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' ${CONTAINER_NAME})
    echo "退出代码: ${EXIT_CODE}"
fi

# 3. 检查健康状态
echo ""
echo "[3] 检查容器健康状态..."
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null)
if [ -n "$HEALTH_STATUS" ]; then
    echo "健康状态: ${HEALTH_STATUS}"
else
    echo "未配置健康检查"
fi

# 4. 检查端口映射
echo ""
echo "[4] 检查端口映射..."
docker port ${CONTAINER_NAME}

# 5. 检查网络连接
echo ""
echo "[5] 检查关键端口..."
PORTS=("80" "443" "9901")
for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
        echo "✓ 端口 ${port} 正在监听"
    elif ss -tuln 2>/dev/null | grep -q ":${port} "; then
        echo "✓ 端口 ${port} 正在监听"
    else
        echo "✗ 端口 ${port} 未监听"
    fi
done

# 6. 检查 Envoy 管理接口
echo ""
echo "[6] 检查 Envoy 管理接口..."
if curl -sf http://localhost:9901/ready > /dev/null 2>&1; then
    echo "✓ Envoy 就绪 (ready endpoint 响应正常)"
else
    echo "✗ Envoy 未就绪 (ready endpoint 无响应)"
fi

if curl -sf http://localhost:9901/stats > /dev/null 2>&1; then
    echo "✓ Envoy 统计接口响应正常"
else
    echo "✗ Envoy 统计接口无响应"
fi

# 7. 检查资源使用情况
echo ""
echo "[7] 检查资源使用情况..."
docker stats ${CONTAINER_NAME} --no-stream --format "CPU: {{.CPUPerc}}\tMemory: {{.MemUsage}}\tNet I/O: {{.NetIO}}"

# 8. 显示最近日志
echo ""
echo "[8] 最近 50 行日志..."
echo "----------------------------------------"
docker logs --tail 50 ${CONTAINER_NAME}
echo "----------------------------------------"

# 9. 检查重启次数
echo ""
echo "[9] 检查重启次数..."
RESTART_COUNT=$(docker inspect --format='{{.RestartCount}}' ${CONTAINER_NAME})
echo "重启次数: ${RESTART_COUNT}"

# 10. 检查错误日志
echo ""
echo "[10] 检查最近错误日志..."
ERROR_COUNT=$(docker logs ${CONTAINER_NAME} 2>&1 | grep -i "error\|fatal\|critical" | tail -10)
if [ -n "$ERROR_COUNT" ]; then
    echo "发现错误日志:"
    echo "$ERROR_COUNT"
else
    echo "✓ 未发现明显错误"
fi

echo ""
echo "======================================"
echo "诊断完成"
echo "======================================"
