#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "./modules/utils.sh"



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
                label="GitHub Copilot CLI"
                login_hint="copilot auth login && copilot auth activate"
                if ! run_module "install_copilot_cli" "$interactive"; then
                    success=1
                fi
                ;;
            *)
                echo -e "${RED}[HATA]${NC} Geçersiz seçim: $option"
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
            echo -e "${BLUE}║        AI CLI Araçları Kurulum Menüsü         ║${NC}"
            echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
            echo -e "  ${GREEN}1${NC} Claude Code CLI"
            echo -e "  ${GREEN}2${NC} Gemini CLI"
            echo -e "  ${GREEN}3${NC} OpenCode CLI"
            echo -e "  ${GREEN}4${NC} Qoder CLI"
            echo -e "  ${GREEN}5${NC} Qwen CLI"
            echo -e "  ${GREEN}6${NC} OpenAI Codex CLI"
            echo -e "  ${GREEN}7${NC} GitHub Copilot CLI"
            echo -e "  ${GREEN}8${NC} Tümünü Kur"
            echo -e "  ${RED}0${NC} Ana Menü"
            echo -e "\n${YELLOW}[BİLGİ]${NC} Birden fazla seçim için virgülle ayırabilirsiniz (örn: 1,3,7)."
            echo
            read -r -p "${YELLOW}Seçiminiz:${NC} " cli_choices </dev/tty
            if [ -z "$(echo "$cli_choices" | tr -d '[:space:]')" ]; then
                echo -e "${YELLOW}[UYARI]${NC} Bir seçim yapmadınız, lütfen tekrar deneyin."
                sleep 1
                continue
            fi
            if [ "$cli_choices" = "0" ]; then
                echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
                break
            fi
        else
            cli_choices="8"
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

            if [ "$choice" = "8" ]; then
                batch_context=true
            fi

            local interactive_flag="true"
            if [ "$batch_context" = true ]; then
                interactive_flag="false"
            fi

            case $choice in
                1|2|3|4|5|6|7)
                    run_cli_choice "$choice" "$interactive_flag" || true
                    ;;
                8)
                    batch_context=true
                    for sub_choice in 1 2 3 4 5 6 7; do
                        run_cli_choice "$sub_choice" "false" || true
                    done
                    all_installed=true
                    ;;
                0)
                    exit_menu=true
                    break
                    ;;
                *)
                    echo -e "${RED}[HATA]${NC} Geçersiz seçim: $choice"
                    ;;
            esac
        done

        if [ "$exit_menu" = true ]; then
            echo -e "${YELLOW}[BİLGİ]${NC} Ana menüye dönülüyor..."
            break
        fi

        if [ "$batch_context" = true ] && [ "${#CLI_SUMMARY[@]}" -gt 0 ]; then
            echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
            echo -e "${YELLOW}[BİLGİ]${NC} Kurulan CLI araçları için giriş komutları:"
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
                    echo -e "  ${GREEN}•${NC} ${summary_label}: ${YELLOW}İlgili CLI dokümanındaki kimlik doğrulama adımlarını uygulayın.${NC}"
                fi
            done
        fi

        if [ "$all_installed" = true ] || [ -n "$install_all" ] || [ "$batch_context" = true ]; then
            break
        fi

        read -r -p "Başka bir AI CLI aracı kurmak ister misiniz? (e/h) [h]: " continue_choice </dev/tty
        if [[ "$continue_choice" != "e" && "$continue_choice" != "E" ]]; then
            break
        fi
    done
}

# Ana kurulum akışı
main() {
    install_ai_cli_tools_menu "$@"
}

main "$@"
