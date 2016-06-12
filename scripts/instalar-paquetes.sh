#!/bin/bash

# rationale: git: descargar código desde repositorio central
# rationale: ntp: mantener el servidor con la hora precisa
# rationale: httpd, mariadb, mariadb-server, php: la aplicación es LAMP
# rationale: gcc, make, php-pear, php-devel: por licencias de Oracle los controladores para PHP (OCI8) solo se distribuyen a manera de código fuente, deben compilarse para poderse usar
# rationale: awscli: interactuar con AWS programáticamente
# rationale: jq: procesar respuestas en JSON de diversas APIs

figlet -f banner paquetes | sed 's|^|# |'

set -eu

sudo yum install -y git mariadb mariadb-server ntp httpd php gcc make php-pear php-devel awscli jq
