#!/bin/bash
#
# deploy script for scholarsphere-test

HHOME="/opt/heracles"
WORKSPACE="${HHOME}/scholarsphere/scholarsphere-test"
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

# stop DJ workers first since they tend to be resource hogs
banner "script/delayed_job stop"
RAILS_ENV=production script/delayed_job stop

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

banner "passenger-install-apache2-module -a"
passenger-install-apache2-module -a

banner "rake db:migrate"
RAILS_ENV=production rake db:migrate

banner "rake assets:precompile"
RAILS_ENV=production rake assets:precompile

banner "script/delayed_job start"
RAILS_ENV=production script/delayed_job -n 2 start

banner "rake scholarsphere:generate_secret"
rake scholarsphere:generate_secret

banner "touch ${WORKSPACE}/tmp/restart.txt"
touch ${WORKSPACE}/tmp/restart.txt

retval=$?

banner "finished $retval"
exit $retval

#
# end
