#!/bin/bash

# rationale: en los repositorios EPEL se encuentran paquetes necesarios como: php-mcrypt entre otros

set -e -u

echo Agregando epel

# Repositorio EPEL
sudo yum install -y -q -e 0 epel-release
