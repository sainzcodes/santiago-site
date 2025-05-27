# Cloudflare Page Rules Management Tools

This directory contains tools for managing Cloudflare page rules and troubleshooting multi-page website configurations for santiagosainz.com.

## Quick Start

### 1. Set up your API Token

First, create a Cloudflare API token:
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use "Custom token" with these permissions:
   - Zone → Page Rules → Edit
   - Zone → DNS → Read
   - Zone → SSL and Certificates → Read
4. Scope to: Include → Specific zone → santiagosainz.com

### 2. Choose Your Tool

We provide two tools with identical functionality:

#### Option A: Bash Script (Simple)
```bash
# Set your API token
export CF_API_TOKEN="your_token_here"

# Run the tool
./cloudflare-page-rules.sh
```

#### Option B: Python Script (Advanced)
```bash
# Install Python dependencies (if needed)
pip3 install requests

# Set your API token
export CF_API_TOKEN="your_token_here"

# Run the tool
python3 cloudflare_manager.py
```

## Features

Both tools provide:

1. **List Page Rules** - View all active page rules
2. **Get Rule Details** - Inspect specific rules
3. **Create Rules** - Add new page rules with various actions
4. **Delete Rules** - Remove unwanted rules
5. **Multi-page Diagnostics** - Check for issues affecting multi-page sites
6. **Recommended Setup** - Auto-create optimal rules for your site

## Common Use Cases

### Check Current Configuration
```bash
# Run either tool and select option 1 to list all rules
./cloudflare-page-rules.sh
# Then select option 5 to check for multi-page issues
```

### Fix Multi-page Navigation Issues

Common problems and solutions:

1. **All pages redirect to index.html**
   - Look for catch-all forwarding rules (e.g., `/*` → `/index.html`)
   - Delete these rules using option 4

2. **Pages load slowly**
   - Create cache rules for static assets using option 6
   - This will cache CSS, JS, and images

3. **HTTP not redirecting to HTTPS**
   - Create an "Always Use HTTPS" rule using option 3 or 6

### Recommended Configuration

For a typical multi-page site, run option 6 to create:

1. **Always Use HTTPS** - Forces secure connections
2. **Cache Static Assets** - Speeds up page loads

## Available Page Rule Actions

When creating custom rules (option 3), you can use:

- **Forwarding URL** - Redirect visitors (301/302)
- **Always Use HTTPS** - Force secure connections
- **Cache Level** - Control caching behavior
- **Browser Cache TTL** - Set cache duration
- **Security Level** - Adjust protection settings
- **SSL Mode** - Configure SSL/TLS settings

## Troubleshooting

### Authentication Failed
- Verify your API token has the correct permissions
- Check that the token is scoped to santiagosainz.com
- Ensure you're using the Bearer token, not Global API Key

### Multi-page Site Not Working
1. Run diagnostic check (option 5)
2. Look for problematic forwarding rules
3. Verify DNS points to correct hosting
4. Check SSL mode is "Full" or "Full (Strict)"

### Rules Not Taking Effect
- Page rules are processed in priority order (1 = highest)
- Only one rule can match per request
- Changes may take 1-5 minutes to propagate

## Security Notes

- Never commit your API token to git
- Use environment variables or .env files
- Create tokens with minimum required permissions
- Regularly rotate API tokens

## Support

For issues specific to:
- These tools: Check the code or modify as needed
- Cloudflare: https://developers.cloudflare.com/
- Your site: Ensure hosting platform supports multi-page sites

## Zone Information

- Domain: santiagosainz.com
- Zone ID: 05a82d6107f1f7b79624f73106c3e3b1
- Hosting: Cloudflare Pages (santiago-sainz-ai.pages.dev)