#!/bin/bash

################################################################################
# Quick Email Configuration Script for camptell.space Laravel App
# 
# This script updates the .env file with Gmail SMTP settings
################################################################################

APP_DIR="/var/www/webapp"

echo "Configuring Gmail SMTP for Laravel..."

cd "$APP_DIR"

# Backup current .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Update email configuration
sed -i "s|MAIL_MAILER=.*|MAIL_MAILER=smtp|g" .env
sed -i "s|MAIL_HOST=.*|MAIL_HOST=smtp.gmail.com|g" .env
sed -i "s|MAIL_PORT=.*|MAIL_PORT=587|g" .env
sed -i "s|MAIL_USERNAME=.*|MAIL_USERNAME=maf.mailing@gmail.com|g" .env
sed -i "s|MAIL_PASSWORD=.*|MAIL_PASSWORD=\"chms nuqu irhq dlpz\"|g" .env
sed -i "s|MAIL_ENCRYPTION=.*|MAIL_ENCRYPTION=tls|g" .env
sed -i "s|MAIL_FROM_ADDRESS=.*|MAIL_FROM_ADDRESS=noreply@camptell.space|g" .env
sed -i "s|MAIL_FROM_NAME=.*|MAIL_FROM_NAME=\"Camptell\"|g" .env

# If mail settings don't exist, add them
grep -q "MAIL_MAILER" .env || echo "
# Mail Configuration
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=maf.mailing@gmail.com
MAIL_PASSWORD=\"chms nuqu irhq dlpz\"
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@camptell.space
MAIL_FROM_NAME=\"Camptell\"
" >> .env

# Clear config cache
php artisan config:clear
php artisan config:cache

echo "✓ Gmail SMTP configured successfully!"
echo ""
echo "Email configured with: maf.mailing@gmail.com"
echo ""
echo "Test email with:"
echo "  cd /var/www/webapp && php artisan tinker"
echo "  Mail::raw('Test from Camptell', function(\$msg) { \$msg->to('test@example.com')->subject('Test'); });"
