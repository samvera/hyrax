#!/bin/bash
#
# Deletes everything in the test instance of the app's RDBMS and reinits it

RAILS_ENV=test rake db:drop
RAILS_ENV=test rake db:create
RAILS_ENV=test rake db:migrate
