ARG BASE_IMAGE=dimetron/os-base:3.0

FROM $BASE_IMAGE
LABEL maintainer="Dmytro Rashko <drashko@me.com>"

## Environment variables required for this build (do NOT change)

ENV IMAGE_VER=3.0

ARG VERSION_KIND=0.11.1
ARG VERSION_HELM3=3.8.0
ARG VERSION_TERRAFORM=1.1.3
ARG VERSION_TERAGRUNT=v0.35.17
ARG VERSION_KUSTOMIZE=v4.4.0
ARG VERSION_KUBESEAL=v0.16.0
ARG VERSION_VAULT=1.9.2

ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM

ENV SDKMAN_DIR=/root/.sdkman
ENV TERM=xterm-256color
ENV DEBIAN_FRONTEND="noninteractive"

#includes all below sdk required path
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.sdkman/bin:/root/.sdkman/candidates/gradle/current/bin:/root/.sdkman/candidates/maven/current/bin:/root/.krew/bin

# set environment variables and DNS to make build pass on Docker buildkit
RUN echo "LANG=en_US.utf-8"   >> /etc/environment \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment \
 && echo "fastestmirror=0"    >> /etc/dnf/dnf.conf

WORKDIR /root


RUN echo "Utils"                                                                                                                                  \
    && curl -sLS https://get.arkade.dev | sh                                                                                                      \
    && curl -sLo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v${VERSION_KIND}/kind-$(uname)-${TARGETARCH}"                  \
    && mv kind  /usr/bin                                                                                                                          \
    && chmod +x /usr/bin/kind                                                                                                                     

RUN curl -sL "https://get.helm.sh/helm-v${VERSION_HELM3}-linux-${TARGETARCH}.tar.gz"   | tar xvz                                                  \
    && ls                                                                                                                                         \
    && mv linux-${TARGETARCH}/helm /usr/bin/helm3                                                                                                 \
    && chmod +x /usr/bin/helm3                                                                                                                    \
    && rm -rf linux-${TARGETARCH}                                                                                                                 \
    && ln -s /usr/bin/helm3 /usr/bin/helm

RUN curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/${VERSION_TERAGRUNT}/terragrunt_linux_${TARGETARCH}" -o terragrunt_linux_${TARGETARCH}        \
    && mv terragrunt_linux_${TARGETARCH} /usr/bin/terragrunt                                                                                      \
    && chmod +x /usr/bin/terragrunt

RUN curl -sL https://raw.githubusercontent.com/derailed/k9s/master/skins/stock.yml --create-dirs -o /root/.config/k9s/skin.yaml                   \
    && curl -sL https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_x86_64.tar.gz -o k9s_amd64.tar.gz                            \
    && curl -sL https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_arm64.tar.gz  -o k9s_arm64.tar.gz                            \
    && tar  -xvf k9s_${TARGETARCH}.tar.gz                                                                                                         \
    && rm -f *.tar                                                                                                                                \
    && mv k9s /usr/bin

RUN curl -sL "https://github.com/derailed/popeye/releases/download/v0.9.8/popeye_Linux_x86_64.tar.gz" -o popeye_Linux_amd64.tar.gz                 \
    && curl -sL "https://github.com/derailed/popeye/releases/download/v0.9.8/popeye_Linux_arm64.tar.gz" -o popeye_Linux_arm64.tar.gz               \
    && tar  -xvf popeye_Linux_${TARGETARCH}.tar.gz                                                                                                 \
    && mv popeye /usr/bin
    
RUN curl -sLO "https://github.com/bcicen/ctop/releases/download/v0.7.6/ctop-0.7.6-linux-${TARGETARCH}"                                             \
    && mv ctop-0.7.6-linux-${TARGETARCH} /usr/bin/ctop                                                                                             \
    && chmod +x /usr/bin/ctop                                                                                                                     
    
RUN curl -sLO "https://github.com/atombender/ktail/releases/download/v1.0.1/ktail-linux-${TARGETARCH}"                                             \
    && mv ktail-linux-${TARGETARCH} /usr/bin/ktail                                                                                                 \
    && chmod +x /usr/bin/ktail

RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip     -o awscliv2_amd64.zip                                                          \
    && curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o awscliv2_arm64.zip                                                        \
    && unzip awscliv2_${TARGETARCH}.zip -d ./aws/                                                                                                   \
    && ./aws/aws/install                                                                                                                           \
    && rm -rf  ./aws /root/*.zip

RUN curl -sL "https://releases.hashicorp.com/terraform/$VERSION_TERRAFORM/terraform_${VERSION_TERRAFORM}_linux_${TARGETARCH}.zip" -o terraform.zip \
    && unzip terraform.zip                                                                                                                         \
    && mv terraform /usr/bin/terraform                                                                                                             \
    && chmod +x /usr/bin/terraform                                                                                                                 \
    && rm -f terraform.zip

RUN curl -sL "https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.45.0/kapp-linux-${TARGETARCH}"  -o /usr/bin/kapp                        \
    && chmod +x /usr/bin/kapp                                                                                                                          \
    && curl -sL "https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.38.0/ytt-linux-${TARGETARCH}" -o /usr/bin/ytt                         \
    && chmod +x /usr/bin/ytt                                                                                                                           \
    && curl -sLO "https://releases.hashicorp.com/vault/${VERSION_VAULT}/vault_${VERSION_VAULT}_linux_${TARGETARCH}.zip"                                \
    && unzip  vault_${VERSION_VAULT}_linux_${TARGETARCH}.zip                                                                                           \
    && rm -rf vault_${VERSION_VAULT}_linux_${TARGETARCH}.zip                                                                                           \
    && mv vault /usr/bin                                                                                                                               \
    && chmod +x /usr/bin/vault

RUN curl -sL https://github.com/google/go-containerregistry/releases/download/v0.8.0/go-containerregistry_Linux_arm64.tar.gz  -o crane_arm64.tar.gz    \
    && curl -sL https://github.com/google/go-containerregistry/releases/download/v0.8.0/go-containerregistry_Linux_x86_64.tar.gz -o crane_amd64.tar.gz \
    && tar xvf crane_${TARGETARCH}.tar.gz  -C /tmp                                                                                                         \
    && mv /tmp/crane /usr/local/bin                                                                                                                    \
    && chmod +x /usr/local/bin/crane                                                                                                                   \
    && rm -rf /tmp/* /root/*

RUN curl -s   'https://get.sdkman.io'                | /bin/bash                                                                                  \
    && echo   'sdkman_auto_answer=true'            > $SDKMAN_DIR/etc/config                                                                       \
    && echo   'sdkman_auto_selfupdate=false'      >> $SDKMAN_DIR/etc/config                                                                       \
    && echo   'sdkman_insecure_ssl=true'          >> $SDKMAN_DIR/etc/config                                                                       \
    && zsh -c 'set +x;source /root/.sdkman/bin/sdkman-init.sh'                                                                                  \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls java   && sdk install java   11.0.13.8.1-amzn'                               \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls maven  && sdk install maven  3.8.4'                                          \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls gradle && sdk install gradle 7.3.3'                                          \
    && rm -rf /root/.sdkman/archives                                                                                                            \
    && mkdir -p /root/.sdkman/archives                                                                                                          

    #TODO: build oc binary for arm64 ??
RUN curl -sL "https://github.com/openshift/okd/releases/download/4.9.0-0.okd-2021-12-12-025847/openshift-client-linux-4.9.0-0.okd-2021-12-12-025847.tar.gz" | tar xvz \
    && cp    -v ./oc       /usr/bin/oc                                                                                                          \
    && chmod +x            /usr/bin/oc                                                                                                          \
    && rm -rf oc kubectl openshift-client-linux-*

RUN curl -sL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" -o /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl

RUN curl -sLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.2/krew-linux_${TARGETARCH}.tar.gz"                                \
    && tar zxvf krew-linux_${TARGETARCH}.tar.gz                                                                                                 \
    && curl -sLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.2/krew.yaml"                                                   \
    && cat krew.yaml ; mkdir -p /root/.krew/bin                                                                                                 \
    && ./krew-linux_${TARGETARCH} install --manifest=krew.yaml --archive=krew-linux_${TARGETARCH}.tar.gz                                        \
    && ./krew-linux_${TARGETARCH} update                                                                                                        \
    && /usr/bin/kubectl krew   install ctx                                                                                                      \
    && /usr/bin/kubectl krew   install ns                                                                                                       \
    && /usr/bin/kubectl krew   install gadget                                                                                                   \
    && /usr/bin/kubectl krew   install images                                                                                                   \
    && /usr/bin/kubectl krew   install stern                                                                                                    \
    && /usr/bin/kubectl plugin list                                                                                                             \
    && ls;rm -rf  krew*

#TODO: need this ?
#RUN curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${VERSION_KUSTOMIZE}/kustomize_${VERSION_KUSTOMIZE}_linux_${TARGETARCH}.tar.gz \
#    && tar xvzf kustomize_${VERSION_KUSTOMIZE}_linux_${TARGETARCH}.tar.gz                                                                       \
#    && rm       kustomize_${VERSION_KUSTOMIZE}_linux_${TARGETARCH}.tar.gz                                                                       \
#    && mv kustomize /usr/bin/kustomize                                                                                                          \
#    && chmod +x /usr/bin/kustomize                                                                                                              \

#TODO: missing tel2 arm64
#    && curl -fL https://app.getambassador.io/download/tel2/linux/${TARGETARCH}/latest/telepresence -o /usr/local/bin/telepresence               \
#    && chmod a+x /usr/local/bin/telepresence                                                                                                    \
#    && curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-${TARGETARCH}.tar.gz{,.sha256sum}  \
#    && sha256sum --check cilium-linux-${TARGETARCH}.tar.gz.sha256sum                                                                           \
#    && tar xzvfC cilium-linux-${TARGETARCH}.tar.gz /usr/local/bin                                                                              \
#    && rm cilium-linux-${TARGETARCH}.tar.gz{,.sha256sum}                                                                                       \
#    && rm LICENSE README.md

#TODO:
#https://github.com/grafana/k6/releases/download/v0.36.0/k6-v0.36.0-linux-amd64.tar.gz

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

RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

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
    && echo 'eval $(starship init zsh)'        >> .zshrc                                                                                        \
    # && echo 'source /root/kubectl.zsh'  >> .zshrc                                                                                             \
    # && echo "RPROMPT='%{\$fg[blue]%}(\$ZSH_KUBECTL_NAMESPACE)%{\$reset_color%}'"  >> .zshrc                                                   \
    && sed 's/\(^plugins=([^)]*\)/\1 kubectl zsh-autosuggestions/' -i .zshrc                                                                    \
    && sed 's/robbyrussell/af-magic/g' -i .zshrc                                                                                                \
    && sh -c 'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'        \
    && sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes                                                                            \
    && mkdir -p ~/.config 
    
ADD starship.toml /root/.config/starship.toml
    
#COPY rootfs /
#ENTRYPOINT ["/entrypoint.sh"]
RUN groupadd -r devops

RUN echo " ---------- Verify $(uname -mm)----------"    \
    && which docker                         \
    && which sshuttle                       \
    && which kubectl                        \
    && which aws

CMD tail -f /dev/null