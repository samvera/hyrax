#!/bin/bash
#
# Currently a stub for jenkins as called from
# https://gamma-ci.dlt.psu.edu/jenkins/job/scholarsphere/configure
#	Build -> Execute Shell Command == 
#	test -x $WORKSPACE/script/jenkins_build.sh && $WORKSPACE/script/jenkins_build.sh
# to run CI testing.

HHOME=/opt/heracles
WORKSPACE=${JENKINS_HOME}/jobs/scholarsphere/workspace
#WORKSPACE=/opt/heracles/scholarsphere-jgm


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

echo "=-=-=-=-= $0 cp -f ${HHOME}/config/{database,fedora,solr}.yml ${WORKSPACE}/config"
cp -f ${HHOME}/config/{database,fedora,solr}.yml ${WORKSPACE}/config

echo "=-=-=-=-= $0 HEADLESS=true rake --trace scholarsphere:ci"
HEADLESS=true rake --trace scholarsphere:ci
retval=$?
echo "=-=-=-=-= $0 finished $retval"
exit $retval

#
# end
