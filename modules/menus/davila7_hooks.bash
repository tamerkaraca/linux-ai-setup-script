#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi

declare -A TEXT_EN=(
    ["menu_title"]="davila7 Templates - Hooks"
    ["select_prompt"]="Select hook(s) (e.g., 1,3,5 or A for all, B for back)"
    ["install_all"]="Installing all hooks in this category..."
    ["installing_selected"]="Installing selected hooks..."
    ["return"]="Return to Main Menu"
)
declare -A TEXT_TR=(
    ["menu_title"]="davila7 Şablonları - Kancalar (Hooks)"
    ["select_prompt"]="Kanca(ları) seçin (örn: 1,3,5 veya tümü için A, geri için B)"
    ["install_all"]="Bu kategorideki tüm kancalar kuruluyor..."
    ["installing_selected"]="Seçilen kancalar kuruluyor..."
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

declare -A HOOKS_CATEGORIES=(
    ["automation"]="automation/agents-md-loader,automation/build-on-change,automation/dependency-checker,automation/deployment-health-monitor,automation/discord-detailed-notifications,automation/discord-error-notifications,automation/discord-notifications,automation/simple-notifications,automation/slack-detailed-notifications,automation/slack-error-notifications,automation/slack-notifications,automation/telegram-detailed-notifications,automation/telegram-error-notifications,automation/telegram-notifications,automation/vercel-auto-deploy,automation/vercel-environment-sync"
    ["development-tools"]="development-tools/change-tracker,development-tools/command-logger,development-tools/file-backup,development-tools/lint-on-save,development-tools/nextjs-code-quality-enforcer,development-tools/smart-formatting"
    ["git-workflow"]="git-workflow/auto-git-add,git-workflow/smart-commit"
    ["git"]="git/conventional-commits,git/conventional-commits.py,git/prevent-direct-push,git/prevent-direct-push.py,git/validate-branch-name,git/validate-branch-name.py"
    ["performance"]="performance/performance-budget-guard,performance/performance-monitor"
    ["post-tool"]="post-tool/format-javascript-files,post-tool/format-python-files,post-tool/git-add-changes,post-tool/run-tests-after-changes"
    ["pre-tool"]="pre-tool/backup-before-edit,pre-tool/notify-before-bash,pre-tool/update-search-year"
    ["security"]="security/file-protection,security/security-scanner"
    ["testing"]="testing/test-runner"
)

show_category_menu() {
    local categories=($(printf "%s\n" "${!HOOKS_CATEGORIES[@]}" | sort))

    while true; do
        clear
        print_heading_panel "$(text 'menu_title')"
        echo

        local i=1
        for cat in "${categories[@]}"; do
            local count=$(echo "${HOOKS_CATEGORIES[$cat]}" | tr ',' '\n' | wc -l)
            printf "  ${GREEN}%2d${NC} - ${CYAN}%-20s${NC} (${YELLOW}%d${NC} hooks)\n" "$i" "$cat" "$count"
            i=$((i + 1))
        done

        echo "  ${YELLOW}A${NC} - Install All Hooks"
        echo "  ${YELLOW}0${NC} - $(text 'return')"
        echo

        read -r -p "$(text 'select_prompt'): " choice </dev/tty

        case "$choice" in
            0) break ;;
            a|A)
                log_info_detail "Installing all hooks..."
                local all_hooks=""
                for cat in "${categories[@]}"; do
                    all_hooks="$all_hooks,${HOOKS_CATEGORIES[$cat]}"
                done
                all_hooks=${all_hooks:1}
                npx claude-code-templates@latest --hook "$all_hooks"
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#categories[@]} ]; then
                    local selected_cat="${categories[$((choice - 1))]}"
                    show_hooks_menu "$selected_cat"
                fi
                ;;
        esac
    done
}

show_hooks_menu() {
    local category="$1"
    local hooks="${HOOKS_CATEGORIES[$category]}"
    IFS=',' read -ra HOOK_ARRAY <<< "$hooks"

    while true; do
        clear
        print_heading_panel "$(text 'menu_title') - ${CYAN}$category${NC}"
        echo

        local i=1
        for hook in "${HOOK_ARRAY[@]}"; do
            local hook_name="${hook##*/}"
            printf "  ${GREEN}%2d${NC} - %s\n" "$i" "$hook_name"
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
                npx claude-code-templates@latest --hook "$hooks"
                ;;
            *)
                local selected_hooks_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#HOOK_ARRAY[@]} ]; then
                        selected_hooks_arr+=("${HOOK_ARRAY[$((selection - 1))]}")
                    fi
                done

                if [ ${#selected_hooks_arr[@]} -gt 0 ]; then
                    log_info_detail "$(text 'installing_selected')"
                    local selected_str
                    selected_str=$(printf ",%s" "${selected_hooks_arr[@]}")
                    selected_str=${selected_str:1}
                    npx claude-code-templates@latest --hook "$selected_str"
                fi
                ;;
        esac
        read -r -p "Press Enter to continue..."
    done
}

davila7_hooks_menu() {
    show_category_menu
}
