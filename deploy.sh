#!/bin/bash
# cPanel Deployment Script
# Run this after git pull

export DEPLOYPATH=/home/camptell/webapp

cd $DEPLOYPATH

echo "Installing Composer dependencies..."
/opt/cpanel/ea-php83/root/usr/bin/php /usr/local/bin/composer install --no-dev --optimize-autoloader

echo "Installing npm dependencies..."
/usr/bin/npm install

echo "Building frontend assets..."
/usr/bin/npm run build

echo "Caching Laravel configuration..."
/opt/cpanel/ea-php83/root/usr/bin/php artisan config:cache
/opt/cpanel/ea-php83/root/usr/bin/php artisan route:cache
/opt/cpanel/ea-php83/root/usr/bin/php artisan view:cache

echo "Deploying to public_html..."
rm -rf /home/camptell/public_html/*
/bin/cp -rL $DEPLOYPATH/public/* /home/camptell/public_html/
/bin/cp $DEPLOYPATH/public/.htaccess /home/camptell/public_html/.htaccess

echo "Setting permissions..."
chmod -R 755 /home/camptell/public_html

echo "Deployment complete!"
