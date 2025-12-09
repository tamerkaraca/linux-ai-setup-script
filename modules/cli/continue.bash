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
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

# Define an associative array for messages in English and Turkish
declare -A MESSAGES_EN=(
    ["install_continue_cli"]="Installing Continue CLI..."
    ["install_continue_cli_success"]="Continue CLI installed successfully."
    ["install_continue_cli_fail"]="Failed to install Continue CLI."
    ["check_node_npm"]="Checking for Node.js and npm..."
    ["node_npm_found"]="Node.js and npm found."
    ["node_npm_not_found"]="Node.js and/or npm not found. Please install them to proceed."
    ["check_if_installed"]="Checking if Continue CLI is already installed..."
    ["already_installed"]="Continue CLI is already installed."
)

declare -A MESSAGES_TR=(
    ["install_continue_cli"]="Continue CLI yükleniyor..."
    ["install_continue_cli_success"]="Continue CLI başarıyla yüklendi."
    ["install_continue_cli_fail"]="Continue CLI yüklenemedi."
    ["check_node_npm"]="Node.js ve npm kontrol ediliyor..."
    ["node_npm_found"]="Node.js ve npm bulundu."
    ["node_npm_not_found"]="Node.js ve/veya npm bulunamadı. Devam etmek için lütfen bunları yükleyin."
    ["check_if_installed"]="Continue CLI'nın zaten yüklü olup olmadığı kontrol ediliyor..."
    ["already_installed"]="Continue CLI zaten yüklü."
)

# Function to get translated messages
message() {
    local key="$1"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${MESSAGES_TR[$key]:-${MESSAGES_EN[$key]}}"
    else
        printf "%s" "${MESSAGES_EN[$key]:-$key}"
    fi
}

# Function to check for Node.js and npm
check_node_npm() {
    log_info "$(message check_node_npm)"
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        log_success "$(message node_npm_found)"
        return 0
    else
        log_error "$(message node_npm_not_found)"
        return 1
    fi
}

# Main installation function
install_continue_cli() {
    install_package "Continue CLI" "npm" "continue" "@continuedev/cli"
    return $?
}

# Ensure Node.js and npm are available before attempting installation
if check_node_npm; then
    install_continue_cli "$@"
else
    exit 1
fi
