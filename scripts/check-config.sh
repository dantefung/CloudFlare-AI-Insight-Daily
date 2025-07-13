#!/bin/bash
# CloudFlare AI Insight Daily Configuration Check Script (Shell Version)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_info "Checking CloudFlare AI Insight Daily configuration..."

if [ ! -f wrangler.toml ]; then
  print_error "wrangler.toml not found"
  exit 1
fi
print_success "Found wrangler.toml configuration file"

config=$(cat wrangler.toml)
issues=()

# Project name
if [[ $config =~ name\s*=\s*"([^"]+)" ]]; then
  print_success "Project name: ${BASH_REMATCH[1]}"
else
  issues+=("Project name not configured")
fi

# Main entry file
if [[ $config =~ main\s*=\s*"([^"]+)" ]]; then
  print_success "Main entry file: ${BASH_REMATCH[1]}"
else
  issues+=("Main entry file not configured")
fi

# KV namespace binding
if grep -q 'DATA_KV' wrangler.toml; then
  print_success "KV namespace binding: DATA_KV"
else
  issues+=("KV namespace binding not found")
fi

# KV namespace ID
if [[ $config =~ id\s*=\s*"([^"]+)" ]]; then
  kvId="${BASH_REMATCH[1]}"
  if [[ "$kvId" == "6a4fc48883044709af5605c2f78ea7b0" ]]; then
    print_warning "KV namespace ID: $kvId (using default, consider updating)"
  else
    print_success "KV namespace ID: $kvId"
  fi
else
  issues+=("KV namespace ID not found")
fi

# Gemini API Key
if [[ $config =~ GEMINI_API_KEY\s*=\s*"([^"]+)" ]]; then
  geminiKey="${BASH_REMATCH[1]}"
  if [[ "$geminiKey" == "AIzaSyDAqrscbINAOjb9xXW_Mbas8gDrtBBCK-U" ]]; then
    print_warning "Gemini API Key: Using default key (consider updating)"
  else
    print_success "Gemini API Key: Configured"
  fi
else
  issues+=("Gemini API Key not configured")
fi

# GitHub Token
if [[ $config =~ GITHUB_TOKEN\s*=\s*"([^"]+)" ]]; then
  githubToken="${BASH_REMATCH[1]}"
  if [[ "$githubToken" == *xxxxxx* ]]; then
    print_error "GitHub Token: Needs to be updated"
    issues+=("GitHub Token needs to be updated")
  else
    print_success "GitHub Token: Configured"
  fi
else
  issues+=("GitHub Token not configured")
fi

# GitHub repo owner
if [[ $config =~ GITHUB_REPO_OWNER\s*=\s*"([^"]+)" ]]; then
  print_success "GitHub repo owner: ${BASH_REMATCH[1]}"
else
  issues+=("GitHub repo owner not configured")
fi

# GitHub repo name
if [[ $config =~ GITHUB_REPO_NAME\s*=\s*"([^"]+)" ]]; then
  print_success "GitHub repo name: ${BASH_REMATCH[1]}"
else
  issues+=("GitHub repo name not configured")
fi

echo
if [ ${#issues[@]} -eq 0 ]; then
  print_success "Configuration check passed! Ready to deploy."
  echo -e "${BLUE}Next steps:${NC}"
  echo -e "1. Run: wrangler dev --local  # Test locally"
  echo -e "2. Run: wrangler deploy       # Deploy to Cloudflare"
else
  print_warning "Configuration issues found:"
  for issue in "${issues[@]}"; do
    print_error "- $issue"
  done
  echo
  print_warning "Please fix the above issues before deploying."
fi 