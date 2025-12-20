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

# Text for the module
declare -A conductor_texts
conductor_texts[module_name_en]="Conductor Gemini Extension"
conductor_texts[module_name_tr]="Conductor Gemini Eklentisi"
conductor_texts[installing_en]="Installing Conductor for Gemini CLI..."
conductor_texts[installing_tr]="Gemini CLI için Conductor kuruluyor..."
conductor_texts[gemini_not_found_en]="Gemini CLI is not installed. Please install it first from the 'AI CLI Tools' menu."
conductor_texts[gemini_not_found_tr]="Gemini CLI kurulu değil. Lütfen önce 'AI CLI Araçları' menüsünden kurun."
conductor_texts[success_en]="Conductor extension for Gemini CLI has been successfully installed."
conductor_texts[success_tr]="Gemini CLI için Conductor eklentisi başarıyla kuruldu."
conductor_texts[usage_title_en]="Usage:"
conductor_texts[usage_title_tr]="Kullanım:"
conductor_texts[usage_en]="You can now use Conductor features with the Gemini CLI. For example: 'gemini --conductor:setup'"
conductor_texts[usage_tr]="Artık Gemini CLI ile Conductor özelliklerini kullanabilirsiniz. Örneğin: 'gemini --conductor:setup'"

# Function to install the Conductor extension
install_conductor() {
    local lang_suffix
    lang_suffix=$(get_lang_suffix)
    log_info_detail "${conductor_texts[installing_${lang_suffix}]}"

    # Check for Gemini CLI prerequisite
    if ! command -v gemini &> /dev/null; then
        log_error_detail "${conductor_texts[gemini_not_found_${lang_suffix}]}"
        return 1
    fi

    # Check if Conductor is already installed
    if gemini extensions list | grep -q "conductor"; then
        log_success_detail "Conductor extension for Gemini CLI is already installed."
        log_info_detail "${conductor_texts[usage_title_${lang_suffix}]}"
        log_info_detail "  ${conductor_texts[usage_en]}"
        return 0
    fi

    # Install the extension
    if gemini extensions install https://github.com/gemini-cli-extensions/conductor; then
        log_success_detail "${conductor_texts[success_${lang_suffix}]}"
        log_info_detail "${conductor_texts[usage_title_${lang_suffix}]}"
        log_info_detail "  ${conductor_texts[usage_en]}"
    else
        log_error_detail "Failed to install the Conductor extension."
        return 1
    fi
}

main() {
    install_conductor
}

main "$@"
