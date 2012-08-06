#!/bin/bash
#
# Stops and then starts resque-pool

RESQUE_POOL_PIDFILE="$(pwd)/tmp/pids/resque-pool.pid"
[ -f $RESQUE_POOL_PIDFILE ] && {
    kill -2 $(cat $RESQUE_POOL_PIDFILE) && wait $(cat $RESQUE_POOL_PIDFILE)
}
resque-pool --daemon --environment production start
