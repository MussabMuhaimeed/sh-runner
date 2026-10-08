#!/bin/sh
set -eu

: "${CRON_SCHEDULE:=0 2 * * *}"
: "${EXECUTE_ON_START:=false}"

LOG_FILE="/logger/default.log"
mkdir -p /logger /sh-scripts
touch "$LOG_FILE"

log() {
  echo "$1" | tee -a "$LOG_FILE"
}

log "[INFO] Using cron schedule: $CRON_SCHEDULE"
log "[INFO] EXECUTE_ON_START = $EXECUTE_ON_START"

# Normalize Windows CRLF and ensure scripts are executable
for f in /run-scripts.sh /defaultPoint.sh /sh-scripts/*.sh; do
  [ -f "$f" ] || continue
  sed -i 's/\r$//' "$f" 2>/dev/null || true
  chmod +x "$f" 2>/dev/null || true
done

# Setup helpers once at start (not cron jobs)
run_setup_scripts() {
  for script in /sh-scripts/install-*.sh /sh-scripts/*.setup.sh; do
    [ -f "$script" ] || continue
    [ -x "$script" ] || continue
    log "[INFO] Running setup script: $script"
    if "$script" >> "$LOG_FILE" 2>&1; then
      log "[SUCCESS] setup script completed: $script"
    else
      log "[WARN] setup script failed: $script (exit $?)"
    fi
  done
}

run_setup_scripts

# Optional one-shot job run on container start (never starts crond)
if [ "$EXECUTE_ON_START" = "true" ]; then
  log "[INFO] EXECUTE_ON_START enabled. Running job scripts once..."
  /run-scripts.sh || log "[WARN] startup job run reported errors"
else
  log "[INFO] EXECUTE_ON_START is false. Skipping startup job scripts."
fi

log "---------------------------------------------------------------------"

# Build crontab from template — schedule runs scripts only, never another crond
sed "s|CRON_SCHEDULE|$CRON_SCHEDULE|g" /app/crontab.txt > /etc/crontabs/root
sed -i 's/\r$//' /etc/crontabs/root

log "[INFO] Final crontab:"
tee -a "$LOG_FILE" < /etc/crontabs/root

# Single long-lived cron daemon for this container
exec crond -f -l 8 -L /logger/cron.log
