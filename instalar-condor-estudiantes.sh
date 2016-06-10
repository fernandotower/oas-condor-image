#!/bin/bash

set -eu

# AUGEAS y GIT
sudo yum install -y augeas git

echo instalando drivers de oracle
mkdir -pv /tmp/rpms

echo "se bajaran los paquetes rpm necesarios del bucket '${oas_repo}'"

aws s3 cp "s3://${oas_repo}/rpms/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm" "/tmp/rpms/"
aws s3 cp "s3://${oas_repo}/rpms/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm" "/tmp/rpms/"
aws s3 cp "s3://${oas_repo}/rpms/oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm" "/tmp/rpms/"

echo verificando integridad de paquetes externos
md5sum -c - << EOF
2d711cf98c19bd4f291838b4a1ed7b6a  /tmp/rpms/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
ac5bf56bce1c1521e1ca1984c3374a93  /tmp/rpms/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
d757d82cb8ac110e8d353e27a348139a  /tmp/rpms/oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm
EOF

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

echo configurando apache
# Define el ServerAdmin de Apache
sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.packer-bak
sudo augtool << 'EOF'
set /files/etc/httpd/conf/httpd.conf/*[self::directive="ServerAdmin"]/arg computo@udistrital.edu.co
save
EOF

#Configurar Apache HTTP Server para una alta demanda de servicio:
echo creando /etc/httpd/conf.d/50-oas-prefork.conf
sudo tee /etc/httpd/conf.d/50-oas-prefork.conf << EOF
<IfModule prefork.c>
  Timeout              150
  ServerLimit          400
  StartServers         20
  MinSpareServers      5
  MaxSpareServers      20
  MaxClients           400
  MaxRequestsPerChild  400
</IfModule>
EOF

echo creando /etc/httpd/conf.d/50-oas-keepalive.conf
sudo tee /etc/httpd/conf.d/50-oas-keepalive.conf << EOF
MaxKeepAliveRequests 10
KeepAliveTimeout 0
EOF

# FIREWALL
# Esto se gestiona por medio del Security Groups de Amazon

# PHP
sudo yum install -y php

echo creando /etc/php.d/50-oas.ini
sudo tee /etc/php.d/50-oas.ini << EOF
short_open_tag = On
max_execution_time = 60
max_input_vars = 10000
post_max_size = 48M
default_charset = "UTF-8"
upload_max_filesize = 48M
allow_url_include = On
date.timezone = "America/Bogota"
oci8.connection_class = "DEFAULT_CONNECTION_CLASS"
EOF

# PHPMYADMIN
sudo yum install -y phpmyadmin

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

echo verificar sintaxis de apache
sudo apachectl -t

echo finalizando
echo el archivo /etc/httpd/conf/tnsnames.ora debe crearse durante runtime mediante user-data y debe tener una conexión de clase DEFAULT_CONNECTION_CLASS
echo creando /etc/cron.hourly/50-oas-check-tnsnames-ora
sudo tee /etc/cron.hourly/50-oas-check-tnsnames-ora << 'EOF'
#!/bin/sh
set -eu
sleep 300 # esperar mientras se crea la ami o se aprovisiona el server por medio de user-data
if [ ! -e /etc/httpd/conf/tnsnames.ora ]
then
  /usr/local/bin/aws --region us-east-1 ec2 terminate-instances --instance-ids `curl http://169.254.169.254/latest/meta-data/instance-id`
else if ! grep DEFAULT_CONNECTION_CLASS
then
  /usr/local/bin/aws --region us-east-1 ec2 terminate-instances --instance-ids `curl http://169.254.169.254/latest/meta-data/instance-id`
fi
EOF
sudo chmod +x /etc/cron.hourly/50-oas-check-tnsnames-ora
