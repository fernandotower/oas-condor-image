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

# SELINUX
sudo sed -i -- 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

# Repositorio EPEL
sudo -y yum install epel-release
sudo yum -y update

# Mysql
sudo yum -y install mariadb-server mariadb
sudo systemctl start mariadb
#sudo mysql_secure_installation # este comando es asistido se debe modificar

# APACHE
sudo yum -y install httpd
sudo systemctl enable httpd #Al inicio arranca apache
sudo apachectl start

# PHP
sudo yum -y install php

# PHPMYADMIN
sudo yum -y install phpmyadmin 
# Se comentan las líneas Require ip 127.0.0.1 y Require ip ::1
# Se agrega la línea Require all granted
sudo sed -i -- 's/Require ip 127.0.0.1/#Require ip 127.0.0.1/g' /etc/httpd/conf.d/phpMyAdmin.conf
sudo sed -i -- 's/Require ip ::1/#Require ip ::1/g' /etc/httpd/conf.d/phpMyAdmin.conf
sudo sed -i -- '/Require ip ::1/a\ \ \ \ \ \ \ Require all granted' /etc/httpd/conf.d/phpMyAdmin.conf

sudo apachectl restart


