#!/bin/sh
set -e

mkdir -p /app/samvera/hyrax-webapp/tmp/pids
rm -f /app/samvera/hyrax-webapp/tmp/pids/*

# Copy gems installed in the image to the dev bundle
mkdir -p /app/bundle/ruby/$RUBY_MAJOR.0
cp -Rn /usr/local/bundle/* /app/bundle/ruby/$RUBY_MAJOR.0
bundle install

# Run the command
exec "$@"
