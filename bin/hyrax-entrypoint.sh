#!/bin/sh
set -e

# Make sure common volume points have the app permission
chown -fR app:app /app/samvera/hyrax-webapp/tmp
chown -fR app:app /app/samvera/hyrax-webapp/public

mkdir -p /app/samvera/hyrax-webapp/tmp/pids
rm -f /app/samvera/hyrax-webapp/tmp/pids/*

if [ -z $RAILS_ENV ]
then
  export RAILS_ENV=development
fi

# Run the command
exec "$@"
