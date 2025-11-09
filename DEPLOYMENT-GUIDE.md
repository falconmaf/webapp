# GitHub Setup & VPS Deployment Instructions

## Step 1: Configure Git (First Time Only)

Run these commands to set your Git identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

## Step 2: Push to GitHub

### Option A: Create New Repository on GitHub

1. **Go to GitHub** and create a new repository:
   - Visit: https://github.com/new
   - Repository name: `webapp` (or your preferred name)
   - Keep it **private** (recommended for your app)
   - **Don't** initialize with README, .gitignore, or license (we already have these)
   - Click "Create repository"

2. **Push your local code:**

```bash
cd ~/local/webapp

# Add your GitHub repository as remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/webapp.git

# Commit your code
git commit -m "Initial commit: Laravel 12 application with deployment scripts"

# Push to GitHub
git push -u origin main
```

### Option B: Using SSH (Recommended for Security)

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy your public key
cat ~/.ssh/id_ed25519.pub

# Add it to GitHub: Settings → SSH and GPG keys → New SSH key

# Then push using SSH URL
git remote add origin git@github.com:YOUR_USERNAME/webapp.git
git commit -m "Initial commit: Laravel 12 application with deployment scripts"
git push -u origin main
```

## Step 3: Deploy to VPS

### Prerequisites on VPS:
- Ubuntu 20.04 or 22.04 LTS
- Root or sudo access
- Domain pointed to VPS IP (for SSL)

### Deployment Steps:

1. **SSH into your VPS:**
```bash
ssh root@your-vps-ip
# or
ssh your-user@your-vps-ip
```

2. **Install Git (if not installed):**
```bash
sudo apt update
sudo apt install -y git
```

3. **Clone your repository:**
```bash
cd ~
git clone https://github.com/YOUR_USERNAME/webapp.git
cd webapp
```

4. **Run the deployment script:**
```bash
sudo bash deploy-vps.sh
```

5. **Follow the prompts and provide:**
   - Domain name: `myapp.com`
   - Application directory: `/var/www/webapp` (recommended)
   - Application URL: `https://myapp.com`
   - Application name: `My Laravel App`
   - PHP version: `8.4` (default)
   - SSL: `y` (yes, recommended)
   - Database type: `sqlite` (easiest) or `mysql`/`pgsql`
   - Environment: `production`
   - Debug mode: `false`

6. **Wait for installation** (takes 5-10 minutes)

7. **Done!** Visit your domain to see your app running 🎉

## Step 4: Configure DNS

Before enabling SSL, make sure your domain DNS is configured:

1. **Add an A record** pointing to your VPS IP:
   - Type: `A`
   - Name: `@` (or subdomain)
   - Value: `YOUR_VPS_IP`
   - TTL: `3600`

2. **For www subdomain** (optional):
   - Type: `A`
   - Name: `www`
   - Value: `YOUR_VPS_IP`
   - TTL: `3600`

3. **Wait for DNS propagation** (can take up to 24 hours, usually 5-15 minutes)

4. **Verify DNS:**
```bash
ping myapp.com
# Should show your VPS IP
```

## Step 5: Future Updates

When you make changes locally and want to deploy:

```bash
# On your local machine
cd ~/local/webapp
git add .
git commit -m "Description of changes"
git push origin main

# On your VPS
ssh your-user@your-vps-ip
cd /var/www/webapp
git pull origin main
./deploy.sh  # Quick deploy script (auto-created during installation)
```

## Troubleshooting

### Permission Denied on GitHub Push

If using HTTPS and GitHub rejects your password:
1. Create a Personal Access Token: https://github.com/settings/tokens
2. Use the token as your password when pushing

Or switch to SSH (recommended - see Option B above).

### Can't Access Application After Deployment

```bash
# Check Nginx status
sudo systemctl status nginx

# Check PHP-FPM status
sudo systemctl status php8.4-fpm

# Check application logs
tail -f /var/www/webapp/storage/logs/laravel.log

# Check Nginx error logs
tail -f /var/log/nginx/error.log
```

### 502 Bad Gateway Error

```bash
sudo systemctl restart php8.4-fpm
sudo systemctl restart nginx
```

### Storage/Permission Errors

```bash
cd /var/www/webapp
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### SSL Certificate Issues

Make sure:
- Domain DNS is properly configured
- Ports 80 and 443 are open in firewall
- You wait for DNS propagation before running the script

Re-run SSL setup:
```bash
sudo certbot --nginx -d yourdomain.com
```

## Security Checklist After Deployment

- [ ] `.env` has `APP_DEBUG=false`
- [ ] `.env` has strong `APP_KEY`
- [ ] SSL is enabled (HTTPS working)
- [ ] Firewall is configured (UFW)
- [ ] Database credentials are secure
- [ ] Only necessary ports are open (22, 80, 443)
- [ ] Regular backups are scheduled
- [ ] Keep system updated: `sudo apt update && sudo apt upgrade`

## Important Files on VPS

- **Application**: `/var/www/webapp`
- **Nginx config**: `/etc/nginx/sites-available/yourdomain.com`
- **Environment**: `/var/www/webapp/.env`
- **Logs**: `/var/www/webapp/storage/logs/`
- **SQLite DB**: `/var/www/webapp/database/database.sqlite`
- **Quick deploy**: `/var/www/webapp/deploy.sh`

## Useful Commands on VPS

```bash
# View real-time logs
tail -f /var/www/webapp/storage/logs/laravel.log

# Restart services
sudo systemctl restart nginx
sudo systemctl restart php8.4-fpm
sudo supervisorctl restart laravel-worker:*

# Clear cache
cd /var/www/webapp
php artisan cache:clear
php artisan config:clear
php artisan view:clear

# Run migrations
php artisan migrate

# Check application status
php artisan about

# Edit environment
sudo nano /var/www/webapp/.env
```

## Support

For deployment issues, check:
1. Application logs: `/var/www/webapp/storage/logs/`
2. Nginx logs: `/var/log/nginx/error.log`
3. Service status: `sudo systemctl status nginx php8.4-fpm supervisor`
4. Full documentation: `README-DEPLOYMENT.md`

---

**Technology Stack:**
- Laravel 12.37.0
- PHP 8.4.1
- Livewire 3.6.4
- Tailwind CSS 4.0.17
- Pest 4.1.3
