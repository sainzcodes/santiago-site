# 🖱️ Exact Click Guide for Cloudflare Token

## Step 1: Create Token Button
After logging in, you'll see:
```
My Profile > API Tokens

[Create Token] <- CLICK THIS BLUE BUTTON
```

## Step 2: Choose Custom Token
You'll see template options. Scroll down and find:
```
Custom token
Create a token with custom permissions

[Get started] <- CLICK THIS
```

## Step 3: Fill Token Form

### 3a. Token Name
```
Token name: [Santiago Sainz Website Management]
```

### 3b. Permissions (CLICK "+ Add more" for each)
```
1st row: [Zone ▼] [Zone ▼] [Read ▼]
2nd row: [Zone ▼] [Page Rules ▼] [Edit ▼]
3rd row: [Zone ▼] [Zone Settings ▼] [Edit ▼]
```

### 3c. Zone Resources
```
Zone Resources
Include [Specific zone ▼]
        [santiagosainz.com ▼] <- SELECT FROM DROPDOWN
```

### 3d. Optional: IP Filtering
```
Client IP Address Filtering (optional)
Is in: [Your_Current_IP_Will_Be_Shown]
```

### 3e. TTL
```
TTL
Start Date: Today (auto-filled)
End Date: [1 year ▼] <- Or your preference
```

## Step 4: Create Token
```
[Continue to summary] <- CLICK THIS BLUE BUTTON
```

Review the summary, then:
```
[Create Token] <- CLICK THIS BLUE BUTTON
```

## Step 5: COPY THE TOKEN IMMEDIATELY!
```
Your API token:
[1234567890abcdef_xxxxxxxxxxxxx] [Copy] <- CLICK COPY

⚠️ This is your only chance to see this token!
```

## Step 6: Test Your Token
Open Terminal and run:
```bash
cd /Users/sainz/santiago-site
./cloudflare-token-helper.sh
```

Paste your token when prompted!