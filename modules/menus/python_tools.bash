#!/bin/bash
set -eu
if set -o | grep -q 'pipefail'; then
    set -o pipefail
fi

# Ortak yardımcı fonksiyonları yükle
# Resolve the directory this script lives in so sources work regardless of CWD
current_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$current_script_dir/../utils/utils.bash"
platform_local="$current_script_dir/../utils/platform_detection.bash"

# When running remotely, we might be in a different directory structure
# Check multiple possible locations for utils
utils_loaded=false
platform_loaded=false

# Try to load utils from various possible locations
for utils_path in "$utils_local" "$current_script_dir/../../utils/utils.bash" "$current_script_dir/utils/utils.bash" "/tmp/utils.bash"; do
    if [ -f "$utils_path" ]; then
        # shellcheck source=/dev/null
        source "$utils_path"
        utils_loaded=true
        break
    fi
done

# If still not loaded, try source_module
if [ "$utils_loaded" = false ] && declare -f source_module > /dev/null 2>&1; then
    if source_module "utils/utils.bash" "modules/utils/utils.bash"; then
        utils_loaded=true
    fi
fi

if [ "$utils_loaded" = false ]; then
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried multiple locations)" >&2
    exit 1
fi

# Try to load platform_detection from various possible locations
for platform_path in "$platform_local" "$current_script_dir/../../utils/platform_detection.bash" "$current_script_dir/utils/platform_detection.bash" "/tmp/platform_detection.bash"; do
    if [ -f "$platform_path" ]; then
        # shellcheck source=/dev/null
        source "$platform_path"
        platform_loaded=true
        break
    fi
done

# If still not loaded, try source_module
if [ "$platform_loaded" = false ] && declare -f source_module > /dev/null 2>&1; then
    if source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"; then
        platform_loaded=true
    fi
fi

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A PY_TEXT_EN=(
    ["menu_title"]="Python Tooling Menu"
    ["menu_option1"]="Install Python 3"
    ["menu_option2"]="Install or update Pip"
    ["menu_option3"]="Install Pipx"
    ["menu_option4"]="Install UV"
    ["menu_option_all"]="Install everything"
    ["menu_option0"]="Return to main menu"
    ["menu_hint"]="Use commas for multiple selections (e.g., 1,3)."
    ["menu_prompt"]="Your choice"
    ["menu_returning"]="Returning to the main menu..."
    ["menu_invalid"]="Invalid selection"
    ["menu_none"]="No valid selection detected."
    ["menu_continue"]="Press Enter to continue, or type 0 to exit."
)

declare -A PY_TEXT_TR=(
    ["menu_title"]="Python Araçları Kurulum Menüsü"
    ["menu_option1"]="Python 3 kur"
    ["menu_option2"]="Pip kur / güncelle"
    ["menu_option3"]="Pipx kur"
    ["menu_option4"]="UV kur"
    ["menu_option_all"]="Hepsini kur"
    ["menu_option0"]="Ana menü"
    ["menu_hint"]="Birden fazla seçim için virgülle ayırabilirsiniz (örn: 1,3)."
    ["menu_prompt"]="Seçiminiz"
    ["menu_returning"]="Ana menüye dönülüyor..."
    ["menu_invalid"]="Geçersiz seçim"
    ["menu_none"]="Geçerli bir seçim yapılmadı."
    ["menu_continue"]="Devam için Enter'a basın, çıkmak için 0 yazın."
)

py_text() {
    local key="$1"
    local default_value="${PY_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo "${PY_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

run_python_tools_menu() {
    while true; do
        clear
        print_heading_panel "$(py_text menu_title)"
        echo -e "  ${GREEN}1${NC} - $(py_text menu_option1)"
        echo -e "  ${GREEN}2${NC} - $(py_text menu_option2)"
        echo -e "  ${GREEN}3${NC} - $(py_text menu_option3)"
        echo -e "  ${GREEN}4${NC} - $(py_text menu_option4)"
        echo -e "  ${GREEN}A${NC} - $(py_text menu_option_all)"
        echo -e "  ${GREEN}0${NC} - $(py_text menu_option0)"
        echo -e "${YELLOW}$(py_text menu_hint)${NC}"
        read -r -p "$(py_text menu_prompt): " raw_choice </dev/tty

        if [ -z "$(echo "$raw_choice" | tr -d '[:space:]')" ]; then
            log_warn_detail "$(py_text menu_none)"
            sleep 1
            continue
        fi

        local choice_upper
        choice_upper=$(echo "$raw_choice" | tr '[:lower:]' '[:upper:]')

        if [[ "$choice_upper" == "0" ]]; then
            log_info_detail "$(py_text menu_returning)"
            break
        fi

        if [[ "$choice_upper" == "A" ]]; then
            install_python_stack
            break
        fi

        local action_performed=false
        IFS=',' read -ra selections <<< "$choice_upper"
        for selection in "${selections[@]}"; do
            selection=$(echo "$selection" | tr -d '[:space:]')
            [ -z "$selection" ] && continue
            case "$selection" in
                1)
                    install_python
                    action_performed=true
                    ;;
                2)
                    install_pip
                    action_performed=true
                    ;;
                3)
                    install_pipx
                    action_performed=true
                    ;;
                4)
                    install_uv
                    action_performed=true
                    ;;
                *)
                    log_warn_detail "$(py_text menu_invalid): ${selection}"
                    ;;
            esac
        done

        if [ "$action_performed" = false ]; then
            log_warn_detail "$(py_text menu_none)"
        fi

        read -r -p "$(py_text menu_continue)" continue_choice </dev/tty
        if [[ "$(echo "$continue_choice" | tr -d '[:space:]')" == "0" ]]; then
            break
        fi
    done
}

install_python_stack() {
    install_python
    install_pip
    install_pipx
    install_uv
    reload_shell_configs
    log_success_detail "$(get_i18n_message python_tools_completed \"Python tooling installation completed!\")"
}

# Ana kurulum akışı
main() {
    if [[ "${1:-}" =~ ^(all|ALL|a)$ ]]; then
        install_python_stack
        return
    fi
    run_python_tools_menu
}

main "$@"
