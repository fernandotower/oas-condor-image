#!/bin/bash

set -eu

base_s3="s3://${STACK_CloudFormerRepositorioRPM}/rpms"

for rpm in *.rpm
do
  if ! aws s3 ls "${base_s3}/${rpm}"
  then
    echo copiando $rpm al bucket $base_s3
    aws s3 cp "${rpm}" "${base_s3}"
  else
    echo $rpm ya esta en el bucket $base_s3
  fi
done
