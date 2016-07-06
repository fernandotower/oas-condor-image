#!/bin/bash

# rationale: figlet: mensajes claramente visibles durante la instalación
# rationale: git: descargar código desde repositorio central
# rationale: ntp: mantener el servidor con la hora precisa
# rationale: httpd, php, php-mysql, php-pgsql, php-mcrypt: la aplicación es LAMP
# rationale: gcc, php-pear, php-devel: por licencias de Oracle los controladores para PHP (OCI8) solo se distribuyen a manera de código fuente, deben compilarse para poderse usar, estos paquetes se necesitan para poder compilar OCI8
# rationale: awscli: interactuar con AWS programáticamente
# rationale: jq: procesar respuestas en JSON de diversas APIs

set -e -u

sudo yum install -y -q -e 0 figlet

figlet -f banner paquetes

sudo yum install -y -q -e 0 gcc ntp git awscli jq libpng libxml2 httpd php php-devel php-mcrypt php-pear php-pgsql php-mysql
