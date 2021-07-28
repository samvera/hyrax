#!/usr/bin/env sh
COUNTER=0;

if [ "$SOLR_ADMIN_USER" ]; then
  solr_user_settings="--user $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD"
fi

solr_config_name="${SOLR_CONFIGSET_NAME:-solrconfig}"
solr_collection_name="${SOLR_COLLECTION_NAME:-hyrax}"

# Solr Cloud Collection API URLs
solr_collection_list_url="$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=LIST"
solr_collection_modify_url="$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=MODIFYCOLLECTION&collection=${solr_collection_name}&collection.configName=${solr_config_name}"

while [ $COUNTER -lt 30 ]; do
  if nc -z "${SOLR_HOST}" "${SOLR_PORT}"; then
    if curl --silent $solr_user_settings "$solr_collection_list_url" | grep -q "$solr_collection_name"; then
      echo "-- Collection ${solr_collection_name} exists; setting ${solr_config_name} ConfigSet ..."
      echo $solr_collection_modify_url
      curl $solr_user_settings "$solr_collection_modify_url"
      exit
    else
      echo "-- Collection ${solr_collection_name} does not exist; creating and setting ${solr_config_name} ConfigSet ..."
      solr_collection_create_url="$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=${solr_collection_name}&collection.configName=${solr_config_name}&numShards=1"
      curl $solr_user_settings "$solr_collection_create_url"
      exit
    fi
  fi
  echo "-- Looking for Solr (${SOLR_HOST}:${SOLR_PORT})..."
  COUNTER=$(( COUNTER+1 ));
  sleep 5s
done

echo "--- ERROR: failed to create/update Solr collection after 5 minutes";
exit 1
