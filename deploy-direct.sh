#!/bin/bash

echo "🚀 Direct Cloudflare Pages Deployment"
echo "===================================="
echo ""
echo "Since automated deployment requires specific API permissions,"
echo "here's how to manually deploy your updated website:"
echo ""
echo "📋 Steps:"
echo "1. Go to: https://dash.cloudflare.com"
echo "2. Navigate to Workers & Pages → santiago-sainz-ai"
echo "3. Click 'Create deployment'"
echo "4. Choose 'Upload assets'"
echo "5. Select these files from this directory:"
echo ""
echo "   Required files:"
for file in index.html styles.css main.js _redirects _headers about.html consulting.html contact.html products.html; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ $file (MISSING!)"
    fi
done
echo ""
echo "6. Click 'Deploy'"
echo ""
echo "🎯 Important: Make sure to upload ALL files listed above!"
echo ""
echo "Your updated website with the Anthropic-inspired design will be live at:"
echo "- https://santiago-sainz-ai.pages.dev"
echo "- https://www.santiagosainz.com"