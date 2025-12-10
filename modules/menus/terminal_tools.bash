#!/bin/bash
# Windows CRLF düzeltme kontrolü
if [ -f "$0" ]; then
    if file "$0" | grep -q "CRLF"; then
        if command -v dos2unix &> /dev/null; then dos2unix "$0"; elif command -v sed &> /dev/null; then sed -i 's/\r$//' "$0"; fi
        exec bash "$0" "$@"
    fi
fi
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

: "${RED:=\033[0;31m}"
: "${GREEN:=\033[0;32m}"
: "${YELLOW:=\033[1;33m}"
: "${BLUE:=\033[0;34m}"
: "${CYAN:=\033[0;36m}"
: "${NC:=\033[0m}"

declare -A TERMINAL_MENU_TEXT_EN=(
    ["menu_title"]="Terminal Tools Menu"
    ["option1"]="Zsh (Shell, Framework, Plugins & Configuration)"
    ["optionA"]="Install All Terminal Tools"
    ["option_return"]="Return to Main Menu"
    ["menu_hint"]="You can make multiple selections with commas (e.g., 1)."
    ["prompt_choice"]="Your choice"
    ["info_returning"]="Returning to the main menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["prompt_continue"]="Install another terminal tool? (y/n) [n]: "
)

declare -A TERMINAL_MENU_TEXT_TR=(
    ["menu_title"]="Terminal Araçları Menüsü"
    ["option1"]="Zsh (Shell, Framework, Eklentiler ve Yapılandırma)"
    ["optionA"]="Tüm Terminal Araçlarını Kur"
    ["option_return"]="Ana Menüye Dön"
    ["menu_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1)."
    ["prompt_choice"]="Seçiminiz"
    ["info_returning"]="Ana menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["prompt_continue"]="Başka bir terminal aracı kurmak ister misiniz? (e/h) [h]: "
)

terminal_menu_text() {
    local key="$1"
    local default_value="${TERMINAL_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${TERMINAL_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_terminal_tools_menu() {
    local install_all="${1:-""}"

    while true; do
        local choices=""
        if [ -z "$install_all" ]; then
            clear
            print_heading_panel "$(terminal_menu_text menu_title)"
            echo -e "  ${GREEN}1${NC} - $(terminal_menu_text option1)"
            echo -e "  ${GREEN}A${NC} - $(terminal_menu_text optionA)"
            echo -e "  ${GREEN}0${NC} - $(terminal_menu_text option_return)"
            echo -e "${YELLOW}$(terminal_menu_text menu_hint)${NC}"

            read -r -p "$(terminal_menu_text prompt_choice): " choices </dev/tty
            if [ "$choices" = "0" ] || [ -z "$choices" ]; then
                log_info_detail "$(terminal_menu_text info_returning)"
                break
            fi
        else
            choices="A" # Install all
        fi

        local all_installed=false
        IFS=',' read -ra SELECTED_ITEMS <<< "$choices"

        for choice in "${SELECTED_ITEMS[@]}"; do
            choice=$(echo "$choice" | tr -d '[:space:]')
            case $choice in
                1) run_module "menus/zsh_plugins" ;;
                A|a) 
                    run_module "menus/zsh_plugins" "all"
                    all_installed=true
                    ;;
                0) 
                    log_info_detail "$(terminal_menu_text info_returning)"
                    return 0
                    ;;
                *) 
                    log_error_detail "$(terminal_menu_text warning_invalid_choice): $choice"
                    ;;
            esac
        done

        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "$(terminal_menu_text prompt_continue): " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

main() {
    install_terminal_tools_menu "$@"
}

main "$@"