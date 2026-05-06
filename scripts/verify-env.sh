#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DEVICE="${1:-fr55}"

status_ok() { printf "[OK] %s\n" "$1"; }
status_warn() { printf "[WARN] %s\n" "$1"; }
status_err() { printf "[ERROR] %s\n" "$1"; }

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    status_err "Environment variable '$name' is not set."
    return 1
  fi
  status_ok "Environment variable '$name' is set."
  return 0
}

validate_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    status_err "$label not found: $path"
    return 1
  fi
  status_ok "$label found: $path"
  return 0
}

validate_exec() {
  local path="$1"
  local label="$2"
  if [[ ! -x "$path" ]]; then
    status_err "$label is not executable: $path"
    return 1
  fi
  status_ok "$label executable: $path"
  return 0
}

FAIL=0

if ! require_env CIQ_SDK_HOME; then FAIL=1; fi
if ! require_env CIQ_DEV_KEY; then FAIL=1; fi

if [[ "$FAIL" -eq 0 ]]; then
  MONKEYC="$CIQ_SDK_HOME/bin/monkeyc"
  CONNECTIQ="$CIQ_SDK_HOME/bin/connectiq"

  if ! validate_exec "$MONKEYC" "monkeyc binary"; then FAIL=1; fi
  if ! validate_exec "$CONNECTIQ" "connectiq binary"; then FAIL=1; fi
  if ! validate_file "$CIQ_DEV_KEY" "Developer key"; then FAIL=1; fi

  if [[ ! -f "$ROOT_DIR/manifest.xml" ]]; then
    status_err "manifest.xml not found in project root."
    FAIL=1
  else
    status_ok "manifest.xml found."
    if grep -q "<iq:product id=\"$TARGET_DEVICE\"" "$ROOT_DIR/manifest.xml"; then
      status_ok "Target device '$TARGET_DEVICE' is declared in manifest.xml."
    else
      status_warn "Target device '$TARGET_DEVICE' not found in manifest.xml."
    fi
  fi

  if [[ ! -d "$ROOT_DIR/bin" ]]; then
    status_warn "bin/ directory missing; it will be created on build."
  else
    status_ok "bin/ directory exists."
  fi
fi

if [[ "$FAIL" -ne 0 ]]; then
  printf "\nPreflight FAILED. Fix errors above before build.\n"
  exit 1
fi

printf "\nPreflight PASSED. Environment is ready for build.\n"
