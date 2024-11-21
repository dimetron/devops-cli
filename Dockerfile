ARG IMAGE_BASE=dimetron/os-base
ARG IMAGE_VER=4.4.2

FROM ${IMAGE_BASE}:${IMAGE_VER}

LABEL maintainer="Dmytro Rashko <drashko@me.com>"

ARG TARGETVARIANT
ARG TARGETPLATFORM
ARG TARGETARCH

ENV SDKMAN_DIR=/root/.sdkman
ENV TERM=xterm-256color

#ENV DEBIAN_FRONTEND="noninteractive"
# set environment variables and DNS to make build pass on Docker buildkit

RUN echo "LANG=en_US.utf-8"   >> /etc/environment  \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment  \
 && echo "fastestmirror=0"    >> /etc/dnf/dnf.conf \
 && sed s/PasswordAuthentication.*/PasswordAuthentication\ no/ -i /etc/ssh/sshd_config                                                       \
 && sed s/GSSAPIAuthentication.*/GSSAPIAuthentication\ no/     -i /etc/ssh/sshd_config                                                       \
 && sed s/#AllowTcpForwarding.*/AllowTcpForwarding\ yes/       -i /etc/ssh/sshd_config                                                       \
 && sed s/#AllowAgentForwarding.*/AllowAgentForwarding\ yes/   -i /etc/ssh/sshd_config                                                       \
 && sed s/#PermitRootLogin.*/PermitRootLogin\ yes/             -i /etc/ssh/sshd_config                                                       \
 && sed s/#PermitTunnel.*/PermitTunnel\ yes/                   -i /etc/ssh/sshd_config                                                       \
 && sed s/#UseDNS.*/UseDNS\ no/                                -i /etc/ssh/sshd_config                                                       \
 && cat /etc/ssh/sshd_config | grep yes   \
 && useradd -m -s /bin/zsh devops \
 && echo "devops ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/devops \
 && echo "devops:devops" | chpasswd

USER root
WORKDIR /root

#includes all below sdk required path
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.sdkman/bin:/root/.sdkman/candidates/maven/current/bin:/root/.krew/bin:/root/.arkade/bin

RUN curl -sLS https://get.arkade.dev | /bin/bash     \
    &&    arkade get jq                              \
    &&    arkade get yq                              \
    &&    arkade get op                              \
    &&    arkade get fzf                             \
    &&    arkade get k9s                             \
    &&    arkade get k3s                             \
    &&    arkade get k3d                             \
    &&    arkade get kind                            \
    &&    arkade get helm                            \
    &&    arkade get dagger                          \
    &&    arkade get buildx                          \
    &&    arkade get kubectl                         \
    &&    arkade get kustomize                       \
    &&    arkade get kubetail                        \
    &&    arkade get argocd                          \
    &&    arkade get istioctl                        \
    &&    arkade get krew                            \
    &&    arkade get crane                           \
    &&    arkade get trivy                           \
    &&    arkade get kubescape                       \
    &&    arkade get terraform                       \
    &&    arkade get terragrunt                      \
    &&    arkade get vhs                             \
    &&    arkade get atuin                           \
    &&    pip uninstall awscli -y                    \
    && echo "arkade installation completed"

RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
RUN curl -sLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew-linux_${TARGETARCH}.tar.gz"                                \
    && tar zxvf krew-linux_${TARGETARCH}.tar.gz                                                                                                 \
    && curl -sLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew.yaml"                                                   \
    && cat krew.yaml ; mkdir -p /root/.krew/bin                                                                                                 \
    && ./krew-linux_${TARGETARCH} install --manifest=krew.yaml --archive=krew-linux_${TARGETARCH}.tar.gz                                        \
    && ./krew-linux_${TARGETARCH} update                                                                                                        \
    && /usr/bin/kubectl krew   install ctx                                                                                                      \
    && /usr/bin/kubectl krew   install ns                                                                                                       \
    && /usr/bin/kubectl krew   install gadget                                                                                                   \
    && /usr/bin/kubectl krew   install images                                                                                                   \
    && /usr/bin/kubectl krew   install stern                                                                                                    \
    && /usr/bin/kubectl krew   install rbac-tool                                                                                                  \
    && /usr/bin/kubectl krew   install access-matrix                                                                                                \
    && /usr/bin/kubectl krew   install rbac-view                                                                                                \
    && /usr/bin/kubectl plugin list                                                                                                             \
    && ls;rm -rf  krew*

#add dimetron user
ADD https://github.com/dimetron.keys /root/.ssh/authorized_keys

RUN echo "Create default ssh keys"                                                                                                              \
    && ssh-keygen -A                                                                                                                            \
    && echo "export TERM=xterm-256color" >> .zshrc                                                                                              \
    && echo "alias vi=vim"    >> .zshrc                                                                                                         \
    && echo "alias k=kubectl" >> .zshrc                                                                                                         \
    && echo "alias kns='kubectl config set-context --current --namespace'" >> .zshrc                                                            \
    && echo 'source <(kubectl completion zsh)' >> .zshrc                                                                                        \
    && echo 'complete -F __start_kubectl k'    >> .zshrc                                                                                        \
    && echo 'eval $(starship init zsh)'        >> .zshrc                                                                                        \
    # && echo 'source /root/kubectl.zsh'  >> .zshrc                                                                                             \
    # && echo "RPROMPT='%{\$fg[blue]%}(\$ZSH_KUBECTL_NAMESPACE)%{\$reset_color%}'"  >> .zshrc                                                   \
    && sed 's/\(^plugins=([^)]*\)/\1 kubectl zsh-autosuggestions/' -i .zshrc                                                                    \
    && sed 's/robbyrussell/af-magic/g' -i .zshrc                                                                                                \
    && sh -c 'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'        \
    && sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes                                                                            \
    && mkdir -p /root/.config

ADD starship.toml /root/.config/starship.toml

#TODO: add catputchin themes
#RUN echo "Install themes"                                                                                                                         \
#    && mkdir -p ~/.config/tmux/plugins/catppuccin  \
#    && git clone -b v2.1.1 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux

CMD tail -f /dev/null