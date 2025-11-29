#!/bin/bash
set -euo pipefail

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A AI_CLI_MENU_TEXT_EN=(
    ["ai_menu_title"]="AI CLI Tools Installation Menu"
    ["ai_option1"]="Claude Code CLI (Anthropic)"
    ["ai_option2"]="Gemini CLI (Google)"
    ["ai_option3"]="OpenCode CLI (OpenCode)"
    ["ai_option4"]="Qoder CLI (Qoder)"
    ["ai_option5"]="Qwen CLI (Alibaba)"
    ["ai_option6"]="OpenAI Codex CLI (OpenAI)"
    ["ai_option7"]="Cursor Agent CLI (Cursor)"
    ["ai_option8"]="Cline CLI (Marvin)"
    ["ai_option9"]="Aider CLI (Aider)"
    ["ai_option10"]="GitHub Copilot CLI"
    ["ai_option11"]="Kilocode CLI"
    ["ai_option12"]="Auggie CLI"
    ["ai_option13"]="Droid CLI"
    ["ai_option14"]="Jules CLI (Google)"
    ["ai_optionA"]="Install All AI CLI Tools"
    ["ai_option_return"]="Return to Main Menu"
    ["ai_menu_hint"]="You can make multiple selections with commas (e.g., 1,2,5)."
    ["prompt_choice"]="Your choice"
    ["warning_no_selection"]="No selection made. Please try again."
    ["info_returning"]="Returning to the previous menu..."
    ["warning_invalid_choice"]="Invalid choice"
    ["ai_summary_title"]="Installation Summary & Login Information"
    ["ai_summary_default_hint"]="Check the tool's documentation for login."
    ["ai_prompt_install_more"]="Install another tool? (y/n) [n]: "
)

declare -A AI_CLI_MENU_TEXT_TR=(
    ["ai_menu_title"]="AI CLI Araçları Kurulum Menüsü"
    ["ai_option1"]="Claude Code CLI (Anthropic)"
    ["ai_option2"]="Gemini CLI (Google)"
    ["ai_option3"]="OpenCode CLI (OpenCode)"
    ["ai_option4"]="Qoder CLI (Qoder)"
    ["ai_option5"]="Qwen CLI (Alibaba)"
    ["ai_option6"]="OpenAI Codex CLI (OpenAI)"
    ["ai_option7"]="Cursor Agent CLI (Cursor)"
    ["ai_option8"]="Cline CLI (Marvin)"
    ["ai_option9"]="Aider CLI (Aider)"
    ["ai_option10"]="GitHub Copilot CLI"
    ["ai_option11"]="Kilocode CLI"
    ["ai_option12"]="Auggie CLI"
    ["ai_option13"]="Droid CLI"
    ["ai_option14"]="Jules CLI (Google)"
    ["ai_optionA"]="Tüm AI CLI Araçlarını Kur"
    ["ai_option_return"]="Ana Menüye Dön"
    ["ai_menu_hint"]="Birden fazla seçim için virgül kullanabilirsiniz (örn: 1,2,5)."
    ["prompt_choice"]="Seçiminiz"
    ["warning_no_selection"]="Hiçbir seçim yapılmadı. Lütfen tekrar deneyin."
    ["info_returning"]="Bir önceki menüye dönülüyor..."
    ["warning_invalid_choice"]="Geçersiz seçim"
    ["ai_summary_title"]="Kurulum Özeti ve Oturum Açma Bilgileri"
    ["ai_summary_default_hint"]="Oturum açma bilgileri için aracın dokümanlarına bakın."
    ["ai_prompt_install_more"]="Başka bir araç kurmak ister misiniz? (e/h) [h]: "
)

ai_cli_menu_text() {
    local key="$1"
    local default_value="${AI_CLI_MENU_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AI_CLI_MENU_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

if ! declare -f run_module >/dev/null 2>&1; then
    run_module() {
        local module_name="$1"
        local module_url="${BASE_URL}/${module_name}.sh"
        shift
        if ! curl -fsSL "$module_url" | LANGUAGE="$LANGUAGE" bash -s -- "$@"; then
            echo -e "${RED}${ERROR_TAG}${NC} $module_name modülü çalıştırılırken bir hata oluştu."
            return 1
        fi
    }
fi


# AI CLI Araçları menüsü
install_ai_cli_tools_menu() {
    local install_all="${1:-}" # "all" parametresi gelirse hepsini kur
    local -a CLI_SUMMARY=()

    run_cli_choice() {
        local option="$1"
        local interactive="$2"
        local label=""
        local login_hint=""
        local success=0

        case "$option" in
            1)
                label="Claude Code CLI"
                login_hint="claude login"
                if ! run_module "install_claude_code" "$interactive"; then
                    success=1
                fi
                ;;
            2)
                label="Gemini CLI"
                login_hint="gemini auth"
                if ! run_module "install_gemini_cli" "$interactive"; then
                    success=1
                fi
                ;;
            3)
                label="OpenCode CLI"
                login_hint="opencode login"
                if ! run_module "install_opencode_cli" "$interactive"; then
                    success=1
                fi
                ;;
            4)
                label="Qoder CLI"
                login_hint="qoder login"
                if ! run_module "install_qoder_cli" "$interactive" "--tool" "qoder"; then
                    success=1
                fi
                ;;
            5)
                label="Qwen CLI"
                login_hint="qwen login"
                if ! run_module "install_qwen_cli" "$interactive"; then
                    success=1
                fi
                ;;
            6)
                label="OpenAI Codex CLI"
                login_hint="codex (Sign in with ChatGPT or OPENAI_API_KEY)"
                if ! run_module "install_codex_cli" "$interactive"; then
                    success=1
                fi
                ;;
            7)
                label="Cursor Agent CLI"
                login_hint="cursor-agent login"
                if ! run_module "install_cursor_cli" "$interactive"; then
                    success=1
                fi
                ;;
            8)
                label="Cline CLI"
                login_hint="cline login"
                if ! run_module "install_cline_cli" "$interactive"; then
                    success=1
                fi
                ;;
            9)
                label="Aider CLI"
                login_hint="aider --help (Export API keys)"
                if ! run_module "install_aider_cli" "$interactive"; then
                    success=1
                fi
                ;;
            10)
                label="GitHub Copilot CLI"
                login_hint="copilot auth login && copilot auth activate"
                if ! run_module "install_copilot_cli" "$interactive"; then
                    success=1
                fi
                ;;
            11)
                label="Kilocode CLI"
                login_hint="kilocode config"
                if ! run_module "install_kilocode_cli" "$interactive"; then
                    success=1
                fi
                ;;
            12)
                label="Auggie CLI"
                login_hint="auggie login"
                if ! run_module "install_auggie_cli" "$interactive"; then
                    success=1
                fi
                ;;
            13)
                label="Droid CLI"
                login_hint="droid (per Factory quickstart)"
                if ! run_module "install_droid_cli" "$interactive"; then
                    success=1
                fi
                ;;
            14)
                label="Jules CLI"
                login_hint="jules login"
                if ! run_module "install_jules_cli" "$interactive"; then
                    success=1
                fi
                ;;
            *)
                echo -e "${RED}$(ai_cli_menu_text warning_invalid_choice): $option${NC}"
                success=1
                ;;
esac

        if [ $success -eq 0 ] && [ -n "$label" ]; then
            CLI_SUMMARY+=("$label:::${login_hint}")
        fi
        return $success
    }

    while true; do
        CLI_SUMMARY=()
        local batch_context=false
        local cli_choices=""

        clear
        if [ -z "$install_all" ]; then
            echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
            text=" $(ai_cli_menu_text ai_menu_title) "
            len=${#text}
            padding=$(( (72 - len) / 2 ))
            printf "${BLUE}║%*s%s%*s║${NC}\n" "$padding" "" "$text" "$((72 - len - padding))" ""
            echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
            echo -e "  ${GREEN}1${NC} $(ai_cli_menu_text ai_option1)"
            echo -e "  ${GREEN}2${NC} $(ai_cli_menu_text ai_option2)"
            echo -e "  ${GREEN}3${NC} $(ai_cli_menu_text ai_option3)"
            echo -e "  ${GREEN}4${NC} $(ai_cli_menu_text ai_option4)"
            echo -e "  ${GREEN}5${NC} $(ai_cli_menu_text ai_option5)"
            echo -e "  ${GREEN}6${NC} $(ai_cli_menu_text ai_option6)"
            echo -e "  ${GREEN}7${NC} $(ai_cli_menu_text ai_option7)"
            echo -e "  ${GREEN}8${NC} $(ai_cli_menu_text ai_option8)"
            echo -e "  ${GREEN}9${NC} $(ai_cli_menu_text ai_option9)"
            echo -e "  ${GREEN}10${NC} $(ai_cli_menu_text ai_option10)"
            echo -e "  ${GREEN}11${NC} $(ai_cli_menu_text ai_option11)"
            echo -e "  ${GREEN}12${NC} $(ai_cli_menu_text ai_option12)"
            echo -e "  ${GREEN}13${NC} $(ai_cli_menu_text ai_option13)"
            echo -e "  ${GREEN}14${NC} $(ai_cli_menu_text ai_option14)"
            echo -e "  ${GREEN}A${NC} $(ai_cli_menu_text ai_optionA)"
            echo -e "  ${RED}0${NC} $(ai_cli_menu_text ai_option_return)"
            echo -e "\n${YELLOW}$(ai_cli_menu_text ai_menu_hint)${NC}"
            echo
            read -r -p "${YELLOW}$(ai_cli_menu_text prompt_choice):${NC} " cli_choices </dev/tty
            if [ -z "$(echo "$cli_choices" | tr -d '[:space:]')" ]; then
                echo -e "${YELLOW}$(ai_cli_menu_text warning_no_selection)${NC}"
                sleep 1
                continue
            fi
            if [ "$cli_choices" = "0" ]; then
                echo -e "${YELLOW}$(ai_cli_menu_text info_returning)${NC}"
                break
            fi
        else
            cli_choices="A"
            batch_context=true
        fi

        local all_installed=false
        local exit_menu=false
        IFS=',' read -ra SELECTED_CLI <<< "$cli_choices"
        if [ "${#SELECTED_CLI[@]}" -gt 1 ]; then
            batch_context=true
        fi

        for choice in "${SELECTED_CLI[@]}"; do
            choice=$(echo "$choice" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
            [ -z "$choice" ] && continue

            if [ "$choice" = "A" ]; then
                batch_context=true
            fi

            local interactive_flag="true"
            if [ "$batch_context" = true ]; then
                interactive_flag="false"
            fi

            case $choice in
                1|2|3|4|5|6|7|8|9|10|11|12|13|14)
                    run_cli_choice "$choice" "$interactive_flag" || true
                    ;;
                A)
                    batch_context=true
                    for sub_choice in {1..14}; do
                        run_cli_choice "$sub_choice" "false" || true
                    done
                    all_installed=true
                    ;;
                0)
                    exit_menu=true
                    break
                    ;;
                *)
                    echo -e "${RED}$(ai_cli_menu_text warning_invalid_choice): $choice${NC}"
                    ;;
esac
        done

        if [ "$exit_menu" = true ]; then
            echo -e "${YELLOW}$(ai_cli_menu_text info_returning)${NC}"
            break
        fi

        if [ "$batch_context" = true ] && [ "${#CLI_SUMMARY[@]}" -gt 0 ]; then
            echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
            echo -e "${YELLOW}${INFO_TAG}${NC} $(ai_cli_menu_text ai_summary_title)"
            echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
            declare -A PRINTED_HINTS=()
            for summary_entry in "${CLI_SUMMARY[@]}"; do
                IFS=':::' read -r summary_label summary_hint <<< "$summary_entry"
                [ -n "$summary_label" ] || continue
                if [ -n "${PRINTED_HINTS[$summary_label]:-}" ]; then
                    continue
                fi
                PRINTED_HINTS["$summary_label"]=$((1))
                if [ -n "$summary_hint" ]; then
                    # Adjust hint translations
                    case "$summary_hint" in
                        "claude login") summary_hint="claude login" ;; 
                        "gemini auth") summary_hint="gemini auth" ;; 
                        "opencode login") summary_hint="opencode login" ;; 
                        "qoder login") summary_hint="qoder login" ;; 
                        "qwen login") summary_hint="qwen login" ;; 
                        "codex (Sign in with ChatGPT or OPENAI_API_KEY)")
                            if [ "${LANGUAGE:-en}" = "tr" ]; then
                                summary_hint="codex (ChatGPT ile oturum açın veya OPENAI_API_KEY kullanın)"
                            fi
                            ;;
                        "cursor-agent login") summary_hint="cursor-agent login" ;; 
                        "cline login") summary_hint="cline login" ;; 
                        "aider --help (Export API keys)")
                            if [ "${LANGUAGE:-en}" = "tr" ]; then
                                summary_hint="aider --help (API anahtarlarını export edin)"
                            fi
                            ;;
                        "copilot auth login && copilot auth activate") summary_hint="copilot auth login && copilot auth activate" ;; 
                        "kilocode config") summary_hint="kilocode config" ;; 
                        "auggie login") summary_hint="auggie login" ;; 
                        "droid (per Factory quickstart)")
                            if [ "${LANGUAGE:-en}" = "tr" ]; then
                                summary_hint="droid (Factory quickstart'a göre)"
                            fi
                            ;;
                        "jules login") summary_hint="jules login" ;;
                    esac
                    echo -e "  ${GREEN}•${NC} ${summary_label}: ${GREEN}${summary_hint}${NC}"
                else
                    echo -e "  ${GREEN}•${NC} ${summary_label}: ${YELLOW}$(ai_cli_menu_text ai_summary_default_hint)${NC}"
                fi
            done
        fi

        if [ "$all_installed" = true ] || [ -n "$install_all" ] || [ "$batch_context" = true ]; then
            break
        fi

        read -r -p "${YELLOW}$(ai_cli_menu_text ai_prompt_install_more)${NC} " continue_choice </dev/tty
        if [[ ! "$continue_choice" =~ ^([eEyY])$ ]]; then
            break
        fi
    done
}

# Ana kurulum akışı
main() {
    install_ai_cli_tools_menu "$@"
}

main "$@"
