# https://docs.docker.com/engine/reference/builder/

# FAQ
#
# Q: Why "apt-get update && apt-get install"?
#
# See https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/apt-get
#
# Q: How to debug ssh?
#
# Commenting out the CMD line, then shell into the machine via:
#
#   $ docker exec --privileged -it barry bash -l
#
# From the shell on the machine, run sshd in debug mode:
#
#   $ sudo /usr/sbin/sshd -ddd
#
# Q: How does /etc/ssh/keys/authorized_keys work?
#
# It's a Docker-created file/volume that must be mapped via "docker run"
# or "docker create", see https://docs.docker.com/engine/reference/run/#/volume-shared-filesystems

FROM ubuntu:16.04

# Configure ssh (allow root to ssh)

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssh-server && \
    echo "AuthorizedKeysCommand /bin/cat /etc/ssh/keys/authorized_keys" >> /etc/ssh/sshd_config && \
    echo "AuthorizedKeysCommandUser root" >> /etc/ssh/sshd_config && \
    mkdir /var/run/sshd
EXPOSE 22
# TODO: Should https://github.com/Yelp/dumb-init be used here?
CMD [ "/usr/sbin/sshd", "-D" ]

# Install packages (with --no-install-recommends)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      command-not-found \
      curl \
      git \
      jed \
      less \
      locales \
      man-db \
      mtr-tiny \
      net-tools \
      rsync \
      sudo \
      unzip \
      wget \
      zip

# Install fish (without --no-install-recommends)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      software-properties-common && \
    apt-add-repository -y ppa:fish-shell/release-2 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      fish

# Generate locale
RUN locale-gen en_GB.UTF-8

# Create user
ENV USER mjs
RUN adduser --disabled-login --gecos "" $USER
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chsh -s /usr/bin/fish $USER
