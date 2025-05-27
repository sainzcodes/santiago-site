#!/bin/bash

# Quick token setup script
echo "🔐 Setting up your Cloudflare token..."
echo ""

# The token you provided
TOKEN="4Wl9mSh43MWpwmV7yPYY2x58OXi7iTVjHsrWsQzE"

# Test the token
echo "Testing token..."
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/05a82d6107f1f7b79624f73106c3e3b1" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json")

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ Token is valid and working!"
    
    # Save to .env
    echo "CF_API_TOKEN=$TOKEN" > .env
    
    # Add to .gitignore
    if ! grep -q "^.env$" .gitignore 2>/dev/null; then
        echo ".env" >> .gitignore
    fi
    
    echo "✅ Token saved to .env file"
    echo ""
    
    # Export for current session
    export CF_API_TOKEN="$TOKEN"
    
    echo "🚀 Running diagnostics..."
    echo ""
    
    # Run quick check
    if [ -f "./cloudflare-quick-check.sh" ]; then
        ./cloudflare-quick-check.sh
    else
        echo "Now run: ./cloudflare-quick-check.sh"
    fi
else
    echo "❌ Token validation failed"
    echo "$RESPONSE" | python3 -m json.tool
fi