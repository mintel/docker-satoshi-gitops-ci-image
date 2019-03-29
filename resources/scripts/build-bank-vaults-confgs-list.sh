#!/bin/bash

CONFS_DIR="/tmp/manifests" 

CONFS_STRING=""


for file in `ls -1 $CONFS_DIR/*.yaml`
do
  CONFS_STRING="${CONFS_STRING}--vault-config-file=${CONFS_DIR}/${file_name}"
done

echo $CONFS_STRING
