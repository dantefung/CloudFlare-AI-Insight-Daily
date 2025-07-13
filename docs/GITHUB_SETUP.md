# GitHub 权限配置指南

## 问题描述

如果您遇到以下错误：
```
✘ [ERROR] GitHub API Error: 403 Forbidden for PUT https://api.github.com/repos/username/repo/contents/daily/2025-07-13.md. Message: Resource not accessible by personal access token
```

这表示您的 GitHub Personal Access Token 没有足够的权限来访问和修改仓库内容。

## 解决方案

### 1. 创建新的 Personal Access Token

#### 步骤 1: 访问 GitHub 设置
1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 在左侧菜单中点击 **Developer settings**
4. 点击 **Personal access tokens** → **Tokens (classic)**

#### 步骤 2: 生成新 Token
1. 点击 **Generate new token (classic)**
2. 输入 Token 描述，例如：`CloudFlare AI Daily Bot`
3. 设置过期时间（建议选择 **No expiration** 或较长时间）

#### 步骤 3: 选择权限范围
**重要：** 确保勾选以下权限：

- ✅ **repo** (Full control of private repositories)
  - 包含所有仓库相关权限
  - 允许读取和写入仓库内容
  - 允许创建和删除文件

- ✅ **workflow** (Update GitHub Action workflows)
  - 如果需要使用 GitHub Actions

#### 步骤 4: 生成 Token
1. 滚动到底部
2. 点击 **Generate token**
3. **立即复制生成的 Token**（重要：页面关闭后无法再次查看）

### 2. 更新配置文件

将新生成的 Token 更新到 `wrangler.toml` 文件中：

```toml
# wrangler.toml
[vars]
GITHUB_TOKEN = "ghp_your_new_token_here"
GITHUB_REPO_OWNER = "your_username"
GITHUB_REPO_NAME = "CloudFlare-AI-Insight-Daily"
GITHUB_BRANCH = "main"
```

### 3. 验证权限

#### 方法 1: 使用 GitHub API 测试
```bash
# 测试读取权限
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO

# 测试写入权限（创建测试文件）
curl -X PUT \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -H "Content-Type: application/json" \
     -d '{
       "message": "Test commit",
       "content": "dGVzdA==",
       "branch": "main"
     }' \
     https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/contents/test.txt
```

#### 方法 2: 使用项目测试脚本
```bash
# 运行环境检查
./scripts/quick-start.sh --check

# 或者使用 PowerShell
.\scripts\quick-start.ps1 -Check
```

### 4. 常见问题排查

#### 问题 1: Token 权限不足
**症状：** 403 Forbidden 错误
**解决：** 确保 Token 有 `repo` 权限

#### 问题 2: 仓库不存在或无权访问
**症状：** 404 Not Found 错误
**解决：** 
1. 检查仓库名称是否正确
2. 确保仓库是公开的，或者 Token 有访问私有仓库的权限

#### 问题 3: 分支不存在
**症状：** 404 Not Found 错误
**解决：** 确保 `GITHUB_BRANCH` 配置的分支存在

#### 问题 4: Token 已过期
**症状：** 401 Unauthorized 错误
**解决：** 重新生成新的 Token

### 5. 安全建议

1. **定期轮换 Token**
   - 建议每 90 天更新一次 Token
   - 删除不再使用的旧 Token

2. **最小权限原则**
   - 只授予必要的权限
   - 避免使用过于宽泛的权限

3. **环境变量安全**
   - 不要在代码中硬编码 Token
   - 使用环境变量或配置文件存储

4. **监控使用情况**
   - 定期检查 Token 的使用日志
   - 发现异常使用及时撤销

### 6. 故障排除检查清单

- [ ] Token 是否已正确生成并复制
- [ ] Token 是否有 `repo` 权限
- [ ] 仓库名称是否正确
- [ ] 分支名称是否正确
- [ ] 仓库是否为公开仓库（或 Token 有私有仓库访问权限）
- [ ] Token 是否已过期
- [ ] 网络连接是否正常

### 7. 获取帮助

如果问题仍然存在，请：

1. 检查 GitHub 的 [API 文档](https://docs.github.com/en/rest)
2. 查看 [GitHub 状态页面](https://www.githubstatus.com/)
3. 在项目 Issues 中报告问题
4. 联系 GitHub 支持

## 相关链接

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub REST API](https://docs.github.com/en/rest)
- [GitHub API 权限](https://docs.github.com/en/rest/overview/permissions-required-for-github-apps) 