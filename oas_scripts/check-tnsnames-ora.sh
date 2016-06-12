#!/bin/bash

# rationale: Si no existe el archivo de configuración de conexiones a Oracle o éste no se encuentra configurado con la conexión necesaria, esta instancia no tiene propósito real y debe terminarse

set -eu

sleep 600 # Esperar mientras se crea la AMI o se aprovisiona el host por medio de user-data

check_file="/etc/httpd/conf/tnsnames.ora"
check_text="DEFAULT_CONNECTION_CLASS"

# http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
instance_document="$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document)"
instance_id="$(jq -r .instanceId <<< "${instance_document}")"
instance_region="$(jq -r .region <<< "${instance_document}")"

if [ -z "${instance_id}" -o -z "${instance_region}" ]
then
  wall "No se pudo encontrar la información de la instancia"
  exit 0
fi

terminate_cmd="aws --region ${instance_region} ec2 terminate-instances --instance-ids ${instance_id}"

if [ ! -e $check_file ]
then
  wall "No existe el archivo '${check_file}'. Terminando instancia."
  $terminate_cmd
elif ! grep $check_text $check_file
then
  wall "El archivo '${check_file}' no contiene '${check_text}'. Terminando instancia."
  $terminate_cmd
fi
