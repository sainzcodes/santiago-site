#!/bin/bash

echo "🔄 Purging Cloudflare Cache"
echo "=========================="

API_TOKEN="dS2trjS1gbj7OeV-zlr7Ow-XUQcctppGAsBc_FJU"
ZONE_ID="05a82d6107f1f7b79624f73106c3e3b1"

echo "📋 Purging cache for all URLs..."

# Purge everything
PURGE_RESPONSE=$(curl -s -X POST \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}')

if echo "$PURGE_RESPONSE" | grep -q '"success":true'; then
    echo "✅ Cache purged successfully!"
    echo ""
    echo "🔄 Forcing deployment refresh..."
    
    # Also purge specific URLs
    curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{
        "files": [
          "https://santiagosainz.com/",
          "https://santiagosainz.com/index.html",
          "https://santiagosainz.com/styles.css",
          "https://www.santiagosainz.com/",
          "https://www.santiagosainz.com/index.html",
          "https://www.santiagosainz.com/styles.css"
        ]
      }' > /dev/null
    
    echo "✅ Specific files purged!"
else
    echo "❌ Cache purge failed:"
    echo "$PURGE_RESPONSE" | jq '.errors' 2>/dev/null
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Wait 30 seconds for cache to clear"
echo "2. Hard refresh your browser: Cmd+Shift+R (Mac) or Ctrl+F5 (Windows)"
echo "3. Or try incognito/private browsing mode"
echo ""
echo "Your new black & teal website should now be visible!"