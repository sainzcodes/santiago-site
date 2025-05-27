#!/bin/bash

# Cloudflare Pages Direct Upload via API
# This script uses curl to deploy directly to Cloudflare Pages

# Configuration
PROJECT_NAME="santiago-sainz-ai"
ACCOUNT_ID="2918e2a16c8ddb207f910938e69f7d81"

# Check for API token
if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -z "$CF_API_TOKEN" ]; then
    echo "❌ Error: No Cloudflare API token found"
    echo ""
    echo "Please set your API token:"
    echo "  export CLOUDFLARE_API_TOKEN=\"your_token_here\""
    exit 1
fi

API_TOKEN="${CLOUDFLARE_API_TOKEN:-$CF_API_TOKEN}"

echo "🚀 Deploying to Cloudflare Pages via API..."
echo ""

# Create deployment
echo "📤 Creating deployment..."

# First, create a new deployment
DEPLOYMENT_RESPONSE=$(curl -s -X POST \
    "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$PROJECT_NAME/deployments" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json")

# Check if project exists
if echo "$DEPLOYMENT_RESPONSE" | grep -q "not_found"; then
    echo "❌ Project not found: $PROJECT_NAME"
    echo ""
    echo "To create the project first:"
    echo "1. Go to https://pages.cloudflare.com"
    echo "2. Create a new project named: $PROJECT_NAME"
    echo "3. Choose 'Direct Upload' as the source"
    echo ""
    echo "Or use wrangler to create it:"
    echo "  wrangler pages project create $PROJECT_NAME"
    exit 1
fi

# Extract deployment ID
DEPLOYMENT_ID=$(echo "$DEPLOYMENT_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$DEPLOYMENT_ID" ]; then
    echo "❌ Failed to create deployment"
    echo "Response: $DEPLOYMENT_RESPONSE"
    exit 1
fi

echo "✅ Deployment created: $DEPLOYMENT_ID"

# Upload files
echo "📦 Uploading files..."

# Function to upload a file
upload_file() {
    local file="$1"
    local path="$2"
    
    curl -s -X PUT \
        "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$PROJECT_NAME/deployments/$DEPLOYMENT_ID/files/$path" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        --data-binary "@$file" > /dev/null
}

# Upload all files
for file in *.html *.css *.js _redirects _headers; do
    if [ -f "$file" ]; then
        echo "  📄 Uploading: $file"
        upload_file "$file" "$file"
    fi
done

# Finalize deployment
echo ""
echo "🔒 Finalizing deployment..."

FINALIZE_RESPONSE=$(curl -s -X PATCH \
    "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$PROJECT_NAME/deployments/$DEPLOYMENT_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"stage": "deploy"}')

if echo "$FINALIZE_RESPONSE" | grep -q "success\":true"; then
    echo ""
    echo "✅ Deployment successful!"
    echo "🌐 Preview URL: https://$DEPLOYMENT_ID.$PROJECT_NAME.pages.dev"
    echo "🔗 Production URL: https://$PROJECT_NAME.pages.dev"
    echo "🔗 Custom domain: https://santiagosainz.com"
else
    echo "❌ Failed to finalize deployment"
    echo "Response: $FINALIZE_RESPONSE"
fi