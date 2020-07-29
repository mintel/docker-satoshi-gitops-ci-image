##
# Builder Golang
##

FROM golang:1.12-stretch AS go-builder

# Until terraform0.12 need tfjson2
RUN go get github.com/justinm/tfjson2
RUN go get github.com/kvz/json2hcl

# No recent release.
# https://github.com/jsonnet-bundler/jsonnet-bundler/issues/45
RUN go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb

# No releases.
RUN go get github.com/brancz/gojsontoyaml

##
# Builder Debian
##

FROM debian:10-slim as deb-builder

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_TYPE=C.UTF-8 \
    GITCRYPT_VERSION=0.6.0 \
    GITCRYPT_SHA256=777c0c7aadbbc758b69aff1339ca61697011ef7b92f1d1ee9518a8ee7702bb78 \
    JSONNET_VERSION=0.15.0 \
    JSONNET_SHA256=f9575ae2dcd769bfe2475b86695387fc57d4b4fd60b0af2dee57f37091754370

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get -y update && \
    apt-get -y install locales --no-install-recommends && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    apt-get -y install --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      g++ \
      libssl-dev \
      make \
      wget && \
      wget -q -O /tmp/jsonnet.tar.gz https://github.com/google/jsonnet/releases/download/v${JSONNET_VERSION}/jsonnet-bin-v${JSONNET_VERSION}-linux.tar.gz && \
      echo "$JSONNET_SHA256 /tmp/jsonnet.tar.gz" | sha256sum -c && \
      tar zxvf /tmp/jsonnet.tar.gz -C /tmp && \
      mv /tmp/jsonnet /usr/local/bin && chmod a+x /usr/local/bin/jsonnet && \
      mv /tmp/jsonnetfmt /usr/local/bin && chmod a+x /usr/local/bin/jsonnetfmt && \
      rm -rf /tmp/jsonnet.tar.gz && \
      wget -q -O /tmp/git-crypt.tar.gz https://github.com/AGWA/git-crypt/archive/$GITCRYPT_VERSION.tar.gz && \
      echo "$GITCRYPT_SHA256 /tmp/git-crypt.tar.gz" | sha256sum -c && \
      tar zxvf /tmp/git-crypt.tar.gz -C /tmp && \
      make -C /tmp/git-crypt-$GITCRYPT_VERSION && make -C /tmp/git-crypt-$GITCRYPT_VERSION install PREFIX=/usr/local && \
      rm -rf /tmp/git-crypt.tar.gz /tmp/git-crypt-$GITCRYPT_VERSION && \
      apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/*

##
# Main Image
##

FROM debian:10-slim

LABEL vendor="Mintel"
LABEL maintainer "fciocchetti@mintel.com"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_TYPE=C.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Clean docs
RUN echo "path-exclude /usr/share/doc/*" > /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo "path-include /usr/share/doc/*/copyright" >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo "path-exclude /usr/share/man/*" >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo "path-exclude /usr/share/groff/*" >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo "path-exclude /usr/share/info/*" >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo "path-exclude /usr/share/lintian/*" >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo "path-exclude /usr/share/linda/*" >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    find /usr/share/doc -depth -type f ! -name copyright -print0 | xargs -0 rm || true && \
    find /usr/share/doc -empty -print0 | xargs -0 rmdir || true && \
    rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/* && \
    rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*

RUN apt-get -y update && \
    apt-get -y install locales --no-install-recommends && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    apt-get -y install --no-install-recommends \
      apt-transport-https \
      bash \
      bash-completion \
      bsdmainutils \
      curl \
      dnsutils \
      ca-certificates \
      gawk \
      gettext-base \
      git \
      gnupg2 \
      make \
      openssl \
      openssh-client \
      pass \
      procps \
      python3-virtualenv \
      python3-pip \
      python3-pkg-resources \
      python3-setuptools \
      python3-wheel \
      software-properties-common \
      wget \
      unzip \
      pwgen \
      ssss \
      vim-tiny && \
    wget -q -O- https://download.docker.com/linux/debian/gpg | apt-key add - && \
    wget -q -O- https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" >> /etc/apt/sources.list && \
    echo "deb https://packages.cloud.google.com/apt cloud-sdk-stretch main" >> /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get -y update && \
    apt-get -y install --no-install-recommends docker-ce-cli google-cloud-sdk && \
    apt-get -y purge aptitude g++ libssl-dev gcc libc-dev && \
    apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/*


ENV YAML2JSON_VERSION=1.3 \
    YAML2JSON_SHA256=e792647dd757c974351ea4ad35030852af97ef9bbbfb9594f0c94317e6738e55 \
    YQ_VERSION=2.3.0 \
    YQ_SHA256=97b2c61ae843a429ce7e5a2c470cfeea1c9e9bf317793b41983ef228216fe31b \
    KUSTOMIZE_VERSION=3.5.3 \
    KUSTOMIZE_SHA256=e0b86d6fc5f46b83b9ee339e98bf265354b66d1ea9bf168a2077d6b5914afd78 \
    KUBECTL_DEFAULT_VERSION=1.15.12 \
    KUBECTL_DEFAULT_SHA256=a32b762279c33cb8d8f4198f3facdae402248c3164e9b9b664c3afbd5a27472e \
    KUBECTL_1_15_VERSION=1.15.12 \
    KUBECTL_1_15_SHA256=a32b762279c33cb8d8f4198f3facdae402248c3164e9b9b664c3afbd5a27472e \
    KUBECTL_1_14_VERSION=1.14.10 \
    KUBECTL_1_14_SHA256=7729c6612bec76badc7926a79b26e0d9b06cc312af46dbb80ea7416d1fce0b36 \
    VAULT_VERSION=1.1.3 \
    VAULT_SHA256=293b88f4d31f6bcdcc8b508eccb7b856a0423270adebfa0f52f04144c5a22ae0 \
    VAULT_SIDEKICK_VERSION=0.3.10 \
    VAULT_SIDEKICK_SHA256=484c6ae5f47ba01989b176f3eb7ce565c3edcce31522187c74129d58cbf829b5 \
    DUMB_INIT_VERSION=1.2.2 \
    DUMB_INIT_SHA256=37f2c1f0372a45554f1b89924fbb134fc24c3756efaedf11e07f599494e0eff9 \
    KIND_VERSION=0.7.0 \
    KIND_SHA256=0e07d5a9d5b8bf410a1ad8a7c8c9c2ea2a4b19eda50f1c629f1afadb7c80fae7 \
    TERRAFORM_VERSION=0.12.29 \
    TERRAFORM_SHA256=872245d9c6302b24dc0d98a1e010aef1e4ef60865a2d1f60102c8ad03e9d5a1d \
    TERRAGRUNT_VERSION=0.23.31 \
    TERRAGRUNT_SHA256=efd124c2b9f406c0eb81b646e6b9eb32056095b38a130e6dc9a27d4be9bc25d9 \
    TERRAFORM_CT_PROVIDER_VERSION=0.4.0 \
    TERRAFORM_CT_PROVIDER_SHA256=b9ddb666fd566f865ff93368f46101ab64f0f2a1c7f44e1a924153277ef3a005 \
    KUBECFG_VERSION=0.14.0 \
    KUBECFG_SHA256=bb1455ec70f93d6f0fd344becec2f1617837a879e8363272d3216bf44c04cb2c \
    JQ_VERSION=1.5 \
    JQ_SHA256=c6b3a7d7d3e7b70c6f51b706a3b90bd01833846c54d32ca32f0027f00226ff6d \
    BASH_UNIT_VERSION=1.6.1 \
    BASH_UNIT_SHA256=596c2bcbcebcc5611e3f2e1458b0f4be1adad8f91498b20e97c9f7634416950f \
    TEST_SSL_VERSION=3.0rc5 \
    TEST_SSL_SHA256=6118f08b88c0075f39820296f0d76889165dd67e64dbfdfd1104d6d122a938c9 \
    KUBESEAL_VERSION=0.5.1 \
    KUBESEAL_SHA256=c8a9dd32197c6ce3420a0d2c78dd7b3963bae03f53c9c1d032d0279fabfe2cb9 \
    CONFTEST_VERSION=0.19.0 \
    CONFTEST_SHA256=fe1112979b081cfd7a2f5bdbf1d5e2521a649ff77efb4c2a528e70de37a8f9c8 \
    STERN_VERSION=1.11.0 \
    STERN_SHA256=e0b39dc26f3a0c7596b2408e4fb8da533352b76aaffdc18c7ad28c833c9eb7db \
    FLUXCTL_VERSION=1.20.0 \
    FLUXCTL_SHA256=790450b7fb3cbb5decc060223e489bce3459753b5e77e7bac1adeee8db41eb21


#yaml2json
RUN set -e \
    && wget -q -O /usr/local/bin/yaml2json https://github.com/bronze1man/yaml2json/releases/download/v${YAML2JSON_VERSION}/yaml2json_linux_amd64 \
    && chmod +x /usr/local/bin/yaml2json \
    && echo "$YAML2JSON_SHA256 /usr/local/bin/yaml2json" | sha256sum -c \
#yq
    && wget -q -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq \
    && echo "$YQ_SHA256 /usr/local/bin/yq" | sha256sum -c \
# kustomize
    && wget -q -O /tmp/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && echo "$KUSTOMIZE_SHA256 /tmp/kustomize.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/kustomize.tar.gz -C /tmp \
    && mv /tmp/kustomize /usr/local/bin/kustomize \
    && chmod +x /usr/local/bin/kustomize \
# kubectl (default version)
    && wget -q -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_DEFAULT_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && echo "$KUBECTL_DEFAULT_SHA256 /usr/local/bin/kubectl" | sha256sum -c \
# kubectl 1.15
    && wget -q -O /usr/local/bin/kubectl_v1.15 https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_1_15_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl_v1.15 \
    && echo "$KUBECTL_1_15_SHA256 /usr/local/bin/kubectl_v1.15" | sha256sum -c \
# kubectl 1.14
    && wget -q -O /usr/local/bin/kubectl_v1.14 https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_1_14_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl_v1.14 \
    && echo "$KUBECTL_1_14_SHA256 /usr/local/bin/kubectl_v1.14" | sha256sum -c \
# vault
    && wget -q -O /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
    && echo "$VAULT_SHA256 /tmp/vault.zip" | sha256sum -c \
    && unzip /tmp/vault.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/vault \
    && rm -rf /tmp/* \
# vault-sidekick
    && wget -q -O /usr/local/bin/vault-sidekick https://github.com/UKHomeOffice/vault-sidekick/releases/download/v${VAULT_SIDEKICK_VERSION}/vault-sidekick_linux_amd64 \
    && chmod +x /usr/local/bin/vault-sidekick \
    && echo "$VAULT_SIDEKICK_SHA256 /usr/local/bin/vault-sidekick" | sha256sum -c \
# dumb-init
    && wget -q -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 \
    && chmod +x /usr/local/bin/dumb-init \
    && echo "$DUMB_INIT_SHA256 /usr/local/bin/dumb-init" | sha256sum -c \
# terraform
    && wget -q -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && echo "$TERRAFORM_SHA256 /tmp/terraform.zip" | sha256sum -c \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm -rf /tmp/* \
# terragrunt
    && wget -q -O /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
    && echo "$TERRAGRUNT_SHA256 /usr/local/bin/terragrunt" | sha256sum -c \
    && chmod +x /usr/local/bin/terragrunt \
# terraform-ct-provider
    && wget -q -O /tmp/terraform-ct-provider.tar.gz https://github.com/coreos/terraform-provider-ct/releases/download/v${TERRAFORM_CT_PROVIDER_VERSION}/terraform-provider-ct-v${TERRAFORM_CT_PROVIDER_VERSION}-linux-amd64.tar.gz \
    && echo "$TERRAFORM_CT_PROVIDER_SHA256 /tmp/terraform-ct-provider.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/terraform-ct-provider.tar.gz -C /tmp \
    && mv /tmp/terraform-provider-ct-v${TERRAFORM_CT_PROVIDER_VERSION}-linux-amd64/terraform-provider-ct /usr/local/bin \
    && rm -rf /tmp/* \
# bash_unit
    && wget -q -O /tmp/bash_unit.tar.gz https://github.com/pgrange/bash_unit/archive/v${BASH_UNIT_VERSION}.tar.gz \
    && echo "$BASH_UNIT_SHA256 /tmp/bash_unit.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/bash_unit.tar.gz -C /tmp \
    && mv /tmp/bash_unit-${BASH_UNIT_VERSION}/bash_unit /usr/local/bin/bash_unit \
    && chmod a+x /usr/local/bin/bash_unit \
    && rm -rf /tmp/* \
# kubecfg
    && wget -q -O /usr/local/bin/kubecfg https://github.com/ksonnet/kubecfg/releases/download/v${KUBECFG_VERSION}/kubecfg-linux-amd64 \
    && chmod +x /usr/local/bin/kubecfg \
    && echo "$KUBECFG_SHA256 /usr/local/bin/kubecfg" | sha256sum -c \
# kubeseal
    && wget -q -O /usr/local/bin/kubeseal https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-linux-amd64 \
    && chmod +x /usr/local/bin/kubeseal \
    && echo "$KUBESEAL_SHA256 /usr/local/bin/kubeseal" | sha256sum -c \
# JQ
    && wget -q -O /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 \
    && chmod +x /usr/local/bin/jq \
    && echo "$JQ_SHA256 /usr/local/bin/jq" | sha256sum -c \
# Kind
    && wget -q -O /usr/local/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64 \
    && chmod +x /usr/local/bin/kind \
    && echo "$KIND_SHA256 /usr/local/bin/kind" | sha256sum -c \
# conftest
    && wget -q -O /tmp/conftest.tar.gz https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz \
    && echo "$CONFTEST_SHA256 /tmp/conftest.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/conftest.tar.gz -C /tmp \
    && mv /tmp/conftest /usr/local/bin/conftest \
    && chmod +x /usr/local/bin/conftest \
    && rm -f /tmp/* \
# stern
    && wget -q -O /usr/local/bin/stern https://github.com/wercker/stern/releases/download/${STERN_VERSION}/stern_linux_amd64 \
    && echo "$STERN_SHA256 /usr/local/bin/stern" | sha256sum -c \
    && chmod a+x /usr/local/bin/stern \
# fluxctl
    && wget -q -O /usr/local/bin/fluxctl https://github.com/fluxcd/flux/releases/download/${FLUXCTL_VERSION}/fluxctl_linux_amd64 \
    && echo "$FLUXCTL_SHA256 /usr/local/bin/fluxctl" | sha256sum -c \
    && chmod +x /usr/local/bin/fluxctl \
# testssl.sh (make sure this is last, or at least don't rm -rf /tmp/* after this point)
    && wget -q -O /tmp/testssl.tar.gz https://github.com/drwetter/testssl.sh/archive/${TEST_SSL_VERSION}.tar.gz \
    && echo "$TEST_SSL_SHA256 /tmp/testssl.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/testssl.tar.gz -C /tmp \
    && mv /tmp/testssl.sh-${TEST_SSL_VERSION} /tmp/testssl.sh \
    && rm -f /tmp/testssl.tar.gz


# Install LETSENCRYPT staging fake root ca
RUN set -e \
    && wget -O /usr/local/share/ca-certificates/fakelerootx1.crt https://letsencrypt.org/certs/fakelerootx1.pem \
    && wget -O /usr/local/share/ca-certificates/fakeleintermediatex1.crt https://letsencrypt.org/certs/fakeleintermediatex1.pem \
    && update-ca-certificates

COPY --from=mintel/k8s-yaml-splitter:0.1.0 /k8s-yaml-splitter /usr/local/bin/k8s-yaml-splitter
COPY --from=gcr.io/google_containers/pause-amd64:3.1 /pause /
COPY --from=openpolicyagent/opa:0.21.1 /opa /usr/local/bin/opa
COPY --from=prom/prometheus:v2.13.0 /bin/promtool /usr/local/bin/promtool

COPY --from=go-builder /go/bin/tfjson2 /go/bin/tfjson2 /go/bin/gojsontoyaml /go/bin/json2hcl /go/bin/jb /usr/local/bin/
COPY --from=deb-builder /usr/local/bin/jsonnet* /usr/local/bin/git-crypt /usr/local/bin/

RUN useradd -ms /bin/bash mintel

COPY resources/ /

USER mintel
WORKDIR /home/mintel

RUN set -e \
    && pip3 install yamllint docker-compose \
# Configure support for terraform-ct-provider
    && printf 'providers {\n  ct = "/usr/local/bin/terraform-provider-ct"\n}\n' >> /home/mintel/.terraformrc \
# Extend PATH for mintel user
    && echo "PATH=\$HOME/.local/bin:\$PATH" >> /home/mintel/.bashrc \
# Add vim-tiny alias
    && echo "alias vim=vim.tiny" >> /home/mintel/.bashrc

ENV PATH=/home/mintel/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DOCKER_HOST_ALIAS=docker \
    KIND_NODES=1 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LC_TYPE=en_US.UTF-8

# Don't use a real entrypoint 
ENTRYPOINT ["/usr/bin/env"]
