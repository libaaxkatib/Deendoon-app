# Portable deployment image for the Deendoon Laravel API + admin panel.
# Runs on any container host that injects a PORT env var and points it at
# a PostgreSQL database (e.g. Railway). No app server other than PHP's
# built-in `artisan serve` is used — see the CMD comment below for why,
# and for the documented trade-offs of that choice.

# ---- Stage 1: frontend asset build -----------------------------------------
# Builds public/build, which is required by the compiled Vite assets in
# resources/views/admin/layout.blade.php and admin/auth/login.blade.php
# (the entire admin panel's CSS/JS), as well as the stub "/" welcome view.
FROM node:20-alpine AS assets
WORKDIR /app
COPY package.json ./
COPY vite.config.js ./
COPY resources ./resources
COPY public ./public
RUN npm install --ignore-scripts && npm run build

# ---- Stage 2: PHP application -----------------------------------------------
FROM php:8.4-cli-alpine

RUN apk add --no-cache postgresql-dev libzip-dev icu-dev oniguruma-dev libpng-dev libjpeg-turbo-dev freetype-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_pgsql pgsql zip bcmath intl mbstring gd

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .
COPY --from=assets /app/public/build ./public/build

RUN composer install --no-dev --no-interaction --optimize-autoloader \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/testing storage/framework/views storage/logs bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# The host injects $PORT at runtime (Railway and Render both use this
# convention: bind to 0.0.0.0:$PORT). `php artisan serve` is used as the
# simplest reliable option (no nginx/php-fpm process supervision to
# configure) — a deliberate simplification, not a recommendation for a
# deployment that needs real request concurrency.
#
# route:cache is intentionally NOT run at startup: routes/web.php's stub
# "/" route is a closure, which route:cache cannot serialize — running it
# would break the container on every boot.
#
# Migrations and seeding are deliberately NOT run here. SESSION_DRIVER=
# database and CACHE_STORE=database mean nearly every request touches
# Postgres, so the database must already be migrated before this
# container starts — that step belongs in the deploy platform's
# pre-deploy/release-phase hook (`php artisan migrate --force &&
# php artisan db:seed --force`), which runs once per deploy in its own
# container, ahead of traffic being routed here. Running migrate/seed
# inside this CMD would re-run it on every container boot/restart,
# risking concurrent migration runs if the platform ever restarts a
# crashed container or scales to multiple replicas.
EXPOSE 8000
CMD ["sh", "-c", "php artisan config:cache && php artisan view:cache && php artisan serve --host=0.0.0.0 --port=${PORT:-8000}"]
