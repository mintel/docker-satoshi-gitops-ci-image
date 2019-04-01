#!/bin/bash

# File with policies
POLICIES_DIR=$1

for file in `ls -1 $POLICIES_DIR/*.yaml`
do
  N_DOCS=$(cat $file | egrep ^kind | wc -l)

  let N_DOCS-=1

  for DOC in `seq 0 $N_DOCS`
  do
    kind=$(yq read -d $DOC $file kind)
    [[ $kind == "SealedSecret" ]] && exit 1
  done
done
