#!/bin/bash

set -eu

mkdir /tmp/oci8-install.$$
pushd  /tmp/oci8-install.$$
# esta version especifica de oci8 es necesaria para php 5.2 - 5.6 ver => https://pecl.php.net/package/oci8
pear download pecl/oci8-1.4.10
tar xvzf oci8-*.tgz
cd oci8-*
phpize
./configure --with-oci8=shared,instantclient,/usr/lib/oracle/12.1/client64/lib
make
sudo make install
popd
rm -rf /tmp/oci8-install.$$

sudo setsebool -P httpd_execmem 1
