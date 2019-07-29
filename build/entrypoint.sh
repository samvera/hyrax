#!/bin/sh

echo "Building ${RAILS_ENV}"

# Remove previous servers pid
rm -f tmp/puma.pid

# Guarantee gems are installed in case docker image is outdated
./build/install_gems.sh

# Do not auto-migrate for production
if [ "${RAILS_ENV}" != 'production' ]; then
  ./build/validate_migrated.sh
fi

