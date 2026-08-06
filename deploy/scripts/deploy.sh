#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# MamaSafe — deploy / update the production stack.
#
#   bash deploy/scripts/deploy.sh /opt/mamasafe/MamaSafe
#
# 1. Pull latest code from origin/deployed
# 2. (Re)build the Docker images and start the stack
# 3. Render the Nginx reverse-proxy config and reload Nginx
#
# Prereqs: repo cloned on the server, deploy/.env.production present.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="${1:-/opt/mamasafe/MamaSafe}"
BRANCH="${DEPLOY_BRANCH:-deployed}"
COMPOSE_DIR="${REPO_DIR}/deploy"
ENV_FILE="${COMPOSE_DIR}/.env.production"

if [[ ! -d "${REPO_DIR}/.git" ]]; then
    echo "ERROR: ${REPO_DIR} is not a git checkout." >&2
    exit 1
fi
if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: ${ENV_FILE} missing. Copy from .env.production.example and fill in values." >&2
    exit 1
fi

# ── 1. Pull code ───────────────────────────────────────────────
echo "==> Pulling origin/${BRANCH} in ${REPO_DIR}"
git -C "${REPO_DIR}" fetch --prune origin
git -C "${REPO_DIR}" checkout "${BRANCH}"
git -C "${REPO_DIR}" pull --ff-only origin "${BRANCH}"

# ── 2. Build & start stack ─────────────────────────────────────
echo "==> docker compose up -d --build"
docker compose --project-directory "${COMPOSE_DIR}" up -d --build

echo "==> Waiting for backend health check..."
sleep 20
curl -fsS http://127.0.0.1:8000/health || echo "WARN: backend health not ready yet — check 'docker compose logs backend'"

# ── 3. Render & install Nginx config ───────────────────────────
# shellcheck disable=SC1091
source "${ENV_FILE}"

TEMPLATE="${COMPOSE_DIR}/nginx/mamasafe.conf"
RENDERED="/etc/nginx/sites-available/mamasafe"

if [[ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
    echo "WARN: TLS certs not found for ${DOMAIN}. Run deploy/scripts/certbot-init.sh first,"
    echo "      then re-run deploy.sh. Installing HTTP-only config meanwhile."
fi

envsubst '${DOMAIN} ${API_DOMAIN} ${DOWNLOAD_DOMAIN}' < "${TEMPLATE}" > "${RENDERED}"
ln -sfn /etc/nginx/sites-available/mamasafe /etc/nginx/sites-enabled/mamasafe
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo
echo "==> Deploy complete."
echo "    App:       https://${DOMAIN}"
echo "    API:       https://${API_DOMAIN}"
echo "    Downloads: https://${DOWNLOAD_DOMAIN}"
echo "    Inspect:   docker compose --project-directory ${COMPOSE_DIR} ps"
echo "               docker compose --project-directory ${COMPOSE_DIR} logs -f"
