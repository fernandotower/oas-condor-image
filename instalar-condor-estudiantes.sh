#!/bin/bash

set -eu

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

# Red # en la wiki está para la red de la Univerisidad se adaptará a AWS

# Proxy

# SELINUX
sudo sed -i.packer-bak 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo setenforce permissive

# Fecha
sudo mv /etc/localtime /etc/localtime.bkp
sudo cp /usr/share/zoneinfo/America/Bogota /etc/localtime
sudo yum install -y ntp
sudo systemctl enable ntpd.service
sudo timedatectl set-timezone America/Bogota
sudo timedatectl set-ntp true
# sudo systemctl restart ntpd.service # no es necesario iniciar servicios mientras se crea la ami

# Repositorio EPEL
sudo yum install -y epel-release

#Actualizar el sistema
sudo yum -y update --skip-broken

# Ajustar la prioridad de uso de la swap
sudo echo "" >> /etc/sysctl.conf
sudo echo "# Controla el porcentaje de uso de la memoria de intercambio con respecto a la RAM" >> /etc/sysctl.conf
sudo echo "vm.swappiness=25" >> /etc/sysctl.conf
sudo sysctl -w vm.swappiness=25

# MARIADB
sudo yum install -y mariadb-server mariadb
sudo sed -i.packer-bak \
  -e '/# instructions in http:\/\/fedoraproject.org\/wiki\/Systemd/a \\n# Recommended in standard MySQL setup'
  -e '/# Recommended in standard MySQL setup/a sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES' \
  /etc/my.cnf
sudo systemctl enable mariadb
sudo systemctl start mariadb

# inicio mysql_secure_installation
# esto funciona, pero quizá debería hacerse en la instancia real para que no todas terminen con el mismo password de root o quizá esto no es un problema
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
# fin mysql_secure_installation

sudo systemctl stop mariadb # después de configurar la base la podemos parar

# APACHE
sudo yum install -y httpd
sudo systemctl enable httpd
# sudo apachectl start # mientras se crea la ami no es necesario iniciar cosas

# PHP
sudo yum install -y php

# PHPMYADMIN
sudo yum install -y phpmyadmin
# Se comentan las líneas "Require ip 127.0.0.1" y "Require ip ::1"
# Se agrega la línea "Require all granted"
sudo sed -i.packer-bak \
  -e 's/Require ip 127.0.0.1/#Require ip 127.0.0.1/g' \
  -e 's/Require ip ::1/#Require ip ::1/g' \
  -e '/Require ip ::1/a\ \ \ \ \ \ \ Require all granted' \
  /etc/httpd/conf.d/phpMyAdmin.conf

if diff /etc/httpd/conf.d/phpMyAdmin.conf.packer-bak /etc/httpd/conf.d/phpMyAdmin.conf
then
  echo sin cambios en phpMyAdmin.conf
fi

# sudo apachectl restart # mientras se crea la ami no es necesario iniciar cosas
sudo apachectl -t
