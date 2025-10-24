# Envoy 容器运维 - Windows 一键上传脚本
# PowerShell 脚本

# 配置
$SSH_KEY = "C:\Key\www.qsgl.cn_id_ed25519"
$SERVER = "root@www.qsgl.cn"
$REMOTE_DIR = "/root/envoy"
$LOCAL_DIR = "K:\Envoy"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Envoy 容器运维 - 文件上传" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# 检查私钥文件是否存在
if (-not (Test-Path $SSH_KEY)) {
    Write-Host "错误: 找不到私钥文件 $SSH_KEY" -ForegroundColor Red
    exit 1
}

# 检查本地文件目录
if (-not (Test-Path $LOCAL_DIR)) {
    Write-Host "错误: 找不到本地目录 $LOCAL_DIR" -ForegroundColor Red
    exit 1
}

# 切换到本地目录
Set-Location $LOCAL_DIR

# 要上传的文件列表
$files = @(
    "docker-compose.yml",
    "diagnose.sh",
    "monitor.sh",
    "deploy.sh",
    "README.md",
    "DEPLOY.md"
)

Write-Host "准备上传以下文件到服务器:" -ForegroundColor Cyan
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (文件不存在)" -ForegroundColor Red
    }
}
Write-Host ""

# 询问是否继续
$continue = Read-Host "是否继续上传? (Y/N)"
if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "已取消上传" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "开始上传文件..." -ForegroundColor Cyan
Write-Host ""

# 上传每个文件
$successCount = 0
$failCount = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "正在上传: $file" -ForegroundColor Yellow
        
        try {
            # 使用 scp 上传文件
            & scp -i $SSH_KEY $file "${SERVER}:${REMOTE_DIR}/"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ $file 上传成功" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  ✗ $file 上传失败" -ForegroundColor Red
                $failCount++
            }
        } catch {
            Write-Host "  ✗ $file 上传出错: $_" -ForegroundColor Red
            $failCount++
        }
        
        Write-Host ""
    }
}

# 显示结果
Write-Host "=====================================" -ForegroundColor Green
Write-Host "上传完成!" -ForegroundColor Green
Write-Host "成功: $successCount 个文件" -ForegroundColor Green
Write-Host "失败: $failCount 个文件" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "下一步操作:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. 登录服务器:" -ForegroundColor Yellow
    Write-Host "   ssh -i `"$SSH_KEY`" $SERVER" -ForegroundColor White
    Write-Host ""
    Write-Host "2. 运行部署脚本:" -ForegroundColor Yellow
    Write-Host "   cd $REMOTE_DIR" -ForegroundColor White
    Write-Host "   chmod +x deploy.sh" -ForegroundColor White
    Write-Host "   bash deploy.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "或者查看部署文档:" -ForegroundColor Yellow
    Write-Host "   cat $REMOTE_DIR/DEPLOY.md" -ForegroundColor White
    Write-Host ""
    
    # 询问是否立即登录服务器
    $login = Read-Host "是否立即登录服务器? (Y/N)"
    if ($login -eq "Y" -or $login -eq "y") {
        Write-Host ""
        Write-Host "正在连接服务器..." -ForegroundColor Cyan
        & ssh -i $SSH_KEY $SERVER
    }
}

Write-Host ""
Write-Host "提示: 部署完成后，监控脚本将每5分钟检查一次服务状态" -ForegroundColor Yellow
Write-Host "告警邮件将发送到: qsoft@139.com" -ForegroundColor Yellow
