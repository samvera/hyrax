#!/bin/sh
set -e

service-wait.sh "$DB_HOST:$DB_PORT"
bundle exec rails db:create
bundle exec rails db:migrate

if [ "$FCREPO_HOST" ]; then
  service-wait.sh "$FCREPO_HOST:$FCREPO_PORT"
fi
service-wait.sh "$SOLR_HOST:$SOLR_PORT"

bundle exec rails db:seed
