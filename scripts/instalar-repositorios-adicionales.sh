#!/bin/bash

# rationale: en los repositorios EPEL se encuentran paquetes necesarios como: TODO

set -eu

echo Agregando epel

# Repositorio EPEL
sudo yum install -y epel-release
