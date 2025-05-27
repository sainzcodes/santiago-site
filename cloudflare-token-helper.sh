#!/bin/bash

# Cloudflare Token Setup Helper
# This script helps you test and store your Cloudflare API token

echo "🔐 Cloudflare API Token Setup Helper"
echo "===================================="
echo ""
echo "📋 Quick Setup Instructions:"
echo "1. In the Cloudflare dashboard that just opened:"
echo "   - Click 'Create Token'"
echo "   - Select 'Custom token' → 'Get started'"
echo ""
echo "2. Configure these permissions:"
echo "   ✓ Zone:Zone:Read"
echo "   ✓ Zone:Page Rules:Edit"
echo "   ✓ Zone:Zone Settings:Edit"
echo ""
echo "3. Zone Resources: Include → santiagosainz.com"
echo ""
echo "4. Create token and copy it"
echo ""
echo "===================================="
echo ""

# Prompt for token
read -p "🔑 Paste your Cloudflare API token here: " CF_TOKEN

# Test the token
echo ""
echo "🧪 Testing your token..."
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/05a82d6107f1f7b79624f73106c3e3b1" \
     -H "Authorization: Bearer $CF_TOKEN" \
     -H "Content-Type: application/json")

# Check if successful
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ Token is valid and working!"
    
    # Extract zone name
    ZONE_NAME=$(echo "$RESPONSE" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "📍 Connected to zone: $ZONE_NAME"
    
    # Save to .env file
    echo ""
    read -p "💾 Save token to .env file? (y/n): " SAVE_CHOICE
    if [[ "$SAVE_CHOICE" == "y" || "$SAVE_CHOICE" == "Y" ]]; then
        echo "CF_API_TOKEN=$CF_TOKEN" > .env
        
        # Add to .gitignore if not already there
        if ! grep -q "^.env$" .gitignore 2>/dev/null; then
            echo ".env" >> .gitignore
            echo "✅ Added .env to .gitignore"
        fi
        
        echo "✅ Token saved to .env file"
        echo ""
        echo "📝 To use in future sessions:"
        echo "   source .env"
        echo "   export CF_API_TOKEN"
    fi
    
    # Export for current session
    export CF_API_TOKEN="$CF_TOKEN"
    
    echo ""
    echo "🚀 Ready to use Cloudflare tools!"
    echo ""
    echo "Next steps:"
    echo "1. Run diagnostics: ./cloudflare-quick-check.sh"
    echo "2. Manage rules: ./cloudflare-page-rules.sh"
    
else
    echo "❌ Token validation failed!"
    echo ""
    echo "Error response:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    echo ""
    echo "Common issues:"
    echo "- Token not copied correctly (check for spaces)"
    echo "- Missing permissions (need Zone:Read and Page Rules:Edit)"
    echo "- Wrong zone selected (should be santiagosainz.com)"
fi