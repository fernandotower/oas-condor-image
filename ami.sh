#!/bin/bash

set -eu

packer -machine-readable validate plantilla.json

now="$(date +%s)"
OAS_EXPIRATION_TIMESTAMP="$((now+2592000))"  # un mes
PACKER_EXPIRATION_TIMESTAMP="$((now+86400))" # un día

export OAS_EXPIRATION_TIMESTAMP
export PACKER_EXPIRATION_TIMESTAMP

./cleanup.sh

rm -rf target
mkdir -p target

packer -machine-readable build plantilla.json | tee target/packer.log

# extraer el artefacto a partir del log y armar un json con eso
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
