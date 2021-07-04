ARG BASE_IMAGE=fedora:latest
FROM $BASE_IMAGE

LABEL maintainer="Dmytro Rashko <drashko@me.com>"

## Environment variables required for this build (do NOT change)
ENV IMAGE_VER=2.39

ARG VERSION_HELM3=3.6.0
ARG VERSION_KIND=0.11.1
ARG VERSION_TERRAFORM=1.0.0
ARG VERSION_KUSTOMIZE=v4.1.2
ARG VERSION_KUBESEAL=v0.16.0

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

#COPY docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN echo "Installing additional software"                                                                                                        \
    && dnf -y install dnf-plugins-core                                                                                                           \
    && dnf -y install https://dl.k6.io/rpm/repo.rpm                                                                                              \
    && dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo                                                     \
    && dnf -y update                                                                                                                             \
    && dnf -y upgrade                                                                                                                            \
    && dnf -y install --nogpgcheck k6                                                                                                            \
    && dnf -y install   yum-utils device-mapper-persistent-data lvm2 sudo                                                                        \
    && dnf -y install   docker-ce-cli oci-runtime conntrack-tools torsocks iptables                                                              \
    && dnf -y install   which wget zip unzip jq tar passwd openssl openssh openssh-server squid dnsmasq socat tmux iputils                       \
    && dnf -y install   bash sshpass hostname curl ca-certificates libstdc++ git zip unzip sed vim-enhanced                                      \
    && dnf -y install   python37 gcc python3-devel sshuttle  bash zsh procps rsync mc htop ansible findutils jq bzip2                            \
    && dnf -y install   shadow-utils iptraf tcpdump net-tools httpie skopeo                                                                      \
    && dnf -y clean all                                                                                                                          \
    && rm -rf /var/lib/{cache,log} /var/log/lastlog /usr/bin/dockerd-ce /usr/bin/containerd                                                      \
    && mkdir /var/log/lastlog

