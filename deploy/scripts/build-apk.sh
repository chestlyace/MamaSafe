# ═══════════════════════════════════════════════════════════════
# MamaSafe — build a release APK and print the values to paste into
# deploy/.env.production (VITE_APK_*).
#
#   bash deploy/scripts/build-apk.sh
#
# Requires: Flutter SDK + Android SDK configured for release builds
#           (mobile/.env must point at the production API).
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MOBILE_DIR="${REPO_DIR}/mobile"

if [[ ! -d "${MOBILE_DIR}" ]]; then
    echo "ERROR: mobile/ not found at ${MOBILE_DIR}" >&2
    exit 1
fi

VERSION="$(grep -m1 '^version:' "${MOBILE_DIR}/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)"
OUTPUT_DIR="${MOBILE_DIR}/build/app/outputs/flutter-apk"

echo "==> Building release APK (version ${VERSION})"
cd "${MOBILE_DIR}"
flutter build apk --release

APK="${OUTPUT_DIR}/app-release.apk"
if [[ ! -f "${APK}" ]]; then
    echo "ERROR: build output not found at ${APK}" >&2
    exit 1
fi

SHA256="$(sha256sum "${APK}" | awk '{print $1}')"
SIZE="$(du -h "${APK}" | cut -f1)"

echo
echo "==> APK ready: ${APK} (${SIZE})"
echo "    SHA-256: ${SHA256}"
echo
echo "==> Copy into deploy/.env.production:"
echo "    VITE_APK_URL=https://downloads.yourdomain.com/mamasafe-v${VERSION}.apk"
echo "    VITE_APK_VERSION=${VERSION}"
echo "    VITE_APK_CHECKSUM=${SHA256}"
echo "    VITE_APK_CHANGELOG=<short release note>"
echo
echo "==> Then upload to the server:"
echo "    scp ${APK} user@host:/var/www/downloads/mamasafe-v${VERSION}.apk"
