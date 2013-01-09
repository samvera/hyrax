#!/bin/bash
#
# Currently a stub for jenkins as called from
# https://gamma-ci.dlt.psu.edu/jenkins/job/scholarsphere/configure
#       Build -> Execute Shell Command ==
#       test -x $WORKSPACE/script/jenkins_build.sh && $WORKSPACE/script/jenkins_build.sh
# to run CI testing.
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
HHOME="/opt/heracles"
WORKSPACE="${JENKINS_HOME}/jobs/scholarsphere-ci/workspace"
RESQUE_POOL_PIDFILE="${WORKSPACE}/tmp/pids/resque-pool.pid"

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

echo "=-=-=-=-= $0 cp -f ${HHOME}/config/{database,fedora,solr,hydra-ldap}.yml ${WORKSPACE}/config"
cp -f ${HHOME}/config/{database,fedora,solr,hydra-ldap}.yml ${WORKSPACE}/config

echo "=-=-=-=-= $0 resque-pool --daemon --environment test start"
resque-pool --daemon --environment test start

echo "=-=-=-=-= $0 HEADLESS=true RAILS_ENV=test bundle exec rake --trace scholarsphere:ci"
HEADLESS=true RAILS_ENV=test bundle exec rake --trace scholarsphere:ci
retval=$?

echo "=-=-=-=-= $0 kill resque-pool's pid to stop it"
[ -f $RESQUE_POOL_PIDFILE ] && {
    kill -2 $(cat $RESQUE_POOL_PIDFILE)
}

echo "=-=-=-=-= $0 finished $retval"
exit $retval

#
# end
