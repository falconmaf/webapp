#!/bin/bash

################################################################################
# Laravel Application VPS Deployment Script
# 
# This script automates the deployment of this Laravel 12 application on a
# Linux VPS with Nginx, PHP 8.4, and SQLite.
#
# Usage: sudo bash deploy-vps.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

################################################################################
# Step 1: Check if running as root
################################################################################
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_info "Laravel VPS Deployment Script"
echo "======================================"
echo ""

################################################################################
# Step 2: Gather user input
################################################################################
print_info "Please provide the following information:"
echo ""

read -p "Domain name (example: myapp.com): " DOMAIN
read -p "Application directory path (example: /var/www/myapp) [/var/www/webapp]: " APP_DIR
APP_DIR=${APP_DIR:-/var/www/webapp}

read -p "Application URL (example: https://myapp.com): " APP_URL
read -p "Application name (example: My Laravel App) [Laravel App]: " APP_NAME
APP_NAME=${APP_NAME:-"Laravel App"}

read -p "PHP version to install (example: 8.4) [8.4]: " PHP_VERSION
PHP_VERSION=${PHP_VERSION:-8.4}

read -p "Non-root user for running the app (example: www-data) [www-data]: " APP_USER
APP_USER=${APP_USER:-www-data}

read -p "Enable SSL with Let's Encrypt? (example: y for yes, n for no) [y]: " ENABLE_SSL
ENABLE_SSL=${ENABLE_SSL:-y}

read -p "Database type (example: sqlite, mysql, or pgsql) [sqlite]: " DB_TYPE
DB_TYPE=${DB_TYPE:-sqlite}

if [[ "$DB_TYPE" != "sqlite" ]]; then
    read -p "Database host (example: localhost or 127.0.0.1) [localhost]: " DB_HOST
    DB_HOST=${DB_HOST:-localhost}
    read -p "Database name (example: laravel_db): " DB_NAME
    read -p "Database user (example: laravel_user): " DB_USER
    read -sp "Database password (example: secure_password_123): " DB_PASSWORD
    echo ""
fi

read -p "Application environment (example: production or local) [production]: " APP_ENV
APP_ENV=${APP_ENV:-production}

read -p "Enable debug mode? (example: false for production, true for development) [false]: " APP_DEBUG
APP_DEBUG=${APP_DEBUG:-false}

echo ""
print_info "Configuration summary:"
echo "  Domain: $DOMAIN"
echo "  App Directory: $APP_DIR"
echo "  App URL: $APP_URL"
echo "  PHP Version: $PHP_VERSION"
echo "  Database: $DB_TYPE"
echo "  SSL: $ENABLE_SSL"
echo ""
read -p "Continue with deployment? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    print_error "Deployment cancelled"
    exit 1
fi

################################################################################
# Step 3: Update system packages
################################################################################
print_info "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq
print_success "System packages updated"

################################################################################
# Step 4: Install required software
################################################################################
print_info "Installing required packages..."

# Add PHP repository for PHP 8.4
add-apt-repository ppa:ondrej/php -y
apt-get update -qq

# Install PHP and extensions
print_info "Installing PHP $PHP_VERSION and extensions..."
apt-get install -y -qq \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-redis

# Install Nginx
print_info "Installing Nginx..."
apt-get install -y -qq nginx

# Install Node.js and npm (for Vite)
print_info "Installing Node.js and npm..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
fi

# Install Composer
print_info "Installing Composer..."
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# Install Supervisor (for queue workers)
print_info "Installing Supervisor..."
apt-get install -y -qq supervisor

# Install Certbot for SSL (if enabled)
if [[ "$ENABLE_SSL" == "y" ]]; then
    print_info "Installing Certbot..."
    apt-get install -y -qq certbot python3-certbot-nginx
fi

# Install SQLite (if needed)
if [[ "$DB_TYPE" == "sqlite" ]]; then
    apt-get install -y -qq sqlite3
fi

# Install Git
apt-get install -y -qq git unzip

print_success "All required packages installed"

################################################################################
# Step 5: Create application directory
################################################################################
print_info "Setting up application directory..."
mkdir -p "$APP_DIR"
print_success "Application directory created: $APP_DIR"

################################################################################
# Step 6: Copy application files
################################################################################
print_info "Checking for application files..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -f "$SCRIPT_DIR/composer.json" ]]; then
    print_info "Copying application files from $SCRIPT_DIR to $APP_DIR..."
    rsync -a --exclude='vendor' --exclude='node_modules' --exclude='.git' "$SCRIPT_DIR/" "$APP_DIR/"
    print_success "Application files copied"
