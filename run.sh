#!/bin/bash

set -eu

packer -machine-readable validate plantilla.json

rm -rf target
mkdir -p target

packer -machine-readable build plantilla.json | tee target/packer.log

# extraer el artefacto a partir del log
awk -F, '
  BEGIN {
    printf("{\"artifacts\":[")
  }

  $3=="artifact" && $5=="id" {
    printf("%s{\"id\":\""$4"\",\"data\":\""$6"\"}",sep);sep=","
  }

  END {
    printf("]}")
  }' target/packer.log > target/artifacts.json

artifacts_data="$(jq '.artifacts[]|.data' < target/artifacts.json)"

if [ -z "$artifacts_data" ]
then
  echo "No se generó ningún artefacto."
  exit 1
fi
