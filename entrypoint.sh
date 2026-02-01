#!/bin/sh
set -e

# Default cron time if not provided
: "${CRON_SCHEDULE:=0 2 * * *}"
: "${EXECUTE_ON_RUN:=false}"

echo "[INFO] Using cron schedule: $CRON_SCHEDULE"
echo "[INFO] EXECUTE_ON_RUN = $EXECUTE_ON_RUN"

LOG_FILE="/logger/default.log"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Execute startup scripts if enabled
if [ "$EXECUTE_ON_RUN" = "true" ]; then
  echo "[INFO] EXECUTE_ON_RUN enabled. Running startup scripts..." >> "$LOG_FILE"
  echo "[INFO] EXECUTE Time $DATE " >> "$LOG_FILE"

  for script in /sh-scripts/*.sh; do
    [ -x "$script" ] || continue

    echo "[INFO] Executing $script..." >> "$LOG_FILE"
    if "$script" >> "$LOG_FILE" 2>&1; then
      echo "[SUCCESS] $script completed successfully." >> "$LOG_FILE"
      echo "-------------------$script completed successfully--------------------" >> "$LOG_FILE"
    else
      echo "[ERROR] $script failed." >> "$LOG_FILE"
    fi
  done

  echo "[INFO] Startup scripts finished." >> "$LOG_FILE"
else
  echo "[INFO] EXECUTE_ON_RUN is false. Skipping startup scripts." >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
echo "---------------------------------------------------------------------" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"


# Generate real crontab from txt template
sed "s|CRON_SCHEDULE|$CRON_SCHEDULE|g" \
  /app/crontab.txt > /etc/crontabs/root

# Fix Windows CRLF if present
sed -i 's/\r$//' /etc/crontabs/root

# Debug
echo "[INFO] Final crontab:"
cat /etc/crontabs/root

# Start cron
exec crond -f -l 8 -L /logger/cron.log