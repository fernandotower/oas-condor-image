#!/bin/bash

set -eu

# subir los rpms al bucket de aprovisionamiento si estos aún no se han subido
base_s3="s3://${STACK_CloudFormerRepositorioRPM}/rpms"

for rpm in *.rpm
do
  if ! aws s3 ls "${base_s3}/${rpm}" > /dev/null
  then
    aws s3 cp "${rpm}" "${base_s3}/${rpm}"
  fi
done
