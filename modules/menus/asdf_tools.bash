#!/bin/bash
set -euo pipefail

# ASDF Version Manager Menu
# Provides options for installing ASDF and its plugins (Node.js, Java, PHP)

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
asdf_installer="$script_dir/../utils/asdf_installer.bash"

if [ -f "$utils_local" ]; then
    source "$utils_local"
elif [ -f "./modules/utils/utils.bash" ]; then
    source "./modules/utils/utils.bash"
else
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash" >&2
    exit 1
fi

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

# --- i18n Support ---
declare -A ASDF_MENU_TEXT_EN=(
    ["menu_title"]="ASDF Version Manager"
    ["menu_subtitle"]="Manage multiple runtime versions with ASDF"
    ["option1"]="Install ASDF Core"
    ["option2"]="Install Node.js (via ASDF)"
    ["option3"]="Install Java (via ASDF)"
    ["option4"]="Install PHP (via ASDF)"
    ["optionA"]="Install All (ASDF + Node + Java + PHP)"
    ["option0"]="Return to Main Menu"
    ["menu_multi_hint"]="You can make multiple selections with commas (e.g., 1,2)."
    ["prompt_choice"]="Your choice"
    ["warning_no_selection"]="No selection made. Please try again."
    ["info_returning"]="Returning to main menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["prompt_press_enter"]="Press Enter to continue..."
    ["asdf_description"]="ASDF is a tool version manager that supports multiple runtimes."
    ["asdf_benefits"]="Benefits: Single CLI for Node, Java, PHP, Ruby, Python and more!"
)

declare -A ASDF_MENU_TEXT_TR=(
    ["menu_title"]="ASDF Sürüm Yöneticisi"
    ["menu_subtitle"]="ASDF ile birden fazla çalışma zamanı sürümünü yönetin"
    ["option1"]="ASDF Çekirdeğini Kur"
    ["option2"]="Node.js Kur (ASDF üzerinden)"
    ["option3"]="Java Kur (ASDF üzerinden)"
    ["option4"]="PHP Kur (ASDF üzerinden)"
    ["optionA"]="Tümünü Kur (ASDF + Node + Java + PHP)"
    ["option0"]="Ana Menüye Dön"
    ["menu_multi_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2)."
    ["prompt_choice"]="Seçiminiz"
    ["warning_no_selection"]="Hiçbir seçim yapılmadı. Lütfen tekrar deneyin."
    ["info_returning"]="Ana menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["prompt_press_enter"]="Devam etmek için Enter'a basın..."
    ["asdf_description"]="ASDF, birden fazla çalışma zamanını destekleyen bir sürüm yöneticisidir."
    ["asdf_benefits"]="Avantajlar: Node, Java, PHP, Ruby, Python ve daha fazlası için tek CLI!"
)

asdf_menu_text() {
    local key="$1"
    local default_value="${ASDF_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${ASDF_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

show_asdf_menu() {
    clear
    print_heading_panel "$(asdf_menu_text menu_title)"
    echo -e "${CYAN}$(asdf_menu_text asdf_description)${NC}"
    echo -e "${YELLOW}$(asdf_menu_text asdf_benefits)${NC}"
    echo
    echo -e "  ${GREEN}1${NC} - $(asdf_menu_text option1)"
    echo -e "  ${GREEN}2${NC} - $(asdf_menu_text option2)"
    echo -e "  ${GREEN}3${NC} - $(asdf_menu_text option3)"
    echo -e "  ${GREEN}4${NC} - $(asdf_menu_text option4)"
    echo -e "  ${GREEN}A${NC} - $(asdf_menu_text optionA)"
    echo -e "  ${GREEN}0${NC} - $(asdf_menu_text option0)"
    echo
    echo -e "${YELLOW}$(asdf_menu_text menu_multi_hint)${NC}"
}

run_asdf_choice() {
    local option="$1"
    
    # Source the installer if available
    if [ -f "$asdf_installer" ]; then
        source "$asdf_installer"
    elif [ -f "./modules/utils/asdf_installer.bash" ]; then
        source "./modules/utils/asdf_installer.bash"
    else
        log_error_detail "asdf_installer.bash not found"
        return 1
    fi
    
    case "$option" in
        1)
            install_asdf
            ;;
        2)
            install_nodejs_via_asdf
            ;;
        3)
            install_java_via_asdf
            ;;
        4)
            install_php_via_asdf
            ;;
        A)
            install_asdf
            install_nodejs_via_asdf
            install_java_via_asdf
            install_php_via_asdf
            ;;
        *)
            log_warn_detail "$(asdf_menu_text warning_invalid_choice): $option"
            ;;
    esac
}

main() {
    local auto_run="${1:-}"
    
    if [ "$auto_run" = "all" ]; then
        run_asdf_choice "A"
        return
    fi
    
    while true; do
        show_asdf_menu
        read -r -p "$(asdf_menu_text prompt_choice): " selection </dev/tty
        
        if [ -z "$(echo "$selection" | tr -d '[:space:]')" ]; then
            log_warn_detail "$(asdf_menu_text warning_no_selection)"
            sleep 1
            continue
        fi
        
        if [ "$selection" = "0" ]; then
            log_info_detail "$(asdf_menu_text info_returning)"
            break
        fi
        
        local batch_context=false
        IFS=',' read -ra choices <<< "$selection"
        [ "${#choices[@]}" -gt 1 ] && batch_context=true
        
        for raw in "${choices[@]}"; do
            local choice
            choice="$(echo "$raw" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
            [ -z "$choice" ] && continue
            if [ "$choice" = "0" ]; then
                batch_context=false
                break
            fi
            run_asdf_choice "$choice"
        done
        
        if [ "$batch_context" = false ]; then
            read -r -p "$(asdf_menu_text prompt_press_enter)" _tmp </dev/tty || true
        fi
    done
}

main "$@"
