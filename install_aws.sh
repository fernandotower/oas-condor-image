#!/bin/bash
set -eu
sudo yum install -y unzip
mkdir -pv "/tmp/aws-install.$$"
pushd "/tmp/aws-install.$$"
# tomado de http://docs.aws.amazon.com/cli/latest/userguide/installing.html
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
popd
