#!/bin/bash

# 简单的 GitHub Token 测试脚本 (Shell 版)
set -e

echo -e "\033[1;32m🔍 GitHub Token 简单测试\033[0m"
echo -e "\033[1;32m=======================\033[0m"
echo

# 检查 wrangler.toml 文件
if [ ! -f "wrangler.toml" ]; then
  echo -e "\033[1;31m❌ 未找到 wrangler.toml 配置文件\033[0m"
  echo -e "\033[1;33m请确保在项目根目录运行此脚本\033[0m"
  exit 1
fi

echo -e "\033[1;32m📁 找到 wrangler.toml 配置文件\033[0m"

# 提取配置
GITHUB_TOKEN=$(grep -E '^GITHUB_TOKEN\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')
GITHUB_REPO_OWNER=$(grep -E '^GITHUB_REPO_OWNER\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')
GITHUB_REPO_NAME=$(grep -E '^GITHUB_REPO_NAME\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')
GITHUB_BRANCH=$(grep -E '^GITHUB_BRANCH\s*=\s*"' wrangler.toml | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "\033[1;31m❌ 未找到 GitHub Token\033[0m"
  echo -e "\033[1;33m请在 wrangler.toml 中配置 GITHUB_TOKEN\033[0m"
  exit 1
else
  echo -e "\033[1;32m✅ 找到 GitHub Token\033[0m"
fi

if [ -z "$GITHUB_REPO_OWNER" ]; then
  echo -e "\033[1;31m❌ 未找到 GITHUB_REPO_OWNER\033[0m"
  exit 1
else
  echo -e "\033[1;32m✅ 仓库所有者: $GITHUB_REPO_OWNER\033[0m"
fi

if [ -z "$GITHUB_REPO_NAME" ]; then
  echo -e "\033[1;31m❌ 未找到 GITHUB_REPO_NAME\033[0m"
  exit 1
else
  echo -e "\033[1;32m✅ 仓库名称: $GITHUB_REPO_NAME\033[0m"
fi

if [ -z "$GITHUB_BRANCH" ]; then
  GITHUB_BRANCH="main"
  echo -e "\033[1;33m⚠️ 未找到 GITHUB_BRANCH，使用默认分支: $GITHUB_BRANCH\033[0m"
else
  echo -e "\033[1;32m✅ 分支: $GITHUB_BRANCH\033[0m"
fi

echo
echo -e "\033[1;34m🧪 开始测试...\033[0m"

# 测试 Token
GH_API="https://api.github.com"
HEADER_AUTH="Authorization: Bearer $GITHUB_TOKEN"
HEADER_ACCEPT="Accept: application/vnd.github.v3+json"
HEADER_UA="User-Agent: Cloudflare-Worker-ContentBot/1.0"

# 测试 1: 用户信息
USER_LOGIN=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" -H "$HEADER_UA" "$GH_API/user" | grep '"login"' | head -n1 | sed -E 's/.*"login": "([^"]+)".*/\1/')
if [ -n "$USER_LOGIN" ]; then
  echo -e "\033[1;32m✅ Token 有效，用户: $USER_LOGIN\033[0m"
else
  echo -e "\033[1;31m❌ Token 无效或已过期\033[0m"
  exit 1
fi

# 测试 2: 仓库访问
REPO_FULL_NAME=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" -H "$HEADER_UA" "$GH_API/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME" | grep '"full_name"' | head -n1 | sed -E 's/.*"full_name": "([^"]+)".*/\1/')
if [ -n "$REPO_FULL_NAME" ]; then
  echo -e "\033[1;32m✅ 可以访问仓库: $REPO_FULL_NAME\033[0m"
else
  echo -e "\033[1;31m❌ 无法访问仓库 $GITHUB_REPO_OWNER/$GITHUB_REPO_NAME\033[0m"
  exit 1
fi

# 测试 3: 分支访问
BRANCH_OK=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" -H "$HEADER_UA" "$GH_API/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/branches/$GITHUB_BRANCH" | grep '"name":' | grep "$GITHUB_BRANCH" || true)
if [ -n "$BRANCH_OK" ]; then
  echo -e "\033[1;32m✅ 可以访问分支: $GITHUB_BRANCH\033[0m"
else
  echo -e "\033[1;31m❌ 无法访问分支: $GITHUB_BRANCH\033[0m"
  exit 1
fi

echo
echo -e "\033[1;32m🎉 基本权限测试通过！\033[0m"
echo
echo -e "\033[1;33m💡 建议:\033[0m"
echo -e "\033[1;37m1. 确保 Token 具有 'repo' 权限\033[0m"
echo -e "\033[1;37m2. 运行项目: ./scripts/quick-start.sh\033[0m" 