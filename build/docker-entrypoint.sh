#!/bin/bash
set -e

# quit if no SOLR_URL
if [[ -z "${SOLR_URL}" ]]; then
  echo "SOLR_URL environment variable not provided"
  exit 1
fi

read -r solr_host solr_port solr_core <<< "$(echo "$SOLR_URL" | sed -r 's|http://(.+):(.+)/solr/(.+)|\1 \2 \3|')"
echo "Creating Solr core: $SOLR_CORE..."

#while ! nc -z "$solr_host" "$solr_port"
#do
#  echo "waiting for solr"
#  sleep 1
#done

echo "Successfully created $SOLR_CORE"

# Then exec the container's main process
# This is what's set as CMD in a) Dockerfile b) compose c) CI
exec "$@"