FROM amazonlinux:latest

LABEL maintainer="Dmytro Rashko <drashko@me.com>"

## Environment variables required for this build (do NOT change)
ENV IMAGE_VER=2.34
ENV VERSION_HELM3=3.5.2
ENV VERSION_KIND=0.10.0
ENV VERSION_TERRAFORM=0.14.9

#https://github.com/helm/helm/releases

ENV SDKMAN_DIR=/root/.sdkman
ENV TERM=xterm

ENV HELM2_BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV HELM2_TAR_FILE="helm-v${VERSION_HELM2}-linux-amd64.tar.gz"

ENV HELM3_BASE_URL="https://get.helm.sh"
ENV HELM3_TAR_FILE="helm-v${VERSION_HELM3}-linux-amd64.tar.gz"

# set environment variables
RUN echo "LANG=en_US.utf-8" >> /etc/environment \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment

WORKDIR /root

#COPY docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN echo "Installing additional software" \
    && curl https://bintray.com/loadimpact/rpm/rpm -o /etc/yum.repos.d/bintray-loadimpact-rpm.repo \
    && amazon-linux-extras install epel docker -y  \
    && curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/devel:kubic:libcontainers:stable.repo \
    && yum -y install yum-plugin-copr \
    && yum -y copr enable lsm5/container-selinux \
    && yum -y update  \
    && yum -y upgrade  \
    && yum -y install \
       yum-utils device-mapper-persistent-data lvm2 sudo \
       docker-ce-cli conntrack-tools torsocks iptables   \
       which wget zip unzip jq tar passwd openssl openssh openssh-server squid dnsmasq socat tmux iputils       \
       bash sshpass hostname curl ca-certificates libstdc++ git zip unzip sed vim-enhanced mosh                 \
       python37 gcc python3-devel sshuttle  bash zsh procps rsync mc htop skopeo ansible findutils jq k6 bzip2  \
       shadow-utils iptraf tcpdump net-tools httpie \
    && rpm -ivh https://packagecloud.io/datawireio/telepresence/packages/fedora/31/telepresence-0.108-1.x86_64.rpm/download.rpm --nodeps \
    #&& pip install --upgrade pip sshuttle \
    #update python due to CVE' https://alas.aws.amazon.com/AL2/ALAS-2020-1483.html
    && yum -y update python \
    && yum -y clean all     \
    && rm -rf /var/lib/{cache,log} /var/log/lastlog /opt/couchbase/samples /usr/bin/dockerd-ce /usr/bin/containerd \
    && mkdir /var/log/lastlog

RUN echo "Verify required tools installed" \
    && which docker \
    && which skopeo \
    && which sshuttle

RUN curl -sLo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v${VERSION_KIND}/kind-$(uname)-amd64" \
    && mv kind  /usr/bin \
    && chmod +x /usr/bin/kind

RUN curl -sL "${HELM3_BASE_URL}/${HELM3_TAR_FILE}" | tar xvz && \
    mv linux-amd64/helm /usr/bin/helm3 && \
    chmod +x /usr/bin/helm3 &&            \
    rm -rf linux-amd64

RUN ln -s /usr/bin/helm3 /usr/bin/helm

#install terraform
RUN curl -sL "https://releases.hashicorp.com/terraform/$VERSION_TERRAFORM/terraform_${VERSION_TERRAFORM}_linux_amd64.zip" -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/bin/terraform \
    && chmod +x /usr/bin/terraform \
    && rm -f terraform.zip

#install terragrunt
RUN curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v0.28.18/terragrunt_linux_amd64" -o terragrunt_linux_amd64 \
    && mv terragrunt_linux_amd64 /usr/bin/terragrunt \
    && chmod +x /usr/bin/terragrunt \
    && rm -f terragrunt.zip

#add aws
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install      \
    && rm -rf  ./aws /root/awscliv2.zip

#install ZSH custom theme
RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

RUN curl -s "https://get.sdkman.io" | /bin/bash && \
    echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config && \
    echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config && \
    echo "sdkman_insecure_ssl=true" >> $SDKMAN_DIR/etc/config

#k9s https://github.com/derailed/k9s/releases
RUN mkdir -p /root/.k9s && \
    curl -sL "https://raw.githubusercontent.com/derailed/k9s/master/skins/stock.yml" -o /root/.k9s/skin.yaml && \
    curl -sL "https://github.com/derailed/k9s/releases/download/v0.24.7/k9s_Linux_x86_64.tar.gz" | tar xvz      && \
    mv k9s /usr/bin

#popeye
RUN curl -sL "https://github.com/derailed/popeye/releases/download/v0.9.0/popeye_Linux_arm64.tar.gz" | tar xvz && \
    mv popeye /usr/bin

#ctop https://github.com/bcicen/ctop/releases/tag/v0.7.5
RUN curl -sLO "https://github.com/bcicen/ctop/releases/download/v0.7.5/ctop-0.7.5-linux-amd64" && \
    mv ctop-0.7.5-linux-amd64 /usr/bin/ctop && \
    chmod +x /usr/bin/ctop

#ktail
RUN curl -sLO "https://github.com/atombender/ktail/releases/download/v1.0.1/ktail-linux-amd64" && \
    mv ktail-linux-amd64 /usr/bin/ktail && \
    chmod +x /usr/bin/ktail

#kapp
RUN curl -sLO "https://github.com/k14s/kapp/releases/download/v0.36.0/kapp-linux-amd64" && \
    mv kapp-linux-amd64 /usr/bin/kapp && \
    chmod +x /usr/bin/kapp

