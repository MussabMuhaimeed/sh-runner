#!/bin/sh
# Backward-compatible wrapper. Older crontabs called this file; it must NOT start crond.
exec /run-scripts.sh
