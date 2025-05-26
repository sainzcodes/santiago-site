# How to Get Your Cloudflare Credentials

## 1. Get Your Zone ID (30 seconds)

1. Go to: https://dash.cloudflare.com
2. Click on `santiagosainz.com`
3. On the right sidebar, you'll see "Zone ID"
4. Copy this value (looks like: 7e3a8b2c9d1f5g6h8j9k0l2m3n4p5q6r)

## 2. Create an API Token (2 minutes)

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Choose "Create Custom Token"
4. Configure as follows:

**Token name**: DNS Update

**Permissions**:
- Zone → DNS → Edit

**Zone Resources**:
- Include → Specific zone → santiagosainz.com

5. Click "Continue to summary"
6. Click "Create Token"
7. **COPY THE TOKEN** (you won't see it again!)

## 3. Run the Script

```bash
cd /Users/sainz/santiago-site
./update-dns.sh
```

Enter your token and Zone ID when prompted.

## Alternative: Manual Update

If you prefer to do it manually:
1. Go to https://dash.cloudflare.com
2. Click on santiagosainz.com → DNS
3. Edit the CNAME record for santiagosainz.com
4. Change content to: santiago-sainz-ai.pages.dev
5. Add new CNAME for www pointing to: santiago-sainz-ai.pages.dev

Your site will be live in minutes!