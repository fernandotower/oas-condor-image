#!/bin/bash

set -eu

while getopts ":p:r:v:s:" opt; do
  case $opt in
    p)
      aws_profile="${OPTARG}"
      ;;
    r)
      oas_repo="${OPTARG}"
      ;;
    v)
      oas_vpc="${OPTARG}"
      ;;
    s)
      oas_subnet="${OPTARG}"
      ;;
  esac
done

source source/aws.sh

OAS_REPO="${oas_repo:-${OAS_REPO:-}}"

if [ -z "${OAS_REPO}" ]
then
  unset OAS_REPO
  echo "No se ha definido el nombre del bucket de S3, definalo con -r <nombre_repo> o con la variable de entorno OAS_REPO"
  exit 1
else
  echo "Se usará el bucket de S3 llamaddo '${OAS_REPO}'"
  export OAS_REPO
fi

OAS_VPC="${oas_vpc:-${OAS_VPC:-}}"

if [ -z "${OAS_VPC}" ]
then
  unset OAS_VPC
  echo "No se ha definido el id de la VPC, definalo con -v <vpc_id> o con la variable de entorno OAS_VPC"
  exit 1
else
  echo "Se usará la VPC con el id '${OAS_VPC}'"
  export OAS_VPC
fi

OAS_SUBNET="${oas_subnet:-${OAS_SUBNET:-}}"

if [ -z "${OAS_SUBNET}" ]
then
  unset OAS_SUBNET
  echo "No se ha definido el id de la Subnet, definalo con -s <subnet_id> o con la variable de entorno OAS_SUBNET"
  exit 1
else
  echo "Se usará la Subnet con el id '${OAS_SUBNET}'"
  export OAS_SUBNET
fi

if [ -n "${CI_BRANCH:-}" ]
then
  ci_branch="${CI_BRANCH}-"
fi
if [ -n "${CI_COMMIT:-}" ]
then
  ci_commit="${CI_COMMIT:0:7}-"
fi
if [ -n "${CI_BUILD_NUMBER:-}" ]
then
  ci_bn="${CI_BUILD_NUMBER}"
fi
NOW="$(date +%s)"
OAS_EXTERNAL_REF="${ci_branch:-SNAPSHOT-}${ci_commit:-SNAPSHOT-}${ci_bn:-${NOW}}"
# un mes de expiración
OAS_EXPIRATION_TIMESTAMP="$((NOW+2592000))"
# un día de expiración
PACKER_EXPIRATION_TIMESTAMP="$((NOW+86400))"

export OAS_EXTERNAL_REF
export OAS_EXPIRATION_TIMESTAMP
export PACKER_EXPIRATION_TIMESTAMP

source cleanup.sh

packer -machine-readable validate plantilla.json

rm -rf target
mkdir -p target

packer -machine-readable build plantilla.json | tee target/packer.log

# extraer el artefacto a partir del log
awk -F, '
  BEGIN {
    printf("[")
  }

  $3=="artifact" && $5=="id" {
    printf("%s{\"id\":\""$4"\",\"data\":\""$6"\"}",sep);sep=","
  }

  END {
    printf("]")
  }' target/packer.log > target/artifacts.json

jq . < target/artifacts.json
