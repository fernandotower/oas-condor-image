#!/bin/bash

set -eu

echo instalando drivers de oracle
mkdir -pv /tmp/rpms

echo "se bajaran los paquetes rpm necesarios del bucket '${oas_repo}'"

aws s3 cp "s3://${oas_repo}/rpms/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm" "/tmp/rpms/"
aws s3 cp "s3://${oas_repo}/rpms/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm" "/tmp/rpms/"
aws s3 cp "s3://${oas_repo}/rpms/oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm" "/tmp/rpms/"

sudo yum install -y \
                "/tmp/rpms/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm" \
                "/tmp/rpms/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm" \
                "/tmp/rpms/oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm"

rm -rfv /tmp/rpms

echo escribiendo /etc/profile.d/oas_oracle_home.sh
sudo tee -a /etc/profile.d/oas_oracle_home.sh << EOF
export ORACLE_HOME=/usr/lib/oracle/12.1/client64
export TNS_ADMIN=/etc/httpd/conf
EOF

echo escribiendo /etc/ld.so.conf.d/oas_oracle.conf
sudo tee -a /etc/ld.so.conf.d/oas_oracle.confa << EOF
/usr/lib/oracle/12.1/client64/lib
EOF
sudo ldconfig

# Red # en la wiki está para la red de la Univerisidad se adaptará a AWS

# Proxy

# SELINUX
echo configurando selinux
sudo setenforce permissive
sudo sed -i.packer-bak 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
egrep '^SELINUX=' /etc/selinux/config

# Fecha
echo configurando hora
sudo mv /etc/localtime /etc/localtime.packer-bak
sudo ln -sv /usr/share/zoneinfo/America/Bogota /etc/localtime
sudo yum install -y ntp
sudo systemctl enable ntpd.service
sudo timedatectl set-timezone America/Bogota
sudo timedatectl set-ntp true
date

echo agregando epel y actualizando paquetes

# Repositorio EPEL
sudo yum install -y epel-release

#Actualizar el sistema
sudo yum update -y --skip-broken

# Ajustar la prioridad de uso de la swap
echo escribiendo /etc/sysctl.d/50-oas-vm-swappiness.conf
sudo tee -a /etc/sysctl.d/50-oas-vm-swappiness.conf << EOF
# Controla el porcentaje de uso de la memoria de intercambio con respecto a la RAM
vm.swappiness=25
EOF
sudo sysctl --system
sudo sysctl vm.swappiness

# MARIADB
echo instalando mariadb
sudo yum install -y mariadb-server mariadb
echo escribiendo /etc/my.cnf.d/oas_sql_mode.cnf
sudo tee -a /etc/my.cnf.d/oas_sql_mode.cnf << EOF
[mysqld]
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
EOF
sudo systemctl enable mariadb
sudo systemctl start mariadb

# inicio mysql_secure_installation
newpass="$(uuidgen)"
sudo tee /var/lib/mysql_secure_installation_answers > /dev/null << EOF

Y
$newpass
$newpass
Y
Y
Y
EOF
sudo chmod 400 /var/lib/mysql_secure_installation_answers
sudo cat /var/lib/mysql_secure_installation_answers | sudo mysql_secure_installation
unset newpass
# fin mysql_secure_installation

sudo systemctl stop mariadb

echo instalando apache, php y phpmyadmin

# APACHE
sudo yum install -y httpd
sudo systemctl enable httpd
# modificar en /etc/httpd/conf/httpd.conf
#ServerAdmin computo@udistrital.edu.co

#Configurar Apache HTTP Server para una alta demanda de servicio: 

#despues de el texto # virtual host being defined.
#agregar las líneas
<IfModule prefork.c>
Timeout              150
ServerLimit          400
StartServers         20
MinSpareServers      5
MaxSpareServers      20
MaxClients           400
MaxRequestsPerChild  400
</IfModule>
#
# MaxKeepAliveRequests: The maximum number of requests to allow
# during a persistent connection. Set to 0 to allow an unlimited amount.
# We recommend you leave this number high, for maximum performance.
#
MaxKeepAliveRequests 10
#
# KeepAliveTimeout: Number of seconds to wait for the next request from the
# same client on the same connection.
#
KeepAliveTimeout 0

# Crear el archivo de configuración para la conexión con Oracle en el TNS_ADMIN:
# vi /etc/httpd/conf/tnsnames.ora
# Agregar las líneas

#TNSNAMES.ORA Network Configuration File: source /etc/httpd/conf/tnsnames.ora

# Generated by Oracle configuration tools.
##SUDD_ORG =  (DESCRIPTION =  (ADDRESS = (PROTOCOL = TCP)(HOST = 10.20.0.4)(PORT = 1521)) (CONNECT_DATA = (SID = SUDD)))
#SUDD =  (DESCRIPTION =  (ADDRESS = (PROTOCOL = TCP)(HOST = 10.20.0.4)(PORT = 1521)) (CONNECT_DATA = (SID = SUDD)(SERVER=POOLED)))
#CONSULTA_PROD =  (DESCRIPTION =  (ADDRESS = (PROTOCOL = TCP)(HOST = 10.20.0.7)(PORT = 1521)) (CONNECT_DATA = (SID = UD)))
#PRUEBA_SIC =  (DESCRIPTION =  (ADDRESS = (PROTOCOL = TCP)(HOST = 10.20.0.11)(PORT = 1521)) (CONNECT_DATA = (SID = UD)))

# Recargar variables
# sudo source /etc/profile


#FIREWALL
# Esto se gestiona por medio del Security Groups de Amazon


# PHP
sudo yum install -y php
# Loaded Configuration File: /etc/php.ini 
# Scan this dir for additional .ini files: /etc/php.d 
# agregar
short_open_tag = On
max_execution_time = 60
max_input_vars = 10000
post_max_size = 48M
default_charset = "UTF-8"
upload_max_filesize = 48M
allow_url_include = On
date.timezone = "America/Bogota"
oci8.connection_class = 'POOL_ACADEMICA' 




# PHPMYADMIN
sudo yum install -y phpmyadmin augeas

sudo cp /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf.packer-bak
sudo augtool << 'EOF'
rm  /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/']/IfModule[arg='mod_authz_core.c']/RequireAny/directive
set /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/']/IfModule[arg='mod_authz_core.c']/RequireAny/directive Require
set /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/']/IfModule[arg='mod_authz_core.c']/RequireAny/*[self::directive="Require"]/arg[1] all
set /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/']/IfModule[arg='mod_authz_core.c']/RequireAny/*[self::directive="Require"]/arg[2] granted
rm  /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/setup/']/IfModule[arg='mod_authz_core.c']/RequireAny/directive
set /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/setup/']/IfModule[arg='mod_authz_core.c']/RequireAny/directive Require
set /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/setup/']/IfModule[arg='mod_authz_core.c']/RequireAny/*[self::directive="Require"]/arg[1] all
set /files/etc/httpd/conf.d/phpMyAdmin.conf/Directory[arg='/usr/share/phpMyAdmin/setup/']/IfModule[arg='mod_authz_core.c']/RequireAny/*[self::directive="Require"]/arg[2] granted
save
EOF

sudo apachectl -t
