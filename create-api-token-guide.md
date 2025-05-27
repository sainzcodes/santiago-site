# How to Create a Cloudflare API Token for Pages Deployment

## Why the current token is failing:
Your token `55165dff5bc714ad5149c94cf38578b76e1b4` appears incomplete (only 37 characters). Cloudflare tokens are usually 40+ characters long.

## Steps to create a new API token:

### 1. Go to Cloudflare API Tokens page:
https://dash.cloudflare.com/profile/api-tokens

### 2. Click "Create Token"

### 3. Use "Custom token" template

### 4. Set these permissions:

#### Account Permissions:
- **Account** → `Santiago Sainz AI`
- **Cloudflare Pages:Edit** ✅ (Required for deployment)

#### Zone Permissions:
- **Zone** → `santiagosainz.com`
- **Zone:Read** ✅
- **Page Rules:Edit** ✅ (For redirects)

### 5. Client IP Address Filtering (Optional):
- Leave as "Is in - Any IP" for flexibility

### 6. TTL:
- Start Date: Today
- End Date: 1 year from now (or your preference)

### 7. Click "Continue to summary"

### 8. Review and "Create Token"

### 9. **IMPORTANT**: Copy the ENTIRE token!
- It will look something like: `1234567890abcdef1234567890abcdef12345678`
- Make sure you get ALL characters

## Alternative: Use Global API Key
If custom tokens aren't working, you can use your Global API Key:
1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Scroll down to "Global API Key"
3. Click "View"
4. Enter your password
5. Copy the key

Note: Global API Key requires your email address for authentication.

## Test your new token:
```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     -H "Content-Type: application/json"
```

Should return: `{"success":true,...}`