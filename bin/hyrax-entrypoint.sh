#!/bin/sh
set -e

# Make sure common volume points have the app permission
chown -fR app:app /app/samvera/hyrax-webapp/tmp
chown -fR app:app /app/samvera/hyrax-webapp/public

if [ -v HYRAX_DERIVITIVES_PATH ]; then
  mkdir -p $HYRAX_DERIVITIVES_PATH
  chown -f -R app:app $HYRAX_DERIVATIVES_PATH
fi

if [ -v HYRAX_UPLOAD_PATH ]; then
  mkdir -p $HYRAX_UPLOAD_PATH
  chown -f -R app:app $HYRAX_UPLOAD_PATH
fi

mkdir -p /app/samvera/hyrax-webapp/tmp/pids
rm -f /app/samvera/hyrax-webapp/tmp/pids/*

# Run the command
exec "$@"
