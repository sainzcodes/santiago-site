#!/bin/bash

echo "🚀 Santiago Site Deployment Script"
echo "================================="
echo ""

# Change to the project directory
cd /Users/sainz/santiago-site

# Check if gh is authenticated
if ! gh auth status &>/dev/null; then
    echo "📱 GitHub CLI not authenticated. Starting authentication..."
    echo ""
    echo "This will open a browser window. Please:"
    echo "1. Copy the code shown"
    echo "2. Paste it in the browser"
    echo "3. Authorize the application"
    echo ""
    gh auth login --git-protocol https --web
else
    echo "✅ GitHub CLI already authenticated"
fi

echo ""
echo "📤 Pushing changes to GitHub..."

# Configure git to use gh as credential helper
gh auth setup-git

# Push the changes
if git push origin main; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "🌐 Cloudflare Pages will automatically deploy your changes."
    echo "   Check your site in 1-2 minutes at: https://santiagosainz.com"
    echo ""
    echo "📊 You can monitor the deployment at:"
    echo "   https://dash.cloudflare.com/?to=/:account/pages"
else
    echo ""
    echo "❌ Failed to push changes. Please check the error above."
fi