RUN echo "Utils"                                                                                                                                \
    && curl -sLo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v${VERSION_KIND}/kind-$(uname)-amd64"                        \
    && mv kind  /usr/bin                                                                                                                        \
    && chmod +x /usr/bin/kind                                                                                                                   \
    && curl -sL "${HELM3_BASE_URL}/${HELM3_TAR_FILE}"   | tar xvz                                                                               \
    && mv linux-amd64/helm /usr/bin/helm3                                                                                                       \
    && chmod +x /usr/bin/helm3                                                                                                                  \
    && rm -rf linux-amd64                                                                                                                       \
    && ln -s /usr/bin/helm3 /usr/bin/helm                                                                                                       \
    && curl -sL "https://releases.hashicorp.com/terraform/$VERSION_TERRAFORM/terraform_${VERSION_TERRAFORM}_linux_amd64.zip" -o terraform.zip   \
    && unzip terraform.zip                                                                                                                      \
    && mv terraform /usr/bin/terraform                                                                                                          \
    && chmod +x /usr/bin/terraform                                                                                                              \
    && rm -f terraform.zip                                                                                                                      \
    && curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v0.29.10/terragrunt_linux_amd64" -o terragrunt_linux_amd64        \
    && mv terragrunt_linux_amd64 /usr/bin/terragrunt                                                                                            \
    && chmod +x /usr/bin/terragrunt                                                                                                             \
    && rm -f terragrunt.zip                                                                                                                     \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"                                                        \
    && unzip awscliv2.zip -d ./aws/                                                                                                             \
    && ./aws/aws/install                                                                                                                        \
    && rm -rf  ./aws /root/awscliv2.zip                                                                                                         \
    && sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"                                               \
    && mkdir -p /root/.k9s                                                                                                                      \
    && curl -sL "https://raw.githubusercontent.com/derailed/k9s/master/skins/stock.yml" -o /root/.k9s/skin.yaml                                 \
    && curl -sL "https://github.com/derailed/k9s/releases/download/v0.24.13/k9s_Linux_x86_64.tar.gz" | tar xvz                                   \
    && mv k9s /usr/bin                                                                                                                          \
    && curl -sL "https://github.com/derailed/popeye/releases/download/v0.9.0/popeye_Linux_arm64.tar.gz" | tar xvz                               \
    && mv popeye /usr/bin                                                                                                                       \
    && curl -sLO "https://github.com/bcicen/ctop/releases/download/v0.7.5/ctop-0.7.5-linux-amd64"                                               \
    && mv ctop-0.7.5-linux-amd64 /usr/bin/ctop                                                                                                  \
    && chmod +x /usr/bin/ctop                                                                                                                   \
    && curl -sLO "https://github.com/atombender/ktail/releases/download/v1.0.1/ktail-linux-amd64"                                               \
    && mv ktail-linux-amd64 /usr/bin/ktail                                                                                                      \
    && chmod +x /usr/bin/ktail                                                                                                                  \
    && curl -sLO "https://github.com/k14s/kapp/releases/download/v0.37.0/kapp-linux-amd64"                                                      \
    && mv kapp-linux-amd64 /usr/bin/kapp                                                                                                        \
    && chmod +x /usr/bin/kapp                                                                                                                   \
    && curl -sLO "https://github.com/k14s/ytt/releases/download/v0.34.0/ytt-linux-amd64"                                                        \
    && mv ytt-linux-amd64 /usr/bin/ytt                                                                                                          \
    && chmod +x /usr/bin/ytt                                                                                                                    \
    && curl -sLO "https://github.com/tektoncd/cli/releases/download/v0.19.0/tkn_0.19.0_Linux_x86_64.tar.gz"                                     \
    && tar xvzf tkn_0.19.0_Linux_x86_64.tar.gz -C /usr/bin tkn                                                                                  \
    && rm -rf tkn_0.19.0_Linux_x86_64.tar.gz                                                                                                    \
    && chmod +x /usr/bin/tkn                                                                                                                    \
    && curl -sLO "https://releases.hashicorp.com/vault/1.7.2/vault_1.7.2_linux_amd64.zip"                                                       \
    && unzip  vault_1.7.2_linux_amd64.zip                                                                                                       \
    && rm -rf vault_1.7.2_linux_amd64.zip                                                                                                       \
    && mv vault /usr/bin                                                                                                                        \
    && chmod +x /usr/bin/vault                                                                                                                  \
    && curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp                  \
    && mv /tmp/eksctl /usr/local/bin                                                                                                              \
    && chmod +x /usr/local/bin/eksctl                                                                                                             \
    && curl -sL https://github.com/google/go-containerregistry/releases/download/v0.5.1/go-containerregistry_Linux_x86_64.tar.gz | tar xz -C /tmp \
    && mv /tmp/crane /usr/local/bin                                                                                                               \
    && chmod +x /usr/local/bin/crane                                                                                                              \
    && rm -rf /root/*

RUN curl -s   'https://get.sdkman.io'                | /bin/bash                                                                                  \
    && echo   'sdkman_auto_answer=true'            > $SDKMAN_DIR/etc/config                                                                       \
    && echo   'sdkman_auto_selfupdate=false'      >> $SDKMAN_DIR/etc/config                                                                       \
    && echo   'sdkman_insecure_ssl=true'          >> $SDKMAN_DIR/etc/config                                                                       \
    && zsh -c 'set +x;source /root/.sdkman/bin/sdkman-init.sh'                                                                                  \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls java   && sdk install java   11.0.11.9.1-amzn'                               \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls maven  && sdk install maven  3.8.1'                                          \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls gradle && sdk install gradle 7.0.2'                                          \
    && rm -rf /root/.sdkman/archives                                                                                                            \
    && mkdir -p /root/.sdkman/archives                                                                                                          \
    && curl -sL "https://github.com/openshift/okd/releases/download/4.7.0-0.okd-2021-06-04-191031/openshift-client-linux-4.7.0-0.okd-2021-06-04-191031.tar.gz" | tar xvz \
    && cp    -v ./oc       /usr/bin/oc                                                                                                          \
    && cp    -v ./kubectl  /usr/bin/kubectl                                                                                                     \
    && chmod +x            /usr/bin/oc                                                                                                          \
    && chmod +x            /usr/bin/kubectl                                                                                                     \
    && ls -ltr             /usr/bin/kubectl                                                                                                     \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.1/krew.yaml"                                                 \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.1/krew.tar.gz"                                               \
    && tar zxvf krew.tar.gz ; cat krew.yaml ; mkdir -p /root/.krew/bin                                                                          \
    && ./krew-linux_amd64 install --manifest=krew.yaml --archive=krew.tar.gz                                                                    \
    && ./krew-linux_amd64 update                                                                                                                \
    && /usr/bin/kubectl krew   install ctx                                                                                                      \
    && /usr/bin/kubectl krew   install ns                                                                                                       \
    && /usr/bin/kubectl krew   install images                                                                                                   \
    && /usr/bin/kubectl krew   install ingress-nginx                                                                                            \
    && /usr/bin/kubectl plugin list                                                                                                             \                                                                                      
    && curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${VERSION_KUSTOMIZE}/kustomize_${VERSION_KUSTOMIZE}_linux_amd64.tar.gz \
    && tar xvzf kustomize_${VERSION_KUSTOMIZE}_linux_amd64.tar.gz                                                                               \
    && rm       kustomize_${VERSION_KUSTOMIZE}_linux_amd64.tar.gz                                                                               \
    && mv kustomize /usr/bin/kustomize                                                                                                          \
    && chmod +x /usr/bin/kustomize                                                                                                              \
    && ls;rm -rf  krew* oc kubectl openshift-client-linux-*                                                                                     \
    && echo "Install helm plugins"                                                                                                              \
    && helm plugin install https://github.com/databus23/helm-diff && rm -rf /tmp/helm-*                                                         \
    && helm plugin install https://github.com/quintush/helm-unittest && rm -rf /tmp/helm-*                                                      \
    && curl -sL https://github.com/bitnami-labs/sealed-secrets/releases/download/${VERSION_KUBESEAL}/kubeseal-linux-amd64 -o kubeseal           \
    && mv kubeseal /usr/bin/kubeseal                                                                                                            \
    && chmod +x /usr/bin/kubeseal                                                                                                               \
    && curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o /usr/local/bin/telepresence                       \
    && chmod a+x /usr/local/bin/telepresence

#use openssh
RUN echo "Setup SSH server defaults" \
    && sed s/PasswordAuthentication.*/PasswordAuthentication\ no/ -i /etc/ssh/sshd_config                                                       \
    && sed s/GSSAPIAuthentication.*/GSSAPIAuthentication\ no/     -i /etc/ssh/sshd_config                                                       \
    && sed s/#AllowTcpForwarding.*/AllowTcpForwarding\ yes/       -i /etc/ssh/sshd_config                                                       \
    && sed s/#AllowAgentForwarding.*/AllowAgentForwarding\ yes/   -i /etc/ssh/sshd_config                                                       \
    && sed s/#PermitRootLogin.*/PermitRootLogin\ yes/             -i /etc/ssh/sshd_config                                                       \
    && sed s/#PermitTunnel.*/PermitTunnel\ yes/                   -i /etc/ssh/sshd_config                                                       \
    && sed s/#UseDNS.*/UseDNS\ no/                                -i /etc/ssh/sshd_config                                                       \
    && cat /etc/ssh/sshd_config | grep yes

