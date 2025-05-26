# DNS Update Instructions

## Current Issue
Your domain is pointing to `default-page.cloudflareregistrar.com` instead of your new website.

## Required Changes

### 1. Update the Root Domain CNAME

**Find this record:**
- Type: CNAME
- Name: santiagosainz.com
- Content: default-page.cloudflareregistrar.com

**Click Edit and change to:**
- Type: CNAME
- Name: santiagosainz.com
- Content: **santiago-sainz-ai.pages.dev**
- Proxy status: **Proxied** (orange cloud ON)
- TTL: Auto

### 2. Add WWW Subdomain

**Click "Add Record" and create:**
- Type: CNAME
- Name: www
- Content: **santiago-sainz-ai.pages.dev**
- Proxy status: **Proxied** (orange cloud ON)
- TTL: Auto

## Steps to Complete:

1. In the table showing your DNS records, find the CNAME record for `santiagosainz.com`
2. Click the "Edit" button on that row
3. Change the Content from `default-page.cloudflareregistrar.com` to `santiago-sainz-ai.pages.dev`
4. Make sure Proxy status shows the orange cloud (Proxied)
5. Click "Save"
6. Click "Add Record" button
7. Add the www record as specified above
8. Click "Save"

## Verification

After making these changes:
- Your site will be live at https://santiagosainz.com within 1-5 minutes
- Both santiagosainz.com and www.santiagosainz.com will work
- HTTPS will be automatically enabled

## Your Other Records
Your ProtonMail records (MX, TXT, DKIM) are all correct and won't be affected by this change.