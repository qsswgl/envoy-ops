#!/bin/bash

# Envoy 容器部署脚本
# 用途: 自动化部署和配置 Envoy 容器运维环境

set -e  # 遇到错误立即退出

# 配置变量
DEPLOY_DIR="/root/envoy"
CONTAINER_NAME="envoy-proxy"
SMTP_USER="qsoft@139.com"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    log_info "检查 Docker 安装..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    log_info "Docker 版本: $(docker --version)"
}

# 检查 Docker Compose 是否安装
check_docker_compose() {
    log_info "检查 Docker Compose 安装..."
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    log_info "Docker Compose 版本: $(docker-compose --version)"
}

# 创建部署目录
create_deploy_dir() {
    log_info "创建部署目录: $DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
}

# 安装邮件发送工具
install_mail_tools() {
    log_info "检查邮件发送工具..."
    
    if command -v sendemail &> /dev/null; then
        log_info "sendemail 已安装"
        return 0
    fi
    
    if command -v python3 &> /dev/null; then
        log_info "Python3 已安装，可用于发送邮件"
        return 0
    fi
    
    log_warn "未找到邮件发送工具，尝试安装 sendemail..."
    
    # 检测系统类型并安装
    if [ -f /etc/redhat-release ]; then
        yum install -y sendemail || log_warn "sendemail 安装失败，将使用 Python3"
    elif [ -f /etc/debian_version ]; then
        apt-get update && apt-get install -y sendemail || log_warn "sendemail 安装失败，将使用 Python3"
    else
        log_warn "未知系统类型，跳过 sendemail 安装"
    fi
}

# 设置脚本权限
set_permissions() {
    log_info "设置脚本执行权限..."
    chmod +x "$DEPLOY_DIR/diagnose.sh"
    chmod +x "$DEPLOY_DIR/monitor.sh"
    log_info "权限设置完成"
}

# 停止现有容器
stop_existing_container() {
    log_info "检查现有容器..."
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warn "发现现有容器 $CONTAINER_NAME，准备停止..."
        docker stop "$CONTAINER_NAME" || true
        log_info "容器已停止"
    else
        log_info "未发现现有容器"
    fi
}

# 使用 Docker Compose 启动
start_with_compose() {
    log_info "使用 Docker Compose 启动服务..."
    cd "$DEPLOY_DIR"
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件"
        exit 1
    fi
    
    docker-compose up -d
    log_info "服务启动完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署状态..."
    
    sleep 5  # 等待容器启动
    
    # 检查容器状态
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "✓ 容器运行中"
    else
        log_error "✗ 容器未运行"
        return 1
    fi
    
    # 检查健康状态
    local status=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME")
    log_info "容器状态: $status"
    
    # 运行诊断
    log_info "运行诊断脚本..."
    bash "$DEPLOY_DIR/diagnose.sh"
}

# 配置 crontab
setup_cron() {
    log_info "配置监控定时任务..."
    
    # 检查是否已存在
    if crontab -l 2>/dev/null | grep -q "monitor.sh"; then
        log_warn "监控任务已存在，跳过配置"
        return 0
    fi
    
    # 添加 cron 任务
    (crontab -l 2>/dev/null; echo "*/5 * * * * $DEPLOY_DIR/monitor.sh >> /var/log/envoy-monitor.log 2>&1") | crontab -
    log_info "监控任务配置完成 (每5分钟执行一次)"
    
    # 显示当前 crontab
    log_info "当前定时任务:"
    crontab -l | grep monitor.sh
}

# 测试监控脚本
test_monitoring() {
    log_info "测试监控脚本..."
    bash "$DEPLOY_DIR/monitor.sh"
    
    if [ -f /var/log/envoy-monitor.log ]; then
        log_info "监控日志:"
        tail -20 /var/log/envoy-monitor.log
    fi
}

# 显示部署摘要
show_summary() {
    echo ""
    log_info "=========================================="
    log_info "部署完成!"
    log_info "=========================================="
    echo ""
    log_info "容器名称: $CONTAINER_NAME"
    log_info "部署目录: $DEPLOY_DIR"
    log_info "监控日志: /var/log/envoy-monitor.log"
    log_info "告警邮箱: $SMTP_USER"
    echo ""
    log_info "常用命令:"
    echo "  查看容器状态: docker ps | grep envoy"
    echo "  查看日志:     docker logs -f $CONTAINER_NAME"
    echo "  运行诊断:     bash $DEPLOY_DIR/diagnose.sh"
    echo "  查看监控日志: tail -f /var/log/envoy-monitor.log"
    echo "  重启服务:     cd $DEPLOY_DIR && docker-compose restart"
    echo ""
    log_info "完整文档请查看: $DEPLOY_DIR/README.md"
    log_info "=========================================="
}

# 主函数
main() {
    log_info "开始 Envoy 容器部署..."
    echo ""
    
    check_docker
    check_docker_compose
    create_deploy_dir
    install_mail_tools
    
    # 检查必要文件是否存在
    if [ ! -f "$DEPLOY_DIR/docker-compose.yml" ]; then
        log_error "缺少 docker-compose.yml 文件，请先上传配置文件"
        log_info "使用以下命令上传文件 (在本地 Windows 执行):"
        echo '  scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" docker-compose.yml root@www.qsgl.cn:/root/envoy/'
        echo '  scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" diagnose.sh root@www.qsgl.cn:/root/envoy/'
        echo '  scp -i "C:\Key\www.qsgl.cn_nopass_id_ed25519" monitor.sh root@www.qsgl.cn:/root/envoy/'
        exit 1
    fi
    
    set_permissions
    stop_existing_container
    start_with_compose
    
    if verify_deployment; then
        setup_cron
        test_monitoring
        show_summary
    else
        log_error "部署验证失败，请检查日志"
        exit 1
    fi
}

# 执行主函数
main "$@"
