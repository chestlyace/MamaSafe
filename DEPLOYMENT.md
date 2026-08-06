# MamaSafe — Single-Server Deployment Runbook

Everything needed to stand up MamaSafe in production on one Linux box
(EC2 t3.small/medium, Ubuntu 22.04 or Amazon Linux 2023). The stack is
Docker Compose (FastAPI + Baileys + PostgreSQL + React) behind a host
Nginx that terminates TLS.

```
Internet
   │ 80/443
┌──▼────────────────────────────────────────────┐
│ Host Nginx (reverse proxy, TLS termination)   │
│  www./root  → frontend container :8080        │
│  /api/      → backend container  :8000        │
│  api.*      → backend container  :8000        │
│  downloads. → /var/www/downloads (APK files)  │
└──┬────────────────────────────────────────────┘
   │ 127.0.0.1 only (not exposed publicly)
┌──▼────────────────────────────────────────────┐
│ Docker Compose ("mamasafe")                   │
│  frontend (nginx:alpine SPA)  127.0.0.1:8080  │
│  backend  (FastAPI/uvicorn)   127.0.0.1:8000  │
│  whatsapp (Baileys/Express)   127.0.0.1:3001  │
│  db       (PostgreSQL 16)     internal only   │
│  volumes: pgdata, wa_auth                     │
└───────────────────────────────────────────────┘
```

## Deployment checklist

| # | Item | Done |
|---|------|------|
| 1 | DNS records point at the server | ☐ |
| 2 | AWS Security Group: 80/443/22 only, SSH locked to your IP | ☐ |
| 3 | Server provisioned (Docker, Compose, Nginx, Certbot) | ☐ |
| 4 | Repo cloned, `deploy/.env.production` filled in | ☐ |
| 5 | TLS certs issued via Let's Encrypt | ☐ |
| 6 | Stack deployed and healthy | ☐ |
| 7 | APK built, uploaded, download page live | ☐ |
| 8 | WhatsApp session paired (QR) | ☐ |
| 9 | Backups verified + cron installed | ☐ |
| 10 | Monitoring cron + logrotate installed | ☐ |
| 11 | Security hardening confirmed (secrets, CORS, firewall) | ☐ |

---

## 1. DNS

Create A records in your DNS provider:

| Name | Type | Value |
|------|------|-------|
| `@`  | A | SERVER_IP |
| `www` | A | SERVER_IP |
| `api` | A | SERVER_IP |
| `downloads` | A | SERVER_IP |

## 2. AWS Security Group

Inbound rules **only**:

| Port | Source | Purpose |
|------|--------|---------|
| 22   | `YOUR_IP/32` | SSH |
| 80   | `0.0.0.0/0` | HTTP (redirect + ACME) |
| 443  | `0.0.0.0/0` | HTTPS |

PostgreSQL is never exposed — it is bound inside the Docker bridge
network only.

## 3. Provision the server

```bash
sudo apt update && sudo apt install -y git
sudo bash -c 'curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /dev/null' # sanity
```

Then run the provisioning script (installs Docker, Compose plugin,
Nginx, Certbot, curl, jq; creates `/opt/mamasafe`, `/var/www/downloads`,
`/var/www/certbot`; enables UFW on 22/80/443):

```bash
sudo bash deploy/scripts/setup-server.sh
```

For Amazon Linux, the same script switches to `dnf` automatically.

> UFW: after provisioning, lock SSH to your operator IP if desired:
> `sudo ufw delete allow 22/tcp && sudo ufw allow from <YOUR_IP> to any port 22 proto tcp`

## 4. Clone the repo & configure

```bash
sudo mkdir -p /opt/mamasafe && sudo chown "$USER" /opt/mamasafe
git clone -b deployed https://<HOST>/MamaSafe.git /opt/mamasafe/MamaSafe
cd /opt/mamasafe/MamaSafe/deploy
cp .env.production.example .env.production
nano .env.production      # ← fill in every CHANGE_ME value
```

Generate strong values:

```bash
openssl rand -hex 32                  # SECRET_KEY, WEBHOOK_SECRET
openssl rand -base64 24               # POSTGRES_PASSWORD
openssl rand -base64 24               # ADMIN_PASSWORD
```

`.env.production` is git-ignored and never committed. It holds all
secrets and the compose stack reads it via `env_file`.

## 5. TLS certificates

Webroot mode; `certbot-init.sh` installs a temporary HTTP bootstrap
site so the ACME challenge succeeds, then restores Nginx:

```bash
sudo bash deploy/scripts/certbot-init.sh /opt/mamasafe/MamaSafe
```

Renewal is automatic (certbot systemd timer / cron).

## 6. Deploy the stack

```bash
bash deploy/scripts/deploy.sh /opt/mamasafe/MamaSafe
```

This: pulls `origin/deployed`, `docker compose up -d --build`, renders
`deploy/nginx/mamasafe.conf` via `envsubst` into
`/etc/nginx/sites-available/mamasafe`, runs `nginx -t`, and reloads.

