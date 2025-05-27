#!/bin/bash

# Cloudflare Page Rules Management Tool
# For santiagosainz.com

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Zone ID for santiagosainz.com
ZONE_ID="05a82d6107f1f7b79624f73106c3e3b1"

# Function to check if credentials are set
check_credentials() {
    if [ -z "$CF_API_TOKEN" ]; then
        echo -e "${YELLOW}⚠️  Cloudflare API Token not found in environment${NC}"
        echo ""
        read -sp "Enter your Cloudflare API Token: " CF_API_TOKEN
        echo ""
        export CF_API_TOKEN
        echo ""
    fi
}

# Function to test API credentials
test_credentials() {
    echo -e "${BLUE}🔐 Testing API credentials...${NC}"
    
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        ZONE_NAME=$(echo "$RESPONSE" | jq -r '.result.name')
        echo -e "${GREEN}✅ Successfully authenticated for zone: $ZONE_NAME${NC}"
        return 0
    else
        echo -e "${RED}❌ Authentication failed${NC}"
        echo "$RESPONSE" | jq '.errors' 2>/dev/null || echo "$RESPONSE"
        return 1
    fi
}

# Function to list all page rules
list_page_rules() {
    echo -e "${BLUE}📋 Fetching page rules for santiagosainz.com...${NC}"
    echo ""
    
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        RULE_COUNT=$(echo "$RESPONSE" | jq '.result | length')
        
        if [ "$RULE_COUNT" -eq 0 ]; then
            echo -e "${YELLOW}No page rules found${NC}"
        else
            echo -e "${GREEN}Found $RULE_COUNT page rule(s):${NC}"
            echo ""
            
            # Parse and display each rule
            echo "$RESPONSE" | jq -r '.result[] | 
                "ID: \(.id)\n" +
                "Priority: \(.priority)\n" +
                "Status: \(.status)\n" +
                "URL Pattern: \(.targets[0].constraint.value)\n" +
                "Actions:" +
                (.actions | map("\n  - \(.id): \(.value // .value.status_code // \"enabled\")") | join("")) +
                "\n---"'
        fi
    else
        echo -e "${RED}❌ Failed to fetch page rules${NC}"
        echo "$RESPONSE" | jq '.errors' 2>/dev/null || echo "$RESPONSE"
    fi
}

# Function to get details of a specific page rule
get_page_rule() {
    local RULE_ID=$1
    
    echo -e "${BLUE}🔍 Fetching details for page rule: $RULE_ID${NC}"
    
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules/$RULE_ID" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        echo "$RESPONSE" | jq '.result'
    else
        echo -e "${RED}❌ Failed to fetch page rule${NC}"
        echo "$RESPONSE" | jq '.errors' 2>/dev/null || echo "$RESPONSE"
    fi
}

# Function to create a page rule
create_page_rule() {
    echo -e "${BLUE}🆕 Create new page rule${NC}"
    echo ""
    
    # Get URL pattern
    read -p "Enter URL pattern (e.g., *santiagosainz.com/*): " URL_PATTERN
    
    # Select action
    echo ""
    echo "Available actions:"
    echo "1. Forwarding URL (301/302 redirect)"
    echo "2. Always Use HTTPS"
    echo "3. Cache Level"
    echo "4. Browser Cache TTL"
    echo "5. Security Level"
    echo "6. SSL Mode"
    
    read -p "Select action (1-6): " ACTION_CHOICE
    
    # Build the action JSON based on choice
    case $ACTION_CHOICE in
        1)
            read -p "Enter destination URL: " DEST_URL
            read -p "Status code (301 or 302): " STATUS_CODE
            ACTION_JSON='{"id": "forwarding_url", "value": {"url": "'$DEST_URL'", "status_code": '$STATUS_CODE'}}'
            ;;
        2)
            ACTION_JSON='{"id": "always_use_https"}'
            ;;
        3)
            echo "Cache levels: bypass, none, standard, aggressive"
            read -p "Enter cache level: " CACHE_LEVEL
            ACTION_JSON='{"id": "cache_level", "value": "'$CACHE_LEVEL'"}'
            ;;
        4)
            read -p "Enter TTL in seconds: " TTL
            ACTION_JSON='{"id": "browser_cache_ttl", "value": '$TTL'}'
            ;;
        5)
            echo "Security levels: off, essentially_off, low, medium, high, under_attack"
            read -p "Enter security level: " SEC_LEVEL
            ACTION_JSON='{"id": "security_level", "value": "'$SEC_LEVEL'"}'
            ;;
        6)
            echo "SSL modes: off, flexible, full, strict"
            read -p "Enter SSL mode: " SSL_MODE
            ACTION_JSON='{"id": "ssl", "value": "'$SSL_MODE'"}'
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return
            ;;
    esac
    
    # Priority
    read -p "Enter priority (1 = highest): " PRIORITY
    
    # Create the rule
    RULE_DATA='{
        "targets": [{
            "target": "url",
            "constraint": {
                "operator": "matches",
                "value": "'$URL_PATTERN'"
            }
        }],
        "actions": ['$ACTION_JSON'],
        "priority": '$PRIORITY',
        "status": "active"
    }'
    
    echo ""
    echo -e "${BLUE}Creating page rule...${NC}"
    
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$RULE_DATA")
    
    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Page rule created successfully!${NC}"
        echo "$RESPONSE" | jq '.result'
    else
        echo -e "${RED}❌ Failed to create page rule${NC}"
        echo "$RESPONSE" | jq '.errors' 2>/dev/null || echo "$RESPONSE"
    fi
}

