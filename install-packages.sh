#!/bin/bash

# Installation script for migrating packages from psycho-h.com to webapp
# Laravel 12 & Livewire 3 Compatible Packages

set -e  # Exit on error

echo "=================================================="
echo "Installing Laravel 12 Compatible Packages"
echo "=================================================="
echo ""

# Change to webapp directory
cd ~/local/webapp

echo "Step 1: Installing Core Utility Packages..."
echo "-------------------------------------------"
composer require adbario/php-dot-notation --no-interaction

echo ""
echo "Step 2: Installing Image Processing..."
echo "-------------------------------------------"
composer require intervention/image --no-interaction

echo ""
echo "Step 3: Installing Persian Date/Time Handler..."
echo "-------------------------------------------"
composer require hekmatinasser/verta --no-interaction

echo ""
echo "Step 4: Installing User Impersonation..."
echo "-------------------------------------------"
composer require lab404/laravel-impersonate --no-interaction

echo ""
echo "Step 5: Installing Activity Logging..."
echo "-------------------------------------------"
composer require spatie/laravel-activitylog --no-interaction

echo ""
echo "Step 6: Installing Short Schedule..."
echo "-------------------------------------------"
composer require spatie/laravel-short-schedule --no-interaction

echo ""
echo "Step 7: Installing JWT Authentication..."
echo "-------------------------------------------"
composer require php-open-source-saver/jwt-auth --no-interaction

echo ""
echo "Step 8: Installing Filament Admin Panel..."
echo "-------------------------------------------"
composer require filament/filament:"^3.0" --no-interaction

echo ""
echo "Step 9: Installing Filament Apex Charts..."
echo "-------------------------------------------"
composer require leandrocfe/filament-apex-charts --no-interaction

echo ""
echo "Step 10: Installing Filament Full Calendar..."
echo "-------------------------------------------"
composer require saade/filament-fullcalendar --no-interaction

echo ""
echo "Step 11: Installing Additional Chart Package..."
echo "-------------------------------------------"
composer require arielmejiadev/larapex-charts --no-interaction

echo ""
echo "Step 12: Installing NPM Packages..."
echo "-------------------------------------------"
npm install apexcharts chart.js --save

echo ""
echo "=================================================="
echo "✅ Installation Complete!"
echo "=================================================="
echo ""
echo "Next Steps:"
echo "1. Run: php artisan vendor:publish --tag=filament-config"
echo "2. Run: php artisan vendor:publish --tag=laravel-activitylog-config"
echo "3. Run: php artisan migrate"
echo "4. Run: php artisan filament:install --panels"
echo "5. Create admin user: php artisan make:filament-user"
echo ""
echo "=================================================="
