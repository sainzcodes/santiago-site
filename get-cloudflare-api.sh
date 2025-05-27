#!/bin/bash

# Cloudflare API Token Retrieval Script
# This script helps you get your API token from existing Cloudflare credentials

echo "🔐 Cloudflare API Token Retrieval"
echo "=================================="
echo ""

# Check for existing credentials in common locations
check_existing_credentials() {
    echo "🔍 Checking for existing Cloudflare credentials..."
    echo ""
    
    # Check .env file
    if [ -f ".env" ]; then
        TOKEN=$(grep "CF_API_TOKEN" .env | cut -d'=' -f2)
        if [ ! -z "$TOKEN" ]; then
            echo "✅ Found token in .env file"
            echo "Token: ${TOKEN:0:20}..."
            export CF_API_TOKEN="$TOKEN"
            return 0
        fi
    fi
    
    # Check environment variable
    if [ ! -z "$CF_API_TOKEN" ]; then
        echo "✅ Found token in environment variable"
        echo "Token: ${CF_API_TOKEN:0:20}..."
        return 0
    fi
    
    # Check cloudflare config
    if [ -f "$HOME/.cloudflare/config.yml" ]; then
        echo "📁 Found Cloudflare config at ~/.cloudflare/config.yml"
    fi
    
    return 1
}

# Get API token using email and global API key
get_token_with_api_key() {
    echo "📧 Method 1: Using Email + Global API Key"
    echo "==========================================="
    echo ""
    echo "Find your Global API Key:"
    echo "1. Go to: https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Scroll down to 'Global API Key'"
    echo "3. Click 'View' (enter password)"
    echo ""
    
    read -p "Enter your Cloudflare email: " CF_EMAIL
    read -s -p "Enter your Global API Key: " CF_KEY
    echo ""
    echo ""
    
    # Test credentials
    echo "🧪 Testing credentials..."
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user" \
         -H "X-Auth-Email: $CF_EMAIL" \
         -H "X-Auth-Key: $CF_KEY" \
         -H "Content-Type: application/json")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo "✅ Credentials valid!"
        echo ""
        echo "⚠️  Note: Global API Key has full account access."
        echo "📌 Recommendation: Create a scoped API token instead."
        echo ""
        
        # Save option
        read -p "Save credentials to .env? (y/n): " SAVE
        if [[ "$SAVE" == "y" || "$SAVE" == "Y" ]]; then
            echo "CF_EMAIL=$CF_EMAIL" > .env
            echo "CF_KEY=$CF_KEY" >> .env
            echo "✅ Saved to .env"
        fi
        
        export CF_EMAIL="$CF_EMAIL"
        export CF_KEY="$CF_KEY"
        return 0
    else
        echo "❌ Invalid credentials"
        return 1
    fi
}

