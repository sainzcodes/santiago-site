#!/bin/bash

# Automated Cloudflare API Token Getter
# Tries multiple methods to find or create your API token

echo "🤖 Automated Cloudflare API Token Finder"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test a token
test_token() {
    local token=$1
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/05a82d6107f1f7b79624f73106c3e3b1" \
         -H "Authorization: Bearer $token" \
         -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        return 0
    else
        return 1
    fi
}

# 1. Check environment variable
echo "1️⃣ Checking environment variables..."
if [ ! -z "$CF_API_TOKEN" ]; then
    echo -e "${GREEN}✓ Found CF_API_TOKEN in environment${NC}"
    if test_token "$CF_API_TOKEN"; then
        echo -e "${GREEN}✓ Token is valid!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Token is invalid${NC}"
    fi
else
    echo "   No CF_API_TOKEN found"
fi

# 2. Check .env file
echo ""
echo "2️⃣ Checking .env file..."
if [ -f ".env" ]; then
    source .env
    if [ ! -z "$CF_API_TOKEN" ]; then
        echo -e "${GREEN}✓ Found token in .env${NC}"
        if test_token "$CF_API_TOKEN"; then
            echo -e "${GREEN}✓ Token is valid!${NC}"
            export CF_API_TOKEN
            exit 0
        else
            echo -e "${RED}✗ Token is invalid${NC}"
        fi
    else
        echo "   No token in .env"
    fi
else
    echo "   No .env file found"
fi

# 3. Check common config locations
echo ""
echo "3️⃣ Checking common config locations..."

# Check ~/.cloudflare
if [ -f "$HOME/.cloudflare/config.yml" ]; then
    echo -e "${BLUE}ℹ Found ~/.cloudflare/config.yml${NC}"
    # Try to extract token (if stored there)
    TOKEN=$(grep "api_token:" "$HOME/.cloudflare/config.yml" 2>/dev/null | cut -d':' -f2 | tr -d ' ')
    if [ ! -z "$TOKEN" ] && test_token "$TOKEN"; then
        echo -e "${GREEN}✓ Found valid token in config${NC}"
        echo "CF_API_TOKEN=$TOKEN" > .env
        export CF_API_TOKEN="$TOKEN"
        exit 0
    fi
fi

# Check wrangler config
if [ -f "$HOME/.wrangler/config/default.toml" ]; then
    echo -e "${BLUE}ℹ Found wrangler config${NC}"
fi

# 4. Try to use system keychain (macOS)
echo ""
echo "4️⃣ Checking macOS Keychain..."
if command -v security &> /dev/null; then
    TOKEN=$(security find-generic-password -s "cloudflare-api-token" -w 2>/dev/null)
    if [ ! -z "$TOKEN" ] && test_token "$TOKEN"; then
        echo -e "${GREEN}✓ Found valid token in Keychain${NC}"
        echo "CF_API_TOKEN=$TOKEN" > .env
        export CF_API_TOKEN="$TOKEN"
        exit 0
    else
        echo "   No valid token in Keychain"
    fi
fi

# 5. Final option - guide to create
echo ""
echo "5️⃣ No valid token found. Let's create one!"
echo ""
echo -e "${BLUE}Opening Cloudflare dashboard...${NC}"
open "https://dash.cloudflare.com/profile/api-tokens"

echo ""
echo "Quick Instructions:"
echo "=================="
echo "1. Click '${GREEN}Create Token${NC}'"
echo "2. Select '${GREEN}Custom token${NC}' → '${GREEN}Get started${NC}'"
echo "3. Add these permissions:"
echo "   • Zone → Zone → Read"
echo "   • Zone → Page Rules → Edit"
echo "   • Zone → Zone Settings → Edit"
echo "4. Zone Resources: Include → ${BLUE}santiagosainz.com${NC}"
echo "5. Click '${GREEN}Create Token${NC}'"
echo "6. ${RED}COPY THE TOKEN${NC} (you won't see it again!)"
echo ""
echo "Paste your token below:"
echo -n "> "
read NEW_TOKEN

if [ ! -z "$NEW_TOKEN" ]; then
    echo ""
    echo "Testing token..."
    if test_token "$NEW_TOKEN"; then
        echo -e "${GREEN}✓ Token is valid!${NC}"
        echo "CF_API_TOKEN=$NEW_TOKEN" > .env
        
        # Add to .gitignore
        if ! grep -q "^.env$" .gitignore 2>/dev/null; then
            echo ".env" >> .gitignore
        fi
        
        # Optionally save to keychain
        if command -v security &> /dev/null; then
            echo ""
            read -p "Save to macOS Keychain for future use? (y/n): " SAVE_KEYCHAIN
            if [[ "$SAVE_KEYCHAIN" == "y" || "$SAVE_KEYCHAIN" == "Y" ]]; then
                security add-generic-password -s "cloudflare-api-token" -a "$USER" -w "$NEW_TOKEN"
                echo -e "${GREEN}✓ Saved to Keychain${NC}"
            fi
        fi
        
        export CF_API_TOKEN="$NEW_TOKEN"
        echo ""
        echo -e "${GREEN}✅ Setup complete!${NC}"
        echo ""
        echo "Run these commands to check your site:"
        echo "  ./cloudflare-quick-check.sh"
        echo "  ./cloudflare-page-rules.sh"
    else
        echo -e "${RED}✗ Token is invalid. Please check and try again.${NC}"
        exit 1
    fi
else
    echo -e "${RED}No token provided${NC}"
    exit 1
fi