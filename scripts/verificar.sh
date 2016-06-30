#!/bin/bash

set -e -u

echo Verificar sintaxis de Apache
sudo apachectl -t

echo Verificar configuraciones de PHP
figlet -f banner phpinfo
php -r 'phpinfo();'
