#!/usr/bin/env sh

COUNTER=0;
# /app/samvera/hyrax-webapp/solr/conf
CONFDIR="${1}"

if [ "$SOLR_ADMIN_USER" ]; then
  solr_user_settings="--user $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD"
fi

# Solr Cloud ConfigSet API URLs
solr_config_list_url="http://$SOLR_HOST:$SOLR_PORT/api/cluster/configs?omitHeader=true"
solr_config_upload_url="http://$SOLR_HOST:$SOLR_PORT/solr/admin/configs?action=UPLOAD&name=solrconfig"

while [ $COUNTER -lt 30 ]; do
  echo "-- Looking for Solr (${SOLR_HOST}:${SOLR_PORT})..."
  if nc -z "${SOLR_HOST}" "${SOLR_PORT}"; then
    if curl --silent $solr_user_settings "$solr_config_list_url" | grep -q 'solrconfig'; then
      echo "-- ConfigSet already exists; skipping creation ...";
    else
      echo "-- ConfigSet for ${CONFDIR} does not exist; creating ..."
      (cd "$CONFDIR" && zip -r - *) | curl -X POST $solr_user_settings --header "Content-Type:application/octet-stream" --data-binary @- "$solr_config_upload_url"
    fi
    exit
  fi
  COUNTER=$(( COUNTER+1 ));
  sleep 5s
done

echo "--- ERROR: failed to create Solr ConfigSet after 5 minutes";
exit 1
