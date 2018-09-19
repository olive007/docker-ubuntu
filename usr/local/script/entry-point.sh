#!/bin/sh

set -e

if [ -t 0 ] ; then

    echo "Container started with interactive shell"
    # Execute command from CMD value
    /bin/bash -c "$@"

else

    echo "Container started without interactive shell"
    # Execute command from CMD value
    /bin/bash -c "$@"
    # Start an infinite loop after to don't stop the container
    while true
    do
	sleep 60
    done
fi
