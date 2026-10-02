# Certificats Cloudflare Origin

Ce dossier doit contenir les certificats Cloudflare Origin utilises par nginx
pour terminer le TLS, en staging comme en production (voir
`.docker/nginx/dokploy.conf`, partage par les deux environnements).

A generer dans le dashboard Cloudflare (SSL/TLS > Origin Server > Create Certificate)
pour le domaine `demo.mycoffret.com`, puis a deposer ici sous ces deux noms :

- `fullchain.pem`
- `privatekey.pem`

Ces fichiers sont ignores par git (voir `.gitignore`) — ne jamais les committer.
Penser a passer le mode SSL/TLS de la zone Cloudflare sur "Full (strict)".
