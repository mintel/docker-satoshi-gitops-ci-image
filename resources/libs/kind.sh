[[ "$TRACE" ]] && set -x

K8S_VERSION="${K8S_VERSION:-v1.13.10@sha256:2f5f882a6d0527a2284d29042f3a6a07402e1699d792d0d5a9b9a48ef155fa2a}"
K8S_WORKERS="${KIND_NODES:-1}"
KIND_FIX_KUBECONFIG="${KIND_FIX_KUBECONFIG:-false}"
KIND_REPLACE_CNI="${KIND_REPLACE_CNI:-false}"
DOCKER_HOST_ALIAS="${DOCKER_HOST_ALIAS:-docker}"

function install_cni() {
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

function start_kind() {
  cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:${K8S_VERSION}
EOF

  if [[ $K8S_WORKERS -gt 0 ]]; then
  for i in $(seq 1 "${K8S_WORKERS}");
  do
    cat >> /tmp/kind-config.yaml <<EOF
- role: worker
  image: kindest/node:${K8S_VERSION}
EOF
  done
  fi
  
  cat >> /tmp/kind-config.yaml <<EOF
networking:
  apiServerAddress: 0.0.0.0
EOF

  if [[ "$KIND_REPLACE_CNI" == "true" ]]; then
    cat >> /tmp/kind-config.yaml <<EOF
  # Disable default CNI and install Weave Net to get around DIND issues
  disableDefaultCNI: true
EOF
  fi

  export KUBECONFIG="${HOME}/.kube/kind-config"

  kind create cluster --config /tmp/kind-config.yaml

  if [[ "$KIND_FIX_KUBECONFIG" == "true" ]]; then  
    sed -i -e "s/server: https:\/\/0\.0\.0\.0/server: https:\/\/$DOCKER_HOST_ALIAS/" "$KUBECONFIG"
  fi

  if [[ "$KIND_REPLACE_CNI" == "true" ]]; then
    install_cni
  fi

  kubectl cluster-info

  kubectl -n kube-system rollout status deployment/coredns --timeout=180s
  kubectl -n kube-system rollout status daemonset/kube-proxy --timeout=180s
  kubectl get pods --all-namespaces
}

function cluster_report() {
  printf "\n# Cluster Report\n"
  printf "##############################\n"
  printf "\n\n# Nodes\n"
  kubectl get nodes -o wide --show-labels

  printf "\n\n# Namespaces\n"
  kubectl get namespaces -o wide --show-labels

  printf "\n\n# Network Policies\n"
  kubectl get networkpolicy -o wide --all-namespaces

  printf "\n\n# Pod Security Policies\n"
  kubectl get psp -o wide

  printf "\n\n# RBAC - clusterroles\n"
  kubectl get clusterrole -o wide
  printf "\n\n# RBAC - clusterrolebindings\n"
  kubectl get clusterrolebindings -o wide
  printf "\n\n# RBAC - roles\n"
  kubectl get role -o wide --all-namespaces
  printf "\n\n# RBAC - rolebindings\n"
  kubectl get rolebindings -o wide --all-namespaces
  printf "\n\n# RBAC - serviceaccounts\n"
  kubectl get serviceaccount -o wide --all-namespaces

  printf "\n\n# All\n"
  kubectl get all --all-namespaces -o wide --show-labels
}
