#!/bin/bash
set -euo pipefail

: "${KILOCODE_NPM_PACKAGE:=@kilocode/cli}"
: "${KILOCODE_MIN_NODE_VERSION:=18}"
: "${KILOCODE_DOC_URL:=https://kilocode.ai/docs/cli}"

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

declare -A KILOCODE_TEXT_EN=(
    ["npm_missing"]="npm command not found. Please run main menu option 3 (Node.js tools) first."
    ["install_title"]="Starting Kilocode CLI installation..."
    ["dry_run_requirement"]="Will verify Node.js >= %s."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run mode skips authentication and config steps."
    ["install_start"]="Kilocode CLI npm installation begins..."
    ["install_fail"]="Kilocode CLI installation failed. Package: %s"
    ["command_missing"]="'kilocode' command not found. Check your PATH."
    ["version_info"]="Kilocode CLI version: %s"
    ["feature_intro"]="Kilocode CLI ships multi-agent modes:"
    ["feature_architect"]="• kilocode --mode architect → scope and planning"
    ["feature_debug"]="• kilocode --mode debug → troubleshooting"
    ["feature_auto"]="• kilocode --auto \"Build feature X\" → CI/CD or headless runs"
    ["feature_config"]="• kilocode config → configure providers (OpenRouter, Vercel Gateway, etc.)"
    ["interactive_prompt"]="Run 'kilocode config' to define provider keys."
    ["launch_question"]="Would you like to launch 'kilocode config' now? (y/N): "
    ["config_error"]="'kilocode config' hit an error. Re-run the command manually if needed."
    ["config_skip"]="You can run 'kilocode config' later."
    ["no_tty"]="TTY not available; please run 'kilocode config' manually."
    ["press_enter"]="Press Enter to continue..."
    ["batch_skip"]="Configuration steps were skipped in batch mode."
    ["batch_note"]="After installation, run '%s' and '%s' manually."
    ["install_done"]="Kilocode CLI installation completed! Docs: %s"
)

declare -A KILOCODE_TEXT_TR=(
    ["npm_missing"]="npm komutu bulunamadı. Lütfen ana menüdeki 3. seçenek (Node.js araçları) ile Node.js kurun."
    ["install_title"]="Kilocode CLI kurulumu başlatılıyor..."
    ["dry_run_requirement"]="Node.js >= %s gereksinimi doğrulanacak."
    ["dry_run_install"]="npm install -g %s"
    ["dry_run_skip"]="Dry-run modunda kimlik doğrulama ve konfigürasyon adımları atlanır."
    ["install_start"]="Kilocode CLI npm paketinin kurulumu başlatılıyor..."
    ["install_fail"]="Kilocode CLI kurulumu başarısız oldu. Paket: %s"
    ["command_missing"]="'kilocode' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
    ["version_info"]="Kilocode CLI sürümü: %s"
    ["feature_intro"]="Kilocode CLI aynı anda birden fazla ajan modu içerir:"
    ["feature_architect"]="• kilocode --mode architect → kapsam belirleme ve planlama"
    ["feature_debug"]="• kilocode --mode debug → hata izleme"
    ["feature_auto"]="• kilocode --auto \"Build feature X\" → CI/CD veya başsız kullanım"
    ["feature_config"]="• kilocode config → OpenRouter, Vercel Gateway vb. sağlayıcı anahtarlarını ayarlama"
    ["interactive_prompt"]="Sağlayıcı anahtarlarını tanımlamak için 'kilocode config' komutunu çalıştırın."
    ["launch_question"]="Kilocode yapılandırmasını şimdi başlatmak ister misiniz? (e/H): "
    ["config_error"]="'kilocode config' çalıştırılırken hata oluştu. Gerekirse komutu manuel olarak tekrar edin."
    ["config_skip"]=" 'kilocode config' adımını daha sonra manuel olarak çalıştırabilirsiniz."
    ["no_tty"]="TTY erişimi yok; 'kilocode config' komutunu manuel çalıştırın."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["batch_skip"]="Toplu kurulum modunda konfigürasyon adımları atlandı."
    ["batch_note"]="Kurulum sonrası '%s' ve '%s' komutlarını manuel çalıştırmayı unutmayın."
    ["install_done"]="Kilocode CLI kurulumu tamamlandı! Doküman: %s"
)

