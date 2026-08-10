# birostweb.fr

Site vitrine statique de Théo Birost — développeur web full-stack.
Servi par **nginx durci** dans un conteneur Docker **non-root**, déployable sur **Dokploy**.

## Structure

```
birostweb/
├── Dockerfile            # image de prod (nginx-unprivileged, port 8080)
├── .dockerignore
├── nginx/
│   └── default.conf      # config nginx durcie + en-têtes de sécurité + CSP
└── site/                 # SEUL contenu servi au public (= web root)
    ├── index.html
    ├── og-image.png      # image de partage réseaux sociaux (1200×630)
    ├── robots.txt
    ├── sitemap.xml
    ├── fonts/            # polices IBM Plex auto-hébergées (RGPD, 0 requête Google)
    └── .well-known/
        └── security.txt
```

## Sécurité mise en place

- **Conteneur non-root** (`nginxinc/nginx-unprivileged`), écoute sur `8080`.
- **En-têtes** : HSTS, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy`, `Permissions-Policy` (toutes API sensibles coupées),
  `Cross-Origin-Opener-Policy` / `Cross-Origin-Resource-Policy`.
- **Content-Security-Policy stricte** : `script-src` verrouillé par le **hash SHA-256**
  du script inline (aucun `'unsafe-inline'` pour le JS → bloque le XSS injecté),
  tout en `'self'`, aucune ressource externe.
- **Méthodes** limitées à `GET`/`HEAD` (le reste → 405).
- **Fichiers cachés** (`.git`, `.env`…) bloqués, sauf `/.well-known/`.
- **Polices auto-hébergées** → aucune fuite d'IP vers Google (conformité RGPD).
- Formulaire de contact en `mailto:` → **aucun back-end**, donc aucune surface d'attaque serveur.

> ⚠️ Si tu modifies le `<script>` dans `index.html`, il faut **régénérer le hash CSP** :
> ```bash
> python3 -c "import re,hashlib,base64;h=open('site/index.html').read();b=re.search(r'<script>(.*?)</script>',h,re.S).group(1);print('sha256-'+base64.b64encode(hashlib.sha256(b.encode()).digest()).decode())"
> ```
> puis remplace la valeur `script-src 'sha256-...'` dans `nginx/default.conf`.

## Tester en local

```bash
docker build -t birostweb .
docker run --rm -p 8080:8080 birostweb
# → http://localhost:8080
```

## Déploiement sur Dokploy

1. **Pousser ce dossier sur un dépôt Git** (GitHub/GitLab).
2. Dans Dokploy : **Create → Application**, source = ton dépôt Git, branche `main`.
3. **Build Type = Dockerfile** (chemin `./Dockerfile`).
4. **Port** exposé par l'app : `8080`.
5. Onglet **Domains** : ajouter `birostweb.fr` (et `www.birostweb.fr`),
   activer **HTTPS / Let's Encrypt** (Traefik génère le certificat automatiquement).
6. **Deploy**.

## DNS chez OVH

Dans l'espace client OVH → **Domaines → birostweb.fr → Zone DNS** :

| Type  | Sous-domaine | Cible                       |
|-------|--------------|-----------------------------|
| A     | (vide / `@`) | `IP.DU.SERVEUR.DOKPLOY`     |
| CNAME | `www`        | `birostweb.fr.`             |

- Remplace `IP.DU.SERVEUR.DOKPLOY` par l'IP publique de ton VPS Dokploy.
- Propagation : quelques minutes à quelques heures.
- Une fois le DNS propagé, Dokploy/Traefik délivre le certificat TLS tout seul.
