#!/bin/bash

set -eu

sudo yum install -y gcc make php-pear php-devel

mkdir /tmp/oci8-install.$$
pushd  /tmp/oci8-install.$$
pear download pecl/oci8
tar xvzf oci8-*.tgz
cd oci8-*
phpize
./configure --with-oci8=shared,instantclient,/usr/lib/oracle/12.1/client64/lib
make
sudo make install
popd
rm -rf /tmp/oci8-install.$$

sudo setsebool -P httpd_execmem 1
