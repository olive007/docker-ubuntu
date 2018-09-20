#!/bin/sh

set -e

SIGNAL_CAUGHT=false

trap 'signalCaught' 2 9 15 # SIGINT SIGKILL SIGTERM

signalCaught() {

    SIGNAL_CAUGHT=true

}

while ! `$SIGNAL_CAUGHT`
do
    sleep 2
done
