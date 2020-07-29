# shellcheck shell=bash

[[ "$TRACE" ]] && set -x

K8S_VERSION="${K8S_VERSION:-v1.13.12@sha256:5e8ae1a4e39f3d151d420ef912e18368745a2ede6d20ea87506920cd947a7e3a}"
K8S_WORKERS="${KIND_NODES:-1}"
KIND_FIX_KUBECONFIG="${KIND_FIX_KUBECONFIG:-false}"
KIND_REPLACE_CNI="${KIND_REPLACE_CNI:-false}"
KIND_OPTS="${KIND_OPTS:-}"
DOCKER_HOST_ALIAS="${DOCKER_HOST_ALIAS:-docker}"

KUBECTL=$(echo "${K8S_VERSION}" | sed -r "s/(v.*\..*)\..*/kubectl_\1/")

function install_cni() {
  $KUBECTL apply -f "https://cloud.weave.works/k8s/net?k8s-version=$($KUBECTL version | base64 | tr -d '\n')"
}

function start_kind() {
  cat >/tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:${K8S_VERSION}
EOF

  if [[ $K8S_WORKERS -gt 0 ]]; then
    for _ in $(seq 1 "${K8S_WORKERS}"); do
      cat >>/tmp/kind-config.yaml <<EOF
- role: worker
  image: kindest/node:${K8S_VERSION}
EOF
    done
  fi

  cat >>/tmp/kind-config.yaml <<EOF
networking:
  apiServerAddress: 0.0.0.0
EOF

  if [[ "$KIND_REPLACE_CNI" == "true" ]]; then
    cat >>/tmp/kind-config.yaml <<EOF
  # Disable default CNI and install Weave Net to get around DIND issues
  disableDefaultCNI: true
EOF
  fi

  export KUBECONFIG="${HOME}/.kube/kind-config"

  kind "${KIND_OPTS}" create cluster --config /tmp/kind-config.yaml

  if [[ "$KIND_FIX_KUBECONFIG" == "true" ]]; then
    sed -i -e "s/server: https:\/\/0\.0\.0\.0/server: https:\/\/$DOCKER_HOST_ALIAS/" "$KUBECONFIG"
  fi

  if [[ "$KIND_REPLACE_CNI" == "true" ]]; then
    install_cni
  fi

  $KUBECTL cluster-info

  $KUBECTL -n kube-system rollout status deployment/coredns --timeout=180s
  $KUBECTL -n kube-system rollout status daemonset/kube-proxy --timeout=180s
  $KUBECTL get pods --all-namespaces
}

function cluster_report() {
  printf "\n# Cluster Report\n"
  printf "##############################\n"
  printf "\n\n# Nodes\n"
  $KUBECTL get nodes -o wide --show-labels

  printf "\n\n# Namespaces\n"
  $KUBECTL get namespaces -o wide --show-labels

  printf "\n\n# Network Policies\n"
  $KUBECTL get networkpolicy -o wide --all-namespaces

  printf "\n\n# Pod Security Policies\n"
  $KUBECTL get psp -o wide

  printf "\n\n# RBAC - clusterroles\n"
  $KUBECTL get clusterrole -o wide
  printf "\n\n# RBAC - clusterrolebindings\n"
  $KUBECTL get clusterrolebindings -o wide
  printf "\n\n# RBAC - roles\n"
  $KUBECTL get role -o wide --all-namespaces
  printf "\n\n# RBAC - rolebindings\n"
  $KUBECTL get rolebindings -o wide --all-namespaces
  printf "\n\n# RBAC - serviceaccounts\n"
  $KUBECTL get serviceaccount -o wide --all-namespaces

  printf "\n\n# All\n"
  $KUBECTL get all --all-namespaces -o wide --show-labels
}
