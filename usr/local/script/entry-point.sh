#!/bin/sh

set -e

/usr/local/script/startup.sh

if [ -t 0 ] ; then

    echo "Container started with interactive shell"
    # Start bash command
    /bin/bash -c "$@"

else

    echo "Container started without interactive shell"
    # Start an infinite loop
    while true
    do
	sleep 60
    done
fi
