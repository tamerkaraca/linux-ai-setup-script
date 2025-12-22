#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi

declare -A TEXT_EN=(
    ["menu_title"]="davila7 Templates - Plugins"
    ["select_prompt"]="Select plugin(s) to install (e.g., 1,3,5 or A for all)"
    ["install_all"]="Installing all plugins..."
    ["installing_selected"]="Installing selected plugins..."
    ["install_single"]="Installing plugin: %s"
    ["return"]="Return to Main Menu"
    ["description"]="Description"
)
declare -A TEXT_TR=(
    ["menu_title"]="davila7 Şablonları - Eklentiler"
    ["select_prompt"]="Kurulacak eklenti(leri) seçin (örn: 1,3,5 veya tümü için A)"
    ["install_all"]="Tüm eklentiler kuruluyor..."
    ["installing_selected"]="Seçilen eklentiler kuruluyor..."
    ["install_single"]="Eklenti kuruluyor: %s"
    ["return"]="Ana Menüye Dön"
    ["description"]="Açıklama"
)

text() {
    local key="$1"
    local arg1="${2:-}"
    local default_value="${TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

# Plugin list from marketplace.json
declare -a PLUGIN_NAMES=(
    "frontend-developer"
    "backend-architect"
    "fullstack-developer"
    "devops-engineer"
    "mobile-developer"
    "ios-developer"
    "ui-ux-designer"
    "cli-ui-designer"
)

declare -A PLUGIN_DESCRIPTIONS=(
    ["frontend-developer"]="Frontend development with React, TypeScript, UI, responsive design, accessibility"
    ["backend-architect"]="Backend API, microservices, database, architecture, scalability"
    ["fullstack-developer"]="Fullstack development with frontend, backend, database, API, TypeScript"
    ["devops-engineer"]="DevOps, CI-CD, infrastructure, Kubernetes, Docker, Terraform"
    ["mobile-developer"]="Mobile development with React Native, Flutter, iOS, Android, cross-platform"
    ["ios-developer"]="iOS development with Swift, SwiftUI, UIKit, Core Data, Xcode"
    ["ui-ux-designer"]="UI/UX design, wireframes, prototyping, accessibility"
    ["cli-ui-designer"]="CLI/terminal UI, command-line, design, web"
)

davila7_plugins_menu() {
    while true; do
        clear
        print_heading_panel "$(text 'menu_title')"
        echo

        local i=1
        for plugin in "${PLUGIN_NAMES[@]}"; do
            printf "  ${GREEN}%2d${NC} - ${CYAN}%-20s${NC}\n" "$i" "$plugin"
            i=$((i + 1))
        done

        echo
        echo "  ${YELLOW}A${NC} - $(text 'install_all')"
        echo "  ${YELLOW}0${NC} - $(text 'return')"
        echo

        read -r -p "$(text 'select_prompt'): " choice_input </dev/tty

        case "$choice_input" in
            0) break ;;
            a|A)
                log_info_detail "$(text 'install_all')"
                for plugin in "${PLUGIN_NAMES[@]}"; do
                    log_info_detail "$(text 'install_single' "$plugin")"
                    npx claude-code-templates@latest --plugins "$plugin"
                done
                ;;
            *)
                local selected_plugins_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#PLUGIN_NAMES[@]} ]; then
                        selected_plugins_arr+=("${PLUGIN_NAMES[$((selection - 1))]}")
                    else
                        log_error_detail "Invalid selection: $selection"
                    fi
                done

                if [ ${#selected_plugins_arr[@]} -gt 0 ]; then
                    log_info_detail "$(text 'installing_selected')"
                    for plugin in "${selected_plugins_arr[@]}"; do
                        npx claude-code-templates@latest --plugins "$plugin"
                    done
                fi
                ;;
        esac
        read -r -p "Press Enter to continue..."
    done
}
