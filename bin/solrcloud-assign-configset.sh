#!/usr/bin/env sh
COUNTER=0;

if [ "$SOLR_ADMIN_USER" ]; then
  solr_user_settings="--user $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD"
fi

# Solr Cloud Collection API URLs
solr_collection_list_url="$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=LIST"
solr_collection_modify_url="$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=MODIFYCOLLECTION&collection=hyrax&collection.configName=solrconfig"

while [ $COUNTER -lt 30 ]; do
  if nc -z "${SOLR_HOST}" "${SOLR_PORT}"; then
    if curl --silent $solr_user_settings "$solr_collection_list_url" | grep -q "hyrax"; then
      echo "-- Collection hyrax exists; setting Hyrax ConfigSet ..."
      echo $solr_collection_modify_url
      curl $solr_user_settings "$solr_collection_modify_url"
      exit
    fi
  fi
  echo "-- Looking for Solr (${SOLR_HOST}:${SOLR_PORT})..."
  COUNTER=$(( COUNTER+1 ));
  sleep 5s
done

echo "--- ERROR: failed to create/update Solr collection after 5 minutes";
exit 1
