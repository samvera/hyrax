#!/bin/sh
set -e

mkdir -p $RAILS_ROOT/tmp/pids
rm -f $RAILS_ROOT/tmp/pids/*

if [ -n "${BUNDLE_PATH}" ]; then
  # Copy gems installed in the image to /app/bundle so they are retained over stack down/ups.
  FULL_BUNDLE_PATH=$(ruby -e "require 'bundler'; puts Bundler.bundle_path")
  echo "Copying gems to $FULL_BUNDLE_PATH"
  mkdir -p $FULL_BUNDLE_PATH
  cp -Ru /usr/local/bundle/* $FULL_BUNDLE_PATH
elif [ "$(id -u)" -eq 0 ]; then
  # Gems coming from git need to be owned by the user, which is root for dev environment
  echo "Ensuring root owns /usr/local/bundle"
  chown -R 0 /usr/local/bundle
fi

bundle install
yarn install

# Precompile assets if running in production (Nurax)
[ "$RAILS_ENV" = "production" ] && bundle exec rake assets:precompile

db-migrate-seed.sh

# Update and run ClamAV
[ "$HYRAX_CLAMAV" = "true" ] && freshclam && clamd

# Run the command
exec "$@"
