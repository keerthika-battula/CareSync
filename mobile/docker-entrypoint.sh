#!/bin/sh
set -e

# Default to port 10000 on Render, or 80 if PORT is not set
PORT="${PORT:-10000}"

echo "Starting CareSync React Web server on port ${PORT}..."

# Replace PORT_PLACEHOLDER with the active runtime PORT
sed "s/PORT_PLACEHOLDER/${PORT}/g" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
