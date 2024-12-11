#!/bin/sh
set -e

# Wait for web app to avoid racing during bundle install
db-wait.sh web:3000

# Run the command
exec "$@"
