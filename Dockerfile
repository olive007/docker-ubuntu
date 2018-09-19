FROM ubuntu:16.04
MAINTAINER SECRET Olivier (olivier@devolive.be)

# Define variable
ARG NEW_USER=olive
ARG USER_PASSWORD=test
ARG SSH_KEY_URL=https://gist.githubusercontent.com/olive007/0eea691d672d827823877c180c4cc354/raw/docker_rsa.pub

# Update the package list
RUN apt-get update

# Update packages to last version 
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# Install several usefull packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends iproute2 openssh-server sudo emacs-nox openssl wget htop unzip

# Add new user with password as test
RUN useradd -mG sudo -s /bin/bash -p $(openssl passwd $USER_PASSWORD) $NEW_USER

# Get bash configuration file
ADD https://gist.githubusercontent.com/olive007/87f72fa69a071dc7d64430317b31d1f2/raw/bash.aliases /home/bash.aliases 
ADD https://gist.githubusercontent.com/olive007/87f72fa69a071dc7d64430317b31d1f2/raw/bash.prompt /home/bash.prompt

RUN chmod 644 /home/bash.aliases /home/bash.prompt

RUN echo "[ -f /home/bash.aliases ] && . /home/bash.aliases" >> /etc/bash.bashrc
RUN echo "[ -f /home/bash.prompt ] && . /home/bash.prompt" >> /etc/bash.bashrc

# Remove basic bash configuration for root
RUN rm /root/.bashrc

# Change user
USER $NEW_USER
WORKDIR /home/olive

# Remove basic bash configuration for the new user
RUN rm /home/$NEW_USER/.bashrc

# Add the public ssh key to the 'authorized_keys' file to easily access to the docker container
RUN mkdir /home/$NEW_USER/.ssh
ADD $SSH_KEY_URL /home/$NEW_USER/.ssh/authorized_keys

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
