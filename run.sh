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

AWS_PROFILE="${aws_profile:-${AWS_PROFILE:-}}"

if [ -z "${AWS_PROFILE}" ]
then
  unset AWS_PROFILE
  echo "Se usaran las credenciales de AWS por defecto"
  echo "AWS_DEFAULT_PROFILE   = '${AWS_DEFAULT_PROFILE:-}'"
  echo "AWS_ACCESS_KEY_ID     = '${AWS_ACCESS_KEY_ID:-}'"
  echo "AWS_SECRET_ACCESS_KEY = '***'"
  echo "AWS_SESSION_TOKEN     = '***'"
else
  echo "Se usará el perfil guardado en '~/.aws/credentials' llamado '${AWS_PROFILE}'"
  export AWS_PROFILE
fi

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
  ci_commit="${CI_COMMIT}-"
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

./cleanup.sh -p "${AWS_PROFILE:-}" || true

packer validate plantilla.json
packer build plantilla.json
