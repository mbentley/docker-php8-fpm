#!/bin/sh

MAX_SIZE=${MAX_SIZE:-8}
MAX_CHILDREN=${MAX_CHILDREN:-5}
MEMORY_LIMIT=${MEMORY_LIMIT:-128}
LISTEN=${LISTEN:-socket}

if [ ! -d /run/php ]
then
  mkdir /run/php
fi

if [ ! -f /tmp/configured ]
then
  if [ ! "${MAX_SIZE}" = "8" ]
  then
    echo "Setting 'post_max_size' and 'upload_max_filesize' to '${MAX_SIZE}'"
    sed -i "s/post_max_size = 8M/post_max_size = ${MAX_SIZE}M/g" /etc/php8/php.ini
    sed -i "s/upload_max_filesize = 8M/upload_max_filesize = ${MAX_SIZE}M/g" /etc/php8/php.ini
  else
    echo "Using default value '${MAX_SIZE}' for 'post_max_size' and 'upload_max_filesize'"
  fi

  if [ ! "${MAX_CHILDREN}" = "5" ]
  then
    echo "Setting 'max_children' to '${MAX_CHILDREN}'"
    sed -i "s/pm.max_children = 5/pm.max_children = ${MAX_CHILDREN}/g" /etc/php8/php-fpm.d/www.conf
  else
    echo "Using default value '${MAX_CHILDREN}' for 'pm.max_children'"
  fi

  if [ "${LISTEN}" = "port" ]
  then
    echo "Disabling UNIX socket; enabling listening on TCP port 9000"
    sed -i "s#listen = /var/run/php/php-fpm8.sock#listen = 9000#g" /etc/php8/php-fpm.d/www.conf
  else
    echo "Using default value 'listen = /var/run/php/php-fpm8.sock' for 'listen'"
  fi

  if [ ! "${MEMORY_LIMIT}" = "128" ]
  then
    echo "Setting 'memory_limit' to '${MEMORY_LIMIT}'"
    sed -i "s/memory_limit = 128M/memory_limit = ${MEMORY_LIMIT}M/g" /etc/php8/php.ini
  else
    echo "Using default value '${MEMORY_LIMIT}' for 'memory_limit'"
  fi

  touch /tmp/configured
  echo "Configuration complete."
fi

exec "$@"
