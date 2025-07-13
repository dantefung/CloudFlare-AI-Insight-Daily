#!/bin/bash

# CloudFlare AI Insight Daily 一键部署脚本
# 自动完成依赖检查、wrangler安装、Cloudflare登录、KV命名空间检查/创建、配置检查、部署

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. 检查Node.js
if ! command -v node &>/dev/null; then
  print_error "未检测到Node.js，请先安装Node.js (推荐18+)"
  exit 1
fi
print_success "Node.js版本: $(node --version)"

# 2. 检查npm
if ! command -v npm &>/dev/null; then
  print_error "未检测到npm，请先安装npm"
  exit 1
fi
print_success "npm版本: $(npm --version)"

# 3. 检查wrangler
if ! command -v wrangler &>/dev/null; then
  print_warning "未检测到wrangler，正在全局安装..."
  npm install -g wrangler
fi
print_success "wrangler版本: $(wrangler --version)"

# 4. Cloudflare登录
if ! wrangler whoami &>/dev/null; then
  print_info "未登录Cloudflare，正在引导登录..."
  wrangler login
fi
print_success "Cloudflare已登录"

# 5. 检查/创建KV命名空间
if grep -q 'kv_namespaces' wrangler.toml; then
  if grep -q 'DATA_KV' wrangler.toml; then
    print_success "wrangler.toml已配置KV命名空间: DATA_KV"
  else
    print_warning "未检测到DATA_KV命名空间，自动创建..."
    NSID=$(wrangler kv namespace create "DATA_KV" | grep 'id =' | head -n1 | awk -F '"' '{print $2}')
    sed -i "/kv_namespaces = \[/a   { binding = \"DATA_KV\", id = \"$NSID\" }" wrangler.toml
    print_success "已写入KV命名空间ID: $NSID"
  fi
else
  print_warning "未检测到kv_namespaces配置，自动创建..."
  NSID=$(wrangler kv namespace create "DATA_KV" | grep 'id =' | head -n1 | awk -F '"' '{print $2}')
  echo -e "\nkv_namespaces = [\n  { binding = \"DATA_KV\", id = \"$NSID\" }\n]" >> wrangler.toml
  print_success "已写入KV命名空间ID: $NSID"
fi

# 6. 配置检查
if [ -f scripts/check-config.ps1 ]; then
  print_info "运行PowerShell配置检查脚本..."
  # 尝试不同的PowerShell命令
  if command -v pwsh &>/dev/null; then
    pwsh -Command "& { ./scripts/check-config.ps1 }"
  elif command -v powershell &>/dev/null; then
    powershell -ExecutionPolicy Bypass -File scripts/check-config.ps1
  else
    print_warning "未找到PowerShell，尝试使用Shell版本..."
    if [ -f scripts/check-config.sh ]; then
      bash scripts/check-config.sh
    else
      print_warning "未找到配置检查脚本，跳过此步"
    fi
  fi
elif [ -f scripts/check-config.sh ]; then
  print_info "运行Shell配置检查脚本..."
  bash scripts/check-config.sh
else
  print_warning "未找到配置检查脚本，跳过此步"
fi

# 7. 一键部署
print_info "开始部署到Cloudflare..."
wrangler deploy
print_success "部署完成！请查看上方输出的workers.dev访问地址。" 