kilocode_text() {
    local key="$1"
    local default_value="${KILOCODE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${KILOCODE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

kilocode_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(kilocode_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

ensure_kilocode_npm_available() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    if bootstrap_node_runtime; then
        return 0
    fi
    echo -e "${RED}${ERROR_TAG}${NC} $(kilocode_text npm_missing)"
    return 1
}

install_kilocode_cli() {
    local interactive_mode="true"
    local dry_run="false"
    local package_spec="${KILOCODE_NPM_PACKAGE}"

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
    echo -e "${YELLOW}${INFO_TAG}${NC} $(kilocode_text install_title)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if [ "$dry_run" = true ]; then
        local kilo_req_msg kilo_install_msg
        kilocode_printf kilo_req_msg dry_run_requirement "$KILOCODE_MIN_NODE_VERSION"
        kilocode_printf kilo_install_msg dry_run_install "$package_spec"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${kilo_req_msg}"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${kilo_install_msg}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(kilocode_text dry_run_skip)"
        return 0
    fi

    require_node_version "$KILOCODE_MIN_NODE_VERSION" "Kilocode CLI" || return 1
    ensure_kilocode_npm_available || return 1

    echo -e "${YELLOW}${INFO_TAG}${NC} $(kilocode_text install_start)"
    if ! npm_install_global_with_fallback "$package_spec" "Kilocode CLI"; then
        local kilo_fail_msg
        kilocode_printf kilo_fail_msg install_fail "$package_spec"
        echo -e "${RED}${ERROR_TAG}${NC} ${kilo_fail_msg}"
        return 1
    fi

    if [ -n "${NPM_LAST_INSTALL_PREFIX:-}" ]; then
        ensure_path_contains_dir "${NPM_LAST_INSTALL_PREFIX}/bin" "npm user prefix"
    fi
    reload_shell_configs silent
    hash -r 2>/dev/null || true

    if ! command -v kilocode >/dev/null 2>&1; then
        echo -e "${RED}${ERROR_TAG}${NC} $(kilocode_text command_missing)"
        return 1
    fi

    local kilo_version_msg
    kilocode_printf kilo_version_msg version_info "$(kilocode --version 2>/dev/null || echo 'unknown version')"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${kilo_version_msg}"

    echo -e "\n${CYAN}${INFO_TAG}${NC} $(kilocode_text feature_intro)"
    echo -e "  ${GREEN}$(kilocode_text feature_architect)${NC}"
    echo -e "  ${GREEN}$(kilocode_text feature_debug)${NC}"
    echo -e "  ${GREEN}$(kilocode_text feature_auto)${NC}"
    echo -e "  ${GREEN}$(kilocode_text feature_config)${NC}"

    if [ "$interactive_mode" = true ]; then
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(kilocode_text interactive_prompt)"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            read -r -p "$(kilocode_text launch_question)" launch_config </dev/tty || true
            if [[ "$launch_config" =~ ^[eEyY]$ ]]; then
                kilocode config </dev/tty >/dev/tty 2>&1 || echo -e "${YELLOW}${WARN_TAG}${NC} $(kilocode_text config_error)"
            else
                echo -e "${YELLOW}${INFO_TAG}${NC} $(kilocode_text config_skip)"
            fi
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} $(kilocode_text no_tty)"
        fi
        read -r -p "$(kilocode_text press_enter)" </dev/tty || true
    else
        echo -e "\n${YELLOW}${INFO_TAG}${NC} $(kilocode_text batch_skip)"
        local batch_msg
        kilocode_printf batch_msg batch_note "${GREEN}kilocode config${NC}" "${GREEN}kilocode --mode architect${NC}"
        echo -e "${YELLOW}${NOTE_TAG}${NC} ${batch_msg}"
    fi

    local done_msg
    kilocode_printf done_msg install_done "$KILOCODE_DOC_URL"
    echo -e "${GREEN}${SUCCESS_TAG}${NC} ${done_msg}"
}

main() {
    install_kilocode_cli "$@"
}

main "$@"