Verify:

```bash
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy ps
curl -s http://127.0.0.1:8000/health
curl -sI https://www.yourdomain.com | head -1      # 200
curl -s https://api.yourdomain.com/health | jq .
```

## 7. Android APK + download page

Point the mobile app at production, build, upload:

```bash
cp mobile/.env.production.example mobile/.env   # edit values
bash deploy/scripts/build-apk.sh                # builds release APK, prints VITE_APK_* values
```

Copy the printed `VITE_APK_*` values into `deploy/.env.production`,
then upload the APK:

```bash
scp mobile/build/app/outputs/flutter-apk/app-release.apk \
    user@SERVER:/var/www/downloads/mamasafe-v1.0.0.apk
bash deploy/scripts/deploy.sh /opt/mamasafe/MamaSafe   # rebuild frontend with new download info
```

The download page (`/download`) reads `VITE_APK_URL`,
`VITE_APK_VERSION`, `VITE_APK_CHECKSUM`, `VITE_APK_CHANGELOG` and
shows the SHA-256. APK files are served from `downloads.` with
`Cache-Control: public, max-age=3600`.

## 8. WhatsApp session pairing

The Baileys session lives in the `wa_auth` Docker volume. To pair:

```bash
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy logs -f whatsapp
```

Scan the QR with the target WhatsApp phone. The session persists in the
volume across restarts. To pair a new phone, delete the volume and
restart the service:

```bash
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy stop whatsapp
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy rm -f whatsapp
docker volume rm mamasafe_wa_auth
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy up -d whatsapp
```

Inbound messages are posted to
`http://backend:8000/api/v1/referrals/webhook/whatsapp` (auth: the
`WEBHOOK_SECRET` shared between both services).

## 9. Backups

Nightly `pg_dump` + config + WhatsApp session volume, 14-day retention,
optional S3 offsite:

```bash
crontab -e
# 30 2 * * * bash /opt/mamasafe/MamaSafe/deploy/scripts/backup-db.sh >> /opt/mamasafe/logs/backup.log 2>&1
```

Restore procedure:

```bash
# one-off, from any host with the dump:
gunzip -c backups/db-YYYYMMDD-HHMMSS.sql.gz > /tmp/db.sql
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy exec -T db \
    psql -U mamasafe_user -d mamasafe < /tmp/db.sql
```

Restore the WhatsApp session volume from `wa-session-*.tar.gz`:

```bash
docker run --rm -v mamasafe_wa_auth:/data -v "$PWD":/backup \
    alpine:3.20 tar xzf /backup/wa-session-*.tar.gz -C /data
```

## 10. Monitoring & logrotate

Every 5 minutes; exits non-zero if a container or health check fails
(usable with any cron-email or nagios wrapper):

```bash
crontab -e
# */5 * * * * bash /opt/mamasafe/MamaSafe/deploy/scripts/monitor.sh >> /opt/mamasafe/logs/monitor.log 2>&1
```

Install logrotate for operator logs (Docker container logs are already
capped 10m x 5 by the json-file driver):

```bash
sudo cp deploy/logrotate/mamasafe /etc/logrotate.d/mamasafe
```

Service logs:

```bash
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy logs -f backend
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy logs -f whatsapp
docker compose --project-directory /opt/mamasafe/MamaSafe/deploy logs -f frontend
```

## 11. Updating / rolling back

Update:

```bash
git -C /opt/mamasafe/MamaSafe pull --ff-only origin deployed
bash deploy/scripts/deploy.sh /opt/mamasafe/MamaSafe
```

Rollback to a previous tag/commit:

```bash
git -C /opt/mamasafe/MamaSafe checkout <PREV_SHA> -- deploy frontend backend mobile
bash deploy/scripts/deploy.sh /opt/mamasafe/MamaSafe
```

## 12. Security hardening (final pass)

- [ ] `deploy/.env.production` contains real secrets and is **not** in git
      (`git check-ignore deploy/.env.production` should print the path).
- [ ] `ALLOWED_ORIGINS` lists only `https://yourdomain.com` +
      `https://www.yourdomain.com` (CORS is origin-restricted, not `*`).
- [ ] PostgreSQL port is not published; DB only reachable inside the
      compose network.
- [ ] UFW: only 22/80/443 inbound; SSH source = operator IP.
- [ ] `ADMIN_PASSWORD` changed from the seeded default; the seeded
      `admin` account forces a password change on first login.
- [ ] Security Group mirrors the UFW rules (defense in depth).
- [ ] Container ports bound to `127.0.0.1` only (verified in
      `deploy/docker-compose.yml`).
- [ ] `VITE_API_URL` empty (same-origin `/api` routing) so no CORS
      surface exists at all; if the separate `api.` subdomain is used,
      its CORS stays restricted to the frontend origin.