# Function to delete a page rule
delete_page_rule() {
    local RULE_ID=$1
    
    echo -e "${YELLOW}⚠️  Are you sure you want to delete page rule: $RULE_ID?${NC}"
    read -p "Type 'yes' to confirm: " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules/$RULE_ID" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json")
        
        if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Page rule deleted successfully${NC}"
        else
            echo -e "${RED}❌ Failed to delete page rule${NC}"
            echo "$RESPONSE" | jq '.errors' 2>/dev/null || echo "$RESPONSE"
        fi
    else
        echo "Deletion cancelled"
    fi
}

# Function to check for common multi-page issues
check_multipage_issues() {
    echo -e "${BLUE}🔍 Checking for multi-page website issues...${NC}"
    echo ""
    
    # Check page rules
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        # Check for conflicting rules
        echo -e "${BLUE}Page Rules Analysis:${NC}"
        
        # Look for forwarding rules that might interfere
        FORWARDING_RULES=$(echo "$RESPONSE" | jq -r '.result[] | select(.actions[] | .id == "forwarding_url") | .targets[0].constraint.value')
        
        if [ -n "$FORWARDING_RULES" ]; then
            echo -e "${YELLOW}⚠️  Found forwarding rules that might affect routing:${NC}"
            echo "$FORWARDING_RULES"
            echo ""
        fi
        
        # Look for cache rules
        CACHE_RULES=$(echo "$RESPONSE" | jq -r '.result[] | select(.actions[] | .id == "cache_level") | .targets[0].constraint.value')
        
        if [ -n "$CACHE_RULES" ]; then
            echo -e "${BLUE}ℹ️  Cache rules found for:${NC}"
            echo "$CACHE_RULES"
            echo ""
        fi
    fi
    
    # Check DNS configuration
    echo -e "${BLUE}DNS Configuration:${NC}"
    
    DNS_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$DNS_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        # Check root domain
        ROOT_RECORD=$(echo "$DNS_RESPONSE" | jq -r '.result[] | select(.name == "santiagosainz.com" and .type == "CNAME") | "CNAME: " + .content + " (Proxied: " + (.proxied|tostring) + ")"')
        if [ -n "$ROOT_RECORD" ]; then
            echo -e "${GREEN}✅ Root domain: $ROOT_RECORD${NC}"
        else
            echo -e "${YELLOW}⚠️  No CNAME record found for root domain${NC}"
        fi
        
        # Check www subdomain
        WWW_RECORD=$(echo "$DNS_RESPONSE" | jq -r '.result[] | select(.name == "www.santiagosainz.com" and .type == "CNAME") | "CNAME: " + .content + " (Proxied: " + (.proxied|tostring) + ")"')
        if [ -n "$WWW_RECORD" ]; then
            echo -e "${GREEN}✅ WWW subdomain: $WWW_RECORD${NC}"
        else
            echo -e "${YELLOW}⚠️  No CNAME record found for www subdomain${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Recommendations for multi-page setup:${NC}"
    echo "1. Ensure no page rules are redirecting all paths to index.html"
    echo "2. Check that your hosting platform (Pages/Workers) handles routing correctly"
    echo "3. Consider adding cache rules for static assets (CSS, JS, images)"
    echo "4. Verify SSL/TLS settings are set to 'Full' or 'Full (Strict)'"
}

# Function to create recommended rules for multi-page site
create_recommended_rules() {
    echo -e "${BLUE}🚀 Creating recommended page rules for multi-page website${NC}"
    echo ""
    
    # Rule 1: Always use HTTPS
    echo -e "${BLUE}Creating rule 1: Always use HTTPS...${NC}"
    
    RULE1_DATA='{
        "targets": [{
            "target": "url",
            "constraint": {
                "operator": "matches",
                "value": "http://*santiagosainz.com/*"
            }
        }],
        "actions": [{"id": "always_use_https"}],
        "priority": 1,
        "status": "active"
    }'
    
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$RULE1_DATA" > /dev/null
    
    # Rule 2: Cache static assets
    echo -e "${BLUE}Creating rule 2: Cache static assets...${NC}"
    
    RULE2_DATA='{
        "targets": [{
            "target": "url",
            "constraint": {
                "operator": "matches",
                "value": "*santiagosainz.com/*.{css,js,jpg,jpeg,png,gif,svg,ico,woff,woff2}"
            }
        }],
        "actions": [
            {"id": "cache_level", "value": "cache_everything"},
            {"id": "browser_cache_ttl", "value": 31536000}
        ],
        "priority": 2,
        "status": "active"
    }'
    
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/pagerules" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$RULE2_DATA" > /dev/null
    
    echo -e "${GREEN}✅ Recommended rules created!${NC}"
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}=== Cloudflare Page Rules Manager ===${NC}"
    echo -e "${BLUE}Zone: santiagosainz.com${NC}"
    echo ""
    echo "1. List all page rules"
    echo "2. Get page rule details"
    echo "3. Create new page rule"
    echo "4. Delete page rule"
    echo "5. Check for multi-page website issues"
    echo "6. Create recommended rules for multi-page site"
    echo "7. Test API credentials"
    echo "8. Exit"
    echo ""
}

# Main program
main() {
    # Check for jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is required but not installed.${NC}"
        echo "Install with: brew install jq"
        exit 1
    fi
    
    # Check credentials
    check_credentials
    
    # Test credentials
    if ! test_credentials; then
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Select an option (1-8): " choice
        
        case $choice in
            1)
                list_page_rules
                ;;
            2)
                read -p "Enter page rule ID: " RULE_ID
                get_page_rule "$RULE_ID"
                ;;
            3)
                create_page_rule
                ;;
            4)
                read -p "Enter page rule ID to delete: " RULE_ID
                delete_page_rule "$RULE_ID"
                ;;
            5)
                check_multipage_issues
                ;;
            6)
                create_recommended_rules
                ;;
            7)
                test_credentials
                ;;
            8)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main program
main