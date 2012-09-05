#!/bin/bash
#
# Stops and then starts resque-pool in dev env

function anywait {
    for pid in "$@"; do
        while kill -0 "$pid"; do
            sleep 0.5
        done
    done
}

RESQUE_POOL_PIDFILE="$(pwd)/tmp/pids/resque-pool.pid"
[ -f $RESQUE_POOL_PIDFILE ] && {
    PID=$(cat $RESQUE_POOL_PIDFILE)
    kill -2 $PID && anywait $PID
}

resque-pool --daemon --environment development start
