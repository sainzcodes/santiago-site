#!/bin/bash

echo "🔄 Creating Redirect Rule for Root Domain"
echo "========================================"

# Load environment variables
source .env

ZONE_ID="05a82d6107f1f7b79624f73106c3e3b1"

# Check for new API token
if [ -z "$CF_API_TOKEN" ]; then
    echo "❌ Error: CF_API_TOKEN not found in .env"
    exit 1
fi

echo "📋 Creating redirect rule: santiagosainz.com → www.santiagosainz.com"
echo ""

# Create redirect rule using the new Ruleset API
RULE_RESPONSE=$(curl -s -X PUT \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_request_dynamic_redirect/entrypoint" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "rules": [
      {
        "expression": "(http.host eq \"santiagosainz.com\")",
        "description": "Redirect root domain to www",
        "action": "redirect",
        "action_parameters": {
          "from_value": {
            "status_code": 301,
            "target_url": {
              "expression": "concat(\"https://www.santiagosainz.com\", http.request.uri.path)"
            },
            "preserve_query_string": true
          }
        }
      }
    ]
  }')

# Check if successful
if echo "$RULE_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ Redirect rule created successfully!"
    echo ""
    echo "🎉 Your website is now fully configured:"
    echo "- https://santiagosainz.com → redirects to → https://www.santiagosainz.com"
    echo "- https://www.santiagosainz.com → shows your new website"
    echo ""
    echo "The redirect should be active immediately!"
else
    echo "❌ Error creating redirect rule:"
    echo "$RULE_RESPONSE" | jq '.' 2>/dev/null || echo "$RULE_RESPONSE"
    echo ""
    echo "📋 Manual Steps:"
    echo "1. Go to: https://dash.cloudflare.com"
    echo "2. Click on 'santiagosainz.com'"
    echo "3. Go to Rules → Redirect Rules"
    echo "4. Click 'Create rule'"
    echo "5. Set up:"
    echo "   - Rule name: Root to WWW Redirect"
    echo "   - When: Hostname equals 'santiagosainz.com'"
    echo "   - Then: Dynamic redirect"
    echo "   - Expression: concat('https://www.santiagosainz.com', http.request.uri.path)"
    echo "   - Status: 301"
    echo "6. Save and deploy"
fi