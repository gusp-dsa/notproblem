#!/usr/bin/env bash
set -euo pipefail

readonly FLUTTER_VERSION="3.50.0"
readonly FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
readonly FLUTTER_SHA256="6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5"
readonly FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"
readonly SDK_DIR="${PWD}/.flutter-sdk"
readonly DEFINES_FILE="${PWD}/config/vercel.generated.json"

if [[ -z "${APP_URL:-}" || -z "${SUPABASE_URL:-}" || -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo "APP_URL, SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY precisam estar configuradas na Vercel." >&2
  exit 1
fi

if [[ ! -x "${SDK_DIR}/bin/flutter" ]]; then
  archive_path="$(mktemp)"
  curl --fail --location --silent --show-error "${FLUTTER_URL}" --output "${archive_path}"
  echo "${FLUTTER_SHA256}  ${archive_path}" | sha256sum --check --status
  tar --extract --xz --file "${archive_path}" --directory "${PWD}"
  mv "${PWD}/flutter" "${SDK_DIR}"
  rm -f "${archive_path}"
fi

export PATH="${SDK_DIR}/bin:${PATH}"
git config --global --add safe.directory "${SDK_DIR}"

flutter config --no-analytics --enable-web
flutter create . --platforms=web --project-name=agile_knowledge
flutter pub get
flutter test

node -e '
  const fs = require("node:fs");
  fs.writeFileSync(
    process.argv[1],
    JSON.stringify({
      APP_URL: process.env.APP_URL,
      SUPABASE_URL: process.env.SUPABASE_URL,
      SUPABASE_PUBLISHABLE_KEY: process.env.SUPABASE_PUBLISHABLE_KEY,
    }),
  );
' "${DEFINES_FILE}"

trap 'rm -f "${DEFINES_FILE}"' EXIT
flutter build web --release --dart-define-from-file="${DEFINES_FILE}"
