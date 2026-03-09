FROM alpine:3.20

RUN apk add --no-cache

# Set working directory
WORKDIR /app

# Copy scripts
COPY defaultPoint.sh /defaultPoint.sh
COPY entrypoint.sh /entrypoint.sh
COPY crontab.txt /app/crontab.txt


COPY crontab.txt /tmp/crontab_root_temp

# Verify sed exists and the file is there before attempting sed
RUN which sed && ls -l /tmp/crontab_root_temp

# --- This is the line that might be causing the error ---
# We'll use 'set -ex' to make sure every command exits immediately on error
# and prints what it's doing.
RUN set -ex && sed -i 's/\r$//' /tmp/crontab_root_temp && mv /tmp/crontab_root_temp /etc/crontabs/root


# Permissions
RUN chmod +x /entrypoint.sh
RUN chmod +x /defaultPoint.sh

# Create log and backup folders
RUN mkdir -p /logger /backup

# Start container with entrypoint
CMD ["/entrypoint.sh"]
