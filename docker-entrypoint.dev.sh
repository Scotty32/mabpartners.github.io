#!/bin/sh
set -e

echo "Initialize application..."

if [ ! -f .env ]; then
    echo "No .env file found, copying from .env.example"
    cp .env.example .env
fi

until nc -z -v -w30 db 3306
do
    echo "Waiting for db connexion..."
    sleep 5
done

echo "Fixing permissions..."
mkdir -p storage/framework/cache storage/framework/sessions storage/framework/testing storage/framework/views storage/logs bootstrap/cache
chown -R www-data:www-data storage/framework storage/logs bootstrap/cache
chmod -R ug+rwX storage/framework storage/logs bootstrap/cache

echo "Installing PHP dependencies..."
composer install --no-interaction --prefer-dist
npm install

php artisan key:generate --ansi --force

echo "Linking storage..."
php artisan storage:link --quiet 2>/dev/null || true

echo "Migrate database..."
php artisan migrate --force || true

echo "Starting background workers..."
php artisan queue:work --tries=1 &
php artisan schedule:work &

echo "Starting Vite dev server..."
npm run dev -- --host &

echo "Ready. Starting PHP-FPM..."
exec php-fpm
