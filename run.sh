#!/bin/bash

set -eu

while getopts ":p:r:" opt; do
  case $opt in
    p)
      aws_profile="${OPTARG}"
      ;;
    r)
      oas_repo="${OPTARG}"
      ;;
  esac
done

AWS_PROFILE="${aws_profile:-${AWS_PROFILE:-}}"

if [ -z "${AWS_PROFILE}" ]
then
  unset AWS_PROFILE
  echo "Se usaran las credenciales de AWS por defecto '$AWS_DEFAULT_PROFILE'"
else
  echo "Se usará el perfil guardado en '~/.aws/credentials' llamado '${AWS_PROFILE}'"
  export AWS_PROFILE
fi

OAS_REPO="${oas_repo:-${OAS_REPO:-}}"

if [ -z "${OAS_REPO}" ]
then
  unset OAS_REPO
  echo "No se ha definido el nombre de bucket de S3, definalo con -r <nombre_repo> o con la variable de entorno $$OAS_REPO" > /dev/stderr
  exit 1
else
  echo "Se usará el bucket de S3 llamaddo '${OAS_REPO}'"
  export OAS_REPO
fi

packer validate plantilla.json
packer build plantilla.json
