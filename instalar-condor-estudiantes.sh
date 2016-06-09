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

# PHP
sudo yum install -y php

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