# Create new API token programmatically
create_api_token() {
    echo "🔨 Method 2: Create New API Token"
    echo "================================="
    echo ""
    
    if [ -z "$CF_EMAIL" ] || [ -z "$CF_KEY" ]; then
        echo "❌ Need email and API key first"
        get_token_with_api_key
    fi
    
    echo "📝 Creating scoped API token..."
    
    # First get account ID
    ACCOUNT_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
         -H "X-Auth-Email: $CF_EMAIL" \
         -H "X-Auth-Key: $CF_KEY" \
         -H "Content-Type: application/json")
    
    ACCOUNT_ID=$(echo "$ACCOUNT_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    # Create token with specific permissions
    TOKEN_PAYLOAD=$(cat <<EOF
{
  "name": "Santiago Sainz Website Management - $(date +%Y%m%d)",
  "policies": [
    {
      "effect": "allow",
      "resources": {
        "com.cloudflare.api.account.zone.*": "*"
      },
      "permission_groups": [
        {
          "id": "c1fde68c7bcc44588cbb6ddbc16d6480",
          "name": "Zone Read"
        },
        {
          "id": "ed07f6c337da4195b4e72a1fb2c6bcae",
          "name": "Page Rules Write"
        },
        {
          "id": "f2877111d0ee446fa3096eca45089bed",
          "name": "Zone Settings Write"
        }
      ]
    }
  ]
}
EOF
)
    
    CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/user/tokens" \
         -H "X-Auth-Email: $CF_EMAIL" \
         -H "X-Auth-Key: $CF_KEY" \
         -H "Content-Type: application/json" \
         -d "$TOKEN_PAYLOAD")
    
    if echo "$CREATE_RESPONSE" | grep -q '"success":true'; then
        NEW_TOKEN=$(echo "$CREATE_RESPONSE" | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
        echo "✅ Token created successfully!"
        echo ""
        echo "🔑 Your new API token:"
        echo "$NEW_TOKEN"
        echo ""
        echo "CF_API_TOKEN=$NEW_TOKEN" > .env
        echo "✅ Saved to .env file"
        export CF_API_TOKEN="$NEW_TOKEN"
        return 0
    else
        echo "❌ Failed to create token"
        echo "$CREATE_RESPONSE" | python3 -m json.tool
        return 1
    fi
}

# Use Cloudflare CLI if installed
check_cloudflare_cli() {
    echo "🖥️  Method 3: Using Cloudflare CLI"
    echo "=================================="
    
    if command -v flarectl &> /dev/null; then
        echo "✅ Cloudflare CLI (flarectl) found"
        flarectl user info
    elif command -v wrangler &> /dev/null; then
        echo "✅ Wrangler CLI found"
        echo "Run: wrangler login"
    else
        echo "❌ No Cloudflare CLI tools found"
        echo ""
        echo "Install with:"
        echo "  brew install cloudflare/cloudflare/cloudflared"
        echo "  npm install -g wrangler"
    fi
}

# Browser automation option
open_browser_method() {
    echo "🌐 Method 4: Open Browser (Recommended)"
    echo "======================================="
    echo ""
    echo "Opening Cloudflare dashboard..."
    open "https://dash.cloudflare.com/profile/api-tokens"
    echo ""
    echo "1. Click 'Create Token'"
    echo "2. Use 'Custom token'"
    echo "3. Add permissions:"
    echo "   - Zone:Zone:Read"
    echo "   - Zone:Page Rules:Edit"
    echo "   - Zone:Zone Settings:Edit"
    echo "4. Select zone: santiagosainz.com"
    echo "5. Create and copy token"
    echo ""
    read -p "Paste your token here: " BROWSER_TOKEN
    
    if [ ! -z "$BROWSER_TOKEN" ]; then
        echo "CF_API_TOKEN=$BROWSER_TOKEN" > .env
        export CF_API_TOKEN="$BROWSER_TOKEN"
        echo "✅ Token saved!"
        return 0
    fi
    return 1
}

# Main menu
main_menu() {
    while true; do
        echo ""
        echo "🔐 Choose method to get Cloudflare API token:"
        echo ""
        echo "1) Check existing credentials"
        echo "2) Use email + Global API Key"
        echo "3) Create new API token (requires Global API Key)"
        echo "4) Check for CLI tools"
        echo "5) Open browser (recommended for first time)"
        echo "6) Exit"
        echo ""
        read -p "Select option (1-6): " choice
        
        case $choice in
            1)
                check_existing_credentials && break
                ;;
            2)
                get_token_with_api_key && break
                ;;
            3)
                create_api_token && break
                ;;
            4)
                check_cloudflare_cli
                ;;
            5)
                open_browser_method && break
                ;;
            6)
                echo "👋 Exiting..."
                exit 0
                ;;
            *)
                echo "❌ Invalid option"
                ;;
        esac
    done
}

# Run main program
main_menu

# Test the token if we have one
if [ ! -z "$CF_API_TOKEN" ]; then
    echo ""
    echo "🧪 Testing API token..."
    TEST_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/05a82d6107f1f7b79624f73106c3e3b1" \
         -H "Authorization: Bearer $CF_API_TOKEN" \
         -H "Content-Type: application/json")
    
    if echo "$TEST_RESPONSE" | grep -q '"success":true'; then
        echo "✅ Token is working!"
        echo ""
        echo "🚀 Next steps:"
        echo "   ./cloudflare-quick-check.sh    # Check current setup"
        echo "   ./cloudflare-page-rules.sh     # Manage page rules"
    else
        echo "❌ Token test failed"
    fi
fi