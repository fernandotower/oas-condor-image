#!/bin/bash

set -eu

imagen_encontrada="$(jq -r '.artifacts[0]|.data|split(":")[1]' < target/artifacts.json)"

if [ -z "${imagen_encontrada}" ]
then
  echo no se generó una imagen
  exit 1
fi

tee target/condor-image.tf << EOF
variable "condor_image" {
  type = "string"
  default = "${imagen_encontrada}"
}
EOF
