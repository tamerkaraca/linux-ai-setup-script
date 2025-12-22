#!/bin/bash
set -euo pipefail

# --- Load Utilities ---
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
if [ -f "$utils_local" ]; then source "$utils_local"; fi
# --- End Load Utilities ---

# --- Text Definitions ---
declare -A TEXT_EN=(
    ["menu_title"]="davila7 Templates - Commands"
    ["category_title"]="Select Command Category"
    ["select_prompt"]="Select command(s) (e.g., 1,3,5 or A for all, B for back)"
    ["install_all"]="Installing all commands in this category..."
    ["installing_selected"]="Installing selected commands..."
    ["return"]="Return to Main Menu"
)
declare -A TEXT_TR=(
    ["menu_title"]="davila7 Şablonları - Komutlar"
    ["category_title"]="Komut Kategorisi Seçin"
    ["select_prompt"]="Komut(ları) seçin (örn: 1,3,5 veya tümü için A, geri için B)"
    ["install_all"]="Bu kategorideki tüm komutlar kuruluyor..."
    ["installing_selected"]="Seçilen komutlar kuruluyor..."
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
# --- End Text Definitions ---

# --- Command Categories ---
# Commands include their category path (category/command-name)
declare -A COMMAND_CATEGORIES=(
    ["automation"]="automation/act,automation/ci-pipeline,automation/husky,automation/workflow-orchestrator"
    ["database"]="database/supabase-backup-manager,database/supabase-data-explorer,database/supabase-migration-assistant,database/supabase-performance-optimizer,database/supabase-realtime-monitor,database/supabase-schema-sync,database/supabase-security-audit,database/supabase-type-generator"
    ["deployment"]="deployment/add-changelog,deployment/blue-green-deployment,deployment/changelog-demo-command,deployment/ci-setup,deployment/containerize-application,deployment/deployment-monitoring,deployment/hotfix-deploy,deployment/prepare-release,deployment/rollback-deploy,deployment/setup-automated-releases,deployment/setup-kubernetes-deployment"
    ["documentation"]="documentation/create-architecture-documentation,documentation/create-onboarding-guide,documentation/doc-api,documentation/docs-maintenance,documentation/generate-api-documentation,documentation/interactive-documentation,documentation/load-llms-txt,documentation/migration-guide,documentation/troubleshooting-guide,documentation/update-docs"
    ["game-development"]="game-development/game-analytics-integration,game-development/game-asset-pipeline,game-development/game-performance-profiler,game-development/game-testing-framework,game-development/unity-project-setup"
    ["git"]="git/feature,git/finish,git/flow-status,git/hotfix,git/release"
    ["git-workflow"]="git-workflow/branch-cleanup,git-workflow/commit,git-workflow/create-pr,git-workflow/create-pull-request,git-workflow/create-worktrees,git-workflow/fix-github-issue,git-workflow/gemini-review,git-workflow/git-bisect-helper,git-workflow/pr-review,git-workflow/update-branch-name"
    ["marketing"]="marketing/publisher-all,marketing/publisher-devto,marketing/publisher-linkedin,marketing/publisher-medium,marketing/publisher-x"
    ["nextjs-vercel"]="nextjs-vercel/nextjs-api-tester,nextjs-vercel/nextjs-bundle-analyzer,nextjs-vercel/nextjs-component-generator,nextjs-vercel/nextjs-middleware-creator,nextjs-vercel/nextjs-migration-helper,nextjs-vercel/nextjs-performance-audit,nextjs-vercel/nextjs-scaffold,nextjs-vercel/vercel-deploy-optimize,nextjs-vercel/vercel-edge-function,nextjs-vercel/vercel-env-sync"
    ["orchestration"]="orchestration/archive,orchestration/commit,orchestration/find,orchestration/log,orchestration/move,orchestration/optimize,orchestration/remove,orchestration/report,orchestration/resume,orchestration/start,orchestration/status,orchestration/sync"
    ["performance"]="performance/add-performance-monitoring,performance/implement-caching-strategy,performance/optimize-api-performance,performance/optimize-build,performance/optimize-bundle-size,performance/optimize-database-performance,performance/optimize-memory-usage,performance/performance-audit,performance/setup-cdn-optimization,performance/system-behavior-simulator"
    ["project-management"]="project-management/add-package,project-management/add-to-changelog,project-management/create-feature,project-management/create-jtbd,project-management/create-prd,project-management/create-prp,project-management/init-project,project-management/milestone-tracker,project-management/pac-configure,project-management/pac-create-epic,project-management/pac-create-ticket,project-management/pac-update-status,project-management/pac-validate,project-management/project-health-check,project-management/project-timeline-simulator,project-management/project-to-linear,project-management/release,project-management/todo"
    ["security"]="security/add-authentication-system,security/dependency-audit,security/penetration-test,security/secrets-scanner,security/security-audit,security/security-hardening"
    ["setup"]="setup/create-database-migrations,setup/design-database-schema,setup/design-rest-api,setup/implement-graphql-api,setup/migrate-to-typescript,setup/setup-ci-cd-pipeline,setup/setup-development-environment,setup/setup-docker-containers,setup/setup-formatting,setup/setup-linting,setup/setup-monitoring-observability,setup/setup-monorepo,setup/setup-rate-limiting,setup/update-dependencies,setup/vercel-analytics"
    ["simulation"]="simulation/business-scenario-explorer,simulation/constraint-modeler,simulation/decision-tree-explorer,simulation/digital-twin-creator,simulation/future-scenario-generator,simulation/market-response-modeler,simulation/monte-carlo-simulator,simulation/simulation-calibrator,simulation/system-dynamics-modeler,simulation/timeline-compressor"
    ["svelte"]="svelte/svelte-a11y,svelte/svelte-component,svelte/svelte-debug,svelte/svelte-migrate,svelte/svelte-optimize,svelte/svelte-scaffold,svelte/svelte-storybook,svelte/svelte-storybook-migrate,svelte/svelte-storybook-mock,svelte/svelte-storybook-setup,svelte/svelte-storybook-story,svelte/svelte-storybook-troubleshoot,svelte/svelte-test,svelte/svelte-test-coverage,svelte/svelte-test-fix,svelte/svelte-test-setup"
    ["sync"]="sync/bidirectional-sync,sync/bulk-import-issues,sync/cross-reference-manager,sync/issue-to-linear-task,sync/linear-task-to-issue,sync/sync-automation-setup,sync/sync-conflict-resolver,sync/sync-health-monitor,sync/sync-issues-to-linear,sync/sync-linear-to-issues,sync/sync-migration-assistant,sync/sync-pr-to-task,sync/sync-status,sync/task-from-pr"
    ["team"]="team/architecture-review,team/decision-quality-analyzer,team/dependency-mapper,team/estimate-assistant,team/issue-triage,team/memory-spring-cleaning,team/migration-assistant,team/retrospective-analyzer,team/session-learning-capture,team/sprint-planning,team/standup-report,team/team-knowledge-mapper,team/team-velocity-tracker,team/team-workload-balancer"
    ["testing"]="testing/add-mutation-testing,testing/add-property-based-testing,testing/e2e-setup,testing/generate-test-cases,testing/generate-tests,testing/setup-comprehensive-testing,testing/setup-load-testing,testing/setup-visual-testing,testing/test-automation-orchestrator,testing/test-changelog-automation,testing/test-coverage,testing/test-quality-analyzer,testing/testing_plan_integration,testing/write-tests"
    ["utilities"]="utilities/all-tools,utilities/architecture-scenario-explorer,utilities/check-file,utilities/clean,utilities/clean-branches,utilities/code-permutation-tester,utilities/code-review,utilities/code-to-task,utilities/context-prime,utilities/debug-error,utilities/directory-deep-dive,utilities/explain-code,utilities/fix-issue,utilities/generate-linear-worklog,utilities/git-status,utilities/initref,utilities/prime,utilities/refactor-code,utilities/ultra-think"
)

# --- Category Menu ---
show_category_menu() {
    local categories=($(printf "%s\n" "${!COMMAND_CATEGORIES[@]}" | sort))

    while true; do
        clear
        print_heading_panel "$(text 'menu_title')"
        echo "  ${YELLOW}$(text 'category_title')${NC}"
        echo

        local i=1
        for cat in "${categories[@]}"; do
            local count=$(echo "${COMMAND_CATEGORIES[$cat]}" | tr ',' '\n' | wc -l)
            printf "  ${GREEN}%2d${NC} - ${CYAN}%-20s${NC} (${YELLOW}%d${NC} commands)\n" "$i" "$cat" "$count"
            i=$((i + 1))
        done

        echo "  ${YELLOW}A${NC} - Install All Commands (All Categories)"
        echo "  ${YELLOW}0${NC} - $(text 'return')"
        echo

        read -r -p "$(text 'select_prompt'): " choice </dev/tty

        case "$choice" in
            0) break ;;
            a|A)
                log_info_detail "Installing all commands..."
                local all_commands=""
                for cat in "${categories[@]}"; do
                    all_commands="$all_commands,${COMMAND_CATEGORIES[$cat]}"
                done
                all_commands=${all_commands:1}
                npx claude-code-templates@latest --command "$all_commands"
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#categories[@]} ]; then
                    local selected_cat="${categories[$((choice - 1))]}"
                    show_commands_menu "$selected_cat"
                else
                    log_error_detail "Invalid choice: $choice"
                fi
                ;;
        esac
    done
}

