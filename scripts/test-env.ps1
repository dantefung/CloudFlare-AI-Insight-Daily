# 环境测试脚本
Write-Host "🚀 CloudFlare AI Insight Daily 环境测试" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# 检查 Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js 未安装" -ForegroundColor Red
}

# 检查 npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm 未安装" -ForegroundColor Red
}

# 检查 Wrangler
try {
    $wranglerVersion = wrangler --version
    Write-Host "✅ Wrangler: $wranglerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Wrangler 未安装" -ForegroundColor Red
}

# 检查配置文件
if (Test-Path "wrangler.toml") {
    Write-Host "✅ wrangler.toml 配置文件存在" -ForegroundColor Green
} else {
    Write-Host "❌ wrangler.toml 配置文件不存在" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 下一步：" -ForegroundColor Yellow
Write-Host "1. 配置 wrangler.toml 中的 API 密钥" -ForegroundColor White
Write-Host "2. 运行 .\scripts\quick-start.ps1 启动项目" -ForegroundColor White 