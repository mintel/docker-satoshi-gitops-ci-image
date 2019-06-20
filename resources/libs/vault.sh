[[ "$TRACE" ]] && set -x

DOCKER_HOST_ALIAS="${DOCKER_HOST_ALIAS:-docker}"
VAULT_VERSION="${VAULT_VERSION:-1.1.3}"
VAULT_DEV_ROOT_TOKEN="${VAULT_DEV_ROOT_TOKEN:-e59546c1-3383-497a-8024-aaf2a400064a}"
BANK_VAULTS_IMAGE="${BANK_VAULTS_IMAGE:-banzaicloud/bank-vaults}"
BANK_VAULTS_VERSION="${BANK_VAULT_VERSION:-master}"
POLICIES_DIR="${POLICIES_DIR}"
CONFS_DIR="/tmp/confs"

[[ -z $POLICIES_DIR ]] && ( printf "\n\nPOLICIES_DIR Undefined\n" && exit 1 )

function build_bank_vaults_configs_list {
printf "\n## "
}

function extract_vault_configs_from_manifests {
  mkdir -p $CONFS_DIR

  # render all kustomize policies

  for k in $(find $POLICIES_DIR -type f -name kustomization.yaml); do
    env="$(dirname $k | rev | cut -d/ -f1 | rev)"  

    mkdir -p $CONFS_DIR/$env/kustomize
    mkdir -p $CONFS_DIR/$env/yamls
    kustomize build $env > $CONFS_DIR/$env/kustomize/manifests.yaml

    N_DOCS=$(cat $CONFS/$env/kustomize/manifests.yaml| egrep ^kind | wc -l)

    let N_DOCS-=1

    for DOC in `seq 0 $N_DOCS`
    do
      kind=$(yq read -d $DOC $file kind)
      skip_ci=$(yq read -d $DOC $file 'metadata.annotations."mintel.com/skip-local-ci"')

      name=$(yq read -d $DOC $file metadata.name)
      namespace=$(yq read -d $DOC $file metadata.namespace)
      data=$(yq read -d $DOC $file 'data."vault-config.yml"')

      file_name="${namespace}_${name}.yaml"

      [[ $kind == "SealedSecret" ]] && echo "EXCLUDING: $namespace-$name - SealedSecret" && continue
      [[ $skip_ci == "true" ]] && echo "EXLCUDING: $namespace-$name - skip-ci annotation" && continue
      [[ $data == "null" ]] && echo "EXLCUDING: $namespace-$name - not a vault-config.yml key" && continue

      if [[ $kind == "ConfigMap" ]]; then
        yq read -d $DOC $file 'data."vault-config.yml"' > $CONFS_DIR/$env/yamls/${file_name}
      elif [[ $kind == "Secret" ]]; then
        yq read -d $DOC $file 'data."vault-config.yml"' | base64 -d > $CONFS_DIR/$env/yamls/${file_name}
      fi
    done 
    
  done

}

function check_vault_policies() {
  printf "\n## Extracting Configs from Kubernetes Vault Policies manifests ##\n"
  docker run --rm -v $CI_PROJECT_DIR:/project -v /tmp:/tmp mintel/satoshi-gitops-ci:latest /scripts/vault/extract-vault-configs-from-manifest.sh /project/$POLICIES_DIR
  export CONFS=$(docker run --rm  -v /tmp:/tmp mintel/satoshi-gitops-ci:latest /scripts/vault/build-bank-vaults-confgs-list.sh)

  printf "\n## Starting Vault Server ##\n"
  docker run -d --net=host -e SKIP_SETCAP=true -e VAULT_DEV_ROOT_TOKEN_ID=${VAULT_DEV_ROOT_TOKEN} vault:$VAULT_VERSION server -dev -dev-listen-address=0.0.0.0:8200
  printf "\n## Starting Configurator ##\n"
  docker run --rm --net=host -e VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN} -e VAULT_ADDR=http://127.0.0.1:8200 -v /tmp:/tmp $BANK_VAULTS_IMAGE:$BANK_VAULTS_VERSION configure --once --fatal --mode dev $CONFS

  printf "\n## Vault status ##\n"
  docker run --rm --net=host -e SKIP_SETCAP=true -e VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN} -e VAULT_ADDR=http://127.0.0.1:8200 vault:$VAULT_VERSION status
  printf "\n## Vault policies ##\n"
  docker run --rm --net=host -e SKIP_SETCAP=true -e VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN} -e VAULT_ADDR=http://127.0.0.1:8200 vault:$VAULT_VERSION policy list
  printf "\n## Vault secrets ##\n"
  docker run --rm --net=host -e SKIP_SETCAP=true -e VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN} -e VAULT_ADDR=http://127.0.0.1:8200 vault:$VAULT_VERSION secrets list
  printf "\n## Vault auth ##\n"
  docker run --rm --net=host -e SKIP_SETCAP=true -e VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN} -e VAULT_ADDR=http://127.0.0.1:8200 vault:$VAULT_VERSION auth list
}

