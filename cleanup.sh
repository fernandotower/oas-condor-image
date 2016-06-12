#!/bin/bash

set -eu

while getopts ":fp:" opt; do
  case $opt in
    p)
      aws_profile="${OPTARG}"
      ;;
    f)
      force="true"
      ;;
  esac
done

source source/aws.sh

if ! type jq > /dev/null
then
  echo Instala JQ primero https://stedolan.github.io/jq/download/
  exit 1
fi

NOW="$(date +%s)"
if [ "${force:-}" = "true" ]
then
  echo Se buscaran recursos mas nuevos
  NOW="$((NOW+2592000))"
fi

echo Buscando instancias para borrar

delete_instances="$(
  aws --output json --region us-east-1 ec2 describe-instances --filters \
    "Name=tag:promoted,Values=no" \
    "Name=tag:Name,Values=Packer Builder" \
    "Name=tag:ami-name,Values=oas-condor-estudiantes" |
  jq -r --arg NOW "${NOW}" '.Reservations[]|.Instances[] | select(.Tags[]|(.Key == "expiration-timestamp" and (.Value|tonumber) <= ($NOW|tonumber))) | .InstanceId'
)"

if [ -n "$delete_instances" ]
then
  echo Borrando instancias $delete_instances
  set -x
  aws --region us-east-1 ec2 terminate-instances --instance-ids $delete_instances || true
  set +x
fi

echo Buscando amis para borrar

delete_amis="$(
  aws --output json --region us-east-1 ec2 describe-images --filters \
    "Name=tag:promoted,Values=no" \
    "Name=tag:ami-name,Values=oas-condor-estudiantes" |
  jq -r --arg NOW "${NOW}" '.Images[] | select(.Tags[]|(.Key == "expiration-timestamp" and (.Value|tonumber) <= ($NOW|tonumber))) | .ImageId'
)"

if [ -n "$delete_amis" ]
then
  echo Borrando amis $delete_amis
  for ami in $delete_amis
  do
    set -x
    aws --region us-east-1 ec2 deregister-image --image-id "${ami}" || true
    set +x
    sleep 2 # durmiendo un poco para no saturar la API
  done
fi

echo Buscando snapshots para borrar

delete_snap="$(
  aws --output json --region us-east-1 ec2 describe-snapshots --filters \
    "Name=tag:promoted,Values=no" \
    "Name=tag:ami-name,Values=oas-condor-estudiantes" |
  jq -r --arg NOW "${NOW}" '.Snapshots[] | select(.Tags[]|(.Key == "expiration-timestamp" and (.Value|tonumber) <= ($NOW|tonumber))) | .SnapshotId'
)"

if [ -n "$delete_snap" ]
then
  echo Borrando snapshots $delete_snap
  for snap in $delete_snap
  do
    set -x
    aws --region us-east-1 ec2 delete-snapshot --snapshot-id "${snap}" || true
    set +x
    sleep 2 # durmiendo un poco para no saturar la API
  done
fi
