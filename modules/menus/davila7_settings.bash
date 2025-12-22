#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi

declare -A TEXT_EN=(
    ["menu_title"]="davila7 Templates - Settings"
    ["select_prompt"]="Select setting(s) (e.g., 1,3,5 or A for all, B for back)"
    ["install_all"]="Installing all settings in this category..."
    ["installing_selected"]="Installing selected settings..."
    ["return"]="Return to Main Menu"
)
declare -A TEXT_TR=(
    ["menu_title"]="davila7 Şablonları - Ayarlar"
    ["select_prompt"]="Ayar(ları) seçin (örn: 1,3,5 veya tümü için A, geri için B)"
    ["install_all"]="Bu kategorideki tüm ayarlar kuruluyor..."
    ["installing_selected"]="Seçilen ayarlar kuruluyor..."
    ["return"]="Ana Menüye Dön"
)

text() {
    local key="$1"
    local default_value="${TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

declare -A SETTINGS_CATEGORIES=(
    ["api"]="api/bedrock-configuration,api/corporate-proxy,api/custom-headers,api/vertex-configuration"
    ["authentication"]="authentication/api-key-helper,authentication/force-claudeai-login,authentication/force-console-login"
    ["cleanup"]="cleanup/retention-7-days,cleanup/retention-90-days"
    ["environment"]="environment/bash-timeouts,environment/development-utils,environment/performance-optimization,environment/privacy-focused"
    ["git"]="git/git-flow-settings"
    ["global"]="global/aws-credentials,global/custom-model,global/git-commit-settings"
    ["mcp"]="mcp/disable-risky-servers,mcp/enable-all-project-servers,mcp/enable-specific-servers,mcp/mcp-timeouts"
    ["model"]="model/use-haiku,model/use-sonnet"
    ["partnerships"]="partnerships/glm-coding-plan"
    ["permissions"]="permissions/additional-directories,permissions/allow-git-operations,permissions/allow-npm-commands,permissions/deny-sensitive-files,permissions/development-mode,permissions/read-only-mode"
    ["statusline"]="statusline/asset-pipeline-controller-statusline,statusline/bug-circus-statusline,statusline/code-casino-statusline,statusline/code-spaceship-statusline,statusline/colorful-statusline,statusline/command-statusline,statusline/context-monitor,statusline/data-ocean-statusline,statusline/emotion-theater-statusline,statusline/game-performance-monitor-statusline,statusline/git-branch-statusline,statusline/minimal-statusline,statusline/multiplatform-build-status-statusline,statusline/neon-database-dev,statusline/neon-database-resources,statusline/productivity-rainbow-statusline,statusline/programmer-tamagotchi-statusline,statusline/programming-fitness-tracker-statusline,statusline/project-info-statusline,statusline/rpg-status-bar-statusline,statusline/time-statusline,statusline/unity-project-dashboard-statusline,statusline/vercel-deployment-monitor,statusline/vercel-error-alert-system,statusline/vercel-multi-env-status,statusline/virtual-code-garden-statusline,statusline/zero-config-deployment-monitor"
    ["telemetry"]="telemetry/custom-telemetry,telemetry/disable-telemetry,telemetry/enable-telemetry"
)

show_category_menu() {
    local categories=($(printf "%s\n" "${!SETTINGS_CATEGORIES[@]}" | sort))

    while true; do
        clear
        print_heading_panel "$(text 'menu_title')"
        echo

        local i=1
        for cat in "${categories[@]}"; do
            local count=$(echo "${SETTINGS_CATEGORIES[$cat]}" | tr ',' '\n' | wc -l)
            printf "  ${GREEN}%2d${NC} - ${CYAN}%-20s${NC} (${YELLOW}%d${NC} settings)\n" "$i" "$cat" "$count"
            i=$((i + 1))
        done

        echo "  ${YELLOW}A${NC} - Install All Settings"
        echo "  ${YELLOW}0${NC} - $(text 'return')"
        echo

        read -r -p "$(text 'select_prompt'): " choice </dev/tty

        case "$choice" in
            0) break ;;
            a|A)
                log_info_detail "Installing all settings..."
                local all_settings=""
                for cat in "${categories[@]}"; do
                    all_settings="$all_settings,${SETTINGS_CATEGORIES[$cat]}"
                done
                all_settings=${all_settings:1}
                npx claude-code-templates@latest --setting "$all_settings"
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#categories[@]} ]; then
                    local selected_cat="${categories[$((choice - 1))]}"
                    show_settings_menu "$selected_cat"
                fi
                ;;
        esac
    done
}

show_settings_menu() {
    local category="$1"
    local settings="${SETTINGS_CATEGORIES[$category]}"
    IFS=',' read -ra STG_ARRAY <<< "$settings"

    while true; do
        clear
        print_heading_panel "$(text 'menu_title') - ${CYAN}$category${NC}"
        echo

        local i=1
        for stg in "${STG_ARRAY[@]}"; do
            local stg_name="${stg##*/}"
            printf "  ${GREEN}%2d${NC} - %s\n" "$i" "$stg_name"
            i=$((i + 1))
        done

        echo
        echo "  ${YELLOW}A${NC} - $(text 'install_all')"
        echo "  ${YELLOW}B${NC} - Back to Categories"
        echo

        read -r -p "$(text 'select_prompt'): " choice_input </dev/tty

        case "$choice_input" in
            b|B) break ;;
            a|A)
                log_info_detail "$(text 'install_all')"
                npx claude-code-templates@latest --setting "$settings"
                ;;
            *)
                local selected_stgs_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#STG_ARRAY[@]} ]; then
                        selected_stgs_arr+=("${STG_ARRAY[$((selection - 1))]}")
                    fi
                done

                if [ ${#selected_stgs_arr[@]} -gt 0 ]; then
                    log_info_detail "$(text 'installing_selected')"
                    local selected_str
                    selected_str=$(printf ",%s" "${selected_stgs_arr[@]}")
                    selected_str=${selected_str:1}
                    npx claude-code-templates@latest --setting "$selected_str"
                fi
                ;;
        esac
        read -r -p "Press Enter to continue..."
    done
}

davila7_settings_menu() {
    show_category_menu
}
