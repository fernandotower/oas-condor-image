#!/bin/bash

set -e -u

# extraer la imagen a partir del json y crear una configuracion de terraform con eso
imagen_encontrada="$(jq -r '.artifacts[0]|.data|split(":")[1]' < target/artifacts.json)"

if [ -z "${imagen_encontrada}" ]
then
  echo no se generó una imagen
  exit 1
fi

tee target/image.tf << EOF
variable "image" {
  type = "string"
  default = "${imagen_encontrada}"
}
EOF
