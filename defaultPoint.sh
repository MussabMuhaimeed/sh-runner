#!/bin/sh
set -e

LOG_FILE="/logger/cronjobExecuteInfo.log"

echo "[INFO] Using cron schedule: $CRON_SCHEDULE"

echo "[INFO] Starting cron and initial sh..."

# Debug cron jobs
echo "[INFO] Registered cron jobs:" >> "$LOG_FILE"
crontab -l || echo "[INFO] No crontab found" >> "$LOG_FILE"

echo "[INFO] Verifying /etc/crontabs/root (CRLF check):"
cat -v /etc/crontabs/root || true
echo "--------------------------------------------------------"

# Ensure log directory exists
mkdir -p /logger
touch /logger/cron.log

# Run startup sh scripts
echo "[INFO] Running executable shell scripts in /sh-scripts..."

for script in /sh-scripts/*.sh; do
  [ -x "$script" ] || continue

  echo "[INFO] Executing $script..." >> "$LOG_FILE"
  "$script"
  echo "[SUCCESS] $script completed." >> "$LOG_FILE"
done

echo "---------------------------------------------------------------------" >> "$LOG_FILE"
# Start cron in foreground (Docker best practice)
echo "[INFO] Starting crond..."
exec crond -f -l 8 -L /logger/cron.log
