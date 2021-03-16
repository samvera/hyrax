#!/bin/sh
set -e

db-wait.sh "$DB_HOST:$DB_PORT"
bundle exec rails db:create
bundle exec rails db:migrate

db-wait.sh "$FCREPO_HOST:$FCREPO_PORT"
db-wait.sh "$SOLR_HOST:$SOLR_PORT"

bundle exec rails db:seed
