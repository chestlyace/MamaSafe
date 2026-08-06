#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# MamaSafe — health + resource monitor.
#
#   bash deploy/scripts/monitor.sh /opt/mamasafe/MamaSafe
#
# Prints a compact health report. Exits non-zero if any container is
# unhealthy/down or a local health check fails — usable as a Nagios/
# cron-style alert:
#   */5 * * * * bash /opt/mamasafe/MamaSafe/deploy/scripts/monitor.sh >> /opt/mamasafe/logs/monitor.log 2>&1
# ═══════════════════════════════════════════════════════════════
set -u

REPO_DIR="${1:-/opt/mamasafe/MamaSafe}"
COMPOSE_DIR="${REPO_DIR}/deploy"
RC=0

sep() { printf '%s\n' '──────────────────────────────────────────'; }

echo "== $(date '+%Y-%m-%d %H:%M:%S') =="

# ── System resources ───────────────────────────────────────────
sep
echo "Load: $(cat /proc/loadavg)"
free -h | awk '/Mem:/{printf "Mem:  used %s / %s\n", $3, $2}'
df -h / | awk 'NR==2{printf "Disk: used %s / %s (%s)\n", $3, $2, $5}'

# ── Containers ─────────────────────────────────────────────────
sep
echo "Docker:"
if ! command -v docker >/dev/null 2>&1; then
    echo "  ERROR: docker not installed" >&2
    exit 1
fi
docker ps --format 'table {{.Names}}\t{{.Status}}'
if docker ps --format '{{.Names}}\t{{.Status}}' | grep -vE '\(healthy\)' | grep -E 'mamasafe|mama' >/dev/null; then
    RC=1
fi

# ── HTTP health checks (via 127.0.0.1, as Nginx would see them) ─
sep
check() {
    local name="$1" url="$2"
    if curl -fsS -o /dev/null --max-time 5 "$url"; then
        echo "OK   ${name} (${url})"
    else
        echo "FAIL ${name} (${url})"
        RC=1
    fi
}
check "frontend" "http://127.0.0.1:8080/"
check "backend"  "http://127.0.0.1:8000/health"
check "whatsapp" "http://127.0.0.1:3001/health"

# ── Recent errors in container logs ─────────────────────────────
sep
echo "Recent errors (last 200 lines per service):"
for svc in backend whatsapp frontend; do
    docker compose --project-directory "${COMPOSE_DIR}" logs --tail 200 "$svc" 2>/dev/null \
        | grep -iE 'error|traceback|exception|fatal' | tail -5 \
        | sed "s/^/${svc}: /" || true
done

exit "${RC}"
