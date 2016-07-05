#!/bin/bash

set -e -u

echo limpiar target
rm -r -f target
mkdir -p target
echo obtener variables
./stack_vars.sh
source target/stack_vars.sh
echo aprovisionar paquetes
./paquetes.sh
echo cleanup
./cleanup.sh
echo crear imagen
./create.sh
echo extraer imagen
./extract.sh
echo generar terraform
./generate_terraform.sh
echo preparar para publicar
cp Dockerfile target/
