#!/bin/bash

# rationale: La aplicación se conecta a una base de datos Oracle

set -eu

figlet -f banner drivers | sed 's|^|# |'
figlet -f banner oracle  | sed 's|^|# |'

echo "Se bajaran los paquetes rpm necesarios del bucket '${oas_repo}'"

# Estos archivos se consiguen en la página oficial de oracle
# link: http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html
basic_rpm="oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm"
devel_rpm="oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm"
sqlplus_rpm="oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm"
oracle_home="/usr/lib/oracle/12.1/client64"

mkdir -pv /tmp/rpms

aws s3 cp "s3://${oas_repo}/rpms/${basic_rpm}" "/tmp/rpms/"
aws s3 cp "s3://${oas_repo}/rpms/${devel_rpm}" "/tmp/rpms/"
aws s3 cp "s3://${oas_repo}/rpms/${sqlplus_rpm}" "/tmp/rpms/"

echo Verificando integridad de paquetes externos
md5sum -c - << EOF
2d711cf98c19bd4f291838b4a1ed7b6a  /tmp/rpms/${basic_rpm}
ac5bf56bce1c1521e1ca1984c3374a93  /tmp/rpms/${devel_rpm}
d757d82cb8ac110e8d353e27a348139a  /tmp/rpms/${sqlplus_rpm}
EOF

sudo yum install -y \
                "/tmp/rpms/${basic_rpm}" \
                "/tmp/rpms/${devel_rpm}" \
                "/tmp/rpms/${sqlplus_rpm}"

rm -rfv /tmp/rpms

oracle_home_profile="/etc/profile.d/oas_oracle_home.sh"
echo Escribiendo $oracle_home_profile
sudo tee $oracle_home_profile << EOF
export ORACLE_HOME=${oracle_home}
export TNS_ADMIN=/etc/httpd/conf
EOF

oracle_ld_config="/etc/ld.so.conf.d/oas_oracle.conf"
echo Escribiendo $oracle_ld_config
sudo tee $oracle_ld_config << EOF
${oracle_home}/lib
EOF

sudo ldconfig

echo Instalando oci8
mkdir /tmp/oci8-install.$$
pushd  /tmp/oci8-install.$$
# Esta version especifica de OCI8 es necesaria para PHP 5.2 a 5.6 (Centos 7 incluye PHP 5.4)
# link: https://pecl.php.net/package/oci8
pear download pecl/oci8-1.4.10
tar xvzf oci8-*.tgz
cd oci8-*
phpize
./configure "--with-oci8=shared,instantclient,${oracle_home}/lib"
make
sudo make install
popd
rm -rf /tmp/oci8-install.$$

sudo ldconfig

sudo setsebool -P httpd_execmem 1
