#!/bin/sh
set -e

# Example setup helper (runs once at container start, not on every cron tick).
# Install only what YOUR jobs need — keep the base image generic.

# apk add --no-cache curl
# apk add --no-cache aws-cli
# apk add --no-cache postgresql-client mariadb-client

echo "[INFO] install-tools.sh: no packages selected (example only)"
