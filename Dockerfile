ARG BASE_IMAGE=ubuntu:21.04
FROM $BASE_IMAGE

LABEL maintainer="Dmytro Rashko <drashko@me.com>"

## Environment variables required for this build (do NOT change)
ENV IMAGE_VER=2.35
ENV VERSION_HELM3=3.6.0
ENV VERSION_KIND=0.10.0       
ENV VERSION_TERRAFORM=1.0.0

#https://github.com/helm/helm/releases
#https://github.com/kubernetes-sigs/kind/releases
#https://www.terraform.io/downloads.html

ENV SDKMAN_DIR=/root/.sdkman
ENV TERM=xterm

ENV HELM2_BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV HELM2_TAR_FILE="helm-v${VERSION_HELM2}-linux-amd64.tar.gz"

ENV HELM3_BASE_URL="https://get.helm.sh"
ENV HELM3_TAR_FILE="helm-v${VERSION_HELM3}-linux-amd64.tar.gz"
ENV DEBIAN_FRONTEND="noninteractive"

#includes all below sdk required path
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.sdkman/bin:/root/.sdkman/candidates/gradle/current/bin:/root/.sdkman/candidates/maven/current/bin:/root/.krew/bin

# set environment variables
RUN echo "LANG=en_US.utf-8" >> /etc/environment \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment

WORKDIR /root

#COPY docker-ce.repo /etc/dnf.repos.d/docker-ce.repo
RUN echo "Installing packages" \
    && apt-get -y update    \
    && apt-get -y upgrade   \
    && apt-get -y install   \
    ansible                 \
    apt-utils               \
    apt-transport-https     \
    bash                    \
    bzip2                   \
    ca-certificates         \
    curl                    \
    dnsmasq                 \
    findutils               \
    gcc                     \
    git                     \
    gnupg                   \
    hostname                \
    htop                    \
    httpie                  \
    iptables                \
    iptraf                  \
    jq                      \
    lsb-release             \
    mc                      \
    net-tools               \
    openssh-client          \
    openssh-server          \
    openssl                 \
    passwd                  \
    procps                  \
    python3                 \
    rsync                   \
    sed                     \
    skopeo                  \
    socat                   \
    squid                   \
    sshpass                 \
    sshuttle                \
    sudo                    \
    tar                     \
    tcpdump                 \
    tmux                    \
    torsocks                \
    unzip                   \
    vim                     \
    wget                    \
    zip                     \
    zsh                     \
    && echo " ---------- Docker ----------"                                                                                     \
    && curl -o  docker-ce-cli.deb -L https://download.docker.com/linux/ubuntu/dists/hirsute/pool/stable/amd64/docker-ce-cli_20.10.7~3-0~ubuntu-hirsute_amd64.deb \
    && dpkg -i  docker-ce-cli.deb                                                                                               \
    && apt  -y  clean all                                                                                                       \
    && rm   -rf *.deb                                                                                                           \
    && rm   -rf /var/lib/{cache,log} /var/log/lastlog                                                                           \
    && mkdir    /var/log/lastlog

