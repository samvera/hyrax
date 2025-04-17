#!/bin/sh
set -e

mkdir -p $RAILS_ROOT/tmp/pids
rm -f $RAILS_ROOT/tmp/pids/*

RUBY_MAJOR=$(ruby -e "puts /^(?'major'\d+)\.(?'minor'\d+)\.(?'patch'\d+)/.match(RUBY_VERSION)[:major]")

# Copy gems installed in the image to the dev bundle
mkdir -p /app/bundle/ruby/$RUBY_MAJOR.0
cp -Rn /usr/local/bundle/* /app/bundle/ruby/$RUBY_MAJOR.0
bundle install
yarn install

# Precompile assets if running in production (Nurax)
[ "$RAILS_ENV" = "production" ] && bundle exec rake assets:precompile

db-migrate-seed.sh

# Run the command
exec "$@"
