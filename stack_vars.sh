#!/bin/bash

set -eu

IFS=,

mkdir -p target
> target/stack_vars.sh
> target/stack_vars.tf

for base_stack in ${OAS_STACKS_NAMES}
do
  stack="$(aws cloudformation describe-stacks --stack-name "${base_stack}")"

  # esta parte genera variables de shell

  jq -r '.Stacks[]|.Outputs[]|"export STACK_" + .OutputKey + "=" + (.OutputValue|@sh)' <<< "${stack}" >> target/stack_vars.sh

  # esta parte genera variables de terraform

  jq -r '.Stacks[]|.Outputs[]|"variable \"stack_" + .OutputKey + "\" {type=\"string\"
  default=" + (.OutputValue|tojson) + "}"' <<< "${stack}" >> target/stack_vars.tf
done
