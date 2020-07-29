# shellcheck shell=bash

[[ "$TRACE" ]] && set -x

DOCKER_HOST_ALIAS="${DOCKER_HOST_ALIAS:-docker}"
VAULT_VERSION="${VAULT_VERSION:-1.3.2}"
VAULT_DEV_ROOT_TOKEN="${VAULT_DEV_ROOT_TOKEN:-e59546c1-3383-497a-8024-aaf2a400064a}"
BANK_VAULTS_IMAGE="${BANK_VAULTS_IMAGE:-banzaicloud/bank-vaults}"
BANK_VAULTS_VERSION="${BANK_VAULTS_VERSION:-0.9.0}"
GITOPS_CI_CONTAINER_IMAGE="${GITOPS_CI_CONTAINER_IMAGE:-mintel/satoshi-gitops-ci}"
GITOPS_CI_CONTAINER_VERSION="${GITOPS_CI_CONTAINER_VERSION:-0.9.0}"
POLICIES_DIR="${POLICIES_DIR}"
CONFS_DIR="/tmp/confs"

[[ -z $POLICIES_DIR ]] && (printf "\n\nPOLICIES_DIR Undefined\n" && exit 1)

function extract_vault_configs_from_manifests() {
  mkdir -p $CONFS_DIR

  # render all kustomize policies

  find "$POLICIES_DIR" -type f -name kustomization.yaml | while read -r k; do
    env="$(dirname "$k" | rev | cut -d/ -f1 | rev)"

    mkdir -p "$CONFS_DIR/$env/kustomize"
    mkdir -p "$CONFS_DIR/$env/yamls"
    kustomize build "$(dirname "$k")" >"$CONFS_DIR/$env/kustomize/manifests.yaml"

    file=$CONFS_DIR/$env/kustomize/manifests.yaml
    N_DOCS=$(grep -E ^kind "$file" -c)

    ((_DOCS -= 1))

    for DOC in $(seq 0 "$N_DOCS"); do
      kind=$(yq read -d "$DOC" "$file" kind)
      skip_ci=$(yq read -d "$DOC" "$file" 'metadata.annotations."mintel.com/skip-local-ci"')

      name=$(yq read -d "$DOC" "$file" metadata.name)
      namespace=$(yq read -d "$DOC" "$file" metadata.namespace)
      data=$(yq read -d "$DOC" "$file" 'data."vault-config.yml"')

      file_name="${namespace}_${name}.yaml"

      [[ $kind == "SealedSecret" ]] && echo "EXCLUDING: $namespace-$name - SealedSecret" && continue
      [[ $skip_ci == "true" ]] && echo "EXLCUDING: $namespace-$name - skip-ci annotation" && continue
      [[ $data == "null" ]] && echo "EXLCUDING: $namespace-$name - not a vault-config.yml key" && continue

      if [[ $kind == "ConfigMap" ]]; then
        yq read -d "$DOC" "$file" 'data."vault-config.yml"' >"$CONFS_DIR/$env/yamls/${file_name}"
      elif [[ "$kind" == "Secret" ]]; then
        yq read -d "$DOC" "$file" 'data."vault-config.yml"' | base64 -d >"$CONFS_DIR/$env/yamls/${file_name}"
      fi
    done

  done
}

function build_bank_vaults_configs_list() {
  local e=$1
  local CONFS_STRING=""

  for file in "$CONFS_DIR"/"$e"/yamls/*; do
    CONFS_STRING="${CONFS_STRING}--vault-config-file=$CONFS_DIR/$e/yamls/${file} "
  done

  echo "$CONFS_STRING"
}

function check_vault_policies() {
  set -e
  docker pull "vault:$VAULT_VERSION" | grep -e 'Pulling from' -e Digest -e Status -e Error
  docker pull "$BANK_VAULTS_IMAGE:$BANK_VAULTS_VERSION" | grep -e 'Pulling from' -e Digest -e Status -e Error
  docker pull "$GITOPS_CI_CONTAINER_IMAGE:$GITOPS_CI_CONTAINER_VERSION" | grep -e 'Pulling from' -e Digest -e Status -e Error

  printf "\n##########################################################"
  printf "\n## extracting Policies from manifests for all Environments"
  printf "\n##########################################################\n"
  docker run --rm --net=host --name extractor -v /tmp:/tmp -v "$CI_PROJECT_DIR:$CI_PROJECT_DIR" -e POLICIES_DIR="$POLICIES_DIR" -e CI_PROJECT_DIR="$CI_PROJECT_DIR" "$GITOPS_CI_CONTAINER_IMAGE:$GITOPS_CI_CONTAINER_VERSION" bash -c "source /libs/vault.sh && extract_vault_configs_from_manifests && tree /tmp/confs"

  local ENVS
  ENVS=$(docker run --rm --net=host --name envs -v /tmp:/tmp "$GITOPS_CI_CONTAINER_IMAGE:$GITOPS_CI_CONTAINER_VERSION" bash -c "ls -1 $CONFS_DIR")

  printf "\n##########################################################"
  printf "\n## Testing policies for all Environments"
  printf "\n##########################################################\n"

  for env in $ENVS; do
    printf "\n##########################################################"
    printf "\n## ENV: %s\n" "$env"

    printf "\n## Starting Vault\n"
    docker run -d --net=host --name vault -e SKIP_SETCAP=true -e VAULT_DEV_ROOT_TOKEN_ID="${VAULT_DEV_ROOT_TOKEN}" "vault:$VAULT_VERSION" server -dev -dev-listen-address=0.0.0.0:8200

    printf "\n## Starting Configurator ##\n"
    local CONFS
    CONFS=$(docker run --rm --net=host --name confstring -v /tmp:/tmp "$GITOPS_CI_CONTAINER_IMAGE:$GITOPS_CI_CONTAINER_VERSION" bash -c "source /libs/vault.sh && build_bank_vaults_configs_list $env")

    docker run --rm --net=host --name configurator -e VAULT_TOKEN="${VAULT_DEV_ROOT_TOKEN}" -e VAULT_ADDR=http://127.0.0.1:8200 -v /tmp:/tmp "$BANK_VAULTS_IMAGE:$BANK_VAULTS_VERSION" configure --once --fatal --mode dev "$CONFS"

    printf "\n## Vault status ##\n"
    docker run --rm --net=host --name report -e SKIP_SETCAP=true -e VAULT_TOKEN="${VAULT_DEV_ROOT_TOKEN}" -e VAULT_ADDR=http://127.0.0.1:8200 --entrypoint sh "vault:$VAULT_VERSION" -c "vault status && echo \" - Policies\" && vault policy list && echo \" - Secrets\" && vault secrets list && echo \" - Auth\" && vault auth list"

    printf "\n## Stopping and Removing Vault\n"
    docker stop vault && docker rm vault

    printf "\n##########################################################\n"

  done

}
