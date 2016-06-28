#!/bin/bash

set -eu

rm -rf target
mkdir -p target

echo stack vars
./stack_vars.sh
source target/stack_vars.sh
echo cleanup
./cleanup.sh
echo crear imagen
./create.sh
echo extraer imagen
./extract.sh
echo generar terraform
./generate_terraform.sh
