#!/bin/bash
set -euo pipefail

# --- Load Utilities ---
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi
# --- End Load Utilities ---

# --- Text Definitions ---
declare -A MENU_TEXT_EN=(
    ["main_title"]="davila7/claude-code-templates Agent Installer"
    ["select_prompt"]="Select agent(s) to install (e.g., 1,3 or A for all)"
    ["detail_prompt"]="Press 1 to install, 0 to return"
    ["install_all"]="Installing all agents..."
    ["installing_selected"]="Installing selected agents..."
    ["install_single"]="Installing agent: %s"
    ["return"]="Return to Main Menu"
    ["executing_command"]="Executing installation command..."
    ["installation_complete"]="Installation complete."
    ["installation_failed"]="Installation failed."
    ["npx_missing"]="`npx` command not found. Please install Node.js and npm first."
)
declare -A MENU_TEXT_TR=(
    ["main_title"]="davila7/claude-code-templates Ajan Yükleyici"
    ["select_prompt"]="Kurulacak ajan(lar)ı seçin (örn: 1,3 veya tümü için A)"
    ["detail_prompt"]="Kurmak için 1'e, dönmek için 0'a basın"
    ["install_all"]="Tüm ajanlar kuruluyor..."
    ["installing_selected"]="Seçilen ajanlar kuruluyor..."
    ["install_single"]="'%s' ajanı kuruluyor..."
    ["return"]="Ana Menüye Dön"
    ["executing_command"]="Kurulum komutu çalıştırılıyor..."
    ["installation_complete"]="Kurulum tamamlandı."
    ["installation_failed"]="Kurulum başarısız oldu."
    ["npx_missing"]="`npx` komutu bulunamadı. Lütfen önce Node.js ve npm'i kurun."
)

menu_text() {
    local key="$1"; local arg1="${2:-"")}"; local lang="${LANGUAGE:-en}";
    local text_map_name="MENU_TEXT_${lang^^}";
    eval "local text=\"
${text_map_name}['$key']\
"";
    if [ -z "$text" ]; then text="${MENU_TEXT_EN[$key]}"; fi
    printf "$text" "$arg1";
}
# --- End Text Definitions ---

# --- Agent Definitions ---
# This list is generated from the npx command provided by the user.
# The array index corresponds to the menu number - 1.
AGENTS_LIST=(
    "development-team/frontend-developer"
    "development-tools/code-reviewer"
    "development-team/backend-architect"
    "development-tools/debugger"
    "development-team/fullstack-developer"
    "ai-specialists/prompt-engineer"
    "development-team/ui-ux-designer"
    "programming-languages/python-pro"
    "development-tools/context-manager"
    "programming-languages/typescript-pro"
    "database/database-architect"
    "development-tools/error-detective"
    "development-tools/test-engineer"
    "expert-advisors/architect-review"
    "ai-specialists/task-decomposition-expert"
    "data-ai/ai-engineer"
    "development-tools/mcp-expert"
    "ai-specialists/search-specialist"
    "documentation/api-documenter"
    "development-team/mobile-developer"
    "programming-languages/javascript-pro"
    "devops-infrastructure/deployment-engineer"
    "development-team/devops-engineer"
    "security/security-auditor"
    "expert-advisors/documentation-expert"
    "documentation/technical-writer"
    "web-tools/nextjs-architecture-expert"
    "deep-research-team/technical-researcher"
    "performance-testing/performance-engineer"
    "performance-testing/react-performance-optimization"
    "database/database-optimization"
    "programming-languages/sql-pro"
    "data-ai/data-engineer"
    "web-tools/seo-analyzer"
    "performance-testing/test-automator"
    "database/database-optimizer"
    "devops-infrastructure/devops-troubleshooter"
    "business-marketing/product-strategist"
    "devops-infrastructure/cloud-architect"
    "development-tools/command-expert"
    "database/database-admin"
    "database/supabase-schema-architect"
    "data-ai/data-scientist"
    "devops-infrastructure/security-engineer"
    "deep-research-team/data-analyst"
    "business-marketing/business-analyst"
    "business-marketing/content-marketer"
    "development-team/ios-developer"
    "security/api-security-audit"
    "documentation/changelog-generator"
    "development-tools/performance-profiler"
    "devops-infrastructure/network-engineer"
    "programming-languages/golang-pro"
    "data-ai/ml-engineer"
    "modernization/architecture-modernizer"
    "deep-research-team/research-orchestrator"
    "deep-research-team/report-generator"
    "programming-languages/php-pro"
    "development-team/cli-ui-designer"
    "development-tools/dx-optimizer"
    "deep-research-team/academic-researcher"
    "git/git-flow-manager"
    "devops-infrastructure/terraform-specialist"
    "business-marketing/payment-integration"
    "programming-languages/shell-scripting-pro"
    "podcast-creator-team/project-supervisor-orchestrator"
    "mcp-dev-team/mcp-server-architect"
    "devops-infrastructure/monitoring-specialist"
    "deep-research-team/research-coordinator"
    "web-tools/react-performance-optimizer"
    "security/penetration-tester"
    "documentation/docusaurus-expert"
    "expert-advisors/dependency-manager"
    "deep-research-team/fact-checker"
    "deep-research-team/research-synthesizer"
    "development-tools/unused-code-cleaner"
    "web-tools/web-accessibility-checker"
    "obsidian-ops-team/review-agent"
    "deep-research-team/agent-overview"
    "ocr-extraction-team/document-structure-analyzer"
    "deep-research-team/competitive-intelligence-analyst"
    "ocr-extraction-team/markdown-syntax-formatter"
    "programming-languages/rust-pro"
    "mcp-dev-team/mcp-integration-engineer"
    "realtime/supabase-realtime-optimizer"
    "obsidian-ops-team/connection-agent"
    "data-ai/quant-analyst"
    "ai-specialists/llms-maintainer"
    "data-ai/mlops-engineer"
    "deep-research-team/research-brief-generator"
    "business-marketing/legal-advisor"
    "mcp-dev-team/mcp-deployment-orchestrator"
    "api-graphql/graphql-architect"
    "data-ai/computer-vision-engineer"
    "data-ai/nlp-engineer"
    "ai-specialists/model-evaluator"
    "performance-testing/load-testing-specialist"
    "mcp-dev-team/mcp-security-auditor"
    "obsidian-ops-team/metadata-agent"
    "deep-research-team/query-clarifier"
    "game-development/game-designer"
    "modernization/legacy-modernizer"
    "mcp-dev-team/mcp-protocol-specialist"
    "ai-specialists/hackathon-ai-strategist"
    "mcp-dev-team/mcp-testing-engineer"
    "web-tools/url-link-extractor"
    "security/compliance-specialist"
    "performance-testing/web-vitals-optimizer"
    "programming-languages/c-sharp-pro"
    "obsidian-ops-team/tag-agent"
    "business-marketing/risk-manager"
    "business-marketing/sales-automator"
    "devops-infrastructure/vercel-deployment-specialist"
    "podcast-creator-team/comprehensive-researcher"
    "mcp-dev-team/mcp-registry-navigator"
    "business-marketing/customer-support"
    "obsidian-ops-team/content-curator"
    "programming-languages/cpp-pro"
    "database/nosql-specialist"
    "web-tools/url-context-validator"
    "obsidian-ops-team/moc-agent"
    "business-marketing/marketing-attribution-analyst"
    "security/incident-responder"
    "ocr-extraction-team/visual-analysis-ocr"
    "game-development/unity-game-developer"
    "podcast-creator-team/market-research-analyst"
    "podcast-creator-team/social-media-copywriter"
    "blockchain-web3/web3-integration-specialist"
    "programming-languages/c-pro"
    "obsidian-ops-team/vault-optimizer"
    "api-graphql/graphql-performance-optimizer"
    "modernization/cloud-migration-specialist"
    "ai-specialists/ai-ethics-advisor"
    "ocr-extraction-team/ocr-preprocessing-optimizer"
    "ffmpeg-clip-team/video-editor"
    "ocr-extraction-team/text-comparison-validator"
    "blockchain-web3/smart-contract-specialist"
    "ffmpeg-clip-team/social-media-clip-creator"
    "blockchain-web3/smart-contract-auditor"
    "ocr-extraction-team/ocr-quality-assurance"
    "ocr-extraction-team/ocr-grammar-fixer"
    "game-development/3d-artist"
)
# --- End Agent Definitions ---

