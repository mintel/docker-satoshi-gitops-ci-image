#!/bin/bash

# File with policies
POLICIES_DIR=$1
CONFS_DIR=/tmp/manifests

# Count number of Docs in the file
for file in `ls -1 $POLICIES_DIR/*.yaml`
do
  N_DOCS=$(cat $file | egrep ^kind | wc -l)

  let N_DOCS-=1

  for DOC in `seq 0 $N_DOCS`
  do
    kind=$(yq read -d $DOC $file kind)
    [[ $kind == "SealedSecret" ]] && continue

    skip_ci=$(yq read -d $DOC $file 'metadata.annotations."mintel.com/skip-ci"')
    [[ $skip_ci == "true" ]] && continue


    name=$(yq read -d $DOC $file metadata.name)
    namespace=$(yq read -d $DOC $file metadata.namespace)
    data=$(yq read -d $DOC $file 'data."vault-config.yml"')
    [[ $data == "null" ]] && continue

    file_name="${namespace}_${name}.yaml"

    if [[ $kind == "ConfigMap" ]]; then
      yq read -d $DOC $file 'data."vault-config.yml"' > ${CONFS_DIR}/${file_name}
    elif [[ $kind == "Secret" ]]; then
      yq read -d $DOC $file 'data."vault-config.yml"' | base64 -d  > ${CONFS_DIR}/${file_name}
    fi
  done
done
