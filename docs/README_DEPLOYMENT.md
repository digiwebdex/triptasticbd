# Triptastic — Self-Hosted VPS Deployment Guide

This guide covers deploying Triptastic on a Hostinger KVM VPS (Ubuntu 22.04+) **without any Supabase dependency**.

> **Important**: This VPS already hosts other websites. All instructions use **non-default ports** and **uniquely-named** services to avoid collisions.

---

## 1. Prerequisites

```bash
sudo apt update && sudo apt install -y nodejs npm postgresql postgresql-contrib nginx git
sudo npm install -g pm2
```

Verify Node ≥ 20:
```bash
node -v
```

---

## 2. Database setup (host PostgreSQL)

The current production deployment uses a host-installed PostgreSQL on **port 5440** (so it does not collide with another website's `5432`/`5433`).

```bash
sudo -u postgres createuser triptastic_user --pwprompt
sudo -u postgres createdb triptastic --owner=triptastic_user
```

Configure `pg_hba.conf` to require password and `postgresql.conf` to listen on the chosen port. Restart Postgres.

Apply the schema:

```bash
cd /var/www/Triptastic
cp .env.example .env       # then edit values
source .env
chmod +x migration/*.sh
./migration/run_migration.sh
./migration/seed_data.sh
```

---

## 3. Backend + frontend

```bash
cd /var/www/Triptastic
npm install
npm run build                       # builds dist/
cd server && npm install --omit=dev
cd ..

pm2 start server/index.js --name triptastic-api --update-env
pm2 save
pm2 startup    # follow the printed command
```

The Node process serves both the API (`/api/*`, `/auth/*`, etc.) and the React `dist/` static assets on `PORT` (default 3045).

Create the primary admin:
```bash
cd server && node create-admin.js
```

---

## 4. Nginx reverse proxy

`/etc/nginx/sites-available/triptastic.conf`:

```nginx
server {
    listen 80;
    server_name triptastic.example.com;

    client_max_body_size 25m;

    location / {
        proxy_pass http://127.0.0.1:3045;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/triptastic.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d triptastic.example.com
```

---

## 5. Docker alternative

```bash
cp .env.example .env   # edit values
docker compose up -d --build
docker compose logs -f triptastic-app
```

Container/host ports are configurable via `.env` (`PORT`, `DB_PORT_HOST`).

---

## 6. Avoiding port conflicts

| Service | Default port | Used by Triptastic |
|---|---|---|
| Nginx | 80/443 | shared via `server_name` |
| Postgres (other sites) | 5432/5433 | **5440** (Triptastic) |
| Other apps | 3000 | **3045** (Triptastic) |

Pick a port in `.env` that `sudo lsof -iTCP -sTCP:LISTEN -P -n` shows is free.

---

## 7. Verifying the deployment

```bash
curl http://127.0.0.1:3045/health
curl http://127.0.0.1:3045/                 # should return index.html
psql -h 127.0.0.1 -p 5440 -U triptastic_user -d triptastic -c '\dt' | head -20
pm2 list
```

Visit `https://triptastic.example.com/auth` and log in with the admin you created.

---

## 8. Troubleshooting

- **502 Bad Gateway** — `pm2 logs triptastic-api` and confirm the process is online.
- **DB auth failed** — URL-encode special chars in `DB_PASSWORD`; restart PM2 with `--update-env`.
- **CORS** — Set `FRONTEND_URL` correctly in `.env`.
- **Port already in use** — Change `PORT` in `.env`, then `pm2 restart triptastic-api --update-env`.
- **Migrations fail with "extension uuid-ossp"** — Run `setup_database.sh` as the Postgres superuser first.

---

## 9. Backups

```bash
pg_dump -h 127.0.0.1 -p 5440 -U triptastic_user triptastic | gzip > /backups/triptastic-$(date +%F).sql.gz
```

The repo also includes `server/backup-to-gdrive.sh` for automated rclone uploads.
