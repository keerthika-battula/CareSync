#!/bin/sh
set -e

# Default to port 80 if PORT is not set by hosting provider
PORT="${PORT:-80}"

echo "Starting CareSync Flutter Web server on port ${PORT}..."

# Replace PORT_PLACEHOLDER with the active runtime PORT
sed "s/PORT_PLACEHOLDER/${PORT}/g" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
