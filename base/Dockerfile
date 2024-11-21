ARG BASE_IMAGE=fedora:41
#ARG BASE_IMAGE=amazonlinux:2022
#ARG BASE_IMAGE=almalinux:9.0-minimal

FROM $BASE_IMAGE
LABEL maintainer="Dmytro Rashko <drashko@me.com>"

## Environment variables required for this build (do NOT change)

ARG IMAGE_VER=4.4.2
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM

ENV TERM=xterm-256color
ENV DEBIAN_FRONTEND="noninteractive"

# set environment variables and DNS to make build pass on Docker buildkit
RUN echo "LANG=en_US.utf-8"   >> /etc/environment \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment \
 && echo "fastestmirror=0"    >> /etc/dnf/dnf.conf

#COPY docker-ce.repo /etc/yum.repos.d/docker-ce.repo
#https://docs.fedoraproject.org/en-US/quick-docs/installing-docker/

RUN --mount=type=cache,target=/var/lib/cache/,rw \
    echo "Installing additional software"                                                                                                        \
    && rpm --import https://packages.microsoft.com/keys/microsoft.asc                                                                            \
    && dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm                                                 \
    && dnf config-manager addrepo --from-repofile="https://pkgs.tailscale.com/stable/fedora/tailscale.repo"                                      \
    && dnf -y clean all                                                                                                                          \
    && dnf -y update                                                                                                                             \
    && dnf -y upgrade                                                                                                                            \
    && dnf -y install --nogpgcheck sudo docker-cli docker-buildx docker-compose tailscale azure-cli python3 python3-pip                          \
    && dnf -y install which wget zip unzip jq tar passwd openssl openssh openssh-server sshpass squid dnsmasq socat tmux iputils               \
    && dnf -y install bash hostname curl ca-certificates git zip unzip sed vim-enhanced                                                        \
    && dnf -y install sshuttle  bash zsh procps rsync mc htop ansible findutils jq bzip2 bat                                                   \
    && dnf -y install shadow-utils iptraf tcpdump net-tools strace                                                                             \
    && dnf -y clean packages                                                                                                                     \
    && pip3 install awscli                                                                                                                       \
    && rm -rf /var/log/lastlog /usr/bin/dockerd-ce /usr/bin/containerd                                                                           \
    && mkdir /var/log/lastlog \
    && ssh-keygen -A

CMD tail -f /dev/null