else
    print_warning "No application files found in script directory."
    read -p "Git repository URL (example: https://github.com/user/repo.git or press Enter to skip): " GIT_REPO
    if [[ ! -z "$GIT_REPO" ]]; then
        print_info "Cloning repository..."
        git clone "$GIT_REPO" "$APP_DIR"
        print_success "Repository cloned"
    fi
fi

################################################################################
# Step 7: Set up environment file
################################################################################
print_info "Configuring environment file..."
cd "$APP_DIR"

if [[ ! -f .env ]]; then
    if [[ -f .env.example ]]; then
        cp .env.example .env
        print_success ".env file created from .env.example"
    else
        print_error ".env.example not found"
        exit 1
    fi
fi

# Generate application key
print_info "Generating application key..."
php artisan key:generate --force

# Update .env file
print_info "Updating environment variables..."
sed -i "s|APP_NAME=.*|APP_NAME=\"$APP_NAME\"|g" .env
sed -i "s|APP_ENV=.*|APP_ENV=$APP_ENV|g" .env
sed -i "s|APP_DEBUG=.*|APP_DEBUG=$APP_DEBUG|g" .env
sed -i "s|APP_URL=.*|APP_URL=$APP_URL|g" .env

if [[ "$DB_TYPE" == "sqlite" ]]; then
    sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=sqlite|g" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=$APP_DIR/database/database.sqlite|g" .env
    # Comment out other DB variables
    sed -i "s|^DB_HOST=|#DB_HOST=|g" .env
    sed -i "s|^DB_PORT=|#DB_PORT=|g" .env
    sed -i "s|^DB_USERNAME=|#DB_USERNAME=|g" .env
    sed -i "s|^DB_PASSWORD=|#DB_PASSWORD=|g" .env
else
    sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=$DB_TYPE|g" .env
    sed -i "s|DB_HOST=.*|DB_HOST=$DB_HOST|g" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|g" .env
    sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|g" .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|g" .env
fi

print_success "Environment configured"

################################################################################
# Step 8: Install dependencies
################################################################################
print_info "Installing Composer dependencies..."
composer install --optimize-autoloader --no-dev --no-interaction
print_success "Composer dependencies installed"

print_info "Installing NPM dependencies..."
npm install --silent
print_success "NPM dependencies installed"

print_info "Building frontend assets..."
npm run build
print_success "Frontend assets built"

################################################################################
# Step 9: Set up database
################################################################################
print_info "Setting up database..."

if [[ "$DB_TYPE" == "sqlite" ]]; then
    touch database/database.sqlite
    chmod 664 database/database.sqlite
    print_success "SQLite database created"
fi

print_info "Running migrations..."
php artisan migrate --force
print_success "Database migrations completed"

################################################################################
# Step 10: Set up storage and permissions
################################################################################
print_info "Setting up storage directories and permissions..."

# Create storage directories
mkdir -p storage/framework/cache/data
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs
mkdir -p storage/app/public
mkdir -p storage/app/private

# Link public storage
php artisan storage:link

# Set permissions
chown -R $APP_USER:$APP_USER "$APP_DIR"
chmod -R 755 "$APP_DIR"
chmod -R 775 "$APP_DIR/storage"
chmod -R 775 "$APP_DIR/bootstrap/cache"

if [[ "$DB_TYPE" == "sqlite" ]]; then
    chmod -R 775 "$APP_DIR/database"
    chown -R $APP_USER:$APP_USER "$APP_DIR/database/database.sqlite"
fi

print_success "Storage and permissions configured"

################################################################################
# Step 11: Configure Nginx
################################################################################
print_info "Configuring Nginx..."

NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"
cat > "$NGINX_CONFIG" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $APP_DIR/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable site
ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Reload Nginx
systemctl reload nginx
systemctl enable nginx

print_success "Nginx configured and reloaded"

################################################################################
# Step 12: Configure PHP-FPM
################################################################################
print_info "Configuring PHP-FPM..."

PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
sed -i "s/user = .*/user = $APP_USER/g" "$PHP_FPM_CONF"
sed -i "s/group = .*/group = $APP_USER/g" "$PHP_FPM_CONF"

# Restart PHP-FPM
systemctl restart php${PHP_VERSION}-fpm
systemctl enable php${PHP_VERSION}-fpm

print_success "PHP-FPM configured"

################################################################################
# Step 13: Set up Supervisor for queue workers
################################################################################
print_info "Setting up Supervisor for queue workers..."

