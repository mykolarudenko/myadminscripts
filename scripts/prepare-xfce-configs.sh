#!/bin/bash
# Copyright (c) 2024 Mykola Rudenko
# This script is licensed under the MIT License.
# See the LICENSE file for details.
# https://github.com/mykolarudenko/myadminscripts
#
# prepare-xfce-configs.sh
#
# This script prepares XFCE configuration files for templating.
# It recursively finds files in the 'scripts/xfce-config' directory
# and replaces any hardcoded user paths (e.g., /home/someuser)
# with a generic placeholder.
#
# For example, a path like '/home/mykola/.config/...' or '/home/user2/.config/...'
# will be changed to '${user_home}/.config/...'.

set -euo pipefail

# The script's directory, which is assumed to be 'scripts'
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONFIG_DIR="${SCRIPT_DIR}/xfce-config"

# The placeholder that will be used in the templates.
PLACEHOLDER='${user_home}'

if [[ ! -d "${CONFIG_DIR}" ]]; then
    echo "Error: Configuration directory not found at ${CONFIG_DIR}" >&2
    exit 1
fi

echo "Preparing XFCE configs in: ${CONFIG_DIR}"
echo "Replacing all user-specific home directory paths (e.g., /home/someuser) with '${PLACEHOLDER}'..."

# Use find to locate all files (excluding cargo.list) and sed to perform in-place replacement.
# The regex matches '/home/' followed by any sequence of non-slash characters.
find "${CONFIG_DIR}" -type f -not -name "cargo.list" -exec sed -i -E "s|/home/[^/]+|${PLACEHOLDER}|g" {} +

echo "Configuration files have been prepared successfully."
