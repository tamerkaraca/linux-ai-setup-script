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
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

: "${GREEN:=$'\033[0;32m'}"
: "${NC:=$'\033[0m'}"

# --- Start: Copilot-specific logic ---

declare -A COPILOT_TEXT_EN=(
    ["install_title"]="Starting GitHub Copilot CLI installation (see https://github.com/github/copilot-cli)"
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
    ["install_failed"]="GitHub Copilot CLI installation failed. Aborting."
    ["cmd_not_found"]="Copilot command not found after installation. Aborting post-install steps."
    ["version_info"]="GitHub Copilot CLI version:"
)

declare -A COPILOT_TEXT_TR=(
    ["install_title"]="GitHub Copilot CLI kurulumu başlatılıyor (bkz. https://github.com/github/copilot-cli)"
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
    ["install_failed"]="GitHub Copilot CLI kurulumu başarısız oldu. İptal ediliyor."
    ["cmd_not_found"]="Copilot komutu kurulumdan sonra bulunamadı. Kurulum sonrası adımlar iptal ediliyor."
    ["version_info"]="GitHub Copilot CLI sürümü:"
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

# --- End: Copilot-specific logic ---

main() {
    local interactive_mode=${1:-true}
    log_info_detail "$(copilot_text install_title)"

    # Use the universal installer from utils.sh
    install_package "GitHub Copilot CLI" "npm" "copilot" "@github/copilot"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(copilot_text install_failed)"
        return 1
    fi

    # The `install_package` function reloads the shell, but sometimes we need to locate the binary again
    if ! command -v copilot &> /dev/null; then
        log_error_detail "$(copilot_text cmd_not_found)"
        return 1
    fi

    log_success_detail "$(copilot_text version_info) $(copilot --version)"

    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(copilot_text auth_heading)"
        echo -e "  ${GREEN}$(copilot_text auth_step1)${NC}"
        echo -e "  ${GREEN}$(copilot_text auth_step2)${NC}"
        echo -e "  ${GREEN}$(copilot_text auth_step3)${NC}"
        echo
        log_info_detail "$(copilot_text auth_auto)"
        read -r -p "$(copilot_text press_enter)" </dev/tty || true
        
        copilot auth login
        copilot auth activate
    else
        echo
        log_info_detail "$(copilot_text bulk_skip)"
        log_info_detail "$(copilot_printf "msg" "bulk_reminder" "'${GREEN}copilot auth login${NC}' && '${GREEN}copilot auth activate${NC}'" && echo "$msg")"
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
    alias_line=$(printf "eval \"\\\\$(copilot alias -- %s)\"" "$detected_shell")

    if copilot alias -- "$detected_shell" >/dev/null 2>&1; then
        eval "$(copilot alias -- "$detected_shell")" 2>/dev/null || true # Reload aliases for current script

        if ! grep -Fq 'copilot alias' "$rc_file"; then
            {
                echo ''
                echo '# GitHub Copilot CLI aliasları'
                echo "$alias_line"
            } >> "$rc_file"
            log_success_detail "$(copilot_printf "msg" "alias_added" "$rc_file" && echo "$msg")"
        else
            log_info_detail "$(copilot_printf "msg" "alias_exists" "$rc_file" && echo "$msg")"
        fi
    else
        log_warn_detail "$(copilot_printf "msg" "alias_failed" "$detected_shell" && echo "$msg")"
    fi

    echo
    log_info_detail "$(copilot_text usage_heading)"
    echo -e "  ${GREEN}•${NC} $(copilot_text usage_request)"
    echo -e "  ${GREEN}•${NC} $(copilot_text usage_explain)"
    log_info_detail "  ${GREEN}•${NC} $(copilot_text usage_alias_reload) ${GREEN}eval \"\\[\$(copilot alias -- ${detected_shell})\\]\"${NC}"
    log_info_detail "  ${GREEN}•${NC} $(copilot_text usage_more)"
    
    echo
    log_success_detail "$(copilot_text install_done)"
}

main "$@"