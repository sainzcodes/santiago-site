#!/usr/bin/env python3
"""
Cloudflare DNS Update Script for santiagosainz.com
Updates DNS records to point to santiago-sainz-ai.pages.dev
"""

import os
import sys
import json
import requests
from typing import Dict, List, Optional

# Configuration
ZONE_ID = "05a82d6107f1f7b79624f73106c3e3b1"
TARGET_CNAME = "santiago-sainz-ai.pages.dev"
DOMAIN = "santiagosainz.com"

def get_api_token() -> str:
    """Get API token from environment or .env file"""
    # Try environment variable first
    token = os.environ.get('CF_API_TOKEN')
    
    # Try .env file
    if not token and os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('CF_API_TOKEN='):
                    token = line.strip().split('=', 1)[1].strip('"\'')
                    break
    
    if not token:
        print("❌ Error: No API token found!")
        print("Please set CF_API_TOKEN environment variable or add to .env file")
        print("\nTo create a new token:")
        print("1. Go to https://dash.cloudflare.com/profile/api-tokens")
        print("2. Create token with 'Zone:DNS:Edit' permission for santiagosainz.com")
        sys.exit(1)
    
    return token

def make_api_request(method: str, endpoint: str, token: str, data: Optional[Dict] = None) -> Dict:
    """Make API request to Cloudflare"""
    url = f"https://api.cloudflare.com/client/v4{endpoint}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    if method == "GET":
        response = requests.get(url, headers=headers)
    elif method == "POST":
        response = requests.post(url, headers=headers, json=data)
    elif method == "PUT":
        response = requests.put(url, headers=headers, json=data)
    elif method == "DELETE":
        response = requests.delete(url, headers=headers)
    else:
        raise ValueError(f"Unsupported method: {method}")
    
    result = response.json()
    
    if not result.get('success', False):
        errors = result.get('errors', [])
        error_messages = [f"{e.get('code', 'Unknown')}: {e.get('message', 'Unknown error')}" for e in errors]
        
        # Check for specific authentication error
        if any('10000' in str(e.get('code', '')) for e in errors):
            print("\n❌ Authentication Error!")
            print("Your API token doesn't have the required permissions.")
            print("\nTo fix this:")
            print("1. Go to https://dash.cloudflare.com/profile/api-tokens")
            print("2. Create a new token with these permissions:")
            print("   - Zone:DNS:Edit")
            print("   - Zone:Zone:Read")
            print("3. Select 'Include - Specific zone' → santiagosainz.com")
            print("4. Update your .env file with the new token")
            sys.exit(1)
        
        raise Exception(f"API Error: {', '.join(error_messages)}")
    
    return result

def get_dns_records(token: str) -> List[Dict]:
    """Get all DNS records for the zone"""
    print("🔍 Fetching current DNS records...")
    result = make_api_request("GET", f"/zones/{ZONE_ID}/dns_records", token)
    return result.get('result', [])

def find_record(records: List[Dict], name: str, record_type: str) -> Optional[Dict]:
    """Find a specific DNS record"""
    for record in records:
        if record['name'] == name and record['type'] == record_type:
            return record
    return None

def delete_record(token: str, record_id: str, name: str) -> None:
    """Delete a DNS record"""
    print(f"🗑️  Deleting record for {name}...")
    make_api_request("DELETE", f"/zones/{ZONE_ID}/dns_records/{record_id}", token)
    print(f"✅ Deleted record for {name}")

def create_cname_record(token: str, name: str, content: str) -> None:
    """Create a CNAME record"""
    print(f"➕ Creating CNAME record: {name} → {content}...")
    data = {
        "type": "CNAME",
        "name": name,
        "content": content,
        "ttl": 1,  # Auto TTL
        "proxied": True  # Enable Cloudflare proxy
    }
    make_api_request("POST", f"/zones/{ZONE_ID}/dns_records", token, data)
    print(f"✅ Created CNAME record for {name}")

def update_cname_record(token: str, record_id: str, name: str, content: str) -> None:
    """Update an existing CNAME record"""
    print(f"📝 Updating CNAME record: {name} → {content}...")
    data = {
        "type": "CNAME",
        "name": name,
        "content": content,
        "ttl": 1,  # Auto TTL
        "proxied": True  # Enable Cloudflare proxy
    }
    make_api_request("PUT", f"/zones/{ZONE_ID}/dns_records/{record_id}", token, data)
    print(f"✅ Updated CNAME record for {name}")

def main():
    """Main function to update DNS records"""
    print("🔧 Cloudflare DNS Update Script")
    print("==============================")
    print(f"Domain: {DOMAIN}")
    print(f"Target: {TARGET_CNAME}")
    print(f"Zone ID: {ZONE_ID}")
    print()
    
    # Get API token
    token = get_api_token()
    
    try:
        # Get all DNS records
        records = get_dns_records(token)
        print(f"📊 Found {len(records)} DNS records total\n")
        
        # Process root domain
        root_record = find_record(records, DOMAIN, "CNAME")
        if root_record:
            current_content = root_record['content']
            print(f"📍 Current root domain points to: {current_content}")
            
            if current_content == "default-page.cloudflareregistrar.com":
                # Delete the old record pointing to default page
                delete_record(token, root_record['id'], DOMAIN)
                # Create new record pointing to Pages
                create_cname_record(token, DOMAIN, TARGET_CNAME)
            elif current_content == TARGET_CNAME:
                print(f"✅ Root domain already points to {TARGET_CNAME}")
            else:
                # Update to new target
                update_cname_record(token, root_record['id'], DOMAIN, TARGET_CNAME)
        else:
            # No CNAME record exists, create one
            print(f"⚠️  No CNAME record found for {DOMAIN}")
            create_cname_record(token, DOMAIN, TARGET_CNAME)
        
        print()
        
        # Process www subdomain
        www_name = f"www.{DOMAIN}"
        www_record = find_record(records, www_name, "CNAME")
        if www_record:
            current_content = www_record['content']
            print(f"📍 Current www subdomain points to: {current_content}")
            
            if current_content != TARGET_CNAME:
                update_cname_record(token, www_record['id'], www_name, TARGET_CNAME)
            else:
                print(f"✅ www subdomain already points to {TARGET_CNAME}")
        else:
            # Create www record
            print(f"⚠️  No CNAME record found for www.{DOMAIN}")
            create_cname_record(token, "www", TARGET_CNAME)
        
        print()
        print("🎉 DNS update complete!")
        print()
        print("Your website will be live at:")
        print(f"- https://{DOMAIN}")
        print(f"- https://www.{DOMAIN}")
        print()
        print("Changes should take effect within 1-5 minutes.")
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()