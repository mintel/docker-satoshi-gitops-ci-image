#!/bin/bash

CONFS_DIR="/tmp/manifests" 

CONFS_STRING=""


for file in `ls -1 $CONFS_DIR/*.yaml`
do
  CONFS_STRING="${CONFS_STRING}--vault-config-file=${file} "
done

echo $CONFS_STRING
