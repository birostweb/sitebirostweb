# ============================================================
#  birostweb.fr — image de production (site statique)
#  Base durcie : nginx "unprivileged" => tourne en utilisateur non-root,
#  écoute sur le port 8080 (aucun privilège root nécessaire).
# ============================================================
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Métadonnées
LABEL org.opencontainers.image.title="birostweb" \
      org.opencontainers.image.description="Site vitrine Theo Birost - developpeur web full-stack" \
      org.opencontainers.image.url="https://birostweb.fr" \
      org.opencontainers.image.licenses="UNLICENSED"

# Config nginx durcie
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Contenu du site
COPY site/ /usr/share/nginx/html/

# Le port applicatif (non privilégié)
EXPOSE 8080

# Healthcheck : Dokploy/Docker vérifie que nginx répond
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/bin/sh","-c","wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1"]

# (l'utilisateur nginx non-root et la commande de lancement sont
#  déjà définis par l'image de base)
