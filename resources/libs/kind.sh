[[ "$TRACE" ]] && set -x

K8S_VERSION="${K8S_VERSION:-v1.12.8@sha256:cc6e1a928a85c14b52e32ea97a198393fb68097f14c4d4c454a8a3bc1d8d486c}"
K8S_WORKERS="${KIND_NODES:-1}"
KIND_FIX_KUBECONFIG="${KIND_FIX_KUBECONFIG:-false}"
DOCKER_HOST_ALIAS="${DOCKER_HOST_ALIAS:-docker}"

function start_kind() {
	cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
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

	kind create cluster --config /tmp/kind-config.yaml

	export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
	if [[ "$KIND_FIX_KUBECONFIG" == "true" ]]; then	
 		sed -i -e "s/localhost/$DOCKER_HOST_ALIAS/" "$KUBECONFIG"
	fi
    
	kubectl cluster-info

	kubectl -n kube-system rollout status deployment/coredns --timeout=180s
	kubectl -n kube-system rollout status daemonset/kube-proxy --timeout=180s
  # This rollout wait fail sometimes even though i think the pods are running
  # One pod ( or more ) is reported as not available 
  # Sleep for now
  sleep 15
  # kubectl -n kube-system rollout status daemonset/weave-net --timeout=180s

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
