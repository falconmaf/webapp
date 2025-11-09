# Package Migration Guide: psycho-h.com → webapp

## Overview
This document outlines the migration of packages from the Laravel 8 project (psycho-h.com) to the Laravel 12 project (webapp).

---

## Installation Instructions

### Method 1: Automated Script (Recommended)

```bash
cd ~/local/webapp
chmod +x install-packages.sh
./install-packages.sh
```

### Method 2: Manual Installation

If the script fails, install packages individually:

```bash
cd ~/local/webapp

# Core utilities
composer require adbario/php-dot-notation
composer require intervention/image
composer require hekmatinasser/verta
composer require lab404/laravel-impersonate

# Spatie packages
composer require spatie/laravel-activitylog
composer require spatie/laravel-short-schedule

# JWT Auth (modern alternative)
composer require php-open-source-saver/jwt-auth

# Filament ecosystem (Voyager replacement)
composer require filament/filament:"^3.0"
composer require leandrocfe/filament-apex-charts
composer require saade/filament-fullcalendar

# Charts (alternative to consoletvs/charts)
composer require arielmejiadev/larapex-charts

# NPM packages
npm install apexcharts chart.js --save
```

---

## Package Mapping

### ✅ Direct Replacements (Same Package, Updated Version)

| Old Package (Laravel 8) | New Package (Laravel 12) | Status |
|-------------------------|--------------------------|--------|
| `adbario/php-dot-notation: ^2.2` | `adbario/php-dot-notation` (latest) | ✅ Compatible |
| `intervention/image: ^2.6` | `intervention/image: ^3.0` | ✅ Compatible (v3) |
| `hekmatinasser/verta: ^1.12` | `hekmatinasser/verta` (latest) | ✅ Compatible |
| `lab404/laravel-impersonate: ^1.2` | `lab404/laravel-impersonate` (latest) | ✅ Compatible |
| `spatie/laravel-activitylog: ^3.17` | `spatie/laravel-activitylog` (latest) | ✅ Compatible |
| `spatie/laravel-short-schedule: ^1.4` | `spatie/laravel-short-schedule` (latest) | ✅ Compatible |

### 🔄 Alternative Packages (Better Fit for Laravel 12)

| Old Package | New Alternative | Reason |
|-------------|----------------|--------|
| `tcg/voyager: 1.4.x-dev` | `filament/filament: ^3.0` | Modern, Livewire 3 native, better UX |
| `tymon/jwt-auth: dev-develop` | `php-open-source-saver/jwt-auth` | Actively maintained fork |
| `consoletvs/charts: 7.*` | `arielmejiadev/larapex-charts` | Laravel 12 compatible |
| `asantibanez/livewire-charts: ^2.3` | `leandrocfe/filament-apex-charts` | Livewire 3 compatible |
| `asantibanez/livewire-calendar: ^2.1` | `saade/filament-fullcalendar` | Livewire 3 compatible |
| `devdojo/themes: 0.0.5` | Filament Themes | Better theming system |

### ❌ Not Needed (Built into Laravel 12)

| Old Package | Replacement | Notes |
|-------------|-------------|-------|
| `fideloper/proxy: ^4.2` | Built-in `TrustProxies` | Use `app/Http/Middleware/TrustProxies.php` |
| `fruitcake/laravel-cors: ^1.0` | Built-in CORS | Configure in `config/cors.php` |
| `laravel/helpers: ^1.0` | Laravel Framework | Helpers included in framework |

### 📦 Already Installed via Dependencies

| Package | Version in webapp | Notes |
|---------|------------------|-------|
| `guzzlehttp/guzzle` | 7.10.0 | Already available |
| `monolog/monolog` | 3.9.0 | Already available |

### 📊 NPM Package Updates

| Old Package | New Package | Notes |
|-------------|-------------|-------|
| `chart.js: ^2.9.4` | `chart.js: latest` | Updated to latest |
| `@chartisan/chartjs: ^2.1.0` | `apexcharts` | Modern alternative |

---

## Post-Installation Configuration

### 1. Publish Configuration Files