#ytt
RUN curl -sLO "https://github.com/k14s/ytt/releases/download/v0.30.0/ytt-linux-amd64" && \
    mv ytt-linux-amd64 /usr/bin/ytt && \
    chmod +x /usr/bin/ytt

#tekton
RUN curl -sLO "https://github.com/tektoncd/cli/releases/download/v0.15.0/tkn_0.15.0_Linux_x86_64.tar.gz" && \
    tar xvzf tkn_0.15.0_Linux_x86_64.tar.gz -C /usr/bin tkn && \
    rm -rd tkn_0.15.0_Linux_x86_64.tar.gz && \
    chmod +x /usr/bin/tkn

#vault
RUN curl -sLO "https://releases.hashicorp.com/vault/1.6.1/vault_1.6.1_linux_amd64.zip" && \
    unzip  vault_1.6.1_linux_amd64.zip && \
    rm -rf vault_1.6.1_linux_amd64.zip && \
    mv vault /usr/bin && \
    chmod +x /usr/bin/vault

#aws auth
#RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator && \
#    mv aws-iam-authenticator /usr/bin/aws-iam-authenticator && \
#    chmod +x /usr/bin/aws-iam-authenticator

#eksctl
RUN curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    chmod +x /usr/local/bin/eksctl

#install maven and java 11
RUN echo "Install JAVA MAVEN" \
    && zsh -c 'set +x;source /root/.sdkman/bin/sdkman-init.sh' \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk install maven' \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk install gradle 6.8.3' \
    && zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls java && sdk install java 11.0.10.9.1-amzn' \
    && rm -rf /root/.sdkman/archives \
    && mkdir -p /root/.sdkman/archives

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.sdkman/bin:/root/.sdkman/candidates/gradle/current/bin:/root/.sdkman/candidates/maven/current/bin:/root/.krew/bin

#RUN curl -sL "https://github.com/openshift/okd/releases/download/4.5.0-0.okd-2020-10-15-235428/openshift-client-linux-4.5.0-0.okd-2020-10-15-235428.tar.gz" | tar xvz && \
RUN curl -sL "https://github.com/openshift/okd/releases/download/4.6.0-0.okd-2021-01-23-132511/openshift-client-linux-4.6.0-0.okd-2021-01-23-132511.tar.gz" | tar xvz && \
    cp oc /usr/bin/ && \
    cp kubectl /usr/bin/ && \
    rm -rf  openshift-client-linux-*

#install krew for kubectl - seems depends on latest k
#https://github.com/kubernetes-sigs/krew-index/blob/master/plugins.md
#https://github.com/kubernetes-sigs/krew/releases/download/v0.4.1/krew.tar.gz
RUN curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.1/krew.yaml" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.1/krew.tar.gz"  \
    && tar zxvf krew.tar.gz ; cat krew.yaml ; mkdir -p /root/.krew/bin \
    && ./krew-linux_amd64 install --manifest=krew.yaml --archive=krew.tar.gz \
    && ./krew-linux_amd64 update            \
    && rm -rf krew*                         \
    && kubectl krew install ctx            \
    && kubectl krew install ns             \
    && kubectl krew install images         \
    && kubectl krew install ingress-nginx  \
    && kubectl plugin list

#fix sshuttle
RUN pip3 install --upgrade pip sshuttle yq

#use openssh
RUN echo "Setup SSH server defaults" \
  && sed s/PasswordAuthentication.*/PasswordAuthentication\ no/ -i /etc/ssh/sshd_config  \
  && sed s/GSSAPIAuthentication.*/GSSAPIAuthentication\ no/     -i /etc/ssh/sshd_config  \
  && sed s/#AllowTcpForwarding.*/AllowTcpForwarding\ yes/       -i /etc/ssh/sshd_config  \
  && sed s/#AllowAgentForwarding.*/AllowAgentForwarding\ yes/   -i /etc/ssh/sshd_config  \
  && sed s/#PermitRootLogin.*/PermitRootLogin\ yes/             -i /etc/ssh/sshd_config  \
  && sed s/#PermitTunnel.*/PermitTunnel\ yes/                   -i /etc/ssh/sshd_config  \
  && sed s/#UseDNS.*/UseDNS\ no/                                -i /etc/ssh/sshd_config  \
  && cat /etc/ssh/sshd_config | grep yes

#add dimetron user
ADD https://github.com/dimetron.keys /root/.ssh/authorized_keys
ADD kubectl.zsh /root/
RUN echo "Create default ssh keys " \
    && passwd -d root    \
    && ssh-keygen -A     \
    && echo "export TERM=xterm-256color" >> .zshrc \
    && echo "alias vi=vim"    >> .zshrc \
    && echo "alias k=kubectl" >> .zshrc \
    && echo "alias kns='kubectl config set-context --current --namespace'" >> .zshrc \
    && echo 'source <(kubectl completion zsh)' >> .zshrc \
    && echo 'complete -F __start_kubectl k'    >> .zshrc \
    && echo 'source kubectl.zsh'  >> .zshrc \
    && echo "RPROMPT='%{\$fg[blue]%}(\$ZSH_KUBECTL_NAMESPACE)%{\$reset_color%}'" >> .zshrc \
    && sed 's/\(^plugins=([^)]*\)/\1 kubectl/' -i .zshrc \
    && sed 's/robbyrussell/af-magic/g' -i .zshrc

#COPY rootfs /
#ENTRYPOINT ["/entrypoint.sh"]
RUN groupadd -r devops
    
CMD tail -f /dev/null