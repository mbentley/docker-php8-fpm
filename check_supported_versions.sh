#!/bin/sh

# set expected supported versions
EXPECTED_SUPPORTED_VERSIONS="8.1 8.2 8.3 8.4 8.5"

# get supported versions
SUPPORTED_VERSIONS="$(curl -s "https://www.php.net/releases/index.php?json" | jq -r .'["8"].supported_versions|.[]' | xargs)"

# compare expected supported versions to those form php.net
if [ "${SUPPORTED_VERSIONS}" != "${EXPECTED_SUPPORTED_VERSIONS}" ]
then
  echo "WARN: supported versions from php.net (${SUPPORTED_VERSIONS}) are different than the expected supported versions (${EXPECTED_SUPPORTED_VERSIONS})!"
  exit 1
else
  echo "INFO: supported versions (${SUPPORTED_VERSIONS}) match as expected."
fi
