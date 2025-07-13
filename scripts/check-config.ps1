# CloudFlare AI Insight Daily Configuration Check Script

Write-Host "Checking CloudFlare AI Insight Daily configuration..." -ForegroundColor Blue

# Check if wrangler.toml exists
if (-not (Test-Path "wrangler.toml")) {
    Write-Host "ERROR: wrangler.toml not found" -ForegroundColor Red
    exit 1
}

Write-Host "Found wrangler.toml configuration file" -ForegroundColor Green

# Read configuration content
$config = Get-Content "wrangler.toml" -Raw

# Check key configurations
$issues = @()

# Check project name
if ($config -match 'name\s*=\s*"([^"]+)"') {
    Write-Host "Project name: $($matches[1])" -ForegroundColor Green
} else {
    $issues += "Project name not configured"
}

# Check main entry file
if ($config -match 'main\s*=\s*"([^"]+)"') {
    Write-Host "Main entry file: $($matches[1])" -ForegroundColor Green
} else {
    $issues += "Main entry file not configured"
}

# Check KV namespace
if ($config -match 'binding\s*=\s*"DATA_KV"') {
    Write-Host "KV namespace binding: DATA_KV" -ForegroundColor Green
} else {
    $issues += "KV namespace binding not found"
}

# Check KV namespace ID
if ($config -match 'id\s*=\s*"([^"]+)"') {
    $kvId = $matches[1]
    if ($kvId -eq "6a4fc48883044709af5605c2f78ea7b0") {
        Write-Host "KV namespace ID: $kvId (using default, consider updating)" -ForegroundColor Yellow
    } else {
        Write-Host "KV namespace ID: $kvId" -ForegroundColor Green
    }
} else {
    $issues += "KV namespace ID not found"
}

# Check Gemini API Key
if ($config -match 'GEMINI_API_KEY\s*=\s*"([^"]+)"') {
    $geminiKey = $matches[1]
    if ($geminiKey -eq "AIzaSyDAqrscbINAOjb9xXW_Mbas8gDrtBBCK-U") {
        Write-Host "Gemini API Key: Using default key (consider updating)" -ForegroundColor Yellow
    } else {
        Write-Host "Gemini API Key: Configured" -ForegroundColor Green
    }
} else {
    $issues += "Gemini API Key not configured"
}

# Check GitHub Token
if ($config -match 'GITHUB_TOKEN\s*=\s*"([^"]+)"') {
    $githubToken = $matches[1]
    if ($githubToken -like "*xxxxxx*") {
        Write-Host "GitHub Token: Needs to be updated" -ForegroundColor Red
        $issues += "GitHub Token needs to be updated"
    } else {
        Write-Host "GitHub Token: Configured" -ForegroundColor Green
    }
} else {
    $issues += "GitHub Token not configured"
}

# Check GitHub repository info
if ($config -match 'GITHUB_REPO_OWNER\s*=\s*"([^"]+)"') {
    Write-Host "GitHub repo owner: $($matches[1])" -ForegroundColor Green
} else {
    $issues += "GitHub repo owner not configured"
}

if ($config -match 'GITHUB_REPO_NAME\s*=\s*"([^"]+)"') {
    Write-Host "GitHub repo name: $($matches[1])" -ForegroundColor Green
} else {
    $issues += "GitHub repo name not configured"
}

Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "Configuration check passed! Ready to deploy." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Blue
    Write-Host "1. Run: wrangler dev --local  # Test locally" -ForegroundColor White
    Write-Host "2. Run: wrangler deploy       # Deploy to Cloudflare" -ForegroundColor White
} else {
    Write-Host "Configuration issues found:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "- $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please fix the above issues before deploying." -ForegroundColor Yellow
} 