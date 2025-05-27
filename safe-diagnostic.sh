#!/bin/bash

# Safe Cloudflare Diagnostic Script
# This helps diagnose issues WITHOUT needing your sensitive keys

echo "🔒 Safe Cloudflare Diagnostic Tool"
echo "=================================="
echo ""
echo "This tool helps identify issues without exposing credentials"
echo ""

# 1. Check DNS resolution
echo "1️⃣ Checking DNS for santiagosainz.com..."
dig santiagosainz.com +short
echo ""

# 2. Check HTTP headers
echo "2️⃣ Checking HTTP response headers..."
curl -sI https://santiagosainz.com | head -10
echo ""

# 3. Check page loading
echo "3️⃣ Testing page routes..."
for page in "" "about.html" "products.html" "consulting.html" "contact.html"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://santiago-sainz-ai.pages.dev/$page")
    if [ "$STATUS" = "200" ]; then
        echo "✅ /$page - OK ($STATUS)"
    else
        echo "❌ /$page - Error ($STATUS)"
    fi
done
echo ""

# 4. Check Cloudflare presence
echo "4️⃣ Checking Cloudflare configuration..."
HEADERS=$(curl -sI https://santiagosainz.com)
if echo "$HEADERS" | grep -q "cf-ray"; then
    echo "✅ Site is using Cloudflare"
    CF_RAY=$(echo "$HEADERS" | grep "cf-ray" | cut -d' ' -f2)
    echo "   Ray ID: $CF_RAY"
else
    echo "⚠️  Cloudflare headers not detected"
fi
echo ""

# 5. Common issues
echo "5️⃣ Common Issues & Solutions:"
echo ""
echo "If pages aren't loading:"
echo "• Check if files exist in GitHub repo"
echo "• Verify Cloudflare Pages deployment succeeded"
echo "• Look for redirect rules blocking access"
echo ""
echo "If you see 404 errors:"
echo "• Cloudflare Pages might need index.html in each folder"
echo "• Check Build settings in Cloudflare dashboard"
echo ""

# 6. Next steps
echo "📋 To fix issues, you can:"
echo "1. Create a scoped API token (safe)"
echo "2. Check Cloudflare Pages dashboard"
echo "3. Review GitHub repository structure"
echo ""
echo "Run: ./auto-get-token.sh to safely create a limited token"