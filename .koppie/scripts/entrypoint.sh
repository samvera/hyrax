#!/bin/sh
set -e

mkdir -p /app/samvera/hyrax-webapp/tmp/pids
rm -f /app/samvera/hyrax-webapp/tmp/pids/*

bundle install --quiet

# Run the command
exec "$@"
