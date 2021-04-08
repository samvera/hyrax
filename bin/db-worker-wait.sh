#!/bin/sh
set -e

db-wait.sh "$DB_HOST:$DB_PORT"
if [ "$FCREPO_HOST" ]; then
  db-wait.sh "$FCREPO_HOST:$FCREPO_PORT"
fi
db-wait.sh "$SOLR_HOST:$SOLR_PORT"
