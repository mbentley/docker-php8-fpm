#!/bin/bash

# download the nextcloud php configuration docs and extract the "PHP Module Quick Reference Table" section
#   into utils/requirements_table.rst for use by check_nextcloud_modules.sh

set -e

cd "$(dirname "${0}")/.."

REQUIREMENTS_TABLE="utils/requirements_table.rst"
SOURCE_URL="https://raw.githubusercontent.com/nextcloud/documentation/refs/heads/master/admin_manual/installation/php_configuration.rst"
SECTION_TITLE="PHP Module Quick Reference Table"

TMP_SOURCE="$(mktemp)"
TMP_TABLE="$(mktemp)"
trap 'rm -f "${TMP_SOURCE}" "${TMP_TABLE}"' EXIT

curl -fsSL "${SOURCE_URL}" -o "${TMP_SOURCE}"

# print from the section title (including its overline) up to, but not including, the next section heading
awk -v title="${SECTION_TITLE}" '
  { line[NR] = $0 }
  END {
    for (i = 1; i <= NR; i++) if (line[i] == title) { start = i - 1; break }
    if (!start) exit 1
    end = NR
    for (i = start + 3; i <= NR - 2; i++) {
      if (line[i] ~ /^-+$/ && line[i + 1] !~ /^[-+|]/ && line[i + 1] != "" && line[i + 2] ~ /^-+$/) { end = i - 1; break }
    }
    # trim trailing blank lines
    while (end > start && line[end] == "") end--
    for (i = start; i <= end; i++) print line[i]
  }' "${TMP_SOURCE}" > "${TMP_TABLE}" || { echo "ERROR: could not find the '${SECTION_TITLE}' section in ${SOURCE_URL}"; exit 1; }

# make sure the table columns are still in the order that check_nextcloud_modules.sh expects
if ! grep -qE '^\| Module +\| Required +\| Recommended +\| For Specific App +\| Description +\|$' "${TMP_TABLE}"
then
  echo "ERROR: the table header has changed format; review ${SOURCE_URL} and update ${REQUIREMENTS_TABLE} manually"
  exit 1
fi

if [ -f "${REQUIREMENTS_TABLE}" ] && diff -q "${REQUIREMENTS_TABLE}" "${TMP_TABLE}" >/dev/null
then
  echo "INFO: ${REQUIREMENTS_TABLE} is already up to date"
else
  diff -u "${REQUIREMENTS_TABLE}" "${TMP_TABLE}" || true
  cp "${TMP_TABLE}" "${REQUIREMENTS_TABLE}"
  echo "INFO: updated ${REQUIREMENTS_TABLE}"
fi
