#!/bin/bash
#
# Currently a stub for jenkins as called from
# https://gamma-ci.dlt.psu.edu/jenkins/job/scholarsphere/configure
#	Build -> Execute Shell Command == 
#	test -x /opt/heracles/deploy_integration.sh && /opt/heracles/deploy_integration.sh 
# to run CI testing.

HHOME=/opt/heracles
WORKSPACE=${HHOME}/scholarsphere/scholarsphere-integration

echo hello ss-integration
echo "=-=-=-=-= $0 export RAILS_ENV=integration"
export RAILS_ENV=integration

echo "=-=-=-=-= $0 source ${HHOME}/.bashrc"
source ${HHOME}/.bashrc

echo "=-=-=-=-= $0 source /etc/profile.d/rvm.sh"
source /etc/profile.d/rvm.sh

echo "=-=-=-=-= $0 cd ${WORKSPACE}"
cd ${WORKSPACE}

echo "=-=-=-=-= $0 source ${WORKSPACE}/.rvmrc"
source ${WORKSPACE}/.rvmrc

echo "=-=-=-=-= $0 cp -f ${HHOME}/config/{database,fedora,solr}.yml ${WORKSPACE}/config"
cp -f ${HHOME}/config/{database,fedora,solr}.yml ${WORKSPACE}/config

echo "=-=-=-=-= $0 bundle install"
bundle install

echo "=-=-=-=-= $0 passenger-install-apache2-module -a"
passenger-install-apache2-module -a

echo "=-=-=-=-= $0 rake db:drop/create/migrate"
RAILS_ENV=integration rake db:drop
RAILS_ENV=integration rake db:create
RAILS_ENV=integration rake db:migrate

echo "=-=-=-=-= $0 rake scholarsphere:db:deleteAll"
RAILS_ENV=integration rake scholarsphere:db:deleteAll

echo "=-=-=-=-= $0 rake fixtures:create/refresh"
RAILS_ENV=integration rake scholarsphere:fixtures:generate
RAILS_ENV=integration rake scholarsphere:fixtures:refresh

echo "=-=-=-=-= $0 script/delayed_job restart"
RAILS_ENV=integration script/delayed_job restart 

retval=$?

echo "=-=-=-=-= $0 finished $retval"
exit $retval

#
# end
