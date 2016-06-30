#!/bin/bash

# rationale: figlet: mensajes claramente visibles durante la instalación
# rationale: git: descargar código desde repositorio central
# rationale: ntp: mantener el servidor con la hora precisa
# rationale: httpd, php, php-mysql, php-pgsql: la aplicación es LAMP
# rationale: gcc, make, php-pear, php-devel: por licencias de Oracle los controladores para PHP (OCI8) solo se distribuyen a manera de código fuente, deben compilarse para poderse usar, estos paquetes se necesitan para poder compilar OCI8
# rationale: awscli: interactuar con AWS programáticamente
# rationale: jq: procesar respuestas en JSON de diversas APIs

set -e -u

sudo yum install -y -q figlet

figlet -f banner paquetes

sudo yum install -yq git ntp httpd php php-mysql gcc make php-pear php-devel awscli jq php-pgsql
