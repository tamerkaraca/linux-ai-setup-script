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

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A AI_FW_MENU_TEXT_EN=(
    ["fw_menu_title"]="AI Frameworks Installation Menu"
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_optionA"]="Install All Frameworks"
    ["fw_option_return"]="Return to Main Menu"
    ["fw_menu_hint"]="You can make multiple selections with commas (e.g., 1,2)."
    ["prompt_choice"]="Your choice"
    ["info_returning"]="Returning to the previous menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["fw_prompt_install_more"]="Install another framework? (y/n) [n]: "
    ["pipx_required"]="Pipx is required for AI Frameworks; installing it first..."
    ["python_required"]="Python is required for Pipx; installing it first..."
    ["module_running_local"]="Running %s module from local file..."
    ["module_downloading"]="Downloading and running %s module..."
    ["module_error"]="An error occurred while running the %s module."
)

declare -A AI_FW_MENU_TEXT_TR=(
    ["fw_menu_title"]="AI Frameworks Kurulum Menüsü"
    ["fw_option1"]="SuperGemini Framework"
    ["fw_option2"]="SuperQwen Framework"
    ["fw_option3"]="SuperClaude Framework"
    ["fw_optionA"]="Tüm Framework'leri Kur"
    ["fw_option_return"]="Ana Menüye Dön"
    ["fw_menu_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2)."
    ["prompt_choice"]="Seçiminiz"
    ["info_returning"]="Bir önceki menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["fw_prompt_install_more"]="Başka bir framework kurmak ister misiniz? (e/h) [h]: "
    ["pipx_required"]="AI Frameworks için önce Pipx kurulumu yapılıyor..."
    ["python_required"]="Pipx için önce Python kurulumu yapılıyor..."
    ["module_running_local"]="%s modülü yerel dosyadan çalıştırılıyor..."
    ["module_downloading"]="%s modülü indiriliyor ve çalıştırılıyor..."
    ["module_error"]="%s modülü çalıştırılırken bir hata oluştu."
)

ai_fw_menu_text() {
    local key="$1"
    local default_value="${AI_FW_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AI_FW_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}



# AI Frameworks menüsü
install_ai_frameworks_menu() {

    local install_all="${1:-}" # "all" parametresi gelirse hepsini kur

    while true; do
        if [ -z "$install_all" ]; then
            clear
            print_heading_panel "$(ai_fw_menu_text fw_menu_title)"
            echo -e "  ${GREEN}1${NC} - $(ai_fw_menu_text fw_option1)"
            echo -e "  ${GREEN}2${NC} - $(ai_fw_menu_text fw_option2)"
            echo -e "  ${GREEN}3${NC} - $(ai_fw_menu_text fw_option3)"
            echo -e "  ${GREEN}A${NC} - $(ai_fw_menu_text fw_optionA)"
            echo -e "  ${GREEN}0${NC} - $(ai_fw_menu_text fw_option_return)"
            echo -e "${YELLOW}$(ai_fw_menu_text fw_menu_hint)${NC}"

            read -r -p "$(ai_fw_menu_text prompt_choice): " framework_choices </dev/tty
            if [ "$framework_choices" = "0" ] || [ -z "$framework_choices" ]; then
                log_info_detail "$(ai_fw_menu_text info_returning)"
                break
            fi
        else
            framework_choices="A" # "all" parametresi gelirse tümünü seç
        fi

        # Pipx kontrolü
        if ! command -v pipx &> /dev/null; then
            log_warn_detail "$(ai_fw_menu_text pipx_required)"
            if ! command -v python3 &> /dev/null; then
                 log_warn_detail "$(ai_fw_menu_text python_required)"
                 install_python
            fi
            install_pipx
        fi

        local all_installed=false
        IFS=',' read -ra SELECTED_FW <<< "$framework_choices"

        for choice in "${SELECTED_FW[@]}"; do
            choice=$(echo "$choice" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
            case $choice in
                1) run_module "frameworks/supergemini" ;;
                2) run_module "frameworks/superqwen" ;;
                3) run_module "frameworks/superclaude" ;;
                A) 
                    run_module "frameworks/supergemini"
                    run_module "frameworks/superqwen"
                    run_module "frameworks/superclaude"
                    all_installed=true
                    ;;
                0)
                    log_info_detail "$(ai_fw_menu_text info_returning)"
                    return 0
                    ;;
                *) log_error_detail "$(ai_fw_menu_text warning_invalid_choice): $choice" ;;
            esac
        done
        
        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "$(ai_fw_menu_text fw_prompt_install_more): " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

# Ana kurulum akışı
main() {
    install_ai_frameworks_menu "$@"
}

main "$@"
