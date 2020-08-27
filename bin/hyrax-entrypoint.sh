#!/bin/sh
set -e

# Make sure common volume points have the app permission
chown -fR app:app /app/samvera/hyrax-webapp/tmp
chown -fR app:app /app/samvera/hyrax-webapp/public

mkdir -p /app/samvera/hyrax-webapp/tmp/pids
rm -f /app/samvera/hyrax-webapp/tmp/pids/*

# Run the command
exec "$@"
