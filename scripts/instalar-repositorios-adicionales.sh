#!/bin/bash

# rationale: en los repositorios EPEL se encuentran paquetes necesarios como: TODO

set -e -u

echo Agregando epel

# Repositorio EPEL
sudo yum install -y -q epel-release
