#!/bin/bash

# rationale: en los repositorios EPEL se encuentran paquetes necesarios como: TODO...

set -eu

echo Agregando epel y actualizando paquetes

# Repositorio EPEL
sudo yum install -y epel-release
sudo yum install -y figlet

figlet -f banner yum
figlet -f banner update
# Actualizar el sistema
sudo yum update -y --skip-broken
