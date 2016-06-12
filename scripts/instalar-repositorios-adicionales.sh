#!/bin/bash

# rationale: en los repositorios EPEL se encuentran paquetes necesarios como: TODO

set -eu

echo Agregando epel y actualizando paquetes

# Repositorio EPEL
sudo yum install -y epel-release
# rationale: figlet: mensajes claramente visibles durante la instalación
sudo yum install -y figlet

figlet -f banner yum    | sed 's|^|# |'
figlet -f banner update | sed 's|^|# |'
# Actualizar el sistema
sudo yum update -y --skip-broken
