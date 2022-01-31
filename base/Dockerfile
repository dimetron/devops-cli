ARG BASE_IMAGE=fedora:latest

FROM $BASE_IMAGE
LABEL maintainer="Dmytro Rashko <drashko@me.com>"

## Environment variables required for this build (do NOT change)

ENV IMAGE_VER=3.0
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM

ENV TERM=xterm-256color
ENV DEBIAN_FRONTEND="noninteractive"

# set environment variables and DNS to make build pass on Docker buildkit
RUN echo "LANG=en_US.utf-8"   >> /etc/environment \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment \
 && echo "fastestmirror=0"    >> /etc/dnf/dnf.conf

WORKDIR /root

#COPY docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN echo "Installing additional software"                                                                                                        \
    && dnf -y clean all                                                                                                                          \
    && dnf -y install dnf-plugins-core                                                                                                           \
    && dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo                                                     \
    && sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/centos/8/tailscale.repo                                              \
    && dnf -y update                                                                                                                             \
    && dnf -y upgrade                                                                                                                            \
    && dnf -y install --nogpgcheck tailscale                                                                                                     \
    && dnf -y install yum-utils device-mapper-persistent-data lvm2 sudo                                                                          \
    && dnf -y install   docker-ce-cli oci-runtime conntrack-tools torsocks iptables                                                              \
    && dnf -y install   which wget zip unzip jq tar passwd openssl openssh openssh-server squid dnsmasq socat tmux iputils                       \
    && dnf -y install   bash sshpass hostname curl ca-certificates libstdc++ git zip unzip sed vim-enhanced                                      \
    && dnf -y install   python37 sshuttle  bash zsh procps rsync mc htop ansible findutils jq bzip2 bat                                          \
    && dnf -y install   shadow-utils iptraf tcpdump net-tools httpie                                                                             \
    && dnf -y clean all                                                                                                                          \
    && rm -rf /var/lib/{cache,log} /var/log/lastlog /usr/bin/dockerd-ce /usr/bin/containerd                                                      \
    && mkdir /var/log/lastlog


CMD tail -f /dev/null