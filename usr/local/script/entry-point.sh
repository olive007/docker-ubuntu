#!/bin/sh

echo "Generate the locale $CONTAINER_LOCALE"
locale-gen $CONTAINER_LOCALE > /dev/null


echo "Add new user $CONTAINER_USER_NAME with password $CONTAINER_USER_PASSWORD"
useradd -mG sudo -s /bin/bash -p $(openssl passwd $CONTAINER_USER_PASSWORD) $CONTAINER_USER_NAME

# Remove basic bash configuration for the new user and root
rm /home/$CONTAINER_USER_NAME/.bashrc /root/.bashrc

# Add the public ssh key to the 'authorized_keys' file to easily access to the docker container
su $CONTAINER_USER_NAME -c "mkdir /home/$CONTAINER_USER_NAME/.ssh"
su $CONTAINER_USER_NAME -c "wget -q $SSH_KEY_URL -O /home/$CONTAINER_USER_NAME/.ssh/authorized_keys"


echo "Changing user id to $CONTAINER_USER_UID"
usermod -u $CONTAINER_USER_UID $CONTAINER_USER_NAME
echo "Changing group id to $CONTAINER_USER_GID"
groupmod -g $CONTAINER_USER_GID $CONTAINER_USER_NAME


echo "Customize bash configuration"
wget -q $CONTAINER_BASH_ALIASES -O/home/bash.aliases 
wget -q $CONTAINER_BASH_PROMPT -O/home/bash.prompt
chmod 644 /home/bash.aliases /home/bash.prompt

# Customize bash configuration:
# - Add personal aliases
# - Add personal prompt
# - Enable bash-completion
echo "
[ -f /home/bash.aliases ] && . /home/bash.aliases
[ -f /home/bash.prompt ] && . /home/bash.prompt

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi" >> /etc/bash.bashrc


if [ -t 0 ]; then

    echo "Container started with interactive shell"

    if [ "$@" = "default-command" ]; then
	# Launch the startup script
	/usr/local/script/startup.sh
	# Login as the addtional user
	cd /home/$CONTAINER_USER_NAME
	su $CONTAINER_USER_NAME
    else
	exec $@
    fi
    
else
    
    echo "Container started without interactive shell"
    
    if [ "$@" = "default-command" ]; then
	# Launch the startup script
	/usr/local/script/startup.sh
	# Star an infinite loop to not stop the container
	exec infinite-loop
    else
	exec $@
    fi

fi
