#!/bin/bash
#
# Stops and then starts resque-pool in dev env

RESQUE_POOL_PIDFILE="$(pwd)/tmp/pids/resque-pool.pid"
[ -f $RESQUE_POOL_PIDFILE ] && {
    PID=$(cat $RESQUE_POOL_PIDFILE)
    kill -2 $PID && wait $PID
}
resque-pool --daemon --environment development start
