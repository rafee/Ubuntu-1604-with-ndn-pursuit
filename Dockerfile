#-------------------------------------------------------------------------------------------------------------
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

# Using Ubuntu 16.04 as the base image
FROM ubuntu:16.04

# This Dockerfile's base image has a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Location and expected SHA for common setup script - SHA generated on release
ARG COMMON_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/v0.112.0/script-library/common-debian.sh"
ARG COMMON_SCRIPT_SHA="28e3d552a08e0d82935ad7335837f354809bec9856a3e0c2855f17bfe3a19523"

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog wget ca-certificates 2>&1 \
    #
    # Verify git, common tools / libs installed, add/modify non-root user, optionally install zsh
    && wget -q -O /tmp/common-setup.sh $COMMON_SCRIPT_SOURCE \
    && if [ "$COMMON_SCRIPT_SHA" != "dev-mode" ]; then echo "$COMMON_SCRIPT_SHA /tmp/common-setup.sh" | sha256sum -c - ; fi \
    && /bin/bash /tmp/common-setup.sh "$INSTALL_ZSH" "$USERNAME" "$USER_UID" "$USER_GID" \
    && rm /tmp/common-setup.sh

# Configure apt and install ndn and pursuit
# Install C++ tools
RUN apt-get -y install build-essential cmake cppcheck valgrind libcpprest-dev libboost-all-dev pkg-config libsqlite3-dev \
    #
    # Clone ndn-cxx and install version suitable for 16.04
    && git clone https://github.com/named-data/ndn-cxx \
    && cd ndn-cxx \
    && git checkout 9603325ba6e35a0b985c77e074b77e3a3e7030ea \
    && ./waf configure \
    && ./waf \
    && ./waf install \
    && ldconfig \
    #
    # Clean ndn-cxx
    && cd .. && rm -rf ndn-cxx

#
# Clone blackadder and install version suitable for 16.04
RUN git clone https://github.com/kohler/click \
    && cd click \
    && ./configure --disable-linuxmodule \
    && make && make install \
    # clean click
    && cd .. && rm -rf click \
    && git clone https://github.com/rafee/blackadder \
    && cd blackadder \
    && ./make-all-libs.sh \
    # clean blackadder
    && cd .. && rm -rf blackadder

# Clean up apt
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
