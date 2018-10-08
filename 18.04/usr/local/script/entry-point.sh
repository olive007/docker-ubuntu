#!/bin/sh

SIGNAL_CAUGHT=false
CHILDREN_SCRIPT_DIRECTORY=/usr/local/script/entry-point.d
INTERACTIVE_SHELL=false
INTERACTIVE_OR_NOT="without interactive shell"


myTrap() {

    # save the function into a var
    func=$1
    # remove the function form the argument list
    shift

    # for each all signals to trap it one by one
    for signal; do
        trap "$func $signal" "$signal"
    done
}


signalHandler() {

    SIGNAL_CAUGHT=true
    echo "Signal "`kill -l $1`" caught"

    /usr/local/script/container-stopped.sh
}


myTrap 'signalHandler' 15 9 2 # TERM KILL INT


if [ -t 0 ]; then

    INTERACTIVE_SHELL=true
    INTERACTIVE_OR_NOT="with interactive shell"
fi


id -u $CONTAINER_USER_NAME >/dev/null 2>/dev/null
# Check we already have add the new user
# (To know if we start or restart the container)
if [ $? -ne 0 ]; then

    echo "Container started $INTERACTIVE_OR_NOT (IP: "`hostname -i`")"

    
    echo "Generate the locale $CONTAINER_LOCALE"
    locale-gen $CONTAINER_LOCALE > /dev/null


    echo "Add new user $CONTAINER_USER_NAME with password $CONTAINER_USER_PASSWORD"
    useradd -mG sudo -s /bin/bash -p $(openssl passwd $CONTAINER_USER_PASSWORD) $CONTAINER_USER_NAME

    # Remove basic bash configuration for the new user and root
    rm /home/$CONTAINER_USER_NAME/.bashrc /root/.bashrc

    # Add the public ssh key to the 'authorized_keys' file to easily access to the docker container
    su $CONTAINER_USER_NAME -c "mkdir /home/$CONTAINER_USER_NAME/.ssh"
    su $CONTAINER_USER_NAME -c "wget -q $CONTAINER_SSH_KEY_URL -O /home/$CONTAINER_USER_NAME/.ssh/authorized_keys"


    echo "Changing user id to $CONTAINER_USER_UID"
    usermod -u $CONTAINER_USER_UID $CONTAINER_USER_NAME
    echo "Changing group id to $CONTAINER_USER_GID"
    groupmod -g $CONTAINER_USER_GID $CONTAINER_USER_NAME


    echo "Customize bash configuration"
    wget -q $CONTAINER_BASH_ALIASES -O/home/bash.aliases 
    wget -q $CONTAINER_BASH_PROMPT -O/home/bash.prompt
    chmod 644 /home/bash.aliases /home/bash.prompt


    for filename in `ls -rt $CHILDREN_SCRIPT_DIRECTORY`; do

	echo "Configuration form $filename"
	. $CHILDREN_SCRIPT_DIRECTORY/$filename

    done
else

    echo "Container restarted $INTERACTIVE_OR_NOT (IP: "`hostname -i`")"
fi


if [ "$@" = "default-command" ]; then
    
    # Launch the startup script
    /usr/local/script/startup.sh

    if `$INTERACTIVE_SHELL`; then

	# Login as the addtional user
	cd /home/$CONTAINER_USER_NAME
	su $CONTAINER_USER_NAME
    else

	# Star an infinite loop to not stop the container
	while ! `$SIGNAL_CAUGHT`
	do
	    sleep 2
	done
    fi

else
    exec $@
fi
