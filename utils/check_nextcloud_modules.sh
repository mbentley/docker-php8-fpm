#!/bin/bash

# check the php modules in each image against the nextcloud requirements table
#   usage: ./utils/check_nextcloud_modules.sh [--pull] [version ...]
#   --pull: test the published mbentley/php8-fpm:<version> images instead of building the local Dockerfiles

set -e

cd "$(dirname "${0}")/.."

REQUIREMENTS_TABLE="utils/requirements_table.rst"
IMAGE_REPO="mbentley/php8-fpm"
PULL="false"

if [ "${1}" = "--pull" ]
then
  PULL="true"
  shift
fi

# default to the expected supported versions
VERSIONS="${*:-8.2 8.3 8.4 8.5}"

# parse the table into "module|category" lines; rows that continue a description have an empty module column
parse_requirements() {
  grep '^| ' "${REQUIREMENTS_TABLE}" | awk -F '|' '
    {
      module = $2; gsub(/[ *]/, "", module)
      if (module == "" || module == "Module") next
      if ($3 ~ /✓/) category = "required"
      else if ($4 ~ /✓/) category = "recommended"
      else if ($5 ~ /optional/) category = "app-optional"
      else category = "app"
      print tolower(module) "|" category
    }'
}

# some rows are binaries rather than php modules
binary_candidates() {
  case "${1}" in
    avconv/ffmpeg) echo "avconv ffmpeg";;
    open/libreoffice) echo "libreoffice soffice";;
  esac
}

FAILED_VERSIONS=""

for VER in ${VERSIONS}
do
  if [ "${PULL}" = "true" ]
  then
    IMAGE="${IMAGE_REPO}:${VER}"
    docker pull -q "${IMAGE}" >/dev/null
  else
    IMAGE="${IMAGE_REPO}:${VER}-modtest"
    echo "INFO: building ${IMAGE} from Dockerfile.${VER}..."
    docker build -q -f "Dockerfile.${VER}" -t "${IMAGE}" . >/dev/null
  fi

  # get the loaded modules (lowercase, without section headers) plus which candidate binaries exist
  INSTALLED_MODULES="$(docker run --rm "${IMAGE}" php -m | grep -v -e '^\[' -e '^$' | tr '[:upper:]' '[:lower:]')"
  INSTALLED_BINARIES="$(docker run --rm "${IMAGE}" sh -c 'for B in avconv ffmpeg libreoffice soffice; do command -v "${B}" >/dev/null && echo "${B}"; done; true')"

  echo
  echo "=== php ${VER} (${IMAGE})"
  printf '%-18s %-14s %s\n' "MODULE" "CATEGORY" "STATUS"

  MISSING_REQUIRED=""
  while IFS='|' read -r MODULE CATEGORY
  do
    CANDIDATES="$(binary_candidates "${MODULE}")"
    if [ -n "${CANDIDATES}" ]
    then
      STATUS="missing (binary)"
      for B in ${CANDIDATES}
      do
        if echo "${INSTALLED_BINARIES}" | grep -qx "${B}"
        then
          STATUS="ok (binary: ${B})"
          break
        fi
      done
    elif echo "${INSTALLED_MODULES}" | grep -qx "${MODULE}"
    then
      STATUS="ok"
    else
      STATUS="MISSING"
      if [ "${CATEGORY}" = "required" ]
      then
        MISSING_REQUIRED="${MISSING_REQUIRED} ${MODULE}"
      fi
    fi
    printf '%-18s %-14s %s\n' "${MODULE}" "${CATEGORY}" "${STATUS}"
  done < <(parse_requirements)

  if [ -n "${MISSING_REQUIRED}" ]
  then
    echo "WARN: php ${VER} is missing required module(s):${MISSING_REQUIRED}"
    FAILED_VERSIONS="${FAILED_VERSIONS} ${VER}"
  else
    echo "INFO: php ${VER} has all required modules"
  fi
done

if [ -n "${FAILED_VERSIONS}" ]
then
  echo
  echo "WARN: version(s) missing required modules:${FAILED_VERSIONS}"
  exit 1
fi