#add dimetron user
ADD https://github.com/dimetron.keys /root/.ssh/authorized_keys
ADD kubectl.zsh /root/
RUN echo "Create default ssh keys"                                                                                                              \
    && passwd -d root                                                                                                                           \
    && ssh-keygen -A                                                                                                                            \
    && echo "export TERM=xterm-256color" >> .zshrc                                                                                              \
    && echo "alias vi=vim"    >> .zshrc                                                                                                         \
    && echo "alias k=kubectl" >> .zshrc                                                                                                         \
    && echo "alias kns='kubectl config set-context --current --namespace'" >> .zshrc                                                            \
    && echo 'source <(kubectl completion zsh)' >> .zshrc                                                                                        \
    && echo 'complete -F __start_kubectl k'    >> .zshrc                                                                                        \
    && echo 'source kubectl.zsh'  >> .zshrc                                                                                                     \
    && echo "RPROMPT='%{\$fg[blue]%}(\$ZSH_KUBECTL_NAMESPACE)%{\$reset_color%}'"  >> .zshrc                                                      \
    && echo 'eval $(starship init zsh)'                                           >> .zshrc                                                      \
    && sed 's/\(^plugins=([^)]*\)/\1 kubectl/' -i .zshrc                                                                                        \
    && sed 's/robbyrussell/af-magic/g' -i .zshrc                                                                                                \
    && sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes                                                                            \
    && mkdir -p ~/.config 
    
ADD starship.toml /root/.config/starship.toml
    
#COPY rootfs /
#ENTRYPOINT ["/entrypoint.sh"]
RUN groupadd -r devops

RUN echo " ---------- Verify ----------"    \
    && which docker                         \
    && which skopeo                         \
    && which sshuttle                       \
    && which kubectl                        \
    && which aws

CMD tail -f /dev/null