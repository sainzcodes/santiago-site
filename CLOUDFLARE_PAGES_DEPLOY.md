# Cloudflare Pages Deployment Guide

## 🚀 Deployment Methods

### Method 1: Wrangler CLI (Recommended)

```bash
# One-time setup: Create API token with Pages permissions
export CLOUDFLARE_API_TOKEN="your_token_here"

# Deploy using the script
./deploy-pages-api.sh
```

### Method 2: Direct API Upload

```bash
# Uses curl to upload files directly
./deploy-pages-curl.sh
```

### Method 3: GitHub Actions (Automatic)

1. Push your code to GitHub
2. Add your API token as a repository secret:
   - Go to Settings → Secrets → Actions
   - Add `CLOUDFLARE_API_TOKEN` with your token
3. Deployments happen automatically on push to main

### Method 4: Wrangler Manual Command

```bash
# Direct wrangler command
wrangler pages deploy . --project-name=santiago-sainz-ai --branch=main
```

## 🔑 API Token Requirements

Your Cloudflare API token needs these permissions:
- **Account:Cloudflare Pages:Edit** - Required for deployments
- **Zone:Zone:Read** - Optional, for domain verification

Create token at: https://dash.cloudflare.com/profile/api-tokens

## 📁 Files Deployed

The deployment includes:
- All HTML files (*.html)
- All CSS files (*.css)
- All JavaScript files (*.js)
- _redirects (URL redirects configuration)
- _headers (HTTP headers configuration)

## 🌐 URLs

- **Preview URL**: https://[deployment-id].santiago-sainz-ai.pages.dev
- **Production URL**: https://santiago-sainz-ai.pages.dev
- **Custom Domain**: https://santiagosainz.com

## 🛠️ Troubleshooting

### "Project not found" error
Create the project first:
```bash
wrangler pages project create santiago-sainz-ai
```

### "Authentication failed" error
Check your token permissions and ensure it's set:
```bash
echo $CLOUDFLARE_API_TOKEN
```

### "Upload failed" error
Verify file permissions and that files exist:
```bash
ls -la *.html *.css *.js _redirects _headers
```

## 📝 Quick Deploy Commands

```bash
# Set token (add to ~/.zshrc for persistence)
export CLOUDFLARE_API_TOKEN="your_token_here"

# Deploy
cd /Users/sainz/santiago-site
./deploy-pages-api.sh
```

## 🔄 Continuous Deployment

For automatic deployments:
1. Connect GitHub repository to Cloudflare Pages
2. Or use the GitHub Actions workflow in `.github/workflows/deploy-pages.yml`

## 📊 Deployment Status

Check deployment status:
```bash
wrangler pages deployment list --project-name=santiago-sainz-ai
```

View deployment logs in Cloudflare Dashboard:
https://dash.cloudflare.com/pages/projects/santiago-sainz-ai