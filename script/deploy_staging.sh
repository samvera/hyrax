#!/bin/bash
#
# deploy script for scholarsphere-staging

HHOME="/opt/heracles"
WORKSPACE="${HHOME}/scholarsphere/scholarsphere-staging"
RESQUE_POOL_PIDFILE="${WORKSPACE}/tmp/pids/resque-pool.pid"
DEFAULT_TERMCOLORS="\e[0m"
HIGHLIGHT_TERMCOLORS="\e[33m\e[44m\e[1m"
ERROR_TERMCOLORS="\e[1m\e[31m"

function banner {
    echo -e "${HIGHLIGHT_TERMCOLORS}=-=-=-=-= $0 ↠ $1 ${DEFAULT_TERMCOLORS}"
}

banner "checking username"
[[ $(id -nu) == "tomcat" ]] || {
    echo -e "${ERROR_TERMCOLORS}*** ERROR: $0 must be run as tomcat user ${DEFAULT_TERMCOLORS}"
    exit 1
}

banner "exit if not ss1stage"
[[ $(hostname -s) == "ss1stage" ]] || {
    echo -e "${ERROR_TERMCOLORS}*** ERROR: $0 must be run on ss1stage ${DEFAULT_TERMCOLORS}"
    exit 1
}

banner "source ${HHOME}/.bashrc"
source ${HHOME}/.bashrc

banner "source /etc/profile.d/rvm.sh"
source /etc/profile.d/rvm.sh

banner "cd ${WORKSPACE}"
cd ${WORKSPACE}

banner "source ${WORKSPACE}/.rvmrc"
source ${WORKSPACE}/.rvmrc

banner "bundle install"
bundle install

# stop Resque pool early
banner "resque-pool stop"
[ -f $RESQUE_POOL_PIDFILE ] && {
    kill -2 $(cat $RESQUE_POOL_PIDFILE) && wait $(cat $RESQUE_POOL_PIDFILE)
}

banner "passenger-install-apache2-module -a"
passenger-install-apache2-module -a

banner "rake db:migrate"
RAILS_ENV=production rake db:migrate

banner "rake assets:precompile"
RAILS_ENV=production rake assets:precompile

banner "resque-pool start"
resque-pool --daemon --environment production start

banner "rake scholarsphere:generate_secret"
rake scholarsphere:generate_secret

banner "rake scholarsphere:resolrize"
RAILS_ENV=production rake scholarsphere:resolrize

banner "touch ${WORKSPACE}/tmp/restart.txt"
touch ${WORKSPACE}/tmp/restart.txt

retval=$?

banner "finished $retval"
exit $retval

#
# end
