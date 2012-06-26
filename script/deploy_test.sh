#!/bin/bash
#
# deploy script for scholarsphere-test

HHOME=/opt/heracles
WORKSPACE=${HHOME}/scholarsphere/scholarsphere-test

echo "=-=-=-=-= $0 source ${HHOME}/.bashrc"
source ${HHOME}/.bashrc

echo "=-=-=-=-= $0 source /etc/profile.d/rvm.sh"
source /etc/profile.d/rvm.sh

echo "=-=-=-=-= $0 cd ${WORKSPACE}"
cd ${WORKSPACE}

echo "=-=-=-=-= $0 source ${WORKSPACE}/.rvmrc"
source ${WORKSPACE}/.rvmrc

echo "=-=-=-=-= $0 bundle install"
bundle install

echo "=-=-=-=-= $0 passenger-install-apache2-module -a"
passenger-install-apache2-module -a

echo "=-=-=-=-= $0 rake db:migrate"
RAILS_ENV=production rake db:migrate

echo "=-=-=-=-= $0 rake assets:precompile"
RAILS_ENV=production rake assets:precompile

echo "=-=-=-=-= $0 script/delayed_job stop/start"
RAILS_ENV=production script/delayed_job stop 
RAILS_ENV=production script/delayed_job -n 10 start

retval=$?

echo "=-=-=-=-= $0 finished $retval"
exit $retval

#
# end
