#!/bin/bash

echo "🔧 Cloudflare DNS Update Script"
echo "=============================="
echo ""
echo "This script will update your DNS records to point to your new website."
echo ""

# You'll need to set these
read -p "Enter your Cloudflare API Token: " CF_API_TOKEN
read -p "Enter your Zone ID (find in Cloudflare dashboard overview): " ZONE_ID

# API endpoint
API_URL="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"

echo ""
echo "🔍 Fetching current DNS records..."

# Get all DNS records
RECORDS=$(curl -s -X GET "$API_URL" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json")

# Find the CNAME record for santiagosainz.com
RECORD_ID=$(echo $RECORDS | jq -r '.result[] | select(.name == "santiagosainz.com" and .type == "CNAME") | .id')

if [ -n "$RECORD_ID" ]; then
    echo "✅ Found existing CNAME record for santiagosainz.com"
    echo "📝 Updating to point to santiago-sainz-ai.pages.dev..."
    
    # Update the existing record
    UPDATE_RESULT=$(curl -s -X PUT "$API_URL/$RECORD_ID" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{
        "type": "CNAME",
        "name": "santiagosainz.com",
        "content": "santiago-sainz-ai.pages.dev",
        "ttl": 1,
        "proxied": true
      }')
    
    if echo $UPDATE_RESULT | jq -e '.success' > /dev/null; then
        echo "✅ Successfully updated santiagosainz.com!"
    else
        echo "❌ Error updating record:"
        echo $UPDATE_RESULT | jq '.errors'
    fi
else
    echo "❌ CNAME record for santiagosainz.com not found"
    echo "Creating new record..."
    
    # Create new CNAME record
    CREATE_RESULT=$(curl -s -X POST "$API_URL" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{
        "type": "CNAME",
        "name": "santiagosainz.com",
        "content": "santiago-sainz-ai.pages.dev",
        "ttl": 1,
        "proxied": true
      }')
    
    if echo $CREATE_RESULT | jq -e '.success' > /dev/null; then
        echo "✅ Successfully created santiagosainz.com record!"
    else
        echo "❌ Error creating record:"
        echo $CREATE_RESULT | jq '.errors'
    fi
fi

# Check if www record exists
WWW_RECORD_ID=$(echo $RECORDS | jq -r '.result[] | select(.name == "www.santiagosainz.com" and .type == "CNAME") | .id')

if [ -z "$WWW_RECORD_ID" ]; then
    echo ""
    echo "📝 Creating www subdomain..."
    
    # Create www CNAME record
    WWW_RESULT=$(curl -s -X POST "$API_URL" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{
        "type": "CNAME",
        "name": "www",
        "content": "santiago-sainz-ai.pages.dev",
        "ttl": 1,
        "proxied": true
      }')
    
    if echo $WWW_RESULT | jq -e '.success' > /dev/null; then
        echo "✅ Successfully created www.santiagosainz.com!"
    else
        echo "❌ Error creating www record:"
        echo $WWW_RESULT | jq '.errors'
    fi
else
    echo "✅ www subdomain already exists"
fi

echo ""
echo "🎉 DNS update complete!"
echo ""
echo "Your website will be live at:"
echo "- https://santiagosainz.com"
echo "- https://www.santiagosainz.com"
echo ""
echo "Changes should take effect within 1-5 minutes."