# --- Commands Menu for a Category ---
show_commands_menu() {
    local category="$1"
    local commands="${COMMAND_CATEGORIES[$category]}"
    IFS=',' read -ra CMD_ARRAY <<< "$commands"

    while true; do
        clear
        print_heading_panel "$(text 'menu_title') - ${CYAN}$category${NC}"
        echo

        local i=1
        for cmd in "${CMD_ARRAY[@]}"; do
            # Display only the command name (after the last slash)
            local cmd_name="${cmd##*/}"
            printf "  ${GREEN}%2d${NC} - %s\n" "$i" "$cmd_name"
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
                npx claude-code-templates@latest --command "$commands"
                ;;
            *)
                local selected_cmds_arr=()
                IFS=',' read -ra selections <<< "$choice_input"
                for selection in "${selections[@]}"; do
                    selection=$(echo "$selection" | tr -d '[:space:]')
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#CMD_ARRAY[@]} ]; then
                        selected_cmds_arr+=("${CMD_ARRAY[$((selection - 1))]}")
                    fi
                done

                if [ ${#selected_cmds_arr[@]} -gt 0 ]; then
                    log_info_detail "$(text 'installing_selected')"
                    local selected_str
                    selected_str=$(printf ",%s" "${selected_cmds_arr[@]}")
                    selected_str=${selected_str:1}
                    npx claude-code-templates@latest --command "$selected_str"
                fi
                ;;
        esac
        read -r -p "Press Enter to continue..."
    done
}

# --- Main Menu ---
davila7_commands_menu() {
    show_category_menu
}
