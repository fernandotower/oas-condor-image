#!/bin/bash

set -eu

while getopts ":r:c:" opt; do
  case $opt in
    r)
      condor_repo="${OPTARG}"
      ;;
    c)
      condor_commit="${OPTARG}"
      ;;
  esac
done

CONDOR_REPO="${condor_repo:-${CONDOR_REPO:-}}"
if [ -z "${CONDOR_REPO}" ]
then
  unset CONDOR_REPO
  echo "No se ha definido el nombre repositorio de git, definalo con -r <nombre_repo> o con la variable de entorno CONDOR_REPO"
  exit 1
else
  echo "Se bajará condor del siguiente repositorio de git: ${CONDOR_REPO}"
  export CONDOR_REPO
fi

CONDOR_COMMMIT="${condor_commit:-${CONDOR_COMMIT:-}}"
if [ -z "${CONDOR_COMMIT}" ]
then
  unset CONDOR_COMMIT
  echo "No se ha definido el commit del repositorio de git, definalo con -c <id_commit> o con la variable de entorno CONDOR_COMMIT"
  exit 1
else
  echo "Se utilizará el siguiente identificador de commit de git: ${CONDOR_COMMIT}"
  export CONDOR_COMMIT
fi

git clone "${CONDOR_REPO}" /tmp/condor.$$
pushd /tmp/condor.$$
git reset --hard "${CONDOR_COMMIT}"
git ls-files -z | xargs -0 tar cf condor.tar
popd
mv /tmp/condor.$$/condor.tar .
rm -rf /tmp/condor.$$
