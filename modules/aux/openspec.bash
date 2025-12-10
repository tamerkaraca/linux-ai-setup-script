#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

# Prefer local direct source (relative to this file). If not available, fall back to
# the setup-provided `source_module` helper when running under the main `setup` script.
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

declare -A OPENSPEC_TEXT_EN=(
    ["install_title"]="Starting OpenSpec CLI installation..."
    ["install_fail"]="OpenSpec CLI installation failed."
)

declare -A OPENSPEC_TEXT_TR=(
    ["install_title"]="OpenSpec CLI kurulumu başlatılıyor..."
    ["install_fail"]="OpenSpec CLI kurulumu başarısız oldu."
)

openspec_text() {
    local key="$1"
    local default_value="${OPENSPEC_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${OPENSPEC_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

main() {
    log_info_detail "$(openspec_text install_title)"
    
    require_node_version 18 "OpenSpec CLI" || return 1
    
    install_package "OpenSpec CLI" "npm" "openspec" "@fission-ai/openspec"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(openspec_text install_fail)"
        return 1
    fi
    
    log_success_detail "OpenSpec CLI installed successfully."
}

main "$@"