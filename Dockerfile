FROM ubuntu:18.04
MAINTAINER SECRET Olivier (olivier@devolive.be)

# Define variables
ARG CONTAINER_LOCALE
ARG CONTAINER_USER_NAME=olive
ARG CONTAINER_USER_PASSWORD=test
ARG CONTAINER_USER_ID=1000
ARG CONTAINER_GROUP_ID=1000
ARG SSH_KEY_URL=https://gist.githubusercontent.com/olive007/0eea691d672d827823877c180c4cc354/raw/docker_rsa.pub

# Put those variables into the env of the container
ENV CONTAINER_USER_NAME $CONTAINER_USER_NAME
ENV CONTAINER_USER_ID $CONTAINER_USER_ID
ENV CONTAINER_GROUP_ID $CONTAINER_GROUP_ID

# Set locale variable as require
RUN test -n "$CONTAINER_LOCALE" || (echo 1>&2 "You have to set CONTAINER_LOCALE '--build-arg'" && exit 1)

# Update the package list
RUN apt-get update

# Update packages to last version 
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# Install several usefull packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    				   locales \
    				   bash-completion \
    				   iproute2 \
				   openssh-server \
				   sudo \
				   emacs-nox \
				   openssl \
				   wget \
				   htop \
				   curl \
				   ca-certificates \
				   unzip

# Generate the locale
RUN locale-gen $CONTAINER_LOCALE

# Add new user with password as test
RUN useradd -mG sudo -s /bin/bash -p $(openssl passwd $CONTAINER_USER_PASSWORD) $CONTAINER_USER_NAME

# Get bash configuration file
ADD https://gist.githubusercontent.com/olive007/87f72fa69a071dc7d64430317b31d1f2/raw/bash.aliases /home/bash.aliases 
ADD https://gist.githubusercontent.com/olive007/87f72fa69a071dc7d64430317b31d1f2/raw/bash.prompt /home/bash.prompt

RUN chmod 644 /home/bash.aliases /home/bash.prompt

# Customize bash configuration:
# - Add personal aliases
# - Add personal prompt
# - Enable bash-completion
RUN echo "[ -f /home/bash.aliases ] && . /home/bash.aliases" >> /etc/bash.bashrc; \
    echo "[ -f /home/bash.prompt ] && . /home/bash.prompt" >> /etc/bash.bashrc; \
    echo "if ! shopt -oq posix; then" >> /etc/bash.bashrc; \
    echo "  if [ -f /usr/share/bash-completion/bash_completion ]; then" >> /etc/bash.bashrc; \
    echo "    . /usr/share/bash-completion/bash_completion" >> /etc/bash.bashrc; \
    echo "  elif [ -f /etc/bash_completion ]; then" >> /etc/bash.bashrc; \
    echo ". /etc/bash_completion" >> /etc/bash.bashrc; \
    echo "  fi" >> /etc/bash.bashrc; \
    echo "fi" >> /etc/bash.bashrc

# Remove basic bash configuration for root
RUN rm /root/.bashrc

# Change user
USER $CONTAINER_USER_NAME
WORKDIR /home/olive

# Remove basic bash configuration for the new user
RUN rm /home/$CONTAINER_USER_NAME/.bashrc

# Add the public ssh key to the 'authorized_keys' file to easily access to the docker container
RUN mkdir /home/$CONTAINER_USER_NAME/.ssh
ADD $SSH_KEY_URL /home/$CONTAINER_USER_NAME/.ssh/authorized_keys

# Go back to root for the next configuration
USER root
WORKDIR /

# Create the script directory
RUN mkdir -p /usr/local/script

# Copy the entry-point script
COPY usr/local/script/entry-point.sh /usr/local/script/entry-point.sh
RUN chmod +x /usr/local/script/entry-point.sh && \
    ln -s /usr/local/script/entry-point.sh /usr/local/bin/entry-point

# Copy the startup script
COPY usr/local/script/startup.sh /usr/local/script/startup.sh
RUN chmod +x /usr/local/script/startup.sh

# Copy the infinite-loop script
COPY usr/local/script/infinite-loop.sh /usr/local/script/infinite-loop.sh
RUN chmod +x /usr/local/script/infinite-loop.sh

# Start SSH service with the startup script
RUN echo "service ssh start" >> /usr/local/script/startup.sh

ENTRYPOINT ["entry-point"]

CMD ["/usr/local/script/startup.sh && bash"]
