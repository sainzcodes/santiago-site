#!/bin/bash

echo "🚀 Deploying to Cloudflare Pages using Wrangler"
echo "=============================================="

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "📦 Installing Wrangler CLI..."
    npm install -g wrangler
fi

# Check for API token
if [ -f .env ]; then
    source .env
    # Use CF_API_TOKEN from .env if CLOUDFLARE_API_TOKEN is not set
    CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-$CF_API_TOKEN}"
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "❌ Error: CLOUDFLARE_API_TOKEN not found"
    echo "Please set it with: export CLOUDFLARE_API_TOKEN='your_token'"
    exit 1
fi

export CLOUDFLARE_API_TOKEN

# Get account ID from .env or use the one from dashboard
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-2918e2a16c8ddb207f910938e69f7d81}"

echo "📁 Deploying files from current directory..."
echo "Project: santiago-sainz-ai"
echo ""

# Deploy using wrangler
wrangler pages deploy . \
    --project-name="santiago-sainz-ai" \
    --branch="main" \
    --commit-message="Deploy updated website with Anthropic design"

echo ""
echo "✅ Deployment complete!"
echo "Your site will be available at:"
echo "- https://santiago-sainz-ai.pages.dev"
echo "- https://www.santiagosainz.com (once DNS propagates)"