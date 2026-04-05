# Troubleshooting Guide — Manasik Travel Hub

> Common issues, solutions, and diagnostic commands
> **Last Updated:** April 2026

---

## Frontend Issues

### Blank page / White screen

**Cause:** Build not completed or JavaScript error

**Fix:**
```bash
cd /var/www/manasik-travel-hub
npm run build
pm2 restart manasik-api
```
Then hard refresh: `Ctrl + Shift + R`

### Build fails with "failed to resolve import"

**Cause:** New npm package not installed on VPS

**Fix:**
```bash
npm install <package-name>
npm run build
pm2 restart manasik-api
```

**Example (react-helmet-async):**
```bash
npm install react-helmet-async && npm run build && pm2 restart manasik-api
```

### "Failed to load notification settings"

**Cause:** Missing notification_settings records in DB

**Fix:** Settings page creates default entries on load. Clear browser cache and reload.

### Language not switching

**Cause:** localStorage cached old language preference

**Fix:**
```javascript
localStorage.removeItem('mth_language');
```

### Login not working

**Cause:** JWT token expired or server/.env misconfigured

**Fix:**
1. Check server: `pm2 status`
2. Check logs: `pm2 logs manasik-api --lines 50`
3. Verify `server/.env` has correct `JWT_SECRET` and `DATABASE_URL`

### CMS content not showing

**Cause:** Missing site_content records in database

**Fix:**
```bash
psql -U digiwebdex -d manasik -p 5433 -h 127.0.0.1 -c "
INSERT INTO site_content (section_key, content)
SELECT key, '{}'::jsonb
FROM unnest(ARRAY['hero','navbar','services','about','packages','testimonials','facilities','gallery','guideline','video_guide','contact','whatsapp','footer']) AS key
WHERE NOT EXISTS (SELECT 1 FROM site_content WHERE section_key = key);
"
```

### SEO meta tags not updating

**Cause:** Browser cache or react-helmet-async not installed

**Fix:**
```bash
npm install react-helmet-async
npm run build && pm2 restart manasik-api
```
Then hard refresh and check page source (`Ctrl+U`)

---

## Backend Issues

### API returns 500

**Cause:** Database connection error or code error

**Fix:**
```bash
pm2 logs manasik-api --lines 50
psql -U digiwebdex -d manasik -p 5433 -h 127.0.0.1 -c "SELECT 1;"
pm2 restart manasik-api
```

### "relation does not exist" error

**Cause:** Schema not fully applied

**Fix:**
```bash
psql -U digiwebdex -d manasik -p 5433 -h 127.0.0.1 -f server/schema.sql
```

### File upload fails

**Cause:** `uploads/` directory missing or no permissions

**Fix:**
```bash
mkdir -p /var/www/manasik-travel-hub/server/uploads
chmod 755 /var/www/manasik-travel-hub/server/uploads
```

### API CORS error

**Cause:** `FRONTEND_URL` in server/.env doesn't match the requesting origin

**Fix:**
```bash
nano server/.env
# Update FRONTEND_URL to match your domain
pm2 restart manasik-api
```

---

## Database Issues

### Cannot connect to PostgreSQL

```bash
# Check Docker container
docker ps | grep postgres

# If container stopped
docker start <container-name>

# Check port
netstat -tlnp | grep 5433

# Test connection
psql -U digiwebdex -d manasik -p 5433 -h 127.0.0.1 -c "SELECT 1;"
```

### Wrong database password

```bash
# Check DATABASE_URL in server/.env
cat server/.env | grep DATABASE_URL
# Password with special characters: use them as-is (no URL encoding) when prompted
```

### Slow queries

```bash
psql -U digiwebdex -d manasik -p 5433 -h 127.0.0.1 -c "
  SELECT relname, n_tup_ins, n_tup_upd, n_tup_del
  FROM pg_stat_user_tables
  ORDER BY n_tup_ins DESC;
"
```

---

## Deployment Issues

### `git pull` fails with merge conflicts

```bash
git stash
git pull origin main
git stash pop
```

### npm install fails

```bash
rm -rf node_modules package-lock.json
npm install
```

### Build out of memory

```bash
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

### .env overwritten after git pull

```bash
# Re-protect .env
git update-index --skip-worktree .env
# Restore from backup or re-create
nano .env
```

### PM2 process not starting after reboot

```bash
pm2 resurrect
# If that fails:
cd /var/www/manasik-travel-hub
pm2 start server/index.js --name manasik-api
pm2 save
```

---

## Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `ECONNREFUSED 5433` | PostgreSQL not running | `docker start <container>` |
| `invalid input syntax for type uuid` | Malformed UUID | Check request parameters |
| `permission denied for table` | Wrong DB user | Check DATABASE_URL credentials |
| `CORS error` | FRONTEND_URL mismatch | Update `server/.env` FRONTEND_URL |
| `413 Payload Too Large` | File > 5MB | Resize file or update Nginx `client_max_body_size` |
| `.env overwritten` | File not protected | `git update-index --skip-worktree .env` |
| `Cannot find module` | Package not installed | `npm install` on VPS |
| `EADDRINUSE 3004` | Port already in use | `lsof -i :3004` and kill process |
| `jwt malformed` | Invalid/expired token | Clear localStorage, re-login |
| `No such container` | Wrong Docker container name | `docker ps -a` to find correct name |

---

## Diagnostic Commands Cheatsheet

```bash
# API health
curl -s http://localhost:3004/api/packages | head -c 200

# PM2 status
pm2 status

# PM2 logs
pm2 logs manasik-api --lines 50

# Database check
psql -U digiwebdex -d manasik -p 5433 -h 127.0.0.1 -c "SELECT count(*) FROM bookings;"

# Disk space
df -h

# Memory
free -h

# Node processes
ps aux | grep node

# Port usage
netstat -tlnp | grep -E '3004|5433|80|443'

# Docker containers
docker ps

# Nginx test
nginx -t

# SSL check
certbot certificates
```
