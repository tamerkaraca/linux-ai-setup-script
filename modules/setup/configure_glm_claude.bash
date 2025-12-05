#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

# Prefer local direct source (relative to this file). If not available, fall back to
# the setup-provided `source_module` helper when running under the main `setup` script.
if [ -f "$utils_local" ]; then
    # shellcheck source=/dev/null
    source "$utils_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

: "${RED:='\033[0;31m'}"
: "${GREEN:='\033[0;32m'}"
: "${YELLOW:='\033[1;33m'}"
: "${BLUE:='\033[0;34m'}"
: "${CYAN:='\033[0;36m'}"
: "${NC:='\033[0m'}"

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
gl_text() {
    local key="$1"
    local default_value="${GL_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo "${GL_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

ensure_claude_settings_dir() {
    if [ ! -d "$CLAUDE_DIR" ]; then
        log_info_detail "Claude dizini oluşturuluyor..."
        mkdir -p "$CLAUDE_DIR"
    fi
}

read_current_env() {
    local key="$1"
    if [ -f "$SETTINGS_FILE" ]; then
        if command -v jq &> /dev/null; then
            jq -r --arg key "$key" '.env[$key] // ""' "$SETTINGS_FILE" 2>/dev/null || echo ""
        else
            grep -m1 "\"$key\"" "$SETTINGS_FILE" | sed -nE 's/.*"'"$key"'": *"(.*)".*/\1/p'
        fi
    fi
}

write_settings_file() {
    local content="$1"
    echo "$content" > "$SETTINGS_FILE"
    log_success_detail "$(gl_text settings_saved): ${SETTINGS_FILE}"
}

# shellcheck disable=SC2120
configure_glm_provider() {
    log_info_detail "$(gl_text glm_title)"

    ensure_claude_settings_dir
    
    log_info_detail "$(gl_text glm_steps_header)"
    log_info_detail "1. $(gl_text glm_step1)"
    log_info_detail "2. $(gl_text glm_step2)"
    log_info_detail "3. $(gl_text glm_step3)"
    log_info_detail "4. $(gl_text glm_step4)"
    
    local default_base_url="https://api.z.ai/api/anthropic"
    local current_api_key
    current_api_key=$(read_current_env "ANTHROPIC_AUTH_TOKEN")
    local GLM_BASE_URL="$default_base_url"

    local masked_key_display
    masked_key_display="$(gl_text api_masked_default)"
    if [ -n "$current_api_key" ]; then
        masked_key_display=$(mask_secret "$current_api_key")
    fi

    read -r -p "$(gl_text glm_api_prompt) [${masked_key_display}]: " GLM_API_KEY </dev/tty
    
    if [ -z "$GLM_API_KEY" ]; then
        if [ -n "$current_api_key" ]; then
            GLM_API_KEY="$current_api_key"
            log_info_detail "$(gl_text glm_keep_existing)"
        else
            log_error_detail "$(gl_text glm_empty_key)"
            return 1
        fi
    fi
    
    log_info_detail "$(gl_text glm_settings_creating)"
    
    write_settings_file "$(cat << EOF
{
  "env": {
      "ANTHROPIC_AUTH_TOKEN": "${GLM_API_KEY}",
      "ANTHROPIC_BASE_URL": "${GLM_BASE_URL}",
      "API_TIMEOUT_MS": "3000000",
      "ANTHROPIC_DEFAULT_OPUS_MODEL": "GLM-4.6",
      "ANTHROPIC_DEFAULT_SONNET_MODEL": "GLM-4.6",
      "ANTHROPIC_DEFAULT_HAIKU_MODEL": "GLM-4.5-Air"
  }
}
EOF
)"
    
    log_info_detail "$(gl_text glm_settings_path) $SETTINGS_FILE"
    log_info_detail "$(gl_text glm_config_header)"
    log_success_detail "  • Opus Model: GLM-4.6"
    log_success_detail "  • Sonnet Model: GLM-4.6"
    log_success_detail "  • Haiku Model: GLM-4.5-Air"
    log_info_detail "$(gl_text glm_launch_hint)"
    log_info_detail "$(gl_text glm_status_hint)"
    
    log_info_detail "$(gl_text glm_plan_header)"
    log_success_detail "  • $(gl_text glm_plan_point1)"
    log_success_detail "  • $(gl_text glm_plan_point2)"
    log_success_detail "  • $(gl_text glm_plan_point3)"
}

maybe_reinstall_claude_cli() {
    if ! command -v npm &> /dev/null; then
        log_warn_detail "$(gl_text reinstall_missing_npm)"
        return 0
    fi
    read -r -p "$(gl_text kimi_reinstall_prompt)" reinstall_choice </dev/tty || true
    if [[ "$reinstall_choice" =~ ^([eEyY])$ ]]; then
        require_node_version 18 "Claude Code CLI"
        log_info_detail "$(gl_text reinstall_running)"
        if npm_install_global_with_fallback "@anthropic-ai/claude-code" "Claude Code CLI"; then
            log_success_detail "$(gl_text reinstall_done)"
        else
            log_error_detail "$(gl_text reinstall_fail)"
        fi
    fi
}

# shellcheck disable=SC2120
configure_kimi_provider() {
    log_info_detail "$(gl_text kimi_title)"

    ensure_claude_settings_dir
    require_node_version 18 "Moonshot kimi-k2 Claude Code"

    log_info_detail "$(gl_text kimi_steps_header)"
    echo -e "  ${CYAN}1.${NC} $(gl_text kimi_step1)"
    echo -e "  ${CYAN}2.${NC} $(gl_text kimi_step2)"
    echo -e "  ${CYAN}3.${NC} $(gl_text kimi_step3)"
    echo -e "  ${CYAN}4.${NC} $(gl_text kimi_step4)"

    maybe_reinstall_claude_cli

    local default_base_url="https://api.moonshot.ai/anthropic"
    local current_api_key
    current_api_key=$(read_current_env "ANTHROPIC_AUTH_TOKEN")

    local masked
    masked="$(gl_text api_masked_default)"
    if [ -n "$current_api_key" ]; then
        masked=$(mask_secret "$current_api_key")
    fi

    read -r -p "$(gl_text kimi_api_prompt) [${masked}]: " MOONSHOT_API_KEY </dev/tty
    if [ -z "$MOONSHOT_API_KEY" ]; then
        if [ -n "$current_api_key" ]; then
            MOONSHOT_API_KEY="$current_api_key"
            log_info_detail "$(gl_text kimi_keep_existing)"
        else
            log_error_detail "$(gl_text kimi_empty_key)"
            return 1
        fi
    fi

    local MOONSHOT_BASE_URL="$default_base_url"

    echo
    echo -e "${YELLOW}$(gl_text kimi_model_prompt)${NC}"
    echo -e "  ${GREEN}1${NC} - $(gl_text kimi_model_opt1)"
    echo -e "  ${GREEN}2${NC} - $(gl_text kimi_model_opt2)"
    echo -e "  ${GREEN}3${NC} - $(gl_text kimi_model_opt3)"
    read -r -p "$(gl_text prov_prompt) [1]: " model_choice </dev/tty
    local selected_model
    case "${model_choice:-1}" in
        2) selected_model="kimi-k2-turbo-preview" ;;
        3)
            read -r -p "$(gl_text kimi_model_manual_prompt)" manual_model </dev/tty
            if [ -z "$manual_model" ]; then
                log_error_detail "$(gl_text kimi_model_manual_error)"
                return 1
            fi
            selected_model="$manual_model"
            ;;
        *) selected_model="kimi-k2-0711-preview" ;;
    esac

    write_settings_file "$(cat << EOF
{
  "env": {
      "ANTHROPIC_AUTH_TOKEN": "${MOONSHOT_API_KEY}",
      "ANTHROPIC_BASE_URL": "${MOONSHOT_BASE_URL}",
      "MOONSHOT_PROVIDER": "kimi-k2",
      "API_TIMEOUT_MS": "3000000",
      "ANTHROPIC_DEFAULT_OPUS_MODEL": "${selected_model}",
      "ANTHROPIC_DEFAULT_SONNET_MODEL": "${selected_model}",
      "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${selected_model}"
  }
}
EOF
)"

    log_success_detail "$(gl_text kimi_success_title)"
    log_info_detail "$(gl_text kimi_success_path): ${SETTINGS_FILE} (${selected_model})"
    log_info_detail "$(gl_text kimi_success_run) ${GREEN}${selected_model}${NC}."
}

configure_menu() {
    while true; do
        print_heading_panel "$(gl_text prov_menu_title)"
        echo -e "  ${GREEN}1${NC} - $(gl_text prov_option1)"
        echo -e "  ${GREEN}2${NC} - $(gl_text prov_option2)"
        echo -e "  ${GREEN}0${NC} - $(gl_text prov_option0)"
        read -r -p "$(gl_text prov_prompt): " cfg_choice </dev/tty
        case "${cfg_choice:-}" in
            1)
                # shellcheck disable=SC2119
                configure_glm_provider
                ;;
            2)
                # shellcheck disable=SC2119
                configure_kimi_provider
                ;;
            0)
                log_info_detail "$(gl_text prov_returning)"
                return 0
                ;;
            *)
                log_error_detail "$(gl_text prov_invalid)"
                ;;
        esac
    done
}

# Ana kurulum akışı
main() {
    configure_menu
}

main
