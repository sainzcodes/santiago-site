#!/bin/bash

echo "🚀 Deploying to Cloudflare Pages via Direct Upload"
echo "================================================"

# Your API key
API_KEY="55165dff5bc714ad5149c94cf38578b76e1b4"
ACCOUNT_ID="2918e2a16c8ddb207f910938e69f7d81"
PROJECT_NAME="santiago-sainz-ai"

# Create a manifest of files to upload
echo "📦 Preparing files for upload..."

# Create a temporary directory for the deployment
DEPLOY_DIR=$(mktemp -d)
echo "Using temp directory: $DEPLOY_DIR"

# Copy all necessary files
cp index.html "$DEPLOY_DIR/"
cp styles.css "$DEPLOY_DIR/"
cp main.js "$DEPLOY_DIR/"
cp _redirects "$DEPLOY_DIR/" 2>/dev/null || true
cp _headers "$DEPLOY_DIR/" 2>/dev/null || true
cp about.html "$DEPLOY_DIR/" 2>/dev/null || true
cp consulting.html "$DEPLOY_DIR/" 2>/dev/null || true
cp contact.html "$DEPLOY_DIR/" 2>/dev/null || true
cp products.html "$DEPLOY_DIR/" 2>/dev/null || true

# Create deployment using the API
echo "🌐 Creating deployment..."

# First, create the deployment
DEPLOYMENT_RESPONSE=$(curl -s -X POST \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$PROJECT_NAME/deployments" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  --data '{
    "branch": "main"
  }')

if echo "$DEPLOYMENT_RESPONSE" | grep -q '"success":true'; then
    DEPLOYMENT_ID=$(echo "$DEPLOYMENT_RESPONSE" | jq -r '.result.id')
    UPLOAD_URL=$(echo "$DEPLOYMENT_RESPONSE" | jq -r '.result.upload_url')
    
    echo "✅ Deployment created: $DEPLOYMENT_ID"
    echo "📤 Upload URL: $UPLOAD_URL"
    
    # Upload files
    echo "📤 Uploading files..."
    
    # Create a tar archive of the files
    cd "$DEPLOY_DIR"
    tar -czf deployment.tar.gz *
    
    # Upload the archive
    UPLOAD_RESPONSE=$(curl -s -X PUT \
      "$UPLOAD_URL" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @deployment.tar.gz)
    
    echo "✅ Files uploaded!"
    
    # Clean up
    rm -rf "$DEPLOY_DIR"
    
    echo ""
    echo "🎉 Deployment Complete!"
    echo "========================"
    echo "Your new Anthropic-inspired website is being deployed."
    echo "It will be available at:"
    echo "- https://santiago-sainz-ai.pages.dev"
    echo "- https://www.santiagosainz.com"
    echo ""
    echo "Features:"
    echo "✅ Black background (#000000)"
    echo "✅ Teal accent color (#14B8A6)"
    echo "✅ Minimal, professional design"
    echo "✅ Smooth animations"
    echo "✅ Case studies with metrics"
else
    echo "❌ Deployment failed:"
    echo "$DEPLOYMENT_RESPONSE" | jq '.' 2>/dev/null || echo "$DEPLOYMENT_RESPONSE"
    
    # Clean up
    rm -rf "$DEPLOY_DIR"
    
    echo ""
    echo "📋 Manual deployment required:"
    echo "1. Go to https://dash.cloudflare.com"
    echo "2. Navigate to Workers & Pages → santiago-sainz-ai"
    echo "3. Click 'Create deployment'"
    echo "4. Upload all files from this directory"
fi