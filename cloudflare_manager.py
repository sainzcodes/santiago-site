#!/usr/bin/env python3
"""
Cloudflare Page Rules Manager for santiagosainz.com
Provides comprehensive management of page rules and diagnostics for multi-page websites
"""

import json
import os
import sys
import requests
from typing import Dict, List, Optional
from datetime import datetime

class CloudflareManager:
    def __init__(self, zone_id: str, api_token: Optional[str] = None):
        self.zone_id = zone_id
        self.api_token = api_token or os.environ.get('CF_API_TOKEN')
        self.base_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}"
        self.headers = {
            'Authorization': f'Bearer {self.api_token}',
            'Content-Type': 'application/json'
        }
        
    def test_credentials(self) -> bool:
        """Test if the API credentials are valid"""
        try:
            response = requests.get(self.base_url, headers=self.headers)
            data = response.json()
            if data.get('success'):
                print(f"✅ Successfully authenticated for zone: {data['result']['name']}")
                return True
            else:
                print(f"❌ Authentication failed: {data.get('errors', 'Unknown error')}")
                return False
        except Exception as e:
            print(f"❌ Connection error: {e}")
            return False
    
    def list_page_rules(self) -> List[Dict]:
        """List all page rules for the zone"""
        try:
            response = requests.get(f"{self.base_url}/pagerules", headers=self.headers)
            data = response.json()
            
            if data.get('success'):
                rules = data.get('result', [])
                if not rules:
                    print("📋 No page rules found")
                else:
                    print(f"📋 Found {len(rules)} page rule(s):\n")
                    for rule in rules:
                        self._print_rule(rule)
                return rules
            else:
                print(f"❌ Failed to fetch page rules: {data.get('errors')}")
                return []
        except Exception as e:
            print(f"❌ Error: {e}")
            return []
    
    def _print_rule(self, rule: Dict):
        """Pretty print a page rule"""
        print(f"ID: {rule['id']}")
        print(f"Priority: {rule['priority']}")
        print(f"Status: {rule['status']}")
        print(f"URL Pattern: {rule['targets'][0]['constraint']['value']}")
        print("Actions:")
        for action in rule['actions']:
            if 'value' in action:
                if isinstance(action['value'], dict):
                    print(f"  - {action['id']}: {json.dumps(action['value'])}")
                else:
                    print(f"  - {action['id']}: {action['value']}")
            else:
                print(f"  - {action['id']}: enabled")
        print("-" * 50)
    
    def get_page_rule(self, rule_id: str) -> Optional[Dict]:
        """Get details of a specific page rule"""
        try:
            response = requests.get(f"{self.base_url}/pagerules/{rule_id}", headers=self.headers)
            data = response.json()
            
            if data.get('success'):
                rule = data.get('result')
                print("🔍 Page rule details:")
                print(json.dumps(rule, indent=2))
                return rule
            else:
                print(f"❌ Failed to fetch page rule: {data.get('errors')}")
                return None
        except Exception as e:
            print(f"❌ Error: {e}")
            return None
    
    def create_page_rule(self, url_pattern: str, actions: List[Dict], priority: int = 1) -> bool:
        """Create a new page rule"""
        rule_data = {
            "targets": [{
                "target": "url",
                "constraint": {
                    "operator": "matches",
                    "value": url_pattern
                }
            }],
            "actions": actions,
            "priority": priority,
            "status": "active"
        }
        
        try:
            response = requests.post(f"{self.base_url}/pagerules", 
                                   headers=self.headers, 
                                   json=rule_data)
            data = response.json()
            
            if data.get('success'):
                print("✅ Page rule created successfully!")
                self._print_rule(data['result'])
                return True
            else:
                print(f"❌ Failed to create page rule: {data.get('errors')}")
                return False
        except Exception as e:
            print(f"❌ Error: {e}")
            return False
    
    def delete_page_rule(self, rule_id: str) -> bool:
        """Delete a page rule"""
        try:
            response = requests.delete(f"{self.base_url}/pagerules/{rule_id}", 
                                     headers=self.headers)
            data = response.json()
            
            if data.get('success'):
                print("✅ Page rule deleted successfully")
                return True
            else:
                print(f"❌ Failed to delete page rule: {data.get('errors')}")
                return False
        except Exception as e:
            print(f"❌ Error: {e}")
            return False
    
    def check_multipage_issues(self):
        """Check for common issues that affect multi-page websites"""
        print("🔍 Checking for multi-page website issues...\n")
        
        # Check page rules
        rules = self._get_page_rules_raw()
        if rules:
            self._analyze_page_rules(rules)
        
        # Check DNS configuration
        self._check_dns_configuration()
        
        # Check SSL/TLS settings
        self._check_ssl_settings()
        
        # Provide recommendations
        self._provide_recommendations()
    
    def _get_page_rules_raw(self) -> List[Dict]:
        """Get raw page rules data"""
        try:
            response = requests.get(f"{self.base_url}/pagerules", headers=self.headers)
            data = response.json()
            return data.get('result', []) if data.get('success') else []
        except:
            return []
    
    def _analyze_page_rules(self, rules: List[Dict]):
        """Analyze page rules for potential issues"""
        print("📋 Page Rules Analysis:")
        
        forwarding_rules = []
        cache_rules = []
        problematic_rules = []
        
        for rule in rules:
            url_pattern = rule['targets'][0]['constraint']['value']
            
            for action in rule['actions']:
                if action['id'] == 'forwarding_url':
                    forwarding_rules.append((url_pattern, action['value']))
                    # Check if it's a catch-all redirect
                    if '*' in url_pattern and '/*' in url_pattern:
                        problematic_rules.append(f"Catch-all redirect: {url_pattern}")
                
                elif action['id'] == 'cache_level':
                    cache_rules.append((url_pattern, action['value']))
        
        if forwarding_rules:
            print("⚠️  Found forwarding rules that might affect routing:")
            for pattern, dest in forwarding_rules:
                print(f"   {pattern} → {dest['url']} ({dest['status_code']})")
        
        if problematic_rules:
            print("\n❗ Potential issues found:")
            for issue in problematic_rules:
                print(f"   - {issue}")
        
        if cache_rules:
            print("\nℹ️  Cache rules:")
            for pattern, level in cache_rules:
                print(f"   {pattern}: {level}")
        
        print()
    
    def _check_dns_configuration(self):
        """Check DNS configuration"""
        print("🌐 DNS Configuration:")
        
        try:
            response = requests.get(f"{self.base_url}/dns_records", headers=self.headers)
            data = response.json()
            
            if data.get('success'):
                records = data.get('result', [])
                
                # Check root domain
                root_records = [r for r in records if r['name'] == 'santiagosainz.com']
                if root_records:
                    for record in root_records:
                        if record['type'] == 'CNAME':
                            print(f"✅ Root domain: CNAME → {record['content']} (Proxied: {record['proxied']})")
                else:
                    print("⚠️  No CNAME record found for root domain")
                
                # Check www subdomain
                www_records = [r for r in records if r['name'] == 'www.santiagosainz.com']
                if www_records:
                    for record in www_records:
                        if record['type'] == 'CNAME':
                            print(f"✅ WWW subdomain: CNAME → {record['content']} (Proxied: {record['proxied']})")
                else:
                    print("⚠️  No CNAME record found for www subdomain")
        except Exception as e:
            print(f"❌ Error checking DNS: {e}")
        
        print()
    
    def _check_ssl_settings(self):
        """Check SSL/TLS settings"""
        print("🔒 SSL/TLS Settings:")
        
        try:
            response = requests.get(f"{self.base_url}/settings/ssl", headers=self.headers)
            data = response.json()
            
            if data.get('success'):
                ssl_mode = data['result']['value']
                print(f"Current SSL mode: {ssl_mode}")
                
                if ssl_mode in ['full', 'strict']:
                    print("✅ SSL mode is appropriate for secure hosting")
                else:
                    print("⚠️  Consider using 'Full' or 'Full (Strict)' SSL mode")
        except Exception as e:
            print(f"❌ Error checking SSL settings: {e}")
        
        print()
    
    def _provide_recommendations(self):
        """Provide recommendations for multi-page setup"""
        print("💡 Recommendations for multi-page setup:")
        print("1. Remove any catch-all forwarding rules (e.g., /*)")
        print("2. Ensure your hosting platform correctly serves HTML files")
        print("3. Add cache rules for static assets (CSS, JS, images)")
        print("4. Use 'Full' or 'Full (Strict)' SSL mode")
        print("5. Enable 'Always Use HTTPS' for security")
        print("6. Consider adding security headers via Transform Rules")
    
    def create_recommended_rules(self):
        """Create recommended page rules for a multi-page website"""
        print("🚀 Creating recommended page rules...\n")
        
        # Rule 1: Always use HTTPS
        print("Creating rule 1: Always use HTTPS...")
        self.create_page_rule(
            url_pattern="http://*santiagosainz.com/*",
            actions=[{"id": "always_use_https"}],
            priority=1
        )
        
        # Rule 2: Cache static assets
        print("\nCreating rule 2: Cache static assets...")
        self.create_page_rule(
            url_pattern="*santiagosainz.com/*.{css,js,jpg,jpeg,png,gif,svg,ico,woff,woff2}",
            actions=[
                {"id": "cache_level", "value": "cache_everything"},
                {"id": "browser_cache_ttl", "value": 31536000},
                {"id": "edge_cache_ttl", "value": 2592000}
            ],
            priority=2
        )
        
        print("\n✅ Recommended rules created!")

