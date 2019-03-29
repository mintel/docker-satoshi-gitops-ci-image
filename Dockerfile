FROM debian:9-slim

LABEL vendor="Mintel"
LABEL maintainer "fciocchetti@mintel.com"

RUN apt-get -y update && \
    apt-get -y install \
      apt-transport-https \
      bash \
      ca-certificates \
      curl \
      git \
      gnupg2 \
      jq \
      make \
      openssh-client \
      python3-pkg-resources \
      software-properties-common \
      wget \
      yamllint && \
    wget -q -O- https://download.docker.com/linux/debian/gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" >> /etc/apt/sources.list && \
    apt-get -y update && \
    apt-get install docker-ce-cli && \
    apt-get -y autoremove && apt-get -y clean

ENV YAML2JSON_VERSION=1.3 \
    YAML2JSON_SHA256=e792647dd757c974351ea4ad35030852af97ef9bbbfb9594f0c94317e6738e55 \
    YQ_VERSION=2.3.0 \
    YQ_SHA256=97b2c61ae843a429ce7e5a2c470cfeea1c9e9bf317793b41983ef228216fe31b \
    KUSTOMIZE_VERSION=2.0.3 \
    KUSTOMIZE_SHA256=a04d79a013827c9ebb0abfe9d41cbcedf507a0310386c8d9a7efec7a36f9d7a3 \
    MINIKUBE_VERSION=0.35.0 \
    MINIKUBE_SHA256=e161995604c42c37a797fd11fac5d545f8b75f0796afc3b10679253bf229ff3d \
    KUBECTL_VERSION=1.12.5 \
    KUBECTL_SHA256=f52abcfbcb74f590a2229364afee11271ce597add3eeceefc1dc174590e2dff8 \
    VAULT_VERSION=1.0.3 \
    VAULT_SHA256=f52abcfbcb74f590a2229364afee11271ce597add3eeceefc1dc174590e2dff8 \
    KIND_VERSION=0.2.0 \
    KIND_SHA256=0ed25a717de8a089eae5e0ebb4779400b2ef2f20ffe428f3b05f425c7beaf092

WORKDIR /usr/local/bin

RUN set -e \
    && wget -q -O /usr/local/bin/yaml2json https://github.com/bronze1man/yaml2json/releases/download/v${YAML2JSON_VERSION}/yaml2json_linux_amd64 \
    && chmod +x /usr/local/bin/yaml2json \
    && echo "$YAML2JSON_SHA256  yaml2json" | sha256sum -c

RUN set -e \
    && wget -q -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq \
    && echo "$YQ_SHA256  yq" | sha256sum -c

RUN set -e \
    && wget -q -O /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64 \
    && chmod +x /usr/local/bin/kustomize \
    && echo "$KUSTOMIZE_SHA256  kustomize" | sha256sum -c

RUN set -xe \
    && wget -q -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && echo "$KUBECTL_SHA256  kubectl" | sha256sum -c

#RUN set -e \
#    && wget -q -O /usr/local/bin/minikube https://github.com/kubernetes/minikube/releases/download/v${MINIKUBE_VERSION}/minikube-linux-amd64 \
#    && chmod +x /usr/local/bin/minikube \
#    && echo "$MINIKUBE_SHA256  minikube" | sha256sum -c

RUN set -e \
    && wget -q -O /usr/local/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64 \
    && chmod +x /usr/local/bin/kind \
    && echo "$KIND_SHA256  kind" | sha256sum -c

USER 0
ADD resources/* /

RUN useradd -ms /bin/bash mintel
USER mintel

# Don't use a real entrypoint 
ENTRYPOINT ["/usr/bin/env"]
