#!/bin/bash

set -e -u

packer -machine-readable validate plantillas/packer.json

now="$(date +%s)"
OAS_EXPIRATION_TIMESTAMP="$((now+2592000))"  # un mes

export OAS_EXPIRATION_TIMESTAMP

if [ "${PACKER_MOCK_CREATION:-}" != "true" ]
then
  packer -machine-readable build plantillas/packer.json | tee target/packer.log
else
  tee target/packer.log << EOF
timestamp,packer-provider,artifact,0,id,us-east-1:ami-fake1
timestamp,packer-provider,artifact,1,id,us-west-1:ami-fake2
EOF
fi
