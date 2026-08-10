# Render deployment image for the Deendoon Laravel API.
# Prepared for a short-term customer demo — see deendoon/RENDER_DEPLOYMENT.md
# for the full deployment plan, required environment variables, and the
# documented trade-offs (local file storage, no worker/queue/cron) behind
# the choices made here.

# ---- Stage 1: frontend asset build -----------------------------------------
# Builds public/build so Laravel's stub "/" welcome view (which references
# @vite) doesn't throw a Vite-manifest exception on request. The /api/v1
# surface the Flutter app actually talks to does not depend on this build.
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

# Render injects $PORT at runtime. `php artisan serve` is used as the
# simplest reliable option for a short-lived demo (no nginx/php-fpm process
# supervision to configure) — a deliberate simplification, not a
# recommendation for an extended/production deployment.
#
# route:cache is intentionally NOT run at startup: routes/web.php's stub
# "/" route is a closure, which route:cache cannot serialize — running it
# would break the container on every boot.
#
# Database migrations are intentionally NOT run here — they remain a
# separate, explicit, approved step against the Render Postgres instance.
EXPOSE 8000
CMD ["sh", "-c", "php artisan config:cache && php artisan view:cache && php artisan serve --host=0.0.0.0 --port=${PORT:-8000}"]
