#!/bin/bash
#
# prepare-xfce-configs.sh
#
# This script prepares XFCE configuration files for templating.
# It recursively finds files in the 'scripts/xfce-config' directory
# and replaces any hardcoded paths containing a specific username
# with a generic placeholder.
#
# For example, a path like '/home/mykola/.config/...' will be changed to
# '${user_home}/.config/...'.

set -euo pipefail

# The script's directory, which is assumed to be 'scripts'
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONFIG_DIR="${SCRIPT_DIR}/xfce-config"

# The hardcoded user path to be replaced.
USER_PATH_TO_REPLACE="/home/mykola"

# The placeholder that will be used in the templates.
PLACEHOLDER='${user_home}'

if [[ ! -d "${CONFIG_DIR}" ]]; then
    echo "Error: Configuration directory not found at ${CONFIG_DIR}" >&2
    exit 1
fi

echo "Preparing XFCE configs in: ${CONFIG_DIR}"
echo "Replacing all occurrences of '${USER_PATH_TO_REPLACE}' with '${PLACEHOLDER}'..."

# Use find to locate all files (excluding cargo.list) and sed to perform in-place replacement.
find "${CONFIG_DIR}" -type f -not -name "cargo.list" -exec sed -i "s|${USER_PATH_TO_REPLACE}|${PLACEHOLDER}|g" {} +

echo "Configuration files have been prepared successfully."
