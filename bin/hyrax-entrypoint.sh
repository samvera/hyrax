#!/bin/sh
set -e

# Make sure common volume points have the app permission
chown -fR app:app /app/samvera/hyrax-webapp/tmp
chown -fR app:app /app/samvera/hyrax-webapp/public

chown -fR app:app $HYRAX_DERIVATIVES_PATH
chown -fR app:app $HYRAX_UPLOAD_PATH

mkdir -p /app/samvera/hyrax-webapp/tmp/pids
rm -f /app/samvera/hyrax-webapp/tmp/pids/*

# Run the command
exec "$@"
