#!/bin/bash
set -e

# quit if no SOLR_URL
if [[ -z "${SOLR_URL}" ]]; then
  echo "SOLR_URL environment variable not provided"
  exit 1
fi

read -r solr_host solr_port solr_core <<< "$(echo "$SOLR_URL" | sed -r 's|http://(.+):(.+)/solr/(.+)|\1 \2 \3|')"
echo "Creating Solr core: $SOLR_CORE..."

configDir="/hyrax_config"
#mkdir /hyrax_config
#cp -r "/data/.internal_test_app/solr/config" "/hyrax_config"

if [[ ! -d $coredir ]]; then
  mkdir  -p "$configDir"
  cp -r "/data/.internal_test_app/solr/config/" "$configDir"
  ls -lart "$configDir"
else
  echo "Solr Config Directory $configDir already exists"
  ls -lart "$configDir"
fi
      
#cat /opt/solr/server/solr/mycores/hyrax-dev/conf/solrconfig.xml
#while ! nc -z "$solr_host" "$solr_port"
#do
#  echo "waiting for solr"
#  sleep 1
#done

#curl "http://$solr_host:$solr_port/solr/admin/configs?action=LIST"

#curl "http://$solr_host:$solr_port/solr/admin/cores?action=STATUS&core=$SOLR_CORE"

#(cd /data/.internal_test_app/solr/conf && zip -r - *) > myconfigset.zip

#curl -X POST --header "Content-Type:application/octet-stream" --data-binary @myconfigset.zip "http://$solr_host:$solr_port/solr/admin/configs?action=UPLOAD&name=myConfigSet"

#curl -X POST --header "Content-Type:application/json" "http://$solr_host:$solr_port/api/collections/" -d "{create: {name: $SOLR_CORE , config: myConfigSet, numShards: 1}}"

#curl "http://$solr_host:$solr_port/solr/admin/cores?action=STATUS&core=$SOLR_CORE"

echo "Successfully created $SOLR_CORE"

# Then exec the container's main process
# This is what's set as CMD in a) Dockerfile b) compose c) CI
exec "$@"