# --- Functions ---

run_npx_install() {
    local agents_to_install_str="$1"
    
    if ! command -v npx &> /dev/null; then
        log_error_detail "$(menu_text 'npx_missing')"
        return 1
    fi

    log_info_detail "$(menu_text 'executing_command')"
    local cmd="npx claude-code-templates@latest --agent ${agents_to_install_str}"
    log_info_detail "$ ${cmd}"

    if eval "$cmd"; then
        log_success_detail "$(menu_text 'installation_complete')"
    else
        log_error_detail "$(menu_text 'installation_failed')"
        return 1
    fi
}


main_menu() {
    while true; do
        clear
        print_heading_panel "$(menu_text 'main_title')"
        
        local i=1
        for agent_name in "${AGENTS_LIST[@]}"; do
            printf "  ${GREEN}%2d${NC} - %s\n" "$i" "$agent_name"
            i=$((i+1))
        done

        echo
        echo "  ${YELLOW}A${NC} - $(menu_text 'install_all')"
        echo "  ${YELLOW}0${NC} - $(menu_text 'return')"
        echo
        read -r -p "$(menu_text 'select_prompt'): " choice_input </dev/tty

        case "$choice_input" in
            0) break ;;
            a|A) 
                log_info_detail "$(menu_text 'install_all')"
                local all_agents_str
                all_agents_str=$(printf ",%s" "${AGENTS_LIST[@]}")
                all_agents_str=${all_agents_str:1} # Remove leading comma
                run_npx_install "$all_agents_str"
                ;; 
            *)
                local selected_agents_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#AGENTS_LIST[@]} ]; then
                        selected_agents_arr+=("${AGENTS_LIST[$((selection - 1))]}")
                    else
                        log_error_detail "Invalid selection: $selection"
                    fi
                done
                
                if [ ${#selected_agents_arr[@]} -gt 0 ]; then
                    log_info_detail "$(menu_text 'installing_selected')"
                    local selected_agents_str
                    selected_agents_str=$(printf ",%s" "${selected_agents_arr[@]}")
                    selected_agents_str=${selected_agents_str:1} # Remove leading comma
                    run_npx_install "$selected_agents_str"
                fi
                ;; 
        esac
        read -r -p "Press Enter to continue..."
    done
}

# --- Execution ---
main_menu
