FROM debian:9-slim

LABEL vendor="Mintel"
LABEL maintainer "fciocchetti@mintel.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install \
      apt-transport-https \
      bash \
      bsdmainutils \
      dnsutils \
      ca-certificates \
      curl \
      git \
      gnupg2 \
      g++ \
      libssl-dev \
      make \
      openssl \
      openssh-client \
      pass \
      procps \
      python3-virtualenv \
      python3-pip \
      python3-pkg-resources \
      software-properties-common \
      wget \
      unzip && \
    wget -q -O- https://download.docker.com/linux/debian/gpg | apt-key add - && \
    wget -q -O- https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" >> /etc/apt/sources.list && \
    echo "deb https://packages.cloud.google.com/apt cloud-sdk-stretch -c -s) main" >> /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get -y update && \
    apt-get -y install docker-ce-cli google-cloud-sdk && \
    apt-get -y purge aptitude && \
     apt-get -y autoremove && apt-get -y clean


ENV YAML2JSON_VERSION=1.3 \
    YAML2JSON_SHA256=e792647dd757c974351ea4ad35030852af97ef9bbbfb9594f0c94317e6738e55 \
    YQ_VERSION=2.3.0 \
    YQ_SHA256=97b2c61ae843a429ce7e5a2c470cfeea1c9e9bf317793b41983ef228216fe31b \
    KUSTOMIZE_VERSION=2.0.3 \
    KUSTOMIZE_SHA256=a04d79a013827c9ebb0abfe9d41cbcedf507a0310386c8d9a7efec7a36f9d7a3 \
    MINIKUBE_VERSION=1.0.1 \
    MINIKUBE_SHA256=7b56374955990ef2dd0289e6ecb62cf2b4587cab2b481d95f58de5db56799868 \
    KUBECTL_VERSION=1.12.5 \
    KUBECTL_SHA256=f52abcfbcb74f590a2229364afee11271ce597add3eeceefc1dc174590e2dff8 \
    VAULT_VERSION=1.1.1 \
    VAULT_SHA256=134261417c8129a92992cba75bf7ebce8ee4d6100de18b722cce7507782e272c \
    KIND_VERSION=0.2.1 \
    KIND_SHA256=4493aaaffb997a07ef15f04ae0ed1b935cd4b648885b79f4fd48977ff4906b8d \
    TERRAFORM_VERSION=0.11.11 \
    TERRAFORM_SHA256=94504f4a67bad612b5c8e3a4b7ce6ca2772b3c1559630dfd71e9c519e3d6149c \
    TERRAGRUNT_VERSION=0.18.4 \
    TERRAGRUNT_SHA256=4c6214733eab284725dbbcd7eee17ef072501b817b42178b58310e2a2ed67dc0 \
    GITCRYPT_VERSION=0.6.0 \
    GITCRYPT_SHA256=777c0c7aadbbc758b69aff1339ca61697011ef7b92f1d1ee9518a8ee7702bb78 \
    TERRAFORM_CT_PROVIDER_VERSION=0.3.0 \
    TERRAFORM_CT_PROVIDER_SHA256=3d023545e08a90f792714998866ae8f8bab60bfbd583932c1c978133886d344c \
    KUBECFG_VERSION=0.11.0 \
    KUBECFG_SHA256=08a74ff85a8544e99cc6aa08c1e7e80e4c3d08ba6ce0730ccbf41d3a514ecb86 \
    JSONNET_VERSION=0.12.1 \
    JSONNET_SHA256=257c6de988f746cc90486d9d0fbd49826832b7a2f0dbdb60a515cc8a2596c950 \
    JQ_VERSION=1.5 \
    JQ_SHA256=c6b3a7d7d3e7b70c6f51b706a3b90bd01833846c54d32ca32f0027f00226ff6d \
    BASH_UNIT_VERSION=1.6.1 \
    BASH_UNIT_SHA256=596c2bcbcebcc5611e3f2e1458b0f4be1adad8f91498b20e97c9f7634416950f \
    TEST_SSL_VERSION=3.0rc5 \
    TEST_SSL_SHA256=6118f08b88c0075f39820296f0d76889165dd67e64dbfdfd1104d6d122a938c9 \
    KUBESEAL_VERSION=0.5.1 \
    KUBESEAL_SHA256=c8a9dd32197c6ce3420a0d2c78dd7b3963bae03f53c9c1d032d0279fabfe2cb9

