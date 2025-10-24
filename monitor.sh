#!/bin/bash

# Envoy 容器监控告警脚本
# 用途: 每5分钟检查容器状态，异常时发送邮件告警
# 配置crontab: */5 * * * * /root/envoy/monitor.sh >> /var/log/envoy-monitor.log 2>&1

CONTAINER_NAME="envoy-proxy"
ALERT_EMAIL="qsoft@139.com"
SMTP_SERVER="smtp.139.com"
SMTP_PORT="465"
SMTP_USER="qsoft@139.com"
SMTP_PASSWORD="574a283d502db51ea200"
LOG_FILE="/var/log/envoy-monitor.log"
ALERT_FLAG_FILE="/tmp/envoy-alert-sent"

# 记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 发送邮件告警
send_alert() {
    local subject="$1"
    local message="$2"
    
    # 使用 sendemail 或 mailx 发送邮件
    # 方法1: 使用 sendemail (需要安装: yum install sendemail 或 apt-get install sendemail)
    if command -v sendemail &> /dev/null; then
        echo "$message" | sendemail \
            -f "$SMTP_USER" \
            -t "$ALERT_EMAIL" \
            -u "$subject" \
            -s "$SMTP_SERVER:$SMTP_PORT" \
            -xu "$SMTP_USER" \
            -xp "$SMTP_PASSWORD" \
            -o tls=yes \
            -o message-charset=utf-8 \
            2>&1 | tee -a "$LOG_FILE"
    
    # 方法2: 使用 Python (备用方案)
    elif command -v python3 &> /dev/null; then
        python3 - <<EOF
import smtplib
from email.mime.text import MIMEText
from email.header import Header
import ssl

try:
    msg = MIMEText('''$message''', 'plain', 'utf-8')
    msg['Subject'] = Header('$subject', 'utf-8')
    msg['From'] = '$SMTP_USER'
    msg['To'] = '$ALERT_EMAIL'
    
    context = ssl.create_default_context()
    with smtplib.SMTP_SSL('$SMTP_SERVER', $SMTP_PORT, context=context) as server:
        server.login('$SMTP_USER', '$SMTP_PASSWORD')
        server.send_message(msg)
    print("邮件发送成功")
except Exception as e:
    print(f"邮件发送失败: {e}")
EOF
    else
        log "错误: 未找到邮件发送工具 (sendemail 或 python3)"
        return 1
    fi
    
    # 标记告警已发送
    touch "$ALERT_FLAG_FILE"
    log "告警邮件已发送: $subject"
}

# 清除告警标记
clear_alert_flag() {
    if [ -f "$ALERT_FLAG_FILE" ]; then
        rm -f "$ALERT_FLAG_FILE"
        log "告警标记已清除，服务已恢复"
    fi
}

# 检查容器状态
check_container() {
    local alert_messages=""
    local has_issue=false
    
    # 检查容器是否存在
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        alert_messages+="✗ 容器不存在\n"
        has_issue=true
    else
        # 检查容器是否运行
        local status=$(docker inspect --format='{{.State.Status}}' ${CONTAINER_NAME} 2>/dev/null)
        
        if [ "$status" != "running" ]; then
            alert_messages+="✗ 容器未运行 (状态: $status)\n"
            has_issue=true
            
            # 获取退出代码
            local exit_code=$(docker inspect --format='{{.State.ExitCode}}' ${CONTAINER_NAME} 2>/dev/null)
            alert_messages+="退出代码: $exit_code\n"
        else
            # 检查健康状态
            local health=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null)
            if [ "$health" == "unhealthy" ]; then
                alert_messages+="✗ 容器健康检查失败\n"
                has_issue=true
            fi
            
            # 检查 Envoy 管理接口
            if ! curl -sf http://localhost:9901/ready > /dev/null 2>&1; then
                alert_messages+="✗ Envoy 就绪接口无响应\n"
                has_issue=true
            fi
            
            # 检查关键端口（443和9901）
            if ! netstat -tuln 2>/dev/null | grep -q ":443 " && ! ss -tuln 2>/dev/null | grep -q ":443 "; then
                alert_messages+="✗ 端口 443 未监听\n"
                has_issue=true
            fi
            
            if ! netstat -tuln 2>/dev/null | grep -q ":9901 " && ! ss -tuln 2>/dev/null | grep -q ":9901 "; then
                alert_messages+="✗ 端口 9901 未监听\n"
                has_issue=true
            fi
            
            # 检查重启次数
            local restart_count=$(docker inspect --format='{{.RestartCount}}' ${CONTAINER_NAME} 2>/dev/null)
            if [ "$restart_count" -gt 5 ]; then
                alert_messages+="⚠ 容器重启次数过多: $restart_count 次\n"
                has_issue=true
            fi
        fi
    fi
    
    # 发送告警或清除标记
    if [ "$has_issue" = true ]; then
        # 避免重复发送告警
        if [ ! -f "$ALERT_FLAG_FILE" ]; then
            local full_message="Envoy 代理服务异常!\n\n"
            full_message+="服务器: www.qsgl.cn\n"
            full_message+="容器名: $CONTAINER_NAME\n"
            full_message+="检测时间: $(date '+%Y-%m-%d %H:%M:%S')\n\n"
            full_message+="异常详情:\n$alert_messages\n"
            full_message+="请立即登录服务器检查:\nssh root@www.qsgl.cn\n"
            full_message+="运行诊断命令: bash /root/envoy/diagnose.sh"
            
            send_alert "【告警】Envoy 代理服务异常" "$full_message"
        else
            log "服务仍处于异常状态，告警已发送，避免重复"
        fi
    else
        log "✓ 所有检查通过，服务运行正常"
        clear_alert_flag
    fi
}

# 主程序
log "========== 开始监控检查 =========="
check_container
log "========== 监控检查完成 =========="
