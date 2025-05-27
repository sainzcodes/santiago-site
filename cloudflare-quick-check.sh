#!/bin/bash

# Quick Cloudflare Configuration Check for santiagosainz.com
# This script provides a quick overview without any interaction

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

ZONE_ID="05a82d6107f1f7b79624f73106c3e3b1"

echo -e "${BLUE}🔍 Cloudflare Quick Check for santiagosainz.com${NC}"
echo "================================================"
echo ""

# Check for API token
if [ -z "$CF_API_TOKEN" ]; then
    echo -e "${RED}❌ Error: CF_API_TOKEN environment variable not set${NC}"
    echo "Set it with: export CF_API_TOKEN='your_token_here'"
    exit 1
fi

# Test authentication
echo -e "${BLUE}Testing authentication...${NC}"
AUTH_TEST=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

if ! echo "$AUTH_TEST" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${RED}❌ Authentication failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authentication successful${NC}"
echo ""

# Check page rules
echo -e "${BLUE}📋 Page Rules:${NC}"
RULES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

RULE_COUNT=$(echo "$RULES" | jq '.result | length')
echo "Total rules: $RULE_COUNT"

if [ "$RULE_COUNT" -gt 0 ]; then
    echo "$RULES" | jq -r '.result[] | "  • " + .targets[0].constraint.value + " (Priority: " + (.priority|tostring) + ")"'
    
    # Check for problematic rules
    CATCH_ALL=$(echo "$RULES" | jq -r '.result[] | select(.targets[0].constraint.value | contains("/*")) | .targets[0].constraint.value')
    if [ -n "$CATCH_ALL" ]; then
        echo -e "${YELLOW}⚠️  Warning: Found catch-all rules that might affect multi-page routing${NC}"
    fi
fi
echo ""

# Check DNS
echo -e "${BLUE}🌐 DNS Configuration:${NC}"
DNS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=CNAME" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

# Root domain
ROOT=$(echo "$DNS" | jq -r '.result[] | select(.name == "santiagosainz.com") | "CNAME → " + .content + " (Proxied: " + (.proxied|tostring) + ")"')
if [ -n "$ROOT" ]; then
    echo -e "  ${GREEN}✅ Root domain: $ROOT${NC}"
else
    echo -e "  ${YELLOW}⚠️  No CNAME for root domain${NC}"
fi

# WWW subdomain
WWW=$(echo "$DNS" | jq -r '.result[] | select(.name == "www.santiagosainz.com") | "CNAME → " + .content + " (Proxied: " + (.proxied|tostring) + ")"')
if [ -n "$WWW" ]; then
    echo -e "  ${GREEN}✅ WWW subdomain: $WWW${NC}"
else
    echo -e "  ${YELLOW}⚠️  No CNAME for www subdomain${NC}"
fi
echo ""

# Check SSL
echo -e "${BLUE}🔒 SSL/TLS Mode:${NC}"
SSL=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/ssl" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

SSL_MODE=$(echo "$SSL" | jq -r '.result.value')
echo "  Current mode: $SSL_MODE"
if [[ "$SSL_MODE" == "full" ]] || [[ "$SSL_MODE" == "strict" ]]; then
    echo -e "  ${GREEN}✅ SSL mode is appropriate${NC}"
else
    echo -e "  ${YELLOW}⚠️  Consider using 'Full' or 'Full (Strict)' mode${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}📊 Summary:${NC}"
echo "  • Zone ID: $ZONE_ID"
echo "  • Page Rules: $RULE_COUNT"
echo "  • DNS: Configured for Cloudflare Pages"
echo "  • SSL: $SSL_MODE mode"
echo ""

# Recommendations
if [ "$RULE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}💡 Recommendation: Consider adding basic page rules:${NC}"
    echo "  1. Always Use HTTPS"
    echo "  2. Cache static assets"
    echo "  Run ./cloudflare-page-rules.sh and select option 6"
fi