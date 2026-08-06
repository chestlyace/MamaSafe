#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# MamaSafe — PostgreSQL + config + WhatsApp session backup.
#
#   bash deploy/scripts/backup-db.sh /opt/mamasafe/MamaSafe
#
# - pg_dump of the production database (via the running container)
# - tar of deploy/.env.production + compose + host nginx config
# - tar of the WhatsApp (Baileys) session volume
# - prunes backups older than BACKUP_KEEP days
# - optional S3 sync (aws cli) if S3_BUCKET is set
#
# Cron example (run nightly 02:30):
#   30 2 * * * bash /opt/mamasafe/MamaSafe/deploy/scripts/backup-db.sh >> /opt/mamasafe/logs/backup.log 2>&1
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="${1:-/opt/mamasafe/MamaSafe}"
COMPOSE_DIR="${REPO_DIR}/deploy"
ENV_FILE="${COMPOSE_DIR}/.env.production"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: ${ENV_FILE} missing." >&2
    exit 1
fi

# shellcheck disable=SC1091
source "${ENV_FILE}"

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="/opt/mamasafe/logs/backup.log"
mkdir -p "${BACKUP_DIR}" "${CONFIG_BACKUP_DIR}" /opt/mamasafe/logs

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG}"; }

# ── 1. Database dump ───────────────────────────────────────────
log "==> Dumping PostgreSQL database '${POSTGRES_DB}'"
DB_FILE="${BACKUP_DIR}/db-${STAMP}.sql.gz"
docker compose --project-directory "${COMPOSE_DIR}" exec -T db \
    pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip -9 > "${DB_FILE}"
log "    wrote ${DB_FILE} ($(du -h "${DB_FILE}" | cut -f1))"

# ── 2. Config backup ───────────────────────────────────────────
log "==> Backing up config"
CFG_FILE="${CONFIG_BACKUP_DIR}/config-${STAMP}.tar.gz"
STAGE="$(mktemp -d)"
cp "${ENV_FILE}"                    "${STAGE}/env.production"
cp "${COMPOSE_DIR}/docker-compose.yml"   "${STAGE}/docker-compose.yml" 2>/dev/null || true
cp "${COMPOSE_DIR}/nginx/mamasafe.conf" "${STAGE}/nginx-mamasafe.conf" 2>/dev/null || true
cp "${REPO_DIR}/frontend/nginx.conf"    "${STAGE}/frontend-nginx.conf" 2>/dev/null || true
cp /etc/nginx/sites-available/mamasafe  "${STAGE}/nginx-installed.conf" 2>/dev/null || true
tar czf "${CFG_FILE}" -C "${STAGE}" .
rm -rf "${STAGE}"
log "    wrote ${CFG_FILE}"

# ── 3. WhatsApp session volume ─────────────────────────────────
log "==> Backing up WhatsApp session volume"
WA_FILE="${BACKUP_DIR}/wa-session-${STAMP}.tar.gz"
VOLUME="$(docker compose --project-directory "${COMPOSE_DIR}" ps -q db >/dev/null 2>&1 && echo mamasafe_wa_auth || true)"
if docker volume inspect mamasafe_wa_auth >/dev/null 2>&1; then
    docker run --rm \
        -v mamasafe_wa_auth:/data:ro \
        -v "${BACKUP_DIR}":/backup \
        alpine:3.20 tar czf "/backup/$(basename "${WA_FILE}")" -C /data . 
    log "    wrote ${WA_FILE}"
else
    log "    WARN: volume mamasafe_wa_auth not found, skipping WhatsApp session backup"
fi

# ── 4. Prune old backups ───────────────────────────────────────
KEEP="${BACKUP_KEEP:-14}"
log "==> Pruning backups older than ${KEEP} days"
find "${BACKUP_DIR}"      -type f -name '*.gz' -mtime "+${KEEP}" -delete
find "${CONFIG_BACKUP_DIR}" -type f -name '*.tar.gz' -mtime "+${KEEP}" -delete

# ── 5. Optional S3 offsite copy ────────────────────────────────
if [[ -n "${S3_BUCKET:-}" ]]; then
    if command -v aws >/dev/null 2>&1; then
        log "==> Syncing to ${S3_BUCKET}"
        aws s3 sync "${BACKUP_DIR}" "${S3_BUCKET}/db" --quiet
        aws s3 sync "${CONFIG_BACKUP_DIR}" "${S3_BUCKET}/config" --quiet
        log "    S3 sync complete"
    else
        log "    WARN: S3_BUCKET set but 'aws' CLI not installed — skipping"
    fi
fi

log "==> Backup finished"
