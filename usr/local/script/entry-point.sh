#!/bin/sh

set -e

echo "Changing id of user $NEW_USER_NAME by $NEW_USER_ID"
usermod -u $NEW_USER_ID $NEW_USER_NAME
echo "Changing id of group $NEW_USER_NAME by $NEW_GROUP_ID"
groupmod -g $NEW_GROUP_ID $NEW_USER_NAME

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
