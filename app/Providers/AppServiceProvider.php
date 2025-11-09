<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Example: Override TallStackUI Button component
        // $this->app->bind(
        //     \TallStackUi\View\Components\Button::class,
        //     \App\Overrides\TallStackUi\Button::class
        // );
    }

    public function boot(): void
    {
        //
    }
}
