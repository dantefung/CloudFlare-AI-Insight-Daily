#!/bin/bash

# CloudFlare AI Insight Daily 快速启动脚本
# 一键本地运行环境

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统要求
check_requirements() {
    print_info "检查系统要求..."
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js 未安装，请先安装 Node.js (推荐版本 18+)"
        print_info "下载地址: https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_warning "Node.js 版本过低，推荐使用 Node.js 18+"
    else
        print_success "Node.js 版本检查通过: $(node --version)"
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        print_error "npm 未安装"
        exit 1
    fi
    print_success "npm 检查通过: $(npm --version)"
    
    # 检查 Wrangler CLI
    if ! command -v wrangler &> /dev/null; then
        print_warning "Wrangler CLI 未安装，正在安装..."
        npm install -g wrangler
    fi
    print_success "Wrangler CLI 检查通过: $(wrangler --version)"
}

# 安装项目依赖
install_dependencies() {
    print_info "安装项目依赖..."
    
    if [ -f "package.json" ]; then
        npm install
        print_success "项目依赖安装完成"
    else
        print_warning "未找到 package.json，跳过依赖安装"
    fi
}

# 创建配置文件模板
create_config_template() {
    print_info "创建配置文件模板..."
    
    if [ ! -f "wrangler.toml" ]; then
        print_error "未找到 wrangler.toml 配置文件"
        exit 1
    fi
    
    # 备份原配置文件
    if [ ! -f "wrangler.toml.backup" ]; then
        cp wrangler.toml wrangler.toml.backup
        print_success "已备份原配置文件到 wrangler.toml.backup"
    fi
    
    print_success "配置文件检查完成"
}

# 检查必要的环境变量
check_environment_vars() {
    print_info "检查环境变量配置..."
    
    # 读取 wrangler.toml 中的关键配置
    if grep -q "kv数据库的ID" wrangler.toml; then
        print_warning "请更新 wrangler.toml 中的 KV 数据库 ID"
        print_info "您需要创建一个 CloudFlare KV 命名空间并更新配置"
    fi
    
    if grep -q "xxxxxx" wrangler.toml; then
        print_warning "请更新 wrangler.toml 中的 API 密钥"
        print_info "需要配置以下密钥："
        echo "  - GEMINI_API_KEY"
        echo "  - OPENAI_API_KEY"
        echo "  - GITHUB_TOKEN"
    fi
    
    print_success "环境变量检查完成"
}

