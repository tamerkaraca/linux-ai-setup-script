#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi

declare -A TEXT_EN=(
    ["menu_title"]="davila7 Templates - MCPs"
    ["select_prompt"]="Select MCP(s) (e.g., 1,3,5 or A for all, B for back)"
    ["install_all"]="Installing all MCPs in this category..."
    ["installing_selected"]="Installing selected MCPs..."
    ["return"]="Return to Main Menu"
)
declare -A TEXT_TR=(
    ["menu_title"]="davila7 Şablonları - MCP'ler"
    ["select_prompt"]="MCP'leri seçin (örn: 1,3,5 veya tümü için A, geri için B)"
    ["install_all"]="Bu kategorideki tüm MCP'ler kuruluyor..."
    ["installing_selected"]="Seçilen MCP'ler kuruluyor..."
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

declare -A MCPS_CATEGORIES=(
    ["audio"]="audio/elevenlabs"
    ["browser_automation"]="browser_automation/browser-use-mcp-server,browser_automation/browsermcp,browser_automation/mcp-server-browserbase,browser_automation/mcp-server-playwright,browser_automation/playwright-mcp-server,browser_automation/playwright-mcp"
    ["database"]="database/mysql-integration,database/neon,database/postgresql-documentation,database/postgresql-integration,database/supabase"
    ["deepgraph"]="deepgraph/deepgraph-nextjs,deepgraph/deepgraph-react,deepgraph/deepgraph-typescript,deepgraph/deepgraph-vue"
    ["deepresearch"]="deepresearch/mcp-server-nia"
    ["devtools"]="devtools/azure-kubernetes-service,devtools/box,devtools/chrome-devtools,devtools/circleci,devtools/codacy,devtools/context7,devtools/dynatrace,devtools/elasticsearch,devtools/figma-dev-mode,devtools/firecrawl,devtools/firefly-mcp,devtools/grafana,devtools/huggingface,devtools/imagesorcery,devtools/ios-simulator-mcp,devtools/jfrog,devtools/just-mcp,devtools/launchdarkly,devtools/leetcode,devtools/logfire,devtools/markitdown,devtools/mcp-server-atlassian-bitbucket,devtools/mcp-server-trello,devtools/microsoft-clarity,devtools/microsoft-dev-box,devtools/mongodb,devtools/postman,devtools/pulumi,devtools/sentry,devtools/serena,devtools/stripe,devtools/terraform,devtools/testsprite,devtools/webflow"
    ["filesystem"]="filesystem/filesystem-access"
    ["integration"]="integration/github-integration,integration/memory-integration"
    ["marketing"]="marketing/facebook-ads-mcp-server,marketing/google-ads-mcp-server"
    ["productivity"]="productivity/monday,productivity/notion"
    ["web"]="web/web-fetch"
)

show_category_menu() {
    local categories=($(printf "%s\n" "${!MCPS_CATEGORIES[@]}" | sort))

    while true; do
        clear
        print_heading_panel "$(text 'menu_title')"
        echo

        local i=1
        for cat in "${categories[@]}"; do
            local count=$(echo "${MCPS_CATEGORIES[$cat]}" | tr ',' '\n' | wc -l)
            printf "  ${GREEN}%2d${NC} - ${CYAN}%-20s${NC} (${YELLOW}%d${NC} MCPs)\n" "$i" "$cat" "$count"
            i=$((i + 1))
        done

        echo "  ${YELLOW}A${NC} - Install All MCPs"
        echo "  ${YELLOW}0${NC} - $(text 'return')"
        echo

        read -r -p "$(text 'select_prompt'): " choice </dev/tty

        case "$choice" in
            0) break ;;
            a|A)
                log_info_detail "Installing all MCPs..."
                local all_mcps=""
                for cat in "${categories[@]}"; do
                    all_mcps="$all_mcps,${MCPS_CATEGORIES[$cat]}"
                done
                all_mcps=${all_mcps:1}
                npx claude-code-templates@latest --mcp "$all_mcps"
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#categories[@]} ]; then
                    local selected_cat="${categories[$((choice - 1))]}"
                    show_mcps_menu "$selected_cat"
                fi
                ;;
        esac
    done
}

show_mcps_menu() {
    local category="$1"
    local mcps="${MCPS_CATEGORIES[$category]}"
    IFS=',' read -ra MCP_ARRAY <<< "$mcps"

    while true; do
        clear
        print_heading_panel "$(text 'menu_title') - ${CYAN}$category${NC}"
        echo

        local i=1
        for mcp in "${MCP_ARRAY[@]}"; do
            local mcp_name="${mcp##*/}"
            printf "  ${GREEN}%2d${NC} - %s\n" "$i" "$mcp_name"
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
                npx claude-code-templates@latest --mcp "$mcps"
                ;;
            *)
                local selected_mcps_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#MCP_ARRAY[@]} ]; then
                        selected_mcps_arr+=("${MCP_ARRAY[$((selection - 1))]}")
                    fi
                done

                if [ ${#selected_mcps_arr[@]} -gt 0 ]; then
                    log_info_detail "$(text 'installing_selected')"
                    local selected_str
                    selected_str=$(printf ",%s" "${selected_mcps_arr[@]}")
                    selected_str=${selected_str:1}
                    npx claude-code-templates@latest --mcp "$selected_str"
                fi
                ;;
        esac
        read -r -p "Press Enter to continue..."
    done
}

davila7_mcps_menu() {
    show_category_menu
}
