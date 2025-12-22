#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi

declare -A TEXT_EN=(
    ["menu_title"]="davila7 Templates - Skills"
    ["select_prompt"]="Select skill(s) (e.g., 1,3,5 or A for all, B for back)"
    ["install_all"]="Installing all skills in this category..."
    ["installing_selected"]="Installing selected skills..."
    ["return"]="Return to Main Menu"
)
declare -A TEXT_TR=(
    ["menu_title"]="davila7 Şablonları - Yetenekler"
    ["select_prompt"]="Yetenek(leri) seçin (örn: 1,3,5 veya tümü için A, geri için B)"
    ["install_all"]="Bu kategorideki tüm yetenekler kuruluyor..."
    ["installing_selected"]="Seçilen yetenekler kuruluyor..."
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

declare -A SKILLS_CATEGORIES=(
    ["business-marketing"]="business-marketing/agile-product-owner,business-marketing/ceo-advisor,business-marketing/competitive-ads-extractor,business-marketing/content-creator,business-marketing/content-research-writer,business-marketing/cto-advisor,business-marketing/lead-research-assistant,business-marketing/marketing-demand-acquisition,business-marketing/marketing-strategy-pmm,business-marketing/product-manager-toolkit,business-marketing/product-strategist,business-marketing/seo-optimizer"
    ["creative-design"]="creative-design/accessibility-auditor,creative-design/algorithmic-art,creative-design/canvas-design,creative-design/executing-marketing-campaigns,creative-design/frontend-design,creative-design/slack-gif-creator,creative-design/theme-factory,creative-design/ui-design-system,creative-design/ux-researcher-designer"
    ["database"]="database/postgres-schema-design"
    ["development"]="development/agent-development,development/api-integration-specialist,development/artifacts-builder,development/brainstorming,development/changelog-generator,development/claude-opus-4-5-migration,development/cocoindex,development/code-reviewer,development/command-development,development/developer-growth-analysis,development/devops-iac-engineer,development/dispatching-parallel-agents,development/error-resolver,development/executing-plans,development/finishing-a-development-branch,development/git-commit-helper,development/hook-development,development/it-operations,development/mcp-builder,development/mcp-integration,development/move-code-quality,development/plugin-settings,development/plugin-structure,development/receiving-code-review,development/requesting-code-review,development/security-compliance,development/senior-architect,development/senior-backend,development/senior-computer-vision,development/senior-data-engineer,development/senior-data-scientist,development/senior-devops,development/senior-frontend,development/senior-fullstack,development/senior-ml-engineer,development/senior-prompt-engineer,development/senior-qa,development/senior-secops,development/senior-security,development/skill-creator,development/skill-development,development/subagent-driven-development,development/systematic-debugging"
    ["document-processing"]="document-processing/markdown-analyzer,document-processing/pdf-text-extraction,document-processing/report-generator-cli"
    ["enterprise-communication"]="enterprise-communication/email-automation,enterprise-communication/slack-workflow"
    ["media"]="media/audio-compressor,media/image-optimizer,media/video-thumbnail-generator"
    ["productivity"]="productivity/task-breakdown,productivity/workflow-automation"
    ["scientific"]="scientific/data-visualization,scientific/statistical-analysis"
    ["utilities"]="utilities/file-converter,utilities/text-transformer"
)

show_category_menu() {
    local categories=($(printf "%s\n" "${!SKILLS_CATEGORIES[@]}" | sort))

    while true; do
        clear
        print_heading_panel "$(text 'menu_title')"
        echo

        local i=1
        for cat in "${categories[@]}"; do
            local count=$(echo "${SKILLS_CATEGORIES[$cat]}" | tr ',' '\n' | wc -l)
            printf "  ${GREEN}%2d${NC} - ${CYAN}%-25s${NC} (${YELLOW}%d${NC} skills)\n" "$i" "$cat" "$count"
            i=$((i + 1))
        done

        echo "  ${YELLOW}A${NC} - Install All Skills"
        echo "  ${YELLOW}0${NC} - $(text 'return')"
        echo

        read -r -p "$(text 'select_prompt'): " choice </dev/tty

        case "$choice" in
            0) break ;;
            a|A)
                log_info_detail "Installing all skills..."
                local all_skills=""
                for cat in "${categories[@]}"; do
                    all_skills="$all_skills,${SKILLS_CATEGORIES[$cat]}"
                done
                all_skills=${all_skills:1}
                npx claude-code-templates@latest --skill "$all_skills"
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#categories[@]} ]; then
                    local selected_cat="${categories[$((choice - 1))]}"
                    show_skills_menu "$selected_cat"
                fi
                ;;
        esac
    done
}

show_skills_menu() {
    local category="$1"
    local skills="${SKILLS_CATEGORIES[$category]}"
    IFS=',' read -ra SKILL_ARRAY <<< "$skills"

    while true; do
        clear
        print_heading_panel "$(text 'menu_title') - ${CYAN}$category${NC}"
        echo

        local i=1
        for skill in "${SKILL_ARRAY[@]}"; do
            local skill_name="${skill##*/}"
            printf "  ${GREEN}%2d${NC} - %s\n" "$i" "$skill_name"
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
                npx claude-code-templates@latest --skill "$skills"
                ;;
            *)
                local selected_skills_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#SKILL_ARRAY[@]} ]; then
                        selected_skills_arr+=("${SKILL_ARRAY[$((selection - 1))]}")
                    fi
                done

                if [ ${#selected_skills_arr[@]} -gt 0 ]; then
                    log_info_detail "$(text 'installing_selected')"
                    local selected_str
                    selected_str=$(printf ",%s" "${selected_skills_arr[@]}")
                    selected_str=${selected_str:1}
                    npx claude-code-templates@latest --skill "$selected_str"
                fi
                ;;
        esac
        read -r -p "Press Enter to continue..."
    done
}

davila7_skills_menu() {
    show_category_menu
}