WORKDIR /tmp

#yaml2json
RUN set -e \
    && wget -q -O /usr/local/bin/yaml2json https://github.com/bronze1man/yaml2json/releases/download/v${YAML2JSON_VERSION}/yaml2json_linux_amd64 \
    && chmod +x /usr/local/bin/yaml2json \
    && cd /usr/local/bin \
    && echo "$YAML2JSON_SHA256  yaml2json" | sha256sum -c

#yq
RUN set -e \
    && wget -q -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq \
    && cd /usr/local/bin \
    && echo "$YQ_SHA256  yq" | sha256sum -c

# kustomize
RUN set -e \
    && wget -q -O /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64 \
    && chmod +x /usr/local/bin/kustomize \
    && cd /usr/local/bin \
    && echo "$KUSTOMIZE_SHA256  kustomize" | sha256sum -c

# minikube
RUN set -e \
    && wget -q -O /usr/local/bin/minikube https://github.com/kubernetes/minikube/releases/download/v${MINIKUBE_VERSION}/minikube-linux-amd64 \
    && chmod +x /usr/local/bin/minikube \
    && cd /usr/local/bin \
    && echo "$MINIKUBE_SHA256  minikube" | sha256sum -c

# kubectl
RUN set -e \
    && wget -q -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && cd /usr/local/bin \
    && echo "$KUBECTL_SHA256  kubectl" | sha256sum -c

# vault
RUN set -e \
    && wget -q -O /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
    && echo "$VAULT_SHA256  vault.zip" | sha256sum -c \
    && unzip vault.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/vault \
    && rm -f vault.zip

# jsonnet
RUN set -e \
    && curl -L https://github.com/google/jsonnet/archive/v${JSONNET_VERSION}.tar.gz -o /tmp/jsonnet.tar.gz \
    && echo "$JSONNET_SHA256  jsonnet.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/jsonnet.tar.gz  -C /tmp \
    && cd /tmp/jsonnet-$JSONNET_VERSION && make && mv jsonnet /usr/local/bin && chmod a+x /usr/local/bin/jsonnet \
    && rm -rf /tmp/jsonnet.tar.gz /tmp/jsonnet-$JSONNET_VERSION

# terraform
RUN set -e \
    && curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform.zip \
    && echo "$TERRAFORM_SHA256  terraform.zip" | sha256sum -c \
    && unzip terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm -f terraform.zip

# terragrunt
RUN set -e \
    && curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o /tmp/terragrunt \
    && echo "$TERRAGRUNT_SHA256  terragrunt" | sha256sum -c \
    && mv /tmp/terragrunt /usr/local/bin \
    && chmod +x /usr/local/bin/terragrunt

# terraform-ct-provider
RUN set -e \
    && curl -L https://github.com/coreos/terraform-provider-ct/releases/download/v${TERRAFORM_CT_PROVIDER_VERSION}/terraform-provider-ct-v${TERRAFORM_CT_PROVIDER_VERSION}-linux-amd64.tar.gz -o /tmp/terraform-ct-provider.tar.gz \
    && echo "$TERRAFORM_CT_PROVIDER_SHA256  terraform-ct-provider.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/terraform-ct-provider.tar.gz  -C /tmp \
    && mv /tmp/terraform-provider-ct-v${TERRAFORM_CT_PROVIDER_VERSION}-linux-amd64/terraform-provider-ct /usr/local/bin \
    && rm -f /tmp/terraform-ct-provider.tar.gz

