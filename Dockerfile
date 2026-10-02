# ─── Stage 1 : Dependances PHP (sans dev) ─────────────────────────────────────
FROM composer:2 AS composer-builder

WORKDIR /build

COPY composer.json composer.lock ./
COPY app/      ./app/
COPY config/   ./config/
COPY database/ ./database/
COPY routes/   ./routes/

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts \
    --ignore-platform-reqs

# ─── Stage 2 : Build des assets frontend ──────────────────────────────────────
FROM node:22-bookworm-slim AS node-builder

WORKDIR /build

COPY package.json package-lock.json ./
RUN npm ci --prefer-offline

COPY resources/                        ./resources/
COPY public/                           ./public/
COPY vite.config.js                    ./

RUN npm run build

# ─── Stage 3 : Image de production finale ─────────────────────────────────────
FROM php:8.3-fpm-bookworm AS final

RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-openbsd \
    default-mysql-client \
    libzip-dev \
    libonig-dev \
 && docker-php-ext-install -j"$(nproc)" \
    bcmath mbstring pdo_mysql zip pcntl opcache \
 && rm -rf /var/lib/apt/lists/*

RUN { \
    echo "opcache.enable=1"; \
    echo "opcache.memory_consumption=256"; \
    echo "opcache.interned_strings_buffer=16"; \
    echo "opcache.max_accelerated_files=20000"; \
    echo "opcache.revalidate_freq=0"; \
    echo "opcache.validate_timestamps=0"; \
    echo "opcache.fast_shutdown=1"; \
} > /usr/local/etc/php/conf.d/opcache-prod.ini

WORKDIR /var/www/html

COPY --chown=www-data:www-data . .

COPY --from=composer-builder --chown=www-data:www-data /build/vendor       ./vendor
COPY --from=node-builder     --chown=www-data:www-data /build/public/build ./public/build

RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R ug+rwX            storage bootstrap/cache

COPY --chmod=755 ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
