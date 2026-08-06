#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# MamaSafe — obtain Let's Encrypt certificates (webroot mode).
#
#   bash deploy/scripts/certbot-init.sh /opt/mamasafe/MamaSafe
#
# Bootstraps a temporary HTTP-only Nginx server that answers ACME
# challenges, requests certs for ${DOMAIN}, www.${DOMAIN},
# ${API_DOMAIN}, ${DOWNLOAD_DOMAIN}, then restores Nginx. Run
# deploy.sh afterwards to install the full HTTPS config.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="${1:-/opt/mamasafe/MamaSafe}"
ENV_FILE="${REPO_DIR}/deploy/.env.production"

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: run as root (sudo)." >&2
    exit 1
fi
if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: ${ENV_FILE} missing." >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib-env.sh"
load_env "${ENV_FILE}"

BOOTSTRAP="/etc/nginx/sites-available/mamasafe-bootstrap"
ACME_ROOT="/var/www/certbot"

# ── Minimal HTTP-only bootstrap config ─────────────────────────
cat > "${BOOTSTRAP}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} ${API_DOMAIN} ${DOWNLOAD_DOMAIN};

    location /.well-known/acme-challenge/ {
        root ${ACME_ROOT};
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

ln -sfn "${BOOTSTRAP}" /etc/nginx/sites-enabled/mamasafe-bootstrap
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ── Request certificates ───────────────────────────────────────
echo "==> Requesting certificates for:"
echo "    ${DOMAIN} www.${DOMAIN} ${API_DOMAIN} ${DOWNLOAD_DOMAIN}"
mkdir -p "${ACME_ROOT}"
certbot certonly --webroot -w "${ACME_ROOT}" --keep-until-expiring \
    -d "${DOMAIN}" -d "www.${DOMAIN}" -d "${API_DOMAIN}" -d "${DOWNLOAD_DOMAIN}"

# ── Restore default site (deploy.sh installs the full config) ──
rm -f /etc/nginx/sites-enabled/mamasafe-bootstrap
systemctl reload nginx

echo
echo "==> Certs issued. Now run: bash ${REPO_DIR}/deploy/scripts/deploy.sh ${REPO_DIR}"
echo "    (renewal is automatic via certbot's systemd timer/cron)"
