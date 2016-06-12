#!/bin/bash

# rationale: git: descargar código desde repositorio central
# rationale: ntp: mantener el servidor con la hora precisa
# rationale: httpd, mariadb, mariadb-server, php: la aplicación es LAMP
# rationale: gcc, make, php-pear, php-devel: por licencias de Oracle los controladores para PHP (OCI8) solo se distribuyen a manera de código fuente, deben compilarse para poderse usar
# rationale: figlet: mensajes claramente visibles durante la instalación
# rationale: awscli: interactuar con AWS programáticamente
# rationale: jq: procesar respuestas en JSON de diversas APIs

set -eu

sudo yum install -y git mariadb mariadb-server ntp httpd php gcc make php-pear php-devel figlet awscli jq
