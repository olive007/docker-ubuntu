FROM ubuntu:18.04
MAINTAINER SECRET Olivier (olivier@devolive.be)

# Update the package list
RUN apt-get update

# Update packages to last version 
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install several usefull packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y iproute2 openssh-server sudo emacs-nox

# Start service
RUN service ssh start

ARG NEW_USER=olive
# Add new user with password as test
RUN useradd -mG sudo -s /bin/bash -p $(openssl passwd test) $NEW_USER

# Get bash configuration file
ADD https://gist.githubusercontent.com/olive007/87f72fa69a071dc7d64430317b31d1f2/raw/bash.aliases /home/bash.aliases 
ADD https://gist.githubusercontent.com/olive007/87f72fa69a071dc7d64430317b31d1f2/raw/bash.prompt /home/bash.prompt

RUN chmod 644 /home/bash.aliases /home/bash.prompt

RUN echo "[ -f /home/bash.aliases ] && . /home/bash.aliases" >> /etc/bash.bashrc
RUN echo "[ -f /home/bash.prompt ] && . /home/bash.prompt" >> /etc/bash.bashrc

# Remove basic bash configuration
RUN rm /root/.bashrc

# Change user
USER $NEW_USER
WORKDIR /home/olive

# Copy the public ssh key from present into the folder
# Dockerfile is copied too because COPY need at least 1 files !
COPY Dockerfile *.pub ./
# Directly delete useless Dockerfile 
RUN rm Dockerfile
RUN mkdir /home/$NEW_USER/.ssh
RUN cat *.pub > /home/$NEW_USER/.ssh/authorized_keys
RUN rm -v *.pub

# Remove basic bash configuration
RUN rm /home/$NEW_USER/.bashrc