RUN echo "Utils"                                                                                                                \
    && curl -sLo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v${VERSION_KIND}/kind-$(uname)-amd64"        \
    && mv kind  /usr/bin                                                                                                        \
    && chmod +x /usr/bin/kind                                                                                                   \
    && curl -sL "${HELM3_BASE_URL}/${HELM3_TAR_FILE}"   | tar xvz                                                               \
    && mv linux-amd64/helm /usr/bin/helm3                                                                                       \
    && chmod +x /usr/bin/helm3                                                                                                  \
    && rm -rf linux-amd64                                                                                                       \
    && ln -s /usr/bin/helm3 /usr/bin/helm                                                                                       \
    && curl -sL "https://releases.hashicorp.com/terraform/$VERSION_TERRAFORM/terraform_${VERSION_TERRAFORM}_linux_amd64.zip" -o terraform.zip \
    && unzip terraform.zip                                                                                                      \
    && mv terraform /usr/bin/terraform                                                                                          \
    && chmod +x /usr/bin/terraform                                                                                              \
    && rm -f terraform.zip                                                                                                      \
    && curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v0.29.10/terragrunt_linux_amd64" -o terragrunt_linux_amd64    \
    && mv terragrunt_linux_amd64 /usr/bin/terragrunt                                                                                        \
    && chmod +x /usr/bin/terragrunt                                                                                                         \
    && rm -f terragrunt.zip                                                                                                                 \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"                                                    \
    && unzip awscliv2.zip -d ./aws/                                                                                                         \
    && rm -rf  ./aws /root/awscliv2.zip                                                                                                     \
    && sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"                                           \
    && mkdir -p /root/.k9s                                                                                                                  \
    && curl -sL "https://raw.githubusercontent.com/derailed/k9s/master/skins/stock.yml" -o /root/.k9s/skin.yaml                             \
    && curl -sL "https://github.com/derailed/k9s/releases/download/v0.24.7/k9s_Linux_x86_64.tar.gz" | tar xvz                               \
    && mv k9s /usr/bin                                                                                                                      \
    && curl -sL "https://github.com/derailed/popeye/releases/download/v0.9.0/popeye_Linux_arm64.tar.gz" | tar xvz                           \
    && mv popeye /usr/bin                                                                                                                   \
    && curl -sLO "https://github.com/bcicen/ctop/releases/download/v0.7.5/ctop-0.7.5-linux-amd64"                                           \
    && mv ctop-0.7.5-linux-amd64 /usr/bin/ctop                                                                                              \
    && chmod +x /usr/bin/ctop                                                                                                               \
    && curl -sLO "https://github.com/atombender/ktail/releases/download/v1.0.1/ktail-linux-amd64"                                           \
    && mv ktail-linux-amd64 /usr/bin/ktail                                                                                                  \
    && chmod +x /usr/bin/ktail                                                                                                              \
    && curl -sLO "https://github.com/k14s/kapp/releases/download/v0.37.0/kapp-linux-amd64"                                                  \
    && mv kapp-linux-amd64 /usr/bin/kapp                                                                                                    \
    && chmod +x /usr/bin/kapp                                                                                                               \
    && curl -sLO "https://github.com/k14s/ytt/releases/download/v0.34.0/ytt-linux-amd64"                                                    \
    && mv ytt-linux-amd64 /usr/bin/ytt                                                                                                      \
    && chmod +x /usr/bin/ytt                                                                                                                \
    && curl -sLO "https://github.com/tektoncd/cli/releases/download/v0.19.0/tkn_0.19.0_Linux_x86_64.tar.gz"                                 \
    && tar xvzf tkn_0.19.0_Linux_x86_64.tar.gz -C /usr/bin tkn                                                                              \
    && rm -rd tkn_0.19.0_Linux_x86_64.tar.gz                                                                                                \
    && chmod +x /usr/bin/tkn                                                                                                                \
    && curl -sLO "https://releases.hashicorp.com/vault/1.7.2/vault_1.7.2_linux_amd64.zip"                                                   \
    && unzip  vault_1.7.2_linux_amd64.zip                                                                                                   \
    && rm -rf vault_1.7.2_linux_amd64.zip                                                                                                   \
    && mv vault /usr/bin                                                                                                                    \
    && chmod +x /usr/bin/vault                                                                                                              \
    && curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp            \
    && mv /tmp/eksctl /usr/local/bin                                                                                                        \
    && chmod +x /usr/local/bin/eksctl

#aws auth
#RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator && \
#    mv aws-iam-authenticator /usr/bin/aws-iam-authenticator && \
#    chmod +x /usr/bin/aws-iam-authenticator

RUN curl -s "https://get.sdkman.io"         | /bin/bash                                                             \
    && echo "sdkman_auto_answer=true"       > $SDKMAN_DIR/etc/config                                                \
    && echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config                                                \
    && echo "sdkman_insecure_ssl=true"     >> $SDKMAN_DIR/etc/config                                                \
    && zsh -c 'set +x;source /root/.sdkman/bin/sdkman-init.sh'                                                      \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls java   && sdk install java   11.0.11.9.1-amzn'   \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls maven  && sdk install maven  3.8.1'              \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls gradle && sdk install gradle 7.0.2'              \
    && rm -rf /root/.sdkman/archives                                                                                \
    && mkdir -p /root/.sdkman/archives

