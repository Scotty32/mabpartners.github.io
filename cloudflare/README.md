# Certificats Cloudflare Origin

Ce dossier doit contenir les certificats Cloudflare Origin utilises par nginx
pour terminer le TLS en staging et en production (voir `.docker/nginx/staging.conf`
et `.docker/nginx/prod.conf`).

A generer dans le dashboard Cloudflare (SSL/TLS > Origin Server > Create Certificate)
pour les domaines `mycoffret.com`, `www.mycoffret.com` et `staging.mycoffret.com`,
puis a deposer ici sous ces deux noms :

- `fullchain.pem`
- `privatekey.pem`

Ces fichiers sont ignores par git (voir `.gitignore`) — ne jamais les committer.
Penser a passer le mode SSL/TLS de la zone Cloudflare sur "Full (strict)".
