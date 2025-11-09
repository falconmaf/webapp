# VPS Deployment Guide

This Laravel 12 application includes an automated deployment script for easy VPS setup.

## Quick Start

### On Your VPS

1. **Upload the deployment script to your VPS:**
   ```bash
   scp deploy-vps.sh user@your-vps-ip:~/
   ```

2. **Or clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd webapp
   ```

3. **Run the deployment script:**
   ```bash
   sudo bash deploy-vps.sh
   ```

4. **Follow the interactive prompts** to configure:
   - Domain name
   - Application directory
   - SSL/HTTPS settings
   - Database configuration
   - Environment settings

## What the Script Does

✅ **System Setup:**
- Updates system packages
- Installs PHP 8.4 + all required extensions
- Installs Nginx web server
- Installs Node.js/npm for Vite
- Installs Composer
- Installs Supervisor for queue workers
- Installs Certbot for SSL (optional)

✅ **Application Setup:**
- Creates application directory
- Copies/clones application files
- Configures `.env` file
- Generates application key
- Installs Composer dependencies
- Installs NPM dependencies
- Builds frontend assets (Vite)

✅ **Database Setup:**
- Creates SQLite database (or configures MySQL/PostgreSQL)
- Runs migrations
- Sets up proper permissions

✅ **Web Server Configuration:**
- Configures Nginx with optimized settings
- Sets up PHP-FPM
- Configures SSL with Let's Encrypt (optional)
- Enables static file caching

✅ **Background Services:**
- Sets up Supervisor for Laravel queue workers
- Configures Laravel scheduler with cron
- Enables auto-start on reboot

✅ **Optimization:**
- Caches configuration
- Caches routes
- Caches views
- Sets proper file permissions

## Post-Deployment

### Quick Deploy Script

After initial deployment, use the generated helper script for updates:

```bash
cd /var/www/webapp  # Or your app directory
./deploy.sh
```

This script:
- Pulls latest code (if using Git)
- Updates dependencies
- Runs migrations
- Clears and rebuilds caches
- Restarts queue workers

### Useful Commands

```bash
# View application logs
tail -f /var/www/webapp/storage/logs/laravel.log

# View Nginx error logs
tail -f /var/log/nginx/error.log

# Restart queue workers
sudo supervisorctl restart laravel-worker:*

# Check service status
sudo systemctl status nginx
sudo systemctl status php8.4-fpm
sudo systemctl status supervisor

# Clear cache manually
cd /var/www/webapp
php artisan cache:clear
php artisan config:clear
php artisan view:clear

# Run database seeders
php artisan db:seed

# Run tests
php artisan test
```

### File Permissions

The script automatically sets correct permissions, but if needed:

```bash
sudo chown -R www-data:www-data /var/www/webapp
sudo chmod -R 755 /var/www/webapp
sudo chmod -R 775 /var/www/webapp/storage
sudo chmod -R 775 /var/www/webapp/bootstrap/cache
```

For SQLite:
```bash
sudo chmod -R 775 /var/www/webapp/database
```

## Environment Configuration

Edit `.env` file if you need to change settings:

```bash
sudo nano /var/www/webapp/.env
```

After changes, clear cache:
```bash
cd /var/www/webapp
php artisan config:clear
php artisan config:cache
```

## Storage Directories

The application has the following storage structure:

- **Public files** (accessible via URL): `/var/www/webapp/storage/app/public`
  - Accessible at: `https://yourdomain.com/storage/`
  
- **Private files** (not web-accessible): `/var/www/webapp/storage/app/private`

- **Logs**: `/var/www/webapp/storage/logs/`

## SSL Certificate Renewal

If you enabled SSL, Certbot auto-renewal is configured. Test it:

```bash
sudo certbot renew --dry-run
```

## Firewall Setup

Configure UFW firewall:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

## Database Backups

### For SQLite:

```bash
# Backup
cp /var/www/webapp/database/database.sqlite ~/backup-$(date +%Y%m%d).sqlite

# Restore
cp ~/backup-20250109.sqlite /var/www/webapp/database/database.sqlite
sudo chown www-data:www-data /var/www/webapp/database/database.sqlite
```

### For MySQL/PostgreSQL:

```bash
# MySQL backup
mysqldump -u username -p database_name > backup-$(date +%Y%m%d).sql

# MySQL restore
mysql -u username -p database_name < backup-20250109.sql
```

## Troubleshooting

### 502 Bad Gateway
```bash
sudo systemctl status php8.4-fpm
sudo systemctl restart php8.4-fpm
sudo systemctl restart nginx
```

### Permission Denied Errors
```bash
sudo chown -R www-data:www-data /var/www/webapp/storage
sudo chmod -R 775 /var/www/webapp/storage
```

### Queue Not Processing
```bash
sudo supervisorctl status
sudo supervisorctl restart laravel-worker:*
```

### Frontend Not Loading
```bash
cd /var/www/webapp
npm run build
php artisan view:clear
```

### Check Logs
```bash
# Application logs
tail -f /var/www/webapp/storage/logs/laravel.log

# Nginx error logs
tail -f /var/log/nginx/error.log

# PHP-FPM logs
tail -f /var/log/php8.4-fpm.log

# Queue worker logs
tail -f /var/www/webapp/storage/logs/worker.log
```

## Security Checklist

- [ ] Set `APP_DEBUG=false` in production
- [ ] Use strong `APP_KEY` (auto-generated)
- [ ] Enable firewall (UFW)
- [ ] Keep system packages updated
- [ ] Use HTTPS (SSL enabled)
- [ ] Secure database credentials
- [ ] Regular backups
- [ ] Monitor logs for suspicious activity

## Updating the Application

1. **Pull latest changes:**
   ```bash
   cd /var/www/webapp
   git pull origin main
   ```

2. **Run the deploy script:**
   ```bash
   ./deploy.sh
   ```

Or manually:
```bash
composer install --optimize-autoloader --no-dev
npm install && npm run build
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
sudo supervisorctl restart laravel-worker:*
```

## Monitoring

### Application Health Check
```bash
cd /var/www/webapp
php artisan about
```

### Disk Usage
```bash
df -h
du -sh /var/www/webapp/storage/*
```

### Process Monitoring
```bash
htop
# or
ps aux | grep php
ps aux | grep nginx
```

## Support

For issues specific to this deployment:
1. Check application logs: `/var/www/webapp/storage/logs/`
2. Check Nginx logs: `/var/log/nginx/`
3. Verify services are running: `sudo systemctl status nginx php8.4-fpm supervisor`
4. Review Laravel documentation: https://laravel.com/docs/12.x

## Technology Stack

- **PHP**: 8.4.1
- **Laravel**: 12.37.0
- **Database**: SQLite (default) or MySQL/PostgreSQL
- **Web Server**: Nginx
- **Frontend**: Vite + TailwindCSS 4 + Livewire 3
- **Queue**: Supervisor + Laravel Queue
- **SSL**: Let's Encrypt (Certbot)
