# https://docs.docker.com/engine/reference/builder/

# FAQ
#
# Why "apt-get update && apt-get install"?
#
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/apt-get
#
# Why DEBIAN_FRONTEND=noninteractive?
#
# To avoid debconf whining: "TERM is not set, so the dialog frontend is not usable."

# COMMANDS RUN AS ROOT 

FROM ubuntu:16.04

ENV USER mjs

# Add apt utilities and fish repository
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-file \
		apt-utils \
    software-properties-common
RUN add-apt-repository -y ppa:fish-shell/release-2

# Install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
		command-not-found \
		curl \
		fish \
		git \
		jed \
		less \
		man-db \
		mtr-tiny \
		net-tools \
		openssh-client \
		openssh-server \
		pv \
		rsync \
		rsyslog \
    sudo \
		unzip \
		wget \
		zip

RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8

# Create user
RUN adduser --disabled-login $USER
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chsh -s /usr/bin/fish $USER

# Debug ssh by commenting out the CMD line, then shell into the machine via:
#
#   $ docker exec --privileged -it barry bash -l
#
# Then, run sshd in debug mode:
# 
#   $ sudo /usr/sbin/sshd -ddd
#
# Note that /etc/ssh/keys/authorized_keys is a Docker-create file/volume, that
# must be mapped via "docker run" or "docker create":
# https://docs.docker.com/engine/reference/run/#/volume-shared-filesystems
RUN echo "AuthorizedKeysCommand /bin/cat /etc/ssh/keys/authorized_keys" >> /etc/ssh/sshd_config
RUN echo "AuthorizedKeysCommandUser root" >> /etc/ssh/sshd_config
RUN mkdir /var/run/sshd
EXPOSE 22
CMD [ "/usr/sbin/sshd", "-D" ]
