#!/bin/bash
set -e

# quit if no SOLR_URL
if [[ -z "${SOLR_URL}" ]]; then
  echo "SOLR_URL environment variable not provided"
  exit 1
fi

read -r solr_host solr_port solr_core <<< "$(echo "$SOLR_URL" | sed -r 's|http://(.+):(.+)/solr/(.+)|\1 \2 \3|')"
echo "Creating Solr core: $solr_core..."

while ! nc -z "$solr_host" "$solr_port"
do
  echo "waiting for solr"
  sleep 1
done

#cd /data/.internal_test_app/solr/config
#zip -1 -r solr_config.zip ./*
#zip -1 -r solr_config.zip . -i /data/.internal_test_app/solr/config/*
#zip -1 -r solr_config.zip /data/.internal_test_app/solr/config/*
zip -r solr_config.zip /data/.internal_test_app/solr/config/*

curl -H "Content-type:application/octet-stream" --data-binary @solr_config.zip "http://$solr_host:$solr_port >>/solr/admin/configs?action=UPLOAD&name=solrconfig"

curl -H 'Content-type: application/json' "http://$solr_host:$solr_port" >>/api/collections/ -d '{create: {name: << "$solr_core" >>, config: solrconfig, numShards: 1}}'

echo "Successfully created $solr_core"

# Then exec the container's main process
# This is what's set as CMD in a) Dockerfile b) compose c) CI
exec "$@"