def main():
    """Main function with interactive menu"""
    zone_id = "05a82d6107f1f7b79624f73106c3e3b1"
    
    # Check for API token
    api_token = os.environ.get('CF_API_TOKEN')
    if not api_token:
        print("⚠️  Cloudflare API Token not found in environment")
        api_token = input("Enter your Cloudflare API Token: ").strip()
    
    # Initialize manager
    manager = CloudflareManager(zone_id, api_token)
    
    # Test credentials
    if not manager.test_credentials():
        print("\nPlease check your API token and try again.")
        print("You can create a token at: https://dash.cloudflare.com/profile/api-tokens")
        sys.exit(1)
    
    while True:
        print("\n=== Cloudflare Page Rules Manager ===")
        print("Zone: santiagosainz.com")
        print("\n1. List all page rules")
        print("2. Get page rule details")
        print("3. Create new page rule")
        print("4. Delete page rule")
        print("5. Check for multi-page website issues")
        print("6. Create recommended rules")
        print("7. Export configuration")
        print("8. Exit")
        
        choice = input("\nSelect an option (1-8): ").strip()
        
        if choice == '1':
            manager.list_page_rules()
        
        elif choice == '2':
            rule_id = input("Enter page rule ID: ").strip()
            manager.get_page_rule(rule_id)
        
        elif choice == '3':
            print("\n🆕 Create new page rule")
            url_pattern = input("Enter URL pattern (e.g., *santiagosainz.com/*): ").strip()
            
            print("\nAvailable actions:")
            print("1. Forwarding URL (redirect)")
            print("2. Always Use HTTPS")
            print("3. Cache Level")
            print("4. Browser Cache TTL")
            
            action_choice = input("Select action (1-4): ").strip()
            
            actions = []
            if action_choice == '1':
                dest_url = input("Enter destination URL: ").strip()
                status_code = int(input("Status code (301 or 302): ").strip())
                actions.append({
                    "id": "forwarding_url",
                    "value": {"url": dest_url, "status_code": status_code}
                })
            elif action_choice == '2':
                actions.append({"id": "always_use_https"})
            elif action_choice == '3':
                cache_level = input("Enter cache level (bypass/none/standard/aggressive): ").strip()
                actions.append({"id": "cache_level", "value": cache_level})
            elif action_choice == '4':
                ttl = int(input("Enter TTL in seconds: ").strip())
                actions.append({"id": "browser_cache_ttl", "value": ttl})
            
            priority = int(input("Enter priority (1 = highest): ").strip())
            manager.create_page_rule(url_pattern, actions, priority)
        
        elif choice == '4':
            rule_id = input("Enter page rule ID to delete: ").strip()
            confirm = input("Are you sure? (yes/no): ").strip().lower()
            if confirm == 'yes':
                manager.delete_page_rule(rule_id)
        
        elif choice == '5':
            manager.check_multipage_issues()
        
        elif choice == '6':
            confirm = input("This will create recommended rules. Continue? (yes/no): ").strip().lower()
            if confirm == 'yes':
                manager.create_recommended_rules()
        
        elif choice == '7':
            # Export current configuration
            rules = manager._get_page_rules_raw()
            if rules:
                filename = f"cloudflare_rules_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
                with open(filename, 'w') as f:
                    json.dump(rules, f, indent=2)
                print(f"✅ Configuration exported to {filename}")
            else:
                print("❌ No rules to export")
        
        elif choice == '8':
            print("Goodbye!")
            break
        
        else:
            print("Invalid option")
        
        input("\nPress Enter to continue...")

if __name__ == "__main__":
    main()