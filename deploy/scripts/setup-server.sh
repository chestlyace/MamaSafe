#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# MamaSafe — one-time server provisioning (run as root or with sudo)
#
#   sudo bash deploy/scripts/setup-server.sh
#
# Installs: Docker Engine + Compose plugin, Nginx, Certbot, curl/jq.
# Creates: /opt/mamasafe (deploy home), /var/www/downloads (APK host),
#          /var/www/certbot (ACME webroot).
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: run as root (sudo)." >&2
    exit 1
fi

# ── OS detection ───────────────────────────────────────────────
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    OS_ID="${ID}"
else
    OS_ID="unknown"
fi

echo "==> Detected OS: ${OS_ID}"

# ── Package install ────────────────────────────────────────────
case "${OS_ID}" in
  ubuntu|debian)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends \
        ca-certificates curl jq git nginx python3 \
        python3-certbot python3-certbot-nginx \
        openssl
    # Docker Engine (official repo)
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg \
        -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/${OS_ID} $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    ;;
  amzn)
    dnf update -y
    dnf install -y curl jq git nginx certbot python3-certbot-nginx openssl
    dnf install -y docker
    systemctl enable --now docker
    # Compose plugin on Amazon Linux 2023
    if ! command -v docker-compose >/dev/null 2>&1 && [[ ! -x /usr/libexec/docker/cli-plugins/docker-compose ]]; then
        mkdir -p /usr/local/lib/docker/cli-plugins
        curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        mkdir -p /usr/local/bin
        ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    fi
    ;;
  *)
    echo "ERROR: unsupported OS '${OS_ID}'. Edit this script for your distro." >&2
    exit 1
    ;;
esac

# ── Enable Docker ──────────────────────────────────────────────
systemctl enable --now docker

# ── Create directories ─────────────────────────────────────────
mkdir -p /opt/mamasafe
mkdir -p /var/www/downloads
mkdir -p /var/www/certbot
mkdir -p /opt/mamasafe/logs
mkdir -p /opt/mamasafe/backups
mkdir -p /opt/mamasafe/config-backups

# ── Firewall (UFW on Ubuntu/Debian) ────────────────────────────
if command -v ufw >/dev/null 2>&1; then
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp  comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw --force enable
    echo "==> UFW enabled (22/80/443). Restrict port 22 to your operator IP if desired:"
    echo "    ufw delete allow 22/tcp && ufw allow from <YOUR_IP> to any port 22 proto tcp"
fi

echo
echo "==> Server setup complete."
echo "    Next: 1) clone the repo to /opt/mamasafe  2) cp deploy/.env.production.example deploy/.env.production"
echo "          3) deploy/scripts/certbot-init.sh    4) deploy/scripts/deploy.sh"
