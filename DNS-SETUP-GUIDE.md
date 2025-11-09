# DNS Records Setup Guide for camptell.space

## Quick Import to Cloudflare

1. **Go to Cloudflare Dashboard**: https://dash.cloudflare.com
2. **Select**: `camptell.space`
3. **Navigate to**: DNS → Records
4. **Click**: "Import and Export" button
5. **Click**: "Import"
6. **Upload**: `cloudflare-dns-records.txt`
7. **Review** the records and click "Import"

## What's Included in the DNS File

### ✅ Web Application Records
- `camptell.space` → `185.215.244.29` (Your Laravel app)
- `www.camptell.space` → `185.215.244.29`
- `mail.camptell.space` → `185.215.244.29` (Optional webmail)

### ✅ Gmail/Google Workspace Email Records
- **MX Records**: Routes email through Gmail servers
- **SPF Record**: Authorizes Gmail to send emails from your domain
- **DMARC Record**: Email security and reporting policy

## Email Setup Options

### Option 1: Gmail SMTP Only (Free - Recommended for Laravel)

If you just want **Laravel to send emails** using your Gmail account:

**No MX records needed!** Just configure Laravel:

```env
# In your .env file on VPS
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-specific-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@camptell.space
MAIL_FROM_NAME="Camptell"
```

**Steps:**
1. Go to Google Account → Security
2. Enable 2-Factor Authentication
3. Generate App Password for "Mail"
4. Use that password in `.env`

**Only add these DNS records:**
- SPF: `v=spf1 include:_spf.google.com ~all`
- DMARC: (from the file)

### Option 2: Google Workspace (Paid - Full Email Service)

If you want **full email addresses** like `admin@camptell.space`:

**Cost**: $6/user/month

**Steps:**
1. Sign up: https://workspace.google.com
2. Add domain: `camptell.space`
3. Import DNS records from `cloudflare-dns-records.txt`
4. Verify domain ownership in Google Workspace
5. Get DKIM record from Google Workspace Admin
6. Add DKIM to Cloudflare:
   ```
   Type: TXT
   Name: google._domainkey
   Content: [value from Google Workspace]
   ```

## After Import - Important Steps

### 1. Configure Cloudflare SSL/TLS
- Go to: SSL/TLS → Overview
- Set to: **Full (strict)**
- Enable: Always Use HTTPS

### 2. Verify DNS Records
Wait 5 minutes, then check:
```bash
dig camptell.space
dig www.camptell.space
dig camptell.space MX
dig camptell.space TXT
```

### 3. Deploy Your Laravel Application
```bash
ssh root@185.215.244.29
cd webapp
sudo bash deploy-vps.sh
```

When prompted:
- Domain: `camptell.space`
- App URL: `https://camptell.space`
- SSL: `y` (yes)
- Email for SSL: `admin@camptell.space` or your Gmail

### 4. Configure Laravel Email Settings

After deployment, edit `.env` on your VPS:
```bash
ssh root@185.215.244.29
nano /var/www/webapp/.env
```

Add Gmail SMTP settings (see Option 1 above).

Then clear config cache:
```bash
cd /var/www/webapp
php artisan config:clear
php artisan config:cache
```

### 5. Test Email Sending

```bash
cd /var/www/webapp
php artisan tinker

# In tinker:
Mail::raw('Test email from Laravel', function($msg) {
    $msg->to('your-email@gmail.com')
        ->subject('Test from camptell.space');
});
```

## DNS Record Details

### Current Records in File:

| Type | Name | Content | Purpose |
|------|------|---------|---------|
| A | @ | 185.215.244.29 | Main domain |
| A | www | 185.215.244.29 | WWW subdomain |
| A | mail | 185.215.244.29 | Mail server (optional) |
| MX | @ | aspmx.l.google.com (priority 1) | Gmail email |
| MX | @ | alt1.aspmx.l.google.com (priority 5) | Gmail backup |
| MX | @ | alt2.aspmx.l.google.com (priority 5) | Gmail backup |
| MX | @ | alt3.aspmx.l.google.com (priority 10) | Gmail backup |
| MX | @ | alt4.aspmx.l.google.com (priority 10) | Gmail backup |
| TXT | @ | v=spf1 include:_spf.google.com ~all | Email authorization |
| TXT | _dmarc | v=DMARC1; p=quarantine... | Email security |

## Troubleshooting

### Email Not Sending?
1. Check Gmail App Password is correct
2. Verify SPF record in DNS
3. Check Laravel logs: `/var/www/webapp/storage/logs/laravel.log`
4. Test SMTP connection:
   ```bash
   telnet smtp.gmail.com 587
   ```

### SSL Issues?
1. Make sure DNS has propagated (wait 10-15 minutes)
2. Verify Cloudflare SSL mode is "Full (strict)"
3. Check Nginx logs: `tail -f /var/log/nginx/error.log`

### Domain Not Resolving?
```bash
dig camptell.space +trace
nslookup camptell.space 8.8.8.8
```

## Next Steps

1. ✅ Import DNS records to Cloudflare
2. ✅ Wait 5-10 minutes for DNS propagation
3. ✅ Deploy Laravel application
4. ✅ Configure email in .env
5. ✅ Test email sending
6. ✅ (Optional) Set up Google Workspace for full email

## Recommended: Use Gmail SMTP for Laravel

For most Laravel applications, you don't need Google Workspace. Just use Gmail SMTP:
- **Free** ✅
- **Reliable** ✅
- **Easy to set up** ✅
- **Perfect for transactional emails** (password resets, notifications, etc.) ✅

Only get Google Workspace if you need email addresses like `support@camptell.space` for your team.