```bash
# Filament
php artisan vendor:publish --tag=filament-config
php artisan vendor:publish --tag=filament-panels

# Activity Log
php artisan vendor:publish --tag=laravel-activitylog-config
php artisan vendor:publish --tag=activitylog-migrations

# JWT Auth
php artisan vendor:publish --provider="PHPOpenSourceSaver\JWTAuth\Providers\LaravelServiceProvider"

# Intervention Image
php artisan vendor:publish --provider="Intervention\Image\ImageServiceProvider"
```

### 2. Run Migrations

```bash
php artisan migrate
```

### 3. Install Filament Panel

```bash
php artisan filament:install --panels
```

### 4. Create Admin User

```bash
php artisan make:filament-user
```

### 5. Generate JWT Secret

```bash
php artisan jwt:secret
```

---

## Configuration Changes Required

### 1. Update `config/app.php`

Add to providers array (if not auto-discovered):

```php
'providers' => [
    // ... other providers
    Intervention\Image\ImageServiceProvider::class,
    Spatie\Activitylog\ActivitylogServiceProvider::class,
    Lab404\Impersonate\ImpersonateServiceProvider::class,
],
```

### 2. Update `.env`

```env
# JWT Configuration
JWT_SECRET=your-secret-key
JWT_TTL=60
JWT_REFRESH_TTL=20160

# Filament Configuration
FILAMENT_FILESYSTEM_DISK=public
```

### 3. Update Models for Activity Log

Add to your models:

```php
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class YourModel extends Model
{
    use LogsActivity;

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'text']);
    }
}
```

---

## Feature Equivalents

### Admin Panel: Voyager → Filament

**Old (Voyager):**
```php
// Routes automatically generated
Route::group(['prefix' => 'admin'], function () {
    Voyager::routes();
});
```

**New (Filament):**
```php
// Create resources
php artisan make:filament-resource User

// Access at /admin
// Fully customizable panels
```

### Charts: consoletvs/charts → ApexCharts/Filament Charts

**Old:**
```php
$chart = Charts::create('line', 'highcharts')
    ->title('My Chart');
```

**New (Filament):**
```php
use Leandrocfe\FilamentApexCharts\Widgets\ApexChartWidget;

class BlogPostsChart extends ApexChartWidget
{
    protected static ?string $chartId = 'blogPostsChart';
    
    protected function getOptions(): array
    {
        return [
            'chart' => [
                'type' => 'line',
            ],
            // ... options
        ];
    }
}
```

### Livewire Calendar

**Old (Livewire 2):**
```blade
<livewire:calendar />
```

**New (Filament Full Calendar):**
```php
php artisan make:filament-widget CalendarWidget
```

---

## Breaking Changes to Watch

1. **Intervention Image v2 → v3**
   - API changed significantly
   - Update image manipulation code

2. **Livewire 2 → 3**
   - Property syntax changed
   - Validation syntax updated
   - Events handling different

3. **JWT Auth**
   - Different namespace: `PHPOpenSourceSaver\JWTAuth` vs `Tymon\JWTAuth`
   - Update imports in controllers

---

## Testing Checklist

After installation, test these features:

- [ ] Admin panel accessible at `/admin`
- [ ] User authentication with JWT
- [ ] Image uploads and manipulation
- [ ] Activity logging for models
- [ ] User impersonation
- [ ] Charts rendering correctly
- [ ] Calendar displaying events
- [ ] Persian date/time conversion

---

## Troubleshooting

### Issue: Composer memory limit

```bash
COMPOSER_MEMORY_LIMIT=-1 composer require package-name
```

### Issue: NPM conflicts

```bash
rm -rf node_modules package-lock.json
npm install
```

### Issue: Permission errors

```bash
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

---

## Additional Resources

- [Filament Documentation](https://filamentphp.com/docs)
- [Intervention Image v3 Docs](https://image.intervention.io/v3)
- [Spatie Activity Log](https://spatie.be/docs/laravel-activitylog)
- [PHP JWT Auth](https://github.com/PHP-Open-Source-Saver/jwt-auth)
- [ApexCharts](https://apexcharts.com/)

---

## Summary

**Total Packages to Install:** 11 composer packages + 2 npm packages

**Estimated Installation Time:** 5-10 minutes

**Post-Configuration Time:** 15-20 minutes

**Total Migration Effort:** ~30 minutes
