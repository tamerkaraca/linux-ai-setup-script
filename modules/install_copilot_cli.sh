#!/bin/bash

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A COPILOT_TEXT_EN=(
    ["install_title"]="Starting GitHub Copilot CLI installation (see https://github.com/github/copilot-cli)"
    ["install_fail"]="npm install -g @github/copilot failed."
    ["command_missing"]="GitHub Copilot CLI command not found. Check your PATH."
    ["version_info"]="GitHub Copilot CLI version: %s"
    ["auth_heading"]="Authenticate following GitHub's official instructions:"
    ["auth_step1"]="Run 'copilot auth login'."
    ["auth_step2"]="Approve the GitHub Copilot page in your browser."
    ["auth_step3"]="Run 'copilot auth activate' to finish shell integration."
    ["auth_auto"]="We’ll run these commands for you; repeat them manually if needed."
    ["press_enter"]="Press Enter to continue..."
    ["bulk_skip"]="Authentication skipped in 'Install All' mode."
    ["bulk_reminder"]="Run '%s' later to authenticate."
    ["alias_added"]="Copilot CLI aliases appended to %s."
    ["alias_exists"]="Copilot CLI aliases are already present in %s."
    ["alias_failed"]="'copilot alias -- %s' failed. Please add aliases manually."
    ["usage_heading"]="GitHub Copilot CLI Usage Tips:"
    ["usage_request"]="Request code: copilot suggest \"read a csv\""
    ["usage_explain"]="Explain command: copilot explain \"what does ls -la do\""
    ["usage_alias_reload"]="Reload aliases:"
    ["usage_more"]="More info: https://github.com/github/copilot-cli"
    ["install_done"]="GitHub Copilot CLI installation completed!"
)

declare -A COPILOT_TEXT_TR=(
    ["install_title"]="GitHub Copilot CLI kurulumu başlatılıyor (bkz. https://github.com/github/copilot-cli)"
    ["install_fail"]="npm install -g @github/copilot komutu başarısız oldu."
    ["command_missing"]="GitHub Copilot CLI komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["version_info"]="GitHub Copilot CLI sürümü: %s"
    ["auth_heading"]="Resmi GitHub yönergelerine göre kimlik doğrulama:"
    ["auth_step1"]="1. 'copilot auth login' komutunu çalıştırın."
    ["auth_step2"]="2. Tarayıcıda açılan GitHub Copilot sayfasından erişimi onaylayın."
    ["auth_step3"]="3. 'copilot auth activate' ile kabuk entegrasyonunu tamamlayın."
    ["auth_auto"]="İşlemleri sizin yerinize başlatıyoruz; gerekirse komutları manuel tekrarlayabilirsiniz."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["bulk_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["bulk_reminder"]="Kimlik doğrulamak için daha sonra '%s' çalıştırın."
    ["alias_added"]="Copilot CLI aliasları %s dosyasına eklendi."
    ["alias_exists"]="Copilot CLI aliasları zaten %s dosyasında mevcut."
    ["alias_failed"]="'copilot alias -- %s' komutu başarısız oldu. Aliasları manuel ekleyin."
    ["usage_heading"]="GitHub Copilot CLI Kullanım İpuçları:"
    ["usage_request"]="Kod isteği: copilot suggest \"read a csv\""
    ["usage_explain"]="Komut açıklaması: copilot explain \"ls -la ne yapar\""
    ["usage_alias_reload"]="Aliasları tekrar yükleme:"
    ["usage_more"]="Daha fazla bilgi: https://github.com/github/copilot-cli"
    ["install_done"]="GitHub Copilot CLI kurulumu tamamlandı!"
)

copilot_text() {
    local key="$1"
    local default_value="${COPILOT_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${COPILOT_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

copilot_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(copilot_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

# GitHub Copilot CLI kurulumu
install_copilot_cli() {
    local interactive_mode=${1:-true}
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(copilot_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if ! npm install -g @github/copilot; then
        echo -e "${RED}${ERROR_TAG}${NC} $(copilot_text install_fail)"
        return 1
    fi

    if ! command -v copilot &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(copilot_text command_missing)"
        return 1
    fi

    local copilot_version_msg
    copilot_printf copilot_version_msg version_info "$(copilot --version)"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${copilot_version_msg}"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}   $(copilot_text auth_heading)${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
        echo -e "  ${GREEN}$(copilot_text auth_step1)${NC}"
        echo -e "  ${GREEN}$(copilot_text auth_step2)${NC}"
        echo -e "  ${GREEN}$(copilot_text auth_step3)${NC}"
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(copilot_text auth_auto)\n"

        read -r -p "$(copilot_text press_enter)" </dev/tty
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(copilot_text bulk_skip)"
        local reminder_msg
        copilot_printf reminder_msg bulk_reminder "'${GREEN}copilot auth login${NC}' && '${GREEN}copilot auth activate${NC}'"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${reminder_msg}"
    fi

    local detected_shell
    detected_shell=$(basename "${SHELL:-bash}")
    case "$detected_shell" in
        bash|zsh) ;; 
        *) detected_shell="bash" ;; 
    esac

    local rc_file
    if [ "$detected_shell" = "zsh" ]; then
        rc_file="$HOME/.zshrc"
    else
        rc_file="$HOME/.bashrc"
    fi
    touch "$rc_file"

    local alias_line
    alias_line=$(printf "eval \"\\\$(copilot alias -- %s)\"" "$detected_shell")

    if copilot alias -- "$detected_shell" >/dev/null 2>&1; then
        eval "$(copilot alias -- "$detected_shell")" 2>/dev/null || true

        if ! grep -Fq 'copilot alias' "$rc_file"; then
            {
                echo ''
                echo '# GitHub Copilot CLI aliasları'
                echo "$alias_line"
            } >> "$rc_file"
            local alias_add_msg
            copilot_printf alias_add_msg alias_added "$rc_file"
            echo -e "${GREEN}${SUCCESS_TAG}${NC} ${alias_add_msg}"
        else
            local alias_exists_msg
            copilot_printf alias_exists_msg alias_exists "$rc_file"
            echo -e "${YELLOW}${INFO_TAG}${NC} ${alias_exists_msg}"
        fi
    else
        local alias_fail_msg
        copilot_printf alias_fail_msg alias_failed "$detected_shell"
        echo -e "${YELLOW}${WARN_TAG}${NC} ${alias_fail_msg}"
    fi

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(copilot_text usage_heading)"
    echo -e "  ${GREEN}•${NC} $(copilot_text usage_request)"
    echo -e "  ${GREEN}•${NC} $(copilot_text usage_explain)"
    echo -e "  ${GREEN}•${NC} $(copilot_text usage_alias_reload) ${GREEN}eval \"\\\$(copilot alias -- ${detected_shell})\"${NC}"
    echo -e "  ${GREEN}•${NC} $(copilot_text usage_more)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}${SUCCESS_TAG}${NC} $(copilot_text install_done)"
}

# Ana kurulum akışı
main() {
    install_copilot_cli "$@"
}

main "$@"
