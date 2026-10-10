#!/bin/sh
set -eu

# Run job scripts in /sh-scripts once (cron + optional EXECUTE_ON_START).
# Must NOT start crond (older defaultPoint.sh did — nested daemons every night).

LOG_FILE="/logger/cronjobExecuteInfo.log"
LOCK_DIR="/tmp/sh-runner-scripts.lock"
SCRIPTS_DIR="/sh-scripts"

mkdir -p /logger "$SCRIPTS_DIR"
touch "$LOG_FILE"

log() {
  echo "$1" >> "$LOG_FILE"
}

should_skip() {
  base="$(basename "$1")"
  case "$base" in
    install-*|_*|*.setup.sh) return 0 ;;
  esac
  return 1
}

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "[WARN] $(date): previous script run still in progress; skipping"
  exit 0
fi
trap release_lock EXIT

log "[INFO] $(date): running scripts in ${SCRIPTS_DIR}"

found=0
# Numeric prefixes (01-, 02-, ...) give a stable run order
for script in "$SCRIPTS_DIR"/*.sh; do
  [ -f "$script" ] || continue
  [ -x "$script" ] || continue
  found=1

  if should_skip "$script"; then
    log "[INFO] Skipping setup script: $script"
    continue
  fi

  log "[INFO] Executing $script..."
  set +e
  "$script" >> "$LOG_FILE" 2>&1
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    log "[SUCCESS] $script completed."
  else
    log "[ERROR] $script failed (exit $status)."
  fi
done

if [ "$found" -eq 0 ]; then
  log "[INFO] No executable *.sh scripts found in ${SCRIPTS_DIR}"
fi

log "[INFO] $(date): script run finished"
log "---------------------------------------------------------------------"
