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
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
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

declare -A ZSH_PLUGINS_MENU_TEXT_EN=(
    ["menu_title"]="Zsh Complete Setup Menu"
    ["option1"]="Install Zsh (Advanced Shell)"
    ["option2"]="Install Oh My Zsh (Framework)"
    ["option3"]="Zsh Autosuggestions"
    ["option4"]="Zsh Syntax Highlighting"
    ["option5"]="Powerlevel10k Theme"
    ["option6"]="Zsh Completions"
    ["option7"]="Configure Zsh (.zshrc)"
    ["optionA"]="Install All Zsh Components"
    ["option_return"]="Return to Terminal Tools Menu"
    ["menu_hint"]="You can make multiple selections with commas (e.g., 1,2,7)."
    ["prompt_choice"]="Your choice"
    ["info_returning"]="Returning to terminal tools menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["prompt_continue"]="Install another Zsh component? (y/n) [n]: "
)

declare -A ZSH_PLUGINS_MENU_TEXT_TR=(
    ["menu_title"]="Zsh Tam Kurulum Menüsü"
    ["option1"]="Zsh Kur (Gelişmiş Shell)"
    ["option2"]="Oh My Zsh Kur (Framework)"
    ["option3"]="Zsh Otomatik Öneriler"
    ["option4"]="Zsh Sözdizimi Vurgulama"
    ["option5"]="Powerlevel10k Teması"
    ["option6"]="Zsh Tamamlamaları"
    ["option7"]="Zsh Yapılandır (.zshrc)"
    ["optionA"]="Tüm Zsh Bileşenlerini Kur"
    ["option_return"]="Terminal Araçları Menüsüne Dön"
    ["menu_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2,7)."
    ["prompt_choice"]="Seçiminiz"
    ["info_returning"]="Terminal araçları menüsüne dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["prompt_continue"]="Başka bir Zsh bileşeni kurmak ister misiniz? (e/h) [h]: "
)

zsh_plugins_menu_text() {
    local key="$1"
    local default_value="${ZSH_PLUGINS_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${ZSH_PLUGINS_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_zsh_plugins_menu() {
    local install_all="${1:-""}"

    while true; do
        local choices=""
        if [ -z "$install_all" ]; then
            clear
            print_heading_panel "$(zsh_plugins_menu_text menu_title)"
            log_info_detail "  1 - $(zsh_plugins_menu_text option1)"
            log_info_detail "  2 - $(zsh_plugins_menu_text option2)"
            log_info_detail "  3 - $(zsh_plugins_menu_text option3)"
            log_info_detail "  4 - $(zsh_plugins_menu_text option4)"
            log_info_detail "  5 - $(zsh_plugins_menu_text option5)"
            log_info_detail "  6 - $(zsh_plugins_menu_text option6)"
            log_info_detail "  7 - $(zsh_plugins_menu_text option7)"
            log_info_detail "  A - $(zsh_plugins_menu_text optionA)"
            log_info_detail "  0 - $(zsh_plugins_menu_text option_return)"
            log_info_detail "$(zsh_plugins_menu_text menu_hint)"

            read -r -p "$(zsh_plugins_menu_text prompt_choice): " choices </dev/tty
            if [ "$choices" = "0" ] || [ -z "$choices" ]; then
                log_info_detail "$(zsh_plugins_menu_text info_returning)"
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
                1) run_module "setup/zsh" ;;
                2) run_module "setup/oh_my_zsh" ;;
                3) run_module "setup/zsh_autosuggestions" ;;
                4) run_module "setup/zsh_syntax_highlighting" ;;
                5) run_module "setup/powerlevel10k" ;;
                6) run_module "setup/zsh_completions" ;;
                7) run_module "setup/configure_zsh" ;;
                A|a) 
                    run_module "setup/zsh"
                    run_module "setup/oh_my_zsh"
                    run_module "setup/zsh_autosuggestions"
                    run_module "setup/zsh_syntax_highlighting"
                    run_module "setup/powerlevel10k"
                    run_module "setup/zsh_completions"
                    run_module "setup/configure_zsh"
                    all_installed=true
                    ;;
                0) 
                    log_info_detail "$(zsh_plugins_menu_text info_returning)"
                    return 0
                    ;;
                *) 
                    log_error_detail "$(zsh_plugins_menu_text warning_invalid_choice): $choice"
                    ;;
            esac
        done

        if [ "$all_installed" = true ] || [ -n "$install_all" ]; then
            break
        fi

        read -r -p "$(zsh_plugins_menu_text prompt_continue): " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

main() {
    install_zsh_plugins_menu "$@"
}

main "$@"