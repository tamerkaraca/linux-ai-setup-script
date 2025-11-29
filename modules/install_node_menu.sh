#!/bin/bash
set -euo pipefail

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A NODE_MENU_TEXT_EN=(
    ["node_menu_title"]="Node.js Tooling Menu"
    ["node_menu_subtitle"]="Select components to install."
    ["node_option1"]="Node.js via NVM (LTS)"
    ["node_option2"]="Bun Runtime"
    ["node_option3"]="Node CLI Extras (pnpm, yarn)"
    ["node_optionA"]="Install All Components"
    ["node_option0"]="Return to Main Menu"
    ["menu_multi_hint"]="You can make multiple selections with commas (e.g., 1,2)."
    ["prompt_choice"]="Your choice"
    ["warning_no_selection"]="No selection made. Please try again."
    ["info_returning"]="Returning to the main menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["prompt_press_enter"]="Press Enter to continue..."
)

declare -A NODE_MENU_TEXT_TR=(
    ["node_menu_title"]="Node.js Araçları Menüsü"
    ["node_menu_subtitle"]="Kurulacak bileşenleri seçin."
    ["node_option1"]="Node.js (NVM üzerinden, LTS)"
    ["node_option2"]="Bun Runtime"
    ["node_option3"]="Node CLI Ekstraları (pnpm, yarn)"
    ["node_optionA"]="Tüm Bileşenleri Kur"
    ["node_option0"]="Ana Menüye Dön"
    ["menu_multi_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2)."
    ["prompt_choice"]="Seçiminiz"
    ["warning_no_selection"]="Hiçbir seçim yapılmadı. Lütfen tekrar deneyin."
    ["info_returning"]="Ana menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["prompt_press_enter"]="Devam etmek için Enter'a basın..."
)

node_menu_text() {
    local key="$1"
    local default_value="${NODE_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${NODE_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

if ! declare -f run_module >/dev/null 2>&1; then
    run_module() {
        local module_name="$1"
        local module_url="${BASE_URL}/${module_name}.sh"
        shift
        if [ -f "./modules/${module_name}.sh" ]; then
            bash "./modules/${module_name}.sh" "$@"
        else
            curl -fsSL "$module_url" | bash -s -- "$@"
        fi
    }
fi

show_node_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    text=" $(node_menu_text node_menu_title) "
    len=${#text}
    padding=$(( (72 - len) / 2 ))
    printf "${BLUE}║%*s%s%*s║${NC}\n" "$padding" "" "$text" "$((72 - len - padding))" ""
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "$(node_menu_text node_menu_subtitle)\n"
    echo -e "  ${GREEN}1${NC} - $(node_menu_text node_option1)"
    echo -e "  ${GREEN}2${NC} - $(node_menu_text node_option2)"
    echo -e "  ${GREEN}3${NC} - $(node_menu_text node_option3)"
    echo -e "  ${GREEN}A${NC} - $(node_menu_text node_optionA)"
    echo -e "  ${RED}0${NC} - $(node_menu_text node_option0)"
    echo -e "\n${YELLOW}$(node_menu_text menu_multi_hint)${NC}\n"
}

run_node_choice() {
    local option="$1"
    case "$option" in
        1)
            run_module "install_nodejs_tools" "--node-only"
            ;; 
        2)
            run_module "install_nodejs_tools" "--bun-only"
            ;; 
        3)
            run_module "install_nodejs_tools" "--extras-only"
            ;; 
        A)
            run_module "install_nodejs_tools"
            ;; 
        *)
            echo -e "${YELLOW}$(node_menu_text warning_invalid_choice): $option${NC}"
            ;; 
    esac
}

main() {
    local auto_run="${1:-}"
    if [ "$auto_run" = "all" ]; then
        run_node_choice "A"
        return
    fi

    while true; do
        show_node_menu
        read -r -p "${YELLOW}$(node_menu_text prompt_choice):${NC} " selection </dev/tty
        if [ -z "$(echo "$selection" | tr -d '[:space:]')" ]; then
            echo -e "${YELLOW}$(node_menu_text warning_no_selection)${NC}"
            sleep 1
            continue
        fi

        if [ "$selection" = "0" ]; then
            echo -e "${GREEN}$(node_menu_text info_returning)${NC}"
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
            run_node_choice "$choice"
        done

        if [ "$batch_context" = false ]; then
            read -r -p "${YELLOW}$(node_menu_text prompt_press_enter)${NC}" _tmp </dev/tty || true
        fi
    done
}

main "$@"