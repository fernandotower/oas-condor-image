#!/bin/bash

set -eu

echo agregando epel y actualizando paquetes

# Repositorio EPEL
sudo yum install -y epel-release

#Actualizar el sistema
sudo yum update -y --skip-broken

