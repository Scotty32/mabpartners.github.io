#!/bin/sh
set -e

log() { echo "[entrypoint] $(date -u '+%H:%M:%S') $*"; }

wait_for() {
    local host=$1 port=$2 label=$3
    log "Waiting for ${label} (${host}:${port})..."
    until nc -z "${host}" "${port}" 2>/dev/null; do
        sleep 2
    done
    log "${label} ready."
}

wait_for "${DB_HOST}" "${DB_PORT}" "MariaDB"

log "Fixing permissions..."
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
# o+rX (pas o+w) : le conteneur nginx (volume app_storage monte en lecture seule)
# tourne sous un autre utilisateur que www-data et doit pouvoir lire/traverser
# storage/app/public pour servir les images uploadees via le lien public/storage.
chmod -R ug+rwX,o+rX        storage bootstrap/cache 2>/dev/null || true

php artisan storage:link --quiet 2>/dev/null || true

# bootstrap/cache est un volume nomme (app_bootstrap) qui survit aux rebuilds
# d'image et aux redeploiements. Un services.php genere avant un cleanup de code
# (classe/provider supprime) y reste indefiniment et fait planter le boot de
# Laravel des le premier artisan invoque — y compris config:clear, qui ne peut
# donc pas s'en charger lui-meme. On supprime les fichiers directement.
log "Purging stale bootstrap cache..."
rm -f bootstrap/cache/*.php

log "Caching config / routes / views / events..."
php artisan config:cache || log "config:cache failed — continuing"
php artisan route:cache  || log "route:cache failed — continuing"
php artisan view:cache   || log "view:cache failed — continuing"
php artisan event:cache  || log "event:cache failed — continuing"

log "Running migrations..."
php artisan migrate --force

log "Starting background workers..."
php artisan queue:work --sleep=3 --tries=3 --max-time=3600 --memory=256 &
php artisan schedule:work &

log "Starting PHP-FPM..."
exec php-fpm