# 检查 GitHub Token 和仓库分支权限
check_github_token_and_repo() {
    print_info "检查 GitHub Token 及仓库分支权限..."

    if [ ! -f "wrangler.toml" ]; then
        print_error "未找到 wrangler.toml 配置文件"
        exit 1
    fi

    GITHUB_TOKEN=$(grep -E '^GITHUB_TOKEN\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')
    GITHUB_REPO_OWNER=$(grep -E '^GITHUB_REPO_OWNER\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')
    GITHUB_REPO_NAME=$(grep -E '^GITHUB_REPO_NAME\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')
    GITHUB_BRANCH=$(grep -E '^GITHUB_BRANCH\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "未找到 GitHub Token"
        print_warning "请在 wrangler.toml 中配置 GITHUB_TOKEN"
        exit 1
    fi
    if [ -z "$GITHUB_REPO_OWNER" ]; then
        print_error "未找到 GITHUB_REPO_OWNER"
        exit 1
    fi
    if [ -z "$GITHUB_REPO_NAME" ]; then
        print_error "未找到 GITHUB_REPO_NAME"
        exit 1
    fi
    if [ -z "$GITHUB_BRANCH" ]; then
        GITHUB_BRANCH="main"
        print_warning "未找到 GITHUB_BRANCH，使用默认分支: $GITHUB_BRANCH"
    fi

    GH_API="https://api.github.com"
    HEADER_AUTH="Authorization: Bearer $GITHUB_TOKEN"
    HEADER_ACCEPT="Accept: application/vnd.github.v3+json"
    HEADER_UA="User-Agent: Cloudflare-Worker-ContentBot/1.0"

    # 测试 1: 用户信息
    USER_LOGIN=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" -H "$HEADER_UA" "$GH_API/user" | grep '"login"' | head -n1 | sed -E 's/.*"login": "([^"]+)".*/\1/')
    if [ -n "$USER_LOGIN" ]; then
        print_success "Token 有效，用户: $USER_LOGIN"
    else
        print_error "Token 无效或已过期"
        exit 1
    fi

    # 测试 2: 仓库访问
    REPO_FULL_NAME=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" -H "$HEADER_UA" "$GH_API/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME" | grep '"full_name"' | head -n1 | sed -E 's/.*"full_name": "([^"]+)".*/\1/')
    if [ -n "$REPO_FULL_NAME" ]; then
        print_success "可以访问仓库: $REPO_FULL_NAME"
    else
        print_error "无法访问仓库 $GITHUB_REPO_OWNER/$GITHUB_REPO_NAME"
        exit 1
    fi

    # 测试 3: 分支访问
    BRANCH_OK=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" -H "$HEADER_UA" "$GH_API/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/branches/$GITHUB_BRANCH" | grep '"name":' | grep "$GITHUB_BRANCH" || true)
    if [ -n "$BRANCH_OK" ]; then
        print_success "可以访问分支: $GITHUB_BRANCH"
    else
        print_error "无法访问分支: $GITHUB_BRANCH"
        exit 1
    fi
}

# 启动本地开发服务器
start_local_server() {
    print_info "启动本地开发服务器..."
    
    # 检查是否已登录 CloudFlare
    if ! wrangler whoami &> /dev/null; then
        print_warning "未登录 CloudFlare，正在引导登录..."
        print_info "请按照提示完成 CloudFlare 登录"
        wrangler login
    fi
    
    print_info "启动本地开发服务器..."
    print_info "访问地址: http://localhost:8787"
    print_info "默认登录账号: root/toor"
    print_info "按 Ctrl+C 停止服务器"
    
    # 启动本地开发服务器
    wrangler dev --local
}

# 显示帮助信息
show_help() {
    echo "CloudFlare AI Insight Daily 快速启动脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -c, --check    仅检查环境要求"
    echo "  -i, --install  仅安装依赖"
    echo "  -s, --start    直接启动服务器"
    echo ""
    echo "示例:"
    echo "  $0             完整启动流程"
    echo "  $0 --check     检查环境"
    echo "  $0 --start     直接启动"
}

# 显示项目信息
show_project_info() {
    echo ""
    echo "🚀 CloudFlare AI Insight Daily"
    echo "================================"
    echo "📖 项目文档: https://github.com/dantefung/CloudFlare-AI-Insight-Daily"
    echo "🌐 在线演示: 暂无"
    echo "📡 RSS订阅: https://dantefung.github.io/CloudFlare-AI-Insight-Daily/rss.xml"
    echo ""
    echo "📋 快速配置指南:"
    echo "1. 获取 Folo Cookie F12 -> Application -> Cookies"
    echo "2. 创建 CloudFlare KV 命名空间"
    echo "3. 配置 API 密钥 Gemini, OpenAI, GitHub"
    echo "4. 更新 wrangler.toml 配置文件"
    echo ""
}

# 主函数
main() {
    local CHECK_ONLY=false
    local INSTALL_ONLY=false
    local START_ONLY=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                CHECK_ONLY=true
                shift
                ;;
            -i|--install)
                INSTALL_ONLY=true
                shift
                ;;
            -s|--start)
                START_ONLY=true
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    show_project_info
    
    if [ "$CHECK_ONLY" = true ]; then
        check_requirements
        check_environment_vars
        exit 0
    fi
    
    if [ "$INSTALL_ONLY" = true ]; then
        check_requirements
        install_dependencies
        create_config_template
        exit 0
    fi
    
    if [ "$START_ONLY" = true ]; then
        start_local_server
        exit 0
    fi
    
    # 完整流程
    print_info "开始完整启动流程..."
    check_requirements
    install_dependencies
    create_config_template
    check_environment_vars
    check_github_token_and_repo
    start_local_server
}

# 脚本入口
main "$@" 