SUPERVISOR_CONFIG="/etc/supervisor/conf.d/laravel-worker.conf"
cat > "$SUPERVISOR_CONFIG" << EOF
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $APP_DIR/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=$APP_USER
numprocs=2
redirect_stderr=true
stdout_logfile=$APP_DIR/storage/logs/worker.log
stopwaitsecs=3600
EOF

supervisorctl reread
supervisorctl update
supervisorctl start laravel-worker:*

print_success "Supervisor configured"

################################################################################
# Step 14: Set up cron for scheduler
################################################################################
print_info "Setting up Laravel scheduler..."

CRON_ENTRY="* * * * * cd $APP_DIR && php artisan schedule:run >> /dev/null 2>&1"
(crontab -u $APP_USER -l 2>/dev/null | grep -v "artisan schedule:run"; echo "$CRON_ENTRY") | crontab -u $APP_USER -

print_success "Laravel scheduler configured"

################################################################################
# Step 15: SSL Configuration
################################################################################
if [[ "$ENABLE_SSL" == "y" ]]; then
    print_info "Setting up SSL certificate with Let's Encrypt..."
    
    read -p "Email address for SSL certificate (example: admin@myapp.com): " SSL_EMAIL
    
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect
    
    # Set up auto-renewal
    systemctl enable certbot.timer
    
    print_success "SSL certificate installed and auto-renewal enabled"
fi

################################################################################
# Step 16: Optimize application
################################################################################
print_info "Optimizing application..."

php artisan config:cache
php artisan route:cache
php artisan view:cache

print_success "Application optimized"

################################################################################
# Step 17: Final checks
################################################################################
print_info "Running final checks..."

# Check PHP version
PHP_CURRENT=$(php -r 'echo PHP_VERSION;')
print_info "PHP version: $PHP_CURRENT"

# Check Nginx status
if systemctl is-active --quiet nginx; then
    print_success "Nginx is running"
else
    print_error "Nginx is not running"
fi

# Check PHP-FPM status
if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
    print_success "PHP-FPM is running"
else
    print_error "PHP-FPM is not running"
fi

# Check Supervisor status
if systemctl is-active --quiet supervisor; then
    print_success "Supervisor is running"
else
    print_error "Supervisor is not running"
fi

################################################################################
# Step 18: Create deployment helper script
################################################################################
print_info "Creating deployment helper script..."

cat > "$APP_DIR/deploy.sh" << 'DEPLOYSCRIPT'
#!/bin/bash
# Quick deployment script for updates

set -e

echo "🚀 Deploying updates..."

# Pull latest changes (if using git)
if [ -d .git ]; then
    git pull origin main
fi

# Install/update dependencies
composer install --optimize-autoloader --no-dev
npm install
npm run build

# Run migrations
php artisan migrate --force

# Clear and cache
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Restart queue workers
sudo supervisorctl restart laravel-worker:*

# Set permissions
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

echo "✓ Deployment complete!"
DEPLOYSCRIPT

chmod +x "$APP_DIR/deploy.sh"
chown $APP_USER:$APP_USER "$APP_DIR/deploy.sh"

print_success "Deployment helper script created at $APP_DIR/deploy.sh"

################################################################################
# Deployment Complete
################################################################################
echo ""
echo "======================================"
print_success "🎉 Deployment Complete!"
echo "======================================"
echo ""
print_info "Application Details:"
echo "  URL: $APP_URL"
echo "  Directory: $APP_DIR"
echo "  Database: $DB_TYPE"
echo ""
print_info "Useful Commands:"
echo "  View logs: tail -f $APP_DIR/storage/logs/laravel.log"
echo "  Restart workers: sudo supervisorctl restart laravel-worker:*"
echo "  Nginx config: sudo nano /etc/nginx/sites-available/$DOMAIN"
echo "  Run artisan: cd $APP_DIR && php artisan"
echo "  Quick deploy: cd $APP_DIR && ./deploy.sh"
echo ""
print_info "Next Steps:"
echo "  1. Visit $APP_URL to verify the installation"
echo "  2. Configure your DNS to point to this server"
echo "  3. Update .env file if needed: nano $APP_DIR/.env"
echo "  4. Run seeders if needed: php artisan db:seed"
echo ""
print_warning "Security Reminders:"
echo "  - Update .env with secure values"
echo "  - Set APP_DEBUG=false in production"
echo "  - Configure firewall (ufw enable)"
echo "  - Keep system packages updated"
echo ""

