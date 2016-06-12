if [ -z "${SOURCE_AWS_SH:-}" ]
then
  SOURCE_AWS_SH=sourced
  AWS_PROFILE="${aws_profile:-${AWS_PROFILE:-}}"

  if [ -n "${AWS_SECRET_ACCESS_KEY:-}" ]
  then
    SHADOW_AWS_SECRET_ACCESS_KEY="**********"
  fi

  if [ -n "${AWS_AWS_SESSION_TOKEN:-}" ]
  then
    SHADOW_AWS_SESSION_TOKEN="**********"
  fi

  if [ -z "${AWS_PROFILE}" ]
  then
    unset AWS_PROFILE
    echo "Se usaran las credenciales de AWS por defecto"
    echo "AWS_DEFAULT_PROFILE   = '${AWS_DEFAULT_PROFILE:-}'"
    echo "AWS_ACCESS_KEY_ID     = '${AWS_ACCESS_KEY_ID:-}'"
    echo "AWS_SECRET_ACCESS_KEY = '${SHADOW_AWS_SECRET_ACCESS_KEY:-}'"
    echo "AWS_SESSION_TOKEN     = '${SHADOW_AWS_SESSION_TOKEN:-}'"
  else
    echo "Se usará el perfil guardado en '~/.aws/credentials' llamado '${AWS_PROFILE}'"
    export AWS_PROFILE
    unset AWS_DEFAULT_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
  fi
fi
