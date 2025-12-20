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

OPENAGENTS_REPO="https://github.com/darrenhinde/OpenAgents.git"
OPENCODE_DIR="$HOME/.opencode"

# --- Start: OpenAgents-specific logic ---
declare -A OPENAGENTS_TEXT_EN=(
    ["install_title"]="Installing OpenAgents from darrenhinde/OpenAgents..."
    ["git_missing"]="'git' command not found. Please install git first."
    ["cloning"]="Cloning OpenAgents repository..."
    ["clone_fail"]="Failed to clone the OpenAgents repository."
    ["copying"]="Copying agents, commands, and contexts to ${OPENCODE_DIR}..."
    ["copy_fail"]="Failed to copy files."
    ["install_done"]="OpenAgents installation completed successfully."
    ["usage_note"]="You can now use the new agents and commands with 'opencode'."
)

declare -A OPENAGENTS_TEXT_TR=(
    ["install_title"]="darrenhinde/OpenAgents deposundan OpenAgents kurulumu..."
    ["git_missing"]="'git' komutu bulunamadı. Lütfen önce git kurun."
    ["cloning"]="OpenAgents deposu klonlanıyor..."
    ["clone_fail"]="OpenAgents deposu klonlanamadı."
    ["copying"]="Ajanlar, komutlar ve bağlamlar ${OPENCODE_DIR} dizinine kopyalanıyor..."
    ["copy_fail"]="Dosyalar kopyalanamadı."
    ["install_done"]="OpenAgents kurulumu başarıyla tamamlandı."
    ["usage_note"]="Artık yeni ajanları ve komutları 'opencode' ile kullanabilirsiniz."
)

openagents_text() {
    local key="$1"
    local default_value="${OPENAGENTS_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${OPENAGENTS_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}
# --- End: OpenAgents-specific logic ---

main() {
    log_info_detail "$(openagents_text install_title)"

    if ! command -v git &> /dev/null; then
        log_error_detail "$(openagents_text git_missing)"
        return 1
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' RETURN

    log_info_detail "$(openagents_text cloning)"
    if ! git clone --depth=1 "$OPENAGENTS_REPO" "$temp_dir/OpenAgents"; then
        log_error_detail "$(openagents_text clone_fail)"
        return 1
    fi
    
    log_info_detail "$(openagents_text copying)"
    mkdir -p "${OPENCODE_DIR}"
    if ! cp -r "$temp_dir/OpenAgents/.opencode/." "${OPENCODE_DIR}/"; then
        log_error_detail "$(openagents_text copy_fail)"
        return 1
    fi

    log_success_detail "$(openagents_text install_done)"
    log_info_detail "$(openagents_text usage_note)"
    trap - RETURN
}

main "$@"
