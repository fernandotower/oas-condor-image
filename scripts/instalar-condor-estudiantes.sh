#!/bin/bash

set -eu

figlet -f banner estudiantes

# SELINUX
# rationale: TODO
echo Configurando SELINUX
sudo setenforce permissive
sudo sed -i.packer-bak 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
egrep '^SELINUX=' /etc/selinux/config

# NTP
# rationale: Tener el servidor en la zona horaria local
echo Configurando hora
sudo mv /etc/localtime /etc/localtime.packer-bak
sudo ln -sv /usr/share/zoneinfo/America/Bogota /etc/localtime
sudo systemctl enable ntpd.service
sudo timedatectl set-timezone America/Bogota
sudo timedatectl set-ntp true
date

# Ajustar la prioridad de uso de la swap
# vm.swappiness
# rationale: TODO
vm_swap_config="/etc/sysctl.d/50-oas-vm-swappiness.conf"
echo Escribiendo $vm_swap_config
sudo tee $vm_swap_config << EOF
# Controla el porcentaje de uso de la memoria de intercambio con respecto a la RAM
vm.swappiness=25
EOF
sudo sysctl --system
sudo sysctl vm.swappiness

# APACHE
sudo systemctl enable httpd

# ServerAdmin
# rationale: Cosmético
echo Configurando apache
server_admin_config="/etc/httpd/conf.d/50-oas-serveradmin.conf"
echo Escribiendo $server_admin_config
sudo tee $server_admin_config << EOF
ServerAdmin computo@udistrital.edu.co
EOF

# prefork
apache_prefork_config="/etc/httpd/conf.d/50-oas-prefork.conf"
# rationale: La configuración de prefork por defecto no es tán concurrente como esta
# rationale: TimeOut: El valor por defecto es 60, puede ser muy corto si algún script de PHP se demora más que eso en responder
# rationale: MaxClients: El valor por defecto es 256
# rationale: ServerLimit: El valor por defecto es 256
# rationale: MaxSpareServers: El valor por defecto es 10
# rationale: MaxRequestsPerChild: El valor por defecto es 10000, un valor menor es mejor si el software no está manjenado bien la memoria
# rationale: MaxRequestsPerChild: Setting MaxRequestsPerChild to a non-zero value limits the amount of memory that process can consume by (accidental) memory leakage.
# link: https://httpd.apache.org/docs/current/mod/prefork.html
# link: https://httpd.apache.org/docs/current/mod/mpm_common.html
# link: https://httpd.apache.org/docs/current/mod/core.html
echo Escribiendo $apache_prefork_config
sudo tee $apache_prefork_config << EOF
<IfModule prefork.c>
  TimeOut 150
  MaxClients 400
  ServerLimit 400
  MaxSpareServers 20
  MaxRequestsPerChild 1000
</IfModule>
EOF

keepalive_config="/etc/httpd/conf.d/50-oas-keepalive.conf"
# rationale: MaxKeepAliveRequests=1000 numero grande de KeepAlive requests
# rationale: MaxKeepAliveRequests: We recommend that this setting be kept to a high value for maximum server performance.
# link: https://httpd.apache.org/docs/current/mod/core.html#maxkeepaliverequests
# rationale: KeepAliveTimeout=1 los requests en el mismo pipeline deben venir antes de 1 segundo para ser consideradas
# rationale: KeepAliveTimeout: Setting KeepAliveTimeout to a high value may cause performance problems in heavily loaded servers.
# link: https://httpd.apache.org/docs/current/mod/core.html#maxkeepaliverequests#keepalivetimeout
echo Escribiendo $keepalive_config
sudo tee $keepalive_config << EOF
MaxKeepAliveRequests 1000
KeepAliveTimeout 1
EOF

php_config="/etc/php.d/50-oas.ini"
# rationale: Configura PHP para las particularidades del software
# rationale: max_execution_time: coincidir con el valor en apache "TimeOut"
echo Escribiendo $php_config
sudo tee $php_config << EOF
short_open_tag = On
max_execution_time = 150
max_input_vars = 10000
post_max_size = 48M
default_charset = "UTF-8"
upload_max_filesize = 48M
allow_url_include = On
date.timezone = "America/Bogota"
oci8.connection_class = "DEFAULT_CONNECTION_CLASS"

[OCI8]
extension=oci8.so
EOF

echo Verificar sintaxis de Apache
sudo apachectl -t

echo Verificar configuraciones de PHP
figlet -f banner phpinfo
php << EOF
<?php
  phpinfo();
?>
EOF

# SCRIPTS
sudo chmod -v +x /tmp/oas_scripts/*.sh
sudo chown -v root:root /tmp/oas_scripts/*.sh
sudo mv -vi /tmp/oas_scripts/*.sh /usr/local/sbin/

echo Progamando script de verificación de tnsnames.ora
sudo ln -sv /usr/local/sbin/check-tnsnames-ora.sh /etc/cron.hourly/50-check-tnsnames-ora.sh

echo Finalizando