# bash_unit
RUN set -e \
    && curl -L https://github.com/pgrange/bash_unit/archive/v${BASH_UNIT_VERSION}.tar.gz -o /tmp/bash_unit.tar.gz \
    && echo "$BASH_UNIT_SHA256  bash_unit.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/bash_unit.tar.gz  -C /tmp \
    && mv /tmp/bash_unit-${BASH_UNIT_VERSION}/bash_unit /usr/local/bin \
    && chmod a+x /usr/local/bin \
    && rm -f /tmp/bash_unit.tar.gz

# kubecfg
RUN set -e \
    && curl -L https://github.com/ksonnet/kubecfg/releases/download/v${KUBECFG_VERSION}/kubecfg-linux-amd64 -o /tmp/kubecfg \
    && chmod +x /tmp/kubecfg \
    && echo "$KUBECFG_SHA256  kubecfg" | sha256sum -c \
    && mv /tmp/kubecfg /usr/local/bin

# kubeseal
RUN set -e \
    && curl -L https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-linux-amd64 -o /tmp/kubeseal \
    && chmod +x /tmp/kubeseal \
    && echo "$KUBESEAL_SHA256  kubeseal" | sha256sum -c \
    && mv /tmp/kubeseal /usr/local/bin

# JQ
RUN set -e \
    && curl -L https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -o /tmp/jq \
    && chmod +x /tmp/jq \
    && echo "$JQ_SHA256  jq" | sha256sum -c \
    && mv /tmp/jq /usr/local/bin

# testssl.sh
RUN set -e \
    && curl -L https://github.com/drwetter/testssl.sh/archive/${TEST_SSL_VERSION}.tar.gz -o /tmp/testssl.tar.gz \
    && echo "$TEST_SSL_SHA256  testssl.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/testssl.tar.gz  -C /tmp \
    && mv /tmp/testssl.sh-${TEST_SSL_VERSION} /tmp/testssl.sh \
    && rm -f /tmp/testssl.tar.gz

# Kind
RUN set -e \
    && wget -q -O /usr/local/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64 \
    && cd /usr/local/bin \
    && chmod +x /usr/local/bin/kind \
    && echo "$KIND_SHA256  kind" | sha256sum -c

## TODO - clean build requirements
# git-crypt
RUN set -e \
    && curl -L https://github.com/AGWA/git-crypt/archive/$GITCRYPT_VERSION.tar.gz -o /tmp/git-crypt.tar.gz \
    && echo "$GITCRYPT_SHA256  git-crypt.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/git-crypt.tar.gz  -C /tmp \
    && cd /tmp/git-crypt-$GITCRYPT_VERSION && make && make install PREFIX=/usr/local \
    && rm -rf /tmp/git-crypt.tar.gz /tmp/git-crypt-$GITCRYPT_VERSION

# Install LETSENCRYPT staging fake root ca
RUN set -e \
    && curl -o /usr/local/share/ca-certificates/fakelerootx1.crt https://letsencrypt.org/certs/fakelerootx1.pem \
    && curl -o /usr/local/share/ca-certificates/fakeleintermediatex1.crt https://letsencrypt.org/certs/fakeleintermediatex1.pem \
    && update-ca-certificates

COPY --from=mintel/k8s-yaml-splitter /k8s-yaml-splitter /usr/local/bin/k8s-yaml-splitter

USER 0
COPY resources/ /

RUN useradd -ms /bin/bash mintel
USER mintel

RUN set -e \
    && pip3 install yamllint

# Configure support for terraform-ct-provider
RUN echo 'providers {\n \
ct = "/usr/local/bin/terraform-provider-ct"\n \
}\n' >> /home/mintel/.terraformrc

# Extend PATH for mintel user
RUN echo 'PATH=$HOME/.local/bin:$PATH' >> /home/mintel/.bashrc


ENV DOCKER_HOST_ALIAS=docker \
    KIND_NODES=0

# Don't use a real entrypoint 
ENTRYPOINT ["/usr/bin/env"]
