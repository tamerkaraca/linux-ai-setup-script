#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

CURRENT_LANG="${LANGUAGE:-en}"
if [ "$CURRENT_LANG" = "tr" ]; then
    INFO_TAG="[BİLGİ]"
    WARN_TAG="[UYARI]"
    ERROR_TAG="[HATA]"
else
    INFO_TAG="[INFO]"
    WARN_TAG="[WARNING]"
    ERROR_TAG="[ERROR]"
fi

declare -A RM_TEXT_EN=(
    ["menu_title"]="AI Framework Removal Menu"
    ["option1"]="Remove SuperGemini Framework"
    ["option2"]="Remove SuperQwen Framework"
    ["option3"]="Remove SuperClaude Framework"
    ["option4"]="Remove all AI frameworks"
    ["option0"]="Return to main menu"
    ["hint"]="Use commas for multiple selections (e.g., 1,3)."
    ["prompt"]="Your choice"
    ["returning"]="Returning to the main menu..."
    ["invalid"]="Invalid selection"
    ["continue_prompt"]="Remove another framework? (y/n) [n]: "
)

declare -A RM_TEXT_TR=(
    ["menu_title"]="AI Framework Kaldırma Menüsü"
    ["option1"]="SuperGemini Framework'ü kaldır"
    ["option2"]="SuperQwen Framework'ü kaldır"
    ["option3"]="SuperClaude Framework'ü kaldır"
    ["option4"]="Tüm AI Frameworklerini kaldır"
    ["option0"]="Ana menüye dön"
    ["hint"]="Birden fazla seçim için virgülle ayırabilirsiniz (örn: 1,3)."
    ["prompt"]="Seçiminiz"
    ["returning"]="Ana menüye dönülüyor..."
    ["invalid"]="Geçersiz seçim"
    ["continue_prompt"]="Başka bir framework kaldırmak ister misiniz? (e/h) [h]: "
)

rm_text() {
    local key="$1"
    local default_value="${RM_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        echo "${RM_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

# Script çalıştırma fonksiyonu (setup script'inden kopyalandı)
run_module() {
    local module_name="$1"
    local module_url="$BASE_URL/$module_name.sh"
    echo -e "${CYAN}${INFO_TAG}${NC} $module_name modülü indiriliyor ve çalıştırılıyor..."
    if ! curl -fsSL "$module_url" | LANGUAGE="$CURRENT_LANG" bash -s -- "${@:2}"; then
        echo -e "${RED}${ERROR_TAG}${NC} $module_name modülü çalıştırılırken bir hata oluştu."
        return 1
    fi
    return 0
}

# AI Framework Kaldırma menüsü
remove_ai_frameworks_menu() {
    while true; do
        clear
        echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
        printf "${BLUE}║%*s║${NC}\n" -43 " $(rm_text menu_title) "
        echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}\n"
        echo -e "  ${GREEN}1${NC} - $(rm_text option1)"
        echo -e "  ${GREEN}2${NC} - $(rm_text option2)"
        echo -e "  ${GREEN}3${NC} - $(rm_text option3)"
        echo -e "  ${GREEN}4${NC} - $(rm_text option4)"
        echo -e "  ${RED}0${NC} - $(rm_text option0)"
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(rm_text hint)"

        read -r -p "${YELLOW}$(rm_text prompt):${NC} " removal_choices </dev/tty
        if [ "$removal_choices" = "0" ] || [ -z "$removal_choices" ]; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(rm_text returning)"
            break
        fi

        local all_removed=false
        IFS=',' read -ra SELECTED_REMOVE <<< "$removal_choices"

        for choice in "${SELECTED_REMOVE[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) run_module "remove_supergemini" ;;
                2) run_module "remove_superqwen" ;;
                3) run_module "remove_superclaude" ;;
                4) 
                    run_module "remove_supergemini"
                    run_module "remove_superqwen"
                    run_module "remove_superclaude"
                    all_removed=true
                    ;;
                *) echo -e "${RED}${ERROR_TAG}${NC} $(rm_text invalid): $choice" ;;
            esac
        done

        if [ "$all_removed" = true ]; then
            break
        fi

        read -r -p "$(rm_text continue_prompt)" continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

# Ana kaldırma akışı
main() {
    remove_ai_frameworks_menu
}

main
