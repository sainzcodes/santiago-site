# Cloudflare API Token Setup Guide

## Step-by-Step Instructions

### 1. Access Cloudflare Dashboard
- Go to https://dash.cloudflare.com/profile/api-tokens
- Log in with your Cloudflare account credentials

### 2. Create Custom Token
1. Click **"Create Token"** button
2. Click **"Custom token"** → **"Get started"**

### 3. Configure Token Permissions
Fill out the form with these exact settings:

#### Token Name:
```
Santiago Sainz Website Management
```

#### Permissions:
Add these 3 permissions (click "+ Add more" for each):

1. **Zone:Zone:Read**
   - Resource: `Zone`
   - Permission: `Zone`
   - Access: `Read`

2. **Zone:Page Rules:Edit** 
   - Resource: `Zone`
   - Permission: `Page Rules`
   - Access: `Edit`

3. **Zone:Zone Settings:Edit**
   - Resource: `Zone`
   - Permission: `Zone Settings`
   - Access: `Edit`

#### Zone Resources:
- Select: **"Include - Specific zone"**
- Choose: **"santiagosainz.com"** from dropdown

#### Client IP Address Filtering (Optional but Recommended):
- Select: **"Is in"**
- Add your current IP address (you'll see it displayed)

#### TTL (Token Lifetime):
- Select a reasonable timeframe (e.g., 1 year)

### 4. Review and Create
1. Click **"Continue to summary"**
2. Review all permissions
3. Click **"Create Token"**

### 5. Save Your Token
⚠️ **IMPORTANT**: Copy the token immediately - you won't see it again!

```bash
# Your token will look like this:
CF_API_TOKEN="1234567890abcdef_1234567890abcdef1234567890"
```

### 6. Test Your Token
```bash
# Set the token in your terminal
export CF_API_TOKEN="your_token_here"

# Test it works
curl -X GET "https://api.cloudflare.com/client/v4/zones/05a82d6107f1f7b79624f73106c3e3b1" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json"
```

### 7. Secure Storage
Create a `.env` file in your project:
```bash
echo "CF_API_TOKEN=your_token_here" > .env
echo ".env" >> .gitignore
```

## Required Permissions Explained

### Zone:Zone:Read
- Allows reading zone information
- Needed to verify domain settings
- Required for diagnostics

### Zone:Page Rules:Edit
- Allows creating, updating, deleting page rules
- Core functionality for website optimization
- Includes read access to existing rules

### Zone:Zone Settings:Edit
- Allows modifying zone-level settings
- Useful for performance optimizations
- Includes SSL, caching, and security settings

## Security Best Practices

1. **Limit IP Access**: Only allow your current IP
2. **Set Expiration**: Don't create permanent tokens
3. **Minimum Permissions**: Only grant what you need
4. **Store Securely**: Never commit tokens to git
5. **Rotate Regularly**: Create new tokens periodically

## Troubleshooting

### Common Issues:

**"Invalid token" error:**
- Check token was copied correctly (no extra spaces)
- Verify token hasn't expired
- Ensure proper permissions were set

**"Zone not found" error:**
- Verify zone ID: `05a82d6107f1f7b79624f73106c3e3b1`
- Check domain is active in your Cloudflare account
- Ensure token has Zone:Read permission

**"Permission denied" error:**
- Add missing permissions to token
- Check zone resource includes santiagosainz.com
- Verify token scope includes required operations

## Next Steps

Once you have your token:

1. **Set environment variable:**
   ```bash
   export CF_API_TOKEN="your_token_here"
   ```

2. **Run diagnostics:**
   ```bash
   cd /Users/sainz/santiago-site
   ./cloudflare-quick-check.sh
   ```

3. **Manage page rules:**
   ```bash
   ./cloudflare-page-rules.sh
   ```

## Token Management

### View Existing Tokens:
- Go to https://dash.cloudflare.com/profile/api-tokens
- See all your active tokens
- Check last used date and activity

### Revoke Token:
- Click "View" next to token
- Click "Delete" to revoke access
- Token becomes invalid immediately

### Update Permissions:
- Cannot modify existing token permissions
- Must create new token with updated permissions
- Revoke old token after testing new one