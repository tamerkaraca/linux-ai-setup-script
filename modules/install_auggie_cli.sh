#!/bin/bash
set -euo pipefail

: "${AUGGIE_NPM_PACKAGE:=@augmentcode/auggie}"
: "${AUGGIE_MIN_NODE_VERSION:=22}"
: "${AUGGIE_DOC_URL:=https://docs.augmentcode.com/cli/overview}"

UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A AUGGIE_TEXT_EN=(
    ["npm_missing"]="npm command not found. Please run main menu option 3 (Node.js tools) first."
    ["install_title"]="Starting Auggie CLI installation..."
    ["dry_run_requirement"]="Will verify Node.js >= %s."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run mode skips authentication steps."
    ["install_start"]="Auggie CLI npm installation begins..."
    ["install_fail"]="Auggie CLI installation failed. Package: %s"
    ["command_missing"]="'auggie' command not found. Check your PATH."
    ["version_info"]="Auggie CLI version: %s"
    ["feature_intro"]="Auggie CLI helps you safely modify code with:"
    ["feature_login"]="• auggie login → browser-based authentication"
    ["feature_prompt"]="• auggie \"prompt\" → interactive run in the project folder"
    ["feature_print"]="• auggie --print \"...\" → CI output (last message only)"
    ["feature_templates"]="• .augment/commands/*.md → reusable slash-command templates"
    ["login_auto"]="We’ll launch 'auggie login' for you; rerun manually if needed."
    ["login_failed"]="'auggie login' failed. Please try again manually."
    ["no_tty"]="TTY not available; run 'auggie login' manually."
    ["press_enter"]="Press Enter to continue..."
    ["batch_skip"]="Authentication skipped in batch mode. Run '%s' later."
    ["install_done"]="Auggie CLI installation completed! Docs: %s"
)

declare -A AUGGIE_TEXT_TR=(
    ["npm_missing"]="npm komutu bulunamadı. Lütfen ana menüdeki 3. seçenek (Node.js araçları) ile Node.js kurun."
    ["install_title"]="Auggie CLI kurulumu başlatılıyor..."
    ["dry_run_requirement"]="Node.js >= %s gereksinimi doğrulanacak."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run modunda kimlik doğrulama adımları atlanır."
    ["install_start"]="Auggie CLI npm paketinin kurulumu başlatılıyor..."
    ["install_fail"]="Auggie CLI kurulumu başarısız oldu. Paket: %s"
    ["command_missing"]="'auggie' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["version_info"]="Auggie CLI sürümü: %s"
    ["feature_intro"]="Auggie CLI, depodaki kodu anlayıp güvenli değişiklikler yapabilmeniz için şu özellikleri sunar:"
    ["feature_login"]="• auggie login → tarayıcı tabanlı oturum açma"
    ["feature_prompt"]="• auggie \"prompt\" → proje dizininde interaktif oturum"
    ["feature_print"]="• auggie --print \"...\" → CI çıktısı (yalnızca son mesaj)"
    ["feature_templates"]="• .augment/commands/*.md → slash komutları için tekrar kullanılabilir şablonlar"
    ["login_auto"]="Bilgileri sizin yerinize girmeye çalışıyoruz; gerekirse komutu manuel çalıştırabilirsiniz."
    ["login_failed"]="'auggie login' komutu başarısız oldu. Gerekirse manuel olarak tekrar çalıştırın."
    ["no_tty"]="TTY erişimi yok; lütfen 'auggie login' komutunu manuel çalıştırın."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["batch_skip"]="Toplu modda kimlik doğrulama atlandı. Kurulum sonrası '%s' komutunu çalıştırmayı unutmayın."
    ["install_done"]="Auggie CLI kurulumu tamamlandı! Detaylı rehber: %s"
)

auggie_text() {
    local key="$1"
    local default_value="${AUGGIE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${AUGGIE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

auggie_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(auggie_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

ensure_auggie_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} $(auggie_text npm_missing)"
    return 1
}

install_auggie_cli() {
    local interactive_mode="true"
    local dry_run="false"
    local package_spec="${AUGGIE_NPM_PACKAGE}"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="true"
                ;;
            --package)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}${ERROR_TAG}${NC} '--package' seçeneği bir değer gerektirir."
                    return 1
                fi
                package_spec="$2"
                shift
                ;;
            *)
                echo -e "${YELLOW}${WARN_TAG}${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(auggie_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        local aug_req_msg aug_install_msg
        auggie_printf aug_req_msg dry_run_requirement "$AUGGIE_MIN_NODE_VERSION"
        auggie_printf aug_install_msg dry_run_install "$package_spec"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${aug_req_msg}"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${aug_install_msg}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(auggie_text dry_run_skip)"
        return 0
    fi

    require_node_version "$AUGGIE_MIN_NODE_VERSION" "Auggie CLI" || return 1
    ensure_auggie_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} $(auggie_text install_start)"
    if ! npm_install_global_with_fallback "$package_spec" "Auggie CLI"; then
        local aug_fail_msg
        auggie_printf aug_fail_msg install_fail "$package_spec"
        echo -e "${RED}${ERROR_TAG}${NC} ${aug_fail_msg}"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX:-}" ]; then
        ensure_path_contains_dir "${NPM_LAST_INSTALL_PREFIX}/bin" "npm user prefix"
    fi
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v auggie >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(auggie_text command_missing)"
        return 1
    fi

    local aug_version_msg
    auggie_printf aug_version_msg version_info "$(auggie --version 2>/dev/null || echo 'unknown version')"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${aug_version_msg}"

    echo -e "${CYAN}${INFO_TAG}${NC} $(auggie_text feature_intro)"
    echo -e "  ${GREEN}$(auggie_text feature_login)${NC}"
    echo -e "  ${GREEN}$(auggie_text feature_prompt)${NC}"
    echo -e "  ${GREEN}$(auggie_text feature_print)${NC}"
    echo -e "  ${GREEN}$(auggie_text feature_templates)${NC}"

    if [ "$interactive_mode" = true ]; then
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            echo -e "\n${YELLOW}${INFO_TAG}${NC} $(auggie_text login_auto)"
            if ! auggie login </dev/tty >/dev/tty 2>&1; then
                echo -e "${YELLOW}${WARN_TAG}${NC} $(auggie_text login_failed)"
            fi
        else
            echo -e "\n${YELLOW}${WARN_TAG}${NC} $(auggie_text no_tty)"
        fi
        read -r -p "$(auggie_text press_enter)" </dev/tty || true
    else
        local batch_msg
        auggie_printf batch_msg batch_skip "${GREEN}auggie login${NC}"
        echo -e "\n${YELLOW}${INFO_TAG}${NC} ${batch_msg}"
    fi

    local done_msg
    auggie_printf done_msg install_done "${AUGGIE_DOC_URL}"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${done_msg}"
}

main() {
    install_auggie_cli "$@"
}

main "$@"
