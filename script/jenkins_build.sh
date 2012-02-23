#!/bin/bash
#
# Currently a stub for jenkins as called from
# https://gamma-ci.dlt.psu.edu/jenkins/job/gamma/configure
#	Build -> Execute Shell Command == 
#	test -x $WORKSPACE/script/jenkins_build.sh && $WORKSPACE/script/jenkins_build.sh
# to run CI testing.

echo "=-=-=-=-= $0 begin"
cd ${JENKINS_HOME}/jobs/gamma/workspace

echo "=-=-=-=-= $0 source rvm.sh/.rvmrc"
source /etc/profile.d/rvm.sh
source .rvmrc

echo "=-=-=-=-= $0 bundle install"
bundle install

echo "=-=-=-=-= $0 rake db:migrate"
rake db:migrate

echo "=-=-=-=-= $0 rake --trace gamma:ci"
rake --trace gamma:ci

echo "=-=-=-=-= $0 finished"


# historical note, these were the original commands:
# bash -l -c "source /etc/profile.d/rvm.sh"
# #bash -l -c "echo EEEEE; env; echo EEEEE; cat $0; echo EEEEE"
# bash -l -c "source .rvmrc;bundle install;rake db:migrate; rake --trace gamma:ci"
