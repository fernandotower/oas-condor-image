#!/bin/bash

set -eu

while getopts ":p:" opt; do
  case $opt in
    p)
      aws_profile="${OPTARG}"
      ;;
  esac
done

AWS_PROFILE="${aws_profile:-${AWS_PROFILE:-}}"

if [ -z "${AWS_PROFILE}" ]
then
  unset AWS_PROFILE
  echo "Se usaran las credenciales de AWS por defecto"
  echo "AWS_DEFAULT_PROFILE   = '${AWS_DEFAULT_PROFILE:-}'"
  echo "AWS_ACCESS_KEY_ID     = '${AWS_ACCESS_KEY_ID:-}'"
  echo "AWS_SECRET_ACCESS_KEY = '***'"
  echo "AWS_SESSION_TOKEN     = '${AWS_SESSION_TOKEN:-}'"
else
  echo "Se usará el perfil guardado en '~/.aws/credentials' llamado '${AWS_PROFILE}'"
  export AWS_PROFILE
fi

if ! which jq > /dev/null
then
  echo Instala JQ primero https://stedolan.github.io/jq/download/
  exit 1
fi

NOW="$(date +%s)"

echo buscando amis para borrar

delete_amis="$(
  aws --output json --region us-east-1 ec2 describe-images --filters "Name=tag:promoted,Values=no" |
  jq -r --arg NOW "${NOW}" '.Images[] | select(.Tags[]|(.Key == "expiration-timestamp" and .Value <= $NOW)) | .ImageId'
)"

if [ -n "$delete_amis" ]
then
  echo borrando amis $delete_amis
  for ami in $delete_amis
  do
    set -x
    aws --region us-east-1 ec2 deregister-image --image-id "${ami}" || true
    set +x
  done
fi

echo buscando snapshots para borrar

delete_snap="$(
  aws --output json --region us-east-1 ec2 describe-snapshots --filters "Name=tag:promoted,Values=no" |
  jq -r --arg NOW "${NOW}" '.Snapshots[] | select(.Tags[]|(.Key == "expiration-timestamp" and .Value <= $NOW)) | .SnapshotId'
)"

if [ -n "$delete_snap" ]
then
  echo borrando snapshots $delete_snap
  for snap in $delete_snap
  do
    set -x
    aws --region us-east-1 ec2 delete-snapshot --snapshot-id "${snap}" || true
    set +x
  done
fi
