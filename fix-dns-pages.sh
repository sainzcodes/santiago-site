#!/bin/bash

echo "🔧 Fixing DNS for Cloudflare Pages"
echo "=================================="

# Load environment variables
source .env

ZONE_ID="05a82d6107f1f7b79624f73106c3e3b1"
API_URL="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"

echo "📋 Checking current DNS records..."

# Get all DNS records
RECORDS=$(curl -s -X GET "$API_URL" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json")

# Check if successful
if ! echo "$RECORDS" | jq -e '.success' > /dev/null; then
    echo "❌ Error fetching records:"
    echo "$RECORDS" | jq '.errors'
    exit 1
fi

# Find root domain records
echo ""
echo "🔍 Looking for santiagosainz.com records..."
ROOT_RECORDS=$(echo "$RECORDS" | jq -r '.result[] | select(.name == "santiagosainz.com" and (.type == "CNAME" or .type == "A")) | "\(.id)|\(.type)|\(.content)"')

if [ -n "$ROOT_RECORDS" ]; then
    echo "Found existing records for santiagosainz.com:"
    while IFS='|' read -r id type content; do
        echo "  - $type record pointing to: $content"
        echo "    Deleting record $id..."
        
        DELETE_RESULT=$(curl -s -X DELETE "$API_URL/$id" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json")
        
        if echo "$DELETE_RESULT" | jq -e '.success' > /dev/null; then
            echo "    ✅ Deleted successfully"
        else
            echo "    ❌ Error deleting:"
            echo "$DELETE_RESULT" | jq '.errors'
        fi
    done <<< "$ROOT_RECORDS"
fi

# Create new CNAME for root domain
echo ""
echo "📝 Creating CNAME for santiagosainz.com → santiago-sainz-ai.pages.dev..."

CREATE_ROOT=$(curl -s -X POST "$API_URL" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "@",
    "content": "santiago-sainz-ai.pages.dev",
    "ttl": 1,
    "proxied": true
  }')

if echo "$CREATE_ROOT" | jq -e '.success' > /dev/null; then
    echo "✅ Created santiagosainz.com CNAME successfully!"
else
    echo "❌ Error creating root CNAME:"
    echo "$CREATE_ROOT" | jq '.errors'
fi

# Check www subdomain
echo ""
echo "🔍 Checking www.santiagosainz.com..."
WWW_RECORD=$(echo "$RECORDS" | jq -r '.result[] | select(.name == "www.santiagosainz.com") | .id')

if [ -z "$WWW_RECORD" ]; then
    echo "Creating www CNAME..."
    
    CREATE_WWW=$(curl -s -X POST "$API_URL" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{
        "type": "CNAME",
        "name": "www",
        "content": "santiago-sainz-ai.pages.dev",
        "ttl": 1,
        "proxied": true
      }')
    
    if echo "$CREATE_WWW" | jq -e '.success' > /dev/null; then
        echo "✅ Created www.santiagosainz.com CNAME successfully!"
    else
        echo "❌ Error creating www CNAME:"
        echo "$CREATE_WWW" | jq '.errors'
    fi
else
    echo "✅ www subdomain already exists"
fi

echo ""
echo "🎉 DNS update complete!"
echo ""
echo "Your website should be accessible at:"
echo "- https://santiagosainz.com"
echo "- https://www.santiagosainz.com"
echo ""
echo "DNS changes may take 1-5 minutes to propagate."