#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"

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
                login_hint="codex (Sign in with ChatGPT veya OPENAI_API_KEY)"
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
                login_hint="aider --help (API anahtarlarını export edin)"
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
                login_hint="droid (Factory quickstart'a göre)"
                if ! run_module "install_droid_cli" "$interactive"; then
                    success=1
                fi
                ;;
            14)
                label="OpenSpec CLI"
                login_hint="openspec init (projede)"
                if ! run_module "install_openspec_cli" "$interactive"; then
                    success=1
                fi
                ;;
            15)
                label="Contains Studio Agents"
                login_hint="Claude Code'u yeniden başlat"
                if ! run_module "install_claude_agents"; then
                    success=1
                fi
                ;;
            16)
                label="Wes Hobson Agents"
                login_hint="Claude Code'u yeniden başlat"
                if ! run_module "install_claude_agents" "wshobson"; then
                    success=1
                fi
                ;;
            *)
                echo -e "${RED}$(translate warning_invalid_choice): $option${NC}"
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
            echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
            printf "${BLUE}║%*s║${NC}\n" -43 " $(translate ai_menu_title) "
            echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
            echo -e "  ${GREEN}1${NC} $(translate ai_option1)"
            echo -e "  ${GREEN}2${NC} $(translate ai_option2)"
            echo -e "  ${GREEN}3${NC} $(translate ai_option3)"
            echo -e "  ${GREEN}4${NC} $(translate ai_option4)"
            echo -e "  ${GREEN}5${NC} $(translate ai_option5)"
            echo -e "  ${GREEN}6${NC} $(translate ai_option6)"
            echo -e "  ${GREEN}7${NC} $(translate ai_option7)"
            echo -e "  ${GREEN}8${NC} $(translate ai_option8)"
            echo -e "  ${GREEN}9${NC} $(translate ai_option9)"
            echo -e "  ${GREEN}10${NC} $(translate ai_option10)"
            echo -e "  ${GREEN}11${NC} $(translate ai_option11)"
            echo -e "  ${GREEN}12${NC} $(translate ai_option12)"
            echo -e "  ${GREEN}13${NC} $(translate ai_option13)"
            echo -e "  ${GREEN}14${NC} $(translate ai_option14)"
            echo -e "  ${GREEN}15${NC} $(translate ai_option15)"
            echo -e "  ${GREEN}16${NC} $(translate ai_option16)"
            echo -e "  ${GREEN}17${NC} $(translate ai_option17)"
            echo -e "  ${RED}0${NC} $(translate ai_option_return)"
            echo -e "\n${YELLOW}$(translate ai_menu_hint)${NC}"
            echo
            read -r -p "${YELLOW}$(translate prompt_choice):${NC} " cli_choices </dev/tty
            if [ -z "$(echo "$cli_choices" | tr -d '[:space:]')" ]; then
                echo -e "${YELLOW}$(translate warning_no_selection)${NC}"
                sleep 1
                continue
            fi
            if [ "$cli_choices" = "0" ]; then
                echo -e "${YELLOW}$(translate info_returning)${NC}"
                break
            fi
        else
            cli_choices="17"
            batch_context=true
        fi

        local all_installed=false
        local exit_menu=false
        IFS=',' read -ra SELECTED_CLI <<< "$cli_choices"
        if [ "${#SELECTED_CLI[@]}" -gt 1 ]; then
            batch_context=true
        fi

        for choice in "${SELECTED_CLI[@]}"; do
            choice=$(echo "$choice" | tr -d '[:space:]')
            [ -z "$choice" ] && continue

            if [ "$choice" = "17" ]; then
                batch_context=true
            fi

            local interactive_flag="true"
            if [ "$batch_context" = true ]; then
                interactive_flag="false"
            fi

            case $choice in
                1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16)
                    run_cli_choice "$choice" "$interactive_flag" || true
                    ;;
                17)
                    batch_context=true
                    for sub_choice in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
                        run_cli_choice "$sub_choice" "false" || true
                    done
                    all_installed=true
                    ;;
                0)
                    exit_menu=true
                    break
                    ;;
                *)
                    echo -e "${RED}$(translate warning_invalid_choice): $choice${NC}"
                    ;;
            esac
        done

        if [ "$exit_menu" = true ]; then
            echo -e "${YELLOW}$(translate info_returning)${NC}"
            break
        fi

        if [ "$batch_context" = true ] && [ "${#CLI_SUMMARY[@]}" -gt 0 ]; then
            echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
            echo -e "${YELLOW}${INFO_TAG}${NC} $(translate ai_summary_title)"
            echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
            declare -A PRINTED_HINTS=()
            for summary_entry in "${CLI_SUMMARY[@]}"; do
                IFS=':::' read -r summary_label summary_hint <<< "$summary_entry"
                [ -n "$summary_label" ] || continue
                if [ -n "${PRINTED_HINTS[$summary_label]:-}" ]; then
                    continue
                fi
                PRINTED_HINTS["$summary_label"]=1
                if [ -n "$summary_hint" ]; then
                    echo -e "  ${GREEN}•${NC} ${summary_label}: ${GREEN}${summary_hint}${NC}"
                else
                    echo -e "  ${GREEN}•${NC} ${summary_label}: ${YELLOW}$(translate ai_summary_default_hint)${NC}"
                fi
            done
        fi

        if [ "$all_installed" = true ] || [ -n "$install_all" ] || [ "$batch_context" = true ]; then
            break
        fi

        read -r -p "${YELLOW}$(translate ai_prompt_install_more)${NC} " continue_choice </dev/tty
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
