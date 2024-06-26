#!/bin/bash

set -e

# figure out the php version from the symlink
PHP_VER="$(readlink -f /usr/bin/php | awk -F '/' '{print $NF}')"

# make sure /run/php exists
if [ ! -d /run/php ]
then
  mkdir /run/php
fi

# get a list of variables that start with PHP_INI_
ENV_VARS_PHP_INI="$(env | awk -F '=' '{print $1}' | grep ^PHP_INI_ | sort)"

# skip if empty
if [ -n "${ENV_VARS_PHP_INI}" ]
then
  # loop through variables to output the contents
  for VAR in ${ENV_VARS_PHP_INI}
  do
    # set VAR to varname
    VARNAME="${VAR}"

    # use substitution to output the contents of the variable
    echo "${!VARNAME}"
  done > "/etc/${PHP_VER}/conf.d/99_entrypoint_var_customizations.ini"
fi

# get a list of variables that start with PHP_FPM_
ENV_VARS_PHP_FPM="$(env | awk -F '=' '{print $1}' | grep ^PHP_FPM_ | sort)"

# skip if empty
if [ -n "${ENV_VARS_PHP_FPM}" ]
then
  # loop through variables to output the contents
  for VAR in ${ENV_VARS_PHP_FPM}
  do
    # set VAR to varname
    VARNAME="${VAR}"

    # use substitution to output the contents of the variable
    echo "${!VARNAME}"
  done > "/etc/${PHP_VER}/php-fpm.d/www.inc"
else
  # touch to file to not have a warning
  touch "/etc/${PHP_VER}/php-fpm.d/www.inc"
fi

# run the actual command
exec "$@"
