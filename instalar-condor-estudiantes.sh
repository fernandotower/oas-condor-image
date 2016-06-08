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
sudo sed -i.bak 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# Repositorio EPEL
sudo yum install -y epel-release
sudo yum update -y

# MariaDB
sudo yum install -y mariadb-server mariadb
sudo systemctl enable mariadb
sudo systemctl start mariadb
#sudo mysql_secure_installation # TODO: este comando es asistido se debe modificar

# APACHE
sudo yum -y install httpd
sudo systemctl enable httpd #Al inicio arranca apache
sudo apachectl start

# PHP
sudo yum -y install php

# PHPMYADMIN
sudo yum -y install phpmyadmin
#vi /etc/httpd/conf.d/phpMyAdmin.conf #con sed
#comentar:
#   Require ip 127.0.0.1
#   Require ip ::1
# agregar
#   Require all granted
sudo apachectl restart