RUN curl -sL "https://github.com/openshift/okd/releases/download/4.7.0-0.okd-2021-06-04-191031/openshift-client-linux-4.7.0-0.okd-2021-06-04-191031.tar.gz" | tar xvz && \
    cp oc /usr/bin/ &&                                                                                              \
    cp kubectl /usr/bin/ &&                                                                                         \
    rm -rf  openshift-client-linux-*

#krew for kubectl - seems depends on latest k
RUN curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.1/krew.yaml" &&         \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.1/krew.tar.gz"          \
    && tar zxvf krew.tar.gz ; cat krew.yaml ; mkdir -p /root/.krew/bin                                  \
    && ./krew-linux_amd64 install --manifest=krew.yaml --archive=krew.tar.gz                            \
    && ./krew-linux_amd64 update                                                                        \
    && rm -rf krew*                                                                                     \
    && kubectl krew install ctx                                                                         \
    && kubectl krew install ns                                                                          \
    && kubectl krew install images                                                                      \
    && kubectl krew install ingress-nginx                                                               \
    && kubectl plugin list

RUN curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o /usr/local/bin/telepresence \
    && chmod a+x /usr/local/bin/telepresence

#use openssh
RUN echo "Setup SSH server defaults" \
    && sed s/PasswordAuthentication.*/PasswordAuthentication\ no/ -i /etc/ssh/sshd_config       \
    && sed s/GSSAPIAuthentication.*/GSSAPIAuthentication\ no/     -i /etc/ssh/sshd_config       \
    && sed s/#AllowTcpForwarding.*/AllowTcpForwarding\ yes/       -i /etc/ssh/sshd_config       \
    && sed s/#AllowAgentForwarding.*/AllowAgentForwarding\ yes/   -i /etc/ssh/sshd_config       \
    && sed s/#PermitRootLogin.*/PermitRootLogin\ yes/             -i /etc/ssh/sshd_config       \
    && sed s/#PermitTunnel.*/PermitTunnel\ yes/                   -i /etc/ssh/sshd_config       \
    && sed s/#UseDNS.*/UseDNS\ no/                                -i /etc/ssh/sshd_config       \
    && cat /etc/ssh/sshd_config | grep yes

#add dimetron user
ADD https://github.com/dimetron.keys /root/.ssh/authorized_keys
ADD kubectl.zsh /root/
RUN echo "Create default ssh keys "                                                             \
    && passwd -d root                                                                           \
    && ssh-keygen -A                                                                            \
    && echo "export TERM=xterm-256color" >> .zshrc                                              \
    && echo "alias vi=vim"    >> .zshrc                                                         \
    && echo "alias k=kubectl" >> .zshrc                                                         \
    && echo "alias kns='kubectl config set-context --current --namespace'" >> .zshrc            \
    && echo 'source <(kubectl completion zsh)' >> .zshrc                                        \
    && echo 'complete -F __start_kubectl k'    >> .zshrc                                        \
    && echo 'source kubectl.zsh'  >> .zshrc                                                     \
    && echo "RPROMPT='%{\$fg[blue]%}(\$ZSH_KUBECTL_NAMESPACE)%{\$reset_color%}'" >> .zshrc      \
    && sed 's/\(^plugins=([^)]*\)/\1 kubectl/' -i .zshrc                                        \
    && sed 's/robbyrussell/af-magic/g' -i .zshrc

#COPY rootfs /
#ENTRYPOINT ["/entrypoint.sh"]
RUN groupadd -r devops

RUN echo " ---------- Verify ----------"    \
    && which docker                         \
    && which skopeo                         \
    && which sshuttle                       \
    && which kubectl

CMD tail -f /dev/null