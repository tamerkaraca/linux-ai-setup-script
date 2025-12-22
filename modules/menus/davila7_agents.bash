#!/bin/bash
set -euo pipefail

# --- Load Utilities ---
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi
# --- End Load Utilities ---

# --- Text Definitions ---
declare -A TEXT_EN=(
    ["menu_title"]="davila7 Templates - Agents (142 available)"
    ["select_prompt"]="Select agent(s) to install (e.g., 1,3,5 or A for all)"
    ["install_all"]="Installing all agents..."
    ["installing_selected"]="Installing selected agents..."
    ["return"]="Return to Main Menu"
    ["page"]="Page %d/%d"
    ["next"]="Next Page (N)"
    ["prev"]="Previous Page (P)"
)
declare -A TEXT_TR=(
    ["menu_title"]="davila7 Şablonları - Ajanlar (142 adet)"
    ["select_prompt"]="Kurulacak ajan(ları) seçin (örn: 1,3,5 veya tümü için A)"
    ["install_all"]="Tüm ajanlar kuruluyor..."
    ["installing_selected"]="Seçilen ajanlar kuruluyor..."
    ["return"]="Ana Menüye Dön"
    ["page"]="Sayfa %d/%d"
    ["next"]="Sonraki Sayfa (N)"
    ["prev"]="Önceki Sayfa (P)"
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
# --- End Text Definitions ---

# --- Agent Categories ---
# Format: "Category:Agent1,Agent2,Agent3"
declare -a AGENT_CATEGORIES=(
    "ai-specialists:ai-ethics-advisor,hackathon-ai-strategist,llms-maintainer,model-evaluator,prompt-engineer,search-specialist,task-decomposition-expert"
    "api-graphql:graphql-architect,graphql-performance-optimizer,graphql-security-specialist"
    "blockchain-web3:smart-contract-auditor,smart-contract-specialist,web3-integration-specialist"
    "business-marketing:business-analyst,content-marketer,customer-support,legal-advisor,marketing-attribution-analyst,payment-integration,product-strategist,risk-manager,sales-automator"
    "data-ai:ai-engineer,computer-vision-engineer,data-engineer,data-scientist,ml-engineer,mlops-engineer,nlp-engineer,quant-analyst"
    "database:database-admin,database-architect,database-optimization,database-optimizer,neon-auth-specialist,neon-database-architect,neon-expert,nosql-specialist,supabase-schema-architect"
    "deep-research-team:academic-researcher,agent-overview,competitive-intelligence-analyst,data-analyst,fact-checker,nia-oracle,query-clarifier,report-generator,research-brief-generator,research-coordinator,research-orchestrator,research-synthesizer,technical-researcher"
    "development-team:backend-architect,cli-ui-designer,devops-engineer,frontend-developer,fullstack-developer,ios-developer,mobile-developer,ui-ux-designer"
    "development-tools:code-reviewer,command-expert,context-manager,debugger,dx-optimizer,error-detective,flutter-go-reviewer,mcp-expert,performance-profiler,test-engineer,unused-code-cleaner"
    "devops-infrastructure:cloud-architect,deployment-engineer,devops-troubleshooter,monitoring-specialist,network-engineer,security-engineer,terraform-specialist,vercel-deployment-specialist"
    "documentation:api-documenter,changelog-generator,docusaurus-expert,technical-writer"
    "expert-advisors:agent-expert,architect-review,dependency-manager,documentation-expert"
    "ffmpeg-clip-team:audio-mixer,audio-quality-controller,podcast-content-analyzer,podcast-metadata-specialist,podcast-transcriber,social-media-clip-creator,timestamp-precision-specialist,video-editor"
    "game-development:3d-artist,game-designer,unity-game-developer,unreal-engine-developer"
    "git:git-flow-manager"
    "mcp-dev-team:mcp-deployment-orchestrator,mcp-integration-engineer,mcp-protocol-specialist,mcp-registry-navigator,mcp-security-auditor,mcp-server-architect,mcp-testing-engineer"
    "modernization:architecture-modernizer,cloud-migration-specialist,legacy-modernizer"
    "obsidian-ops-team:connection-agent,content-curator,metadata-agent,moc-agent,review-agent,tag-agent,vault-optimizer"
    "ocr-extraction-team:document-structure-analyzer,markdown-syntax-formatter,ocr-grammar-fixer,ocr-preprocessing-optimizer,ocr-quality-assurance,text-comparison-validator,visual-analysis-ocr"
    "performance-testing:load-testing-specialist,performance-engineer,react-performance-optimization,test-automator,web-vitals-optimizer"
    "podcast-creator-team:academic-research-synthesizer,comprehensive-researcher,episode-orchestrator,guest-outreach-coordinator,market-research-analyst,podcast-editor,podcast-trend-scout,project-supervisor-orchestrator,seo-podcast-optimizer,social-media-copywriter,twitter-ai-influencer-manager"
    "programming-languages:c-pro,c-sharp-pro,cpp-pro,golang-pro,javascript-pro,php-pro,python-pro,rust-pro,shell-scripting-pro,sql-pro,typescript-pro"
    "realtime:supabase-realtime-optimizer"
    "security:api-security-audit,compliance-specialist,incident-responder,penetration-tester,security-auditor"
    "web-tools:nextjs-architecture-expert,react-performance-optimizer,seo-analyzer,url-context-validator,url-link-extractor,web-accessibility-checker"
)

# --- Parse Agents into Array ---
declare -a AGENT_LIST
declare -a AGENT_CATEGORIES_LIST

parse_agents() {
    AGENT_LIST=()
    AGENT_CATEGORIES_LIST=()

    for category_entry in "${AGENT_CATEGORIES[@]}"; do
        local category="${category_entry%%:*}"
        local agents="${category_entry#*:}"

        IFS=',' read -ra agent_array <<< "$agents"
        for agent in "${agent_array[@]}"; do
            AGENT_LIST+=("$category/$agent")
            AGENT_CATEGORIES_LIST+=("$category")
        done
    done
}

# --- Display Agents Page ---
display_agents_page() {
    local page=$1
    local per_page=30
    local total_agents=${#AGENT_LIST[@]}
    local total_pages=$(( (total_agents + per_page - 1) / per_page ))
    local start=$((page * per_page))
    local end=$((start + per_page))

    if [ $end -gt $total_agents ]; then
        end=$total_agents
    fi

    clear
    print_heading_panel "$(text 'menu_title')"
    printf "$(text 'page')\n\n" "$((page + 1))" "$total_pages"

    local i=$start
    while [ $i -lt $end ]; do
        local agent="${AGENT_LIST[$i]}"
        local category="${AGENT_CATEGORIES_LIST[$i]}"
        local display_num=$((i + 1))
        printf "  ${GREEN}%3d${NC} - ${CYAN}[%s]${NC} %s\n" "$display_num" "$category" "${agent#*/}"
        i=$((i + 1))
    done

    echo
    if [ $total_pages -gt 1 ]; then
        if [ $page -lt $((total_pages - 1)) ]; then
            echo "  ${YELLOW}N${NC} - $(text 'next')"
        fi
        if [ $page -gt 0 ]; then
            echo "  ${YELLOW}P${NC} - $(text 'prev')"
        fi
    fi
    echo "  ${YELLOW}A${NC} - $(text 'install_all')"
    echo "  ${YELLOW}0${NC} - $(text 'return')"
}

# --- Main Menu ---
davila7_agents_menu() {
    parse_agents

    local page=0
    local per_page=30
    local total_agents=${#AGENT_LIST[@]}
    local total_pages=$(( (total_agents + per_page - 1) / per_page ))

    while true; do
        display_agents_page "$page"

        read -r -p "$(text 'select_prompt'): " choice_input </dev/tty

        case "$choice_input" in
            0) break ;;
            a|A)
                log_info_detail "$(text 'install_all')"
                local all_agents_str
                all_agents_str=$(printf ",%s" "${AGENT_LIST[@]}")
                all_agents_str=${all_agents_str:1}
                npx claude-code-templates@latest --agent "$all_agents_str"
                ;;
            n|N)
                if [ $page -lt $((total_pages - 1)) ]; then
                    page=$((page + 1))
                fi
                ;;
            p|P)
                if [ $page -gt 0 ]; then
                    page=$((page - 1))
                fi
                ;;
            *)
                local selected_agents_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le $total_agents ]; then
                        selected_agents_arr+=("${AGENT_LIST[$((selection - 1))]}")
                    else
                        log_error_detail "Invalid selection: $selection"
                    fi
                done

                if [ ${#selected_agents_arr[@]} -gt 0 ]; then
                    log_info_detail "$(text 'installing_selected')"
                    local selected_agents_str
                    selected_agents_str=$(printf ",%s" "${selected_agents_arr[@]}")
                    selected_agents_str=${selected_agents_str:1}
                    npx claude-code-templates@latest --agent "$selected_agents_str"
                fi
                ;;
        esac
        read -r -p "Press Enter to continue..."
    done
}
