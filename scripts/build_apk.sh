#!/usr/bin/env bash
set -euo pipefail

# Build APK Flutter lalu salin otomatis ke landing/apk/.
# Pemakaian:
#   bash scripts/build_apk.sh mobile
#   bash scripts/build_apk.sh merchant
#   bash scripts/build_apk.sh all

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK_DIR="$ROOT/landing/apk"

build_one() {
  local label="$1"
  local app_dir="$2"
  local output_name="$3"

  echo "==> Building $label..."
  (
    cd "$app_dir"
    flutter pub get
    flutter build apk --release
  )

  local built_apk="$app_dir/build/app/outputs/flutter-apk/app-release.apk"
  if [[ ! -f "$built_apk" ]]; then
    echo "APK tidak ditemukan: $built_apk" >&2
    exit 1
  fi

  mkdir -p "$APK_DIR"
  cp "$built_apk" "$APK_DIR/$output_name"
  echo "✓ $label -> landing/apk/$output_name"
  ls -lh "$APK_DIR/$output_name"
}

case "${1:-all}" in
  mobile|student|semestapay)
    build_one "SemestaPAY" "$ROOT/apps/mobile/student" "semestapay.apk"
    cp "$APK_DIR/semestapay.apk" "$APK_DIR/smpay-mobile.apk"
    ;;
  merchant)
    build_one "SemestaPAY Merchant" "$ROOT/apps/mobile/merchant" "semestapay-merchant.apk"
    cp "$APK_DIR/semestapay-merchant.apk" "$APK_DIR/smpay-merchant.apk"
    ;;
  all)
    build_one "SemestaPAY" "$ROOT/apps/mobile/student" "semestapay.apk"
    cp "$APK_DIR/semestapay.apk" "$APK_DIR/smpay-mobile.apk"
    build_one "SemestaPAY Merchant" "$ROOT/apps/mobile/merchant" "semestapay-merchant.apk"
    cp "$APK_DIR/semestapay-merchant.apk" "$APK_DIR/smpay-merchant.apk"
    ;;
  *)
    echo "Pemakaian: bash scripts/build_apk.sh [semestapay|merchant|all]" >&2
    exit 1
    ;;
esac
