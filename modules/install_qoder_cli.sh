#!/bin/bash
set -euo pipefail

: "${NPM_LAST_INSTALL_PREFIX:=}"
: "${QODER_NPM_PACKAGE:=}"
: "${QODER_CLI_BUNDLE:=}"
: "${QODER_SKIP_NPM_PROBE:=false}"

QODER_PACKAGE_OVERRIDE="${QODER_NPM_PACKAGE}"
QODER_BUNDLE_OVERRIDE="${QODER_CLI_BUNDLE}"
QODER_SKIP_PACKAGE_PROBE="${QODER_SKIP_NPM_PROBE}"

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

# Renk değişkenleri yoksa tanımla (uzaktan çalıştırmalarda set -u güvenli)
: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"
: "${QODER_DOC_URL:=https://docs.qoder.com/cli/quick-start}"

declare -A QODER_TEXT_EN=(
    ["npm_missing"]="npm command not found. Please install Node.js (Main Menu → 3)."
    ["npm_version_read_error"]="Unable to read npm version."
    ["npm_version_low"]="Current npm version (%s) is below the minimum requirement (%s)."
    ["npm_dry_run_upgrade"]="npm install -g npm@latest (user prefix)"
    ["npm_upgrading"]="Updating npm..."
    ["npm_upgrade_success"]="npm upgraded: %s"
    ["npm_upgrade_fail"]="npm upgrade failed."
    ["install_intro"]="%s installation started (docs: ${QODER_DOC_URL})"
    ["already_installed"]="%s is already installed: %s"
    ["dry_run_install"]="npm install -g %s"
    ["npm_installing"]="Installing %s via npm..."
    ["install_success"]="%s installation completed."
    ["install_fail"]="%s installation failed."
    ["dry_run_skipped"]="Installation skipped (dry-run)."
    ["command_ready"]="%s installed successfully: %s"
    ["command_missing"]="%s installed but '%s' command not found. Check your PATH or restart the terminal."
    ["reload_hint"]="Please restart your terminal or run:"
    ["source_hint"]="  source ~/.bashrc (or ~/.zshrc)"
    ["hash_hint"]="  hash -r"
    ["pkg_override"]="Qoder CLI package override: %s"
    ["pkg_dry_run_default"]="Default npm package: %s"
    ["pkg_skip_warn"]="npm registry probe skipped. Using default package: %s"
    ["pkg_skip_info"]="Override package via QODER_NPM_PACKAGE or '--package <name>'."
    ["pkg_found"]="Discovered npm package: %s"
    ["pkg_not_found"]="No verified Qoder CLI package found. Using default: %s"
    ["pkg_docs_hint"]="Latest instructions: ${QODER_DOC_URL}"
    ["bundle_dry_run"]="Local Qoder CLI bundle will be used: %s"
    ["bundle_missing"]="Bundle file not found: %s"
    ["bundle_using"]="Using local Qoder CLI bundle: %s"
    ["arg_package_required"]="The '--package' option requires a value."
    ["arg_bundle_required"]="The '--bundle' option requires a file path."
    ["arg_unknown"]="Unknown argument: %s"
    ["invalid_tool"]="Invalid --tool value: %s. Use 'qoder', 'coder', or 'both'."
    ["summary_done"]="%s CLI installation steps completed."
    ["summary_reload"]="For the changes to take effect, restart the terminal or run:"
)

declare -A QODER_TEXT_TR=(
    ["npm_missing"]="npm bulunamadı. Lütfen Node.js'yi kurun (Ana Menü → 3)."
    ["npm_version_read_error"]="npm sürümü okunamadı."
    ["npm_version_low"]="Mevcut npm sürümü (%s) minimum gereksinim (%s) altında."
    ["npm_dry_run_upgrade"]="npm install -g npm@latest (kullanıcı prefix)"
    ["npm_upgrading"]="npm güncelleniyor..."
    ["npm_upgrade_success"]="npm sürümü güncellendi: %s"
    ["npm_upgrade_fail"]="npm güncellemesi başarısız oldu."
    ["install_intro"]="%s kurulumu başlatılıyor (doküman: ${QODER_DOC_URL})"
    ["already_installed"]="%s zaten kurulu: %s"
    ["dry_run_install"]="npm install -g %s"
    ["npm_installing"]="%s npm ile kuruluyor..."
    ["install_success"]="%s kurulumu tamamlandı."
    ["install_fail"]="%s kurulumu başarısız oldu."
    ["dry_run_skipped"]="Kurulum atlandı (dry-run)."
    ["command_ready"]="%s başarıyla kuruldu: %s"
    ["command_missing"]="%s kuruldu ancak '%s' komutu bulunamadı. PATH ayarlarını kontrol edin."
    ["reload_hint"]="Terminalinizi yeniden başlatın veya aşağıdaki komutları çalıştırın:"
    ["source_hint"]="  source ~/.bashrc (veya ~/.zshrc)"
    ["hash_hint"]="  hash -r"
    ["pkg_override"]="Qoder CLI paketi override edildi: %s"
    ["pkg_dry_run_default"]="Varsayılan npm paketi: %s"
    ["pkg_skip_warn"]="npm kayıt kontrolü atlandı. Varsayılan paket kullanılacak: %s"
    ["pkg_skip_info"]="Paket belirtmek için QODER_NPM_PACKAGE veya '--package <ad>' kullanın."
    ["pkg_found"]="npm paketi bulundu: %s"
    ["pkg_not_found"]="npm kaydında doğrulanmış bir Qoder CLI paketi bulunamadı. Varsayılan paket: %s"
    ["pkg_docs_hint"]="Güncel talimatlar: ${QODER_DOC_URL}"
    ["bundle_dry_run"]="Yerel Qoder CLI paketi kullanılacak: %s"
    ["bundle_missing"]="'--bundle' ile belirtilen dosya bulunamadı: %s"
    ["bundle_using"]="Yerel Qoder CLI paketi kullanılıyor: %s"
    ["arg_package_required"]="'--package' seçeneği bir değer gerektirir."
    ["arg_bundle_required"]="'--bundle' seçeneği bir dosya yolu gerektirir."
    ["arg_unknown"]="Bilinmeyen argüman: %s"
    ["invalid_tool"]="Geçersiz --tool değeri: %s. 'qoder', 'coder' veya 'both' kullanın."
    ["summary_done"]="%s CLI kurulum adımları tamamlandı."
    ["summary_reload"]="Kurulumun tam etkili olması için terminalinizi yeniden başlatın veya aşağıdaki komutları çalıştırın:"
)

qoder_text() {
    local key="$1"
    local default_value="${QODER_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${QODER_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

qoder_printf() {
    local __out="$1"
    local __key="$2"
    shift 2
    local __fmt
    __fmt="$(qoder_text "$__key")"
    # shellcheck disable=SC2059
    printf -v "$__out" "$__fmt" "$@"
}

MIN_NPM_VERSION="${MIN_NPM_VERSION:-9.0.0}"

# Basit semver karşılaştırması (a >= b)
semver_ge() {
    local version_a="$1"
    local version_b="$2"
    if [ "$version_a" = "$version_b" ]; then
        return 0
    fi
    if [ "$(printf '%s\n%s\n' "$version_a" "$version_b" | sort -V | head -n1)" = "$version_b" ]; then
        return 0
    fi
    return 1
}

ensure_npm_available() {
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}${ERROR_TAG}${NC} $(qoder_text npm_missing)"
        return 1
    fi
}

ensure_modern_npm() {
    local dry_run="${1:-false}"
    local current_version
    current_version=$(npm -v 2>/dev/null | tr -d '[:space:]')
    if [ -z "$current_version" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} $(qoder_text npm_version_read_error)"
        return 1
    fi

    if semver_ge "$current_version" "$MIN_NPM_VERSION"; then
        return 0
    fi

    local qoder_npm_low
    qoder_printf qoder_npm_low npm_version_low "$current_version" "$MIN_NPM_VERSION"
    echo -e "${YELLOW}${WARN_TAG}${NC} ${qoder_npm_low}"
    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $(qoder_text npm_dry_run_upgrade)"
        return 0
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} $(qoder_text npm_upgrading)"
    if npm_install_global_with_fallback "npm@latest" "npm" true; then
        local qoder_npm_updated
        qoder_printf qoder_npm_updated npm_upgrade_success "$(npm -v 2>/dev/null)"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} ${qoder_npm_updated}"
        return 0
    fi

    echo -e "${RED}${ERROR_TAG}${NC} $(qoder_text npm_upgrade_fail)"
    return 1
}

install_npm_cli() {
    local display_name="$1"
    local npm_package="$2"
    local binary_name="$3"
    local dry_run="${4:-false}"

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    local qoder_install_msg
    qoder_printf qoder_install_msg install_intro "$display_name"
    echo -e "${YELLOW}${INFO_TAG}${NC} ${qoder_install_msg}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v "$binary_name" &> /dev/null; then
        local qoder_already_msg
        qoder_printf qoder_already_msg already_installed "$display_name" "$("$binary_name" --version 2>/dev/null)"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} ${qoder_already_msg}"
        return 0
    fi

    ensure_npm_available || return 1
    ensure_modern_npm "$dry_run" || return 1

    if [ "$dry_run" = true ]; then
        local qoder_dry_run
        qoder_printf qoder_dry_run dry_run_install "$npm_package"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${qoder_dry_run}"
    else
        local qoder_installing
        qoder_printf qoder_installing npm_installing "$display_name"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${qoder_installing}"
        if npm_install_global_with_fallback "$npm_package" "$display_name"; then
            local qoder_success
            qoder_printf qoder_success install_success "$display_name"
            echo -e "${GREEN}${SUCCESS_TAG}${NC} ${qoder_success}"
            reload_shell_configs silent
        else
            local qoder_fail
            qoder_printf qoder_fail install_fail "$display_name"
            echo -e "${RED}${ERROR_TAG}${NC} ${qoder_fail}"
            return 1
        fi
    fi

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} $(qoder_text dry_run_skipped)"
        return 0
    fi

    if command -v "$binary_name" &> /dev/null; then
        local qoder_ready
        qoder_printf qoder_ready command_ready "$display_name" "$("$binary_name" --version 2>/dev/null)"
        echo -e "${GREEN}${SUCCESS_TAG}${NC} ${qoder_ready}"
    else
        local qoder_cmd_missing
        qoder_printf qoder_cmd_missing command_missing "$display_name" "$binary_name"
        echo -e "${RED}${ERROR_TAG}${NC} ${qoder_cmd_missing}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(qoder_text reload_hint)"
        echo -e "${CYAN}$(qoder_text source_hint)${NC}"
        echo -e "${CYAN}$(qoder_text hash_hint)${NC}"
        return 1
    fi
}

resolve_qoder_package() {
    local -n resolved_ref=$1
    local dry_run="${2:-false}"
    local explicit_package="${3:-}"
    local skip_probe="${4:-false}"
    local -a candidates=(
        "@qoder-ai/qodercli"
        "@qoderhq/qoder"
        "@qoderhq/cli"
        "@qoder/cli"
        "qoder-cli"
        "qoder"
    )

    if [ -n "$explicit_package" ]; then
        resolved_ref="$explicit_package"
        local qoder_override
        qoder_printf qoder_override pkg_override "$explicit_package"
        echo -e "${YELLOW}${INFO_TAG}${NC} ${qoder_override}"
        return 0
    fi

    if [ "$dry_run" = true ]; then
        resolved_ref="${candidates[0]}"
        local qoder_default
        qoder_printf qoder_default pkg_dry_run_default "$resolved_ref"
        echo -e "${YELLOW}[DRY-RUN]${NC} ${qoder_default}"
        return 0
    fi

    if [ "$skip_probe" = "true" ]; then
        resolved_ref="${candidates[0]}"
        local qoder_skip_warn
        qoder_printf qoder_skip_warn pkg_skip_warn "$resolved_ref"
        echo -e "${YELLOW}${WARN_TAG}${NC} ${qoder_skip_warn}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(qoder_text pkg_skip_info)"
        return 0
    fi

    local candidate
    for candidate in "${candidates[@]}"; do
        if npm view "$candidate" version >/dev/null 2>&1; then
            resolved_ref="$candidate"
            local qoder_pkg_found
            qoder_printf qoder_pkg_found pkg_found "$candidate"
            echo -e "${YELLOW}${INFO_TAG}${NC} ${qoder_pkg_found}"
            return 0
        fi
    done

    resolved_ref="${candidates[0]}"
    local qoder_pkg_missing
    qoder_printf qoder_pkg_missing pkg_not_found "$resolved_ref"
    echo -e "${YELLOW}${WARN_TAG}${NC} ${qoder_pkg_missing}"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(qoder_text pkg_skip_info)"
    echo -e "${YELLOW}${INFO_TAG}${NC} $(qoder_text pkg_docs_hint)"
    return 0
}

install_qoder_cli() {
    local dry_run="${1:-false}"
    if [ "$dry_run" != true ]; then
        ensure_npm_available || return 1
    fi
    local install_source=""
    if [ -n "$QODER_BUNDLE_OVERRIDE" ]; then
        if [ "$dry_run" = true ]; then
            local qoder_bundle_dry
            qoder_printf qoder_bundle_dry bundle_dry_run "$QODER_BUNDLE_OVERRIDE"
            echo -e "${YELLOW}[DRY-RUN]${NC} ${qoder_bundle_dry}"
        else
            if [ ! -e "$QODER_BUNDLE_OVERRIDE" ]; then
                local qoder_bundle_missing
                qoder_printf qoder_bundle_missing bundle_missing "$QODER_BUNDLE_OVERRIDE"
                echo -e "${RED}${ERROR_TAG}${NC} ${qoder_bundle_missing}"
                return 1
            fi
            local qoder_bundle_using
            qoder_printf qoder_bundle_using bundle_using "$QODER_BUNDLE_OVERRIDE"
            echo -e "${YELLOW}${INFO_TAG}${NC} ${qoder_bundle_using}"
        fi
        install_source="$QODER_BUNDLE_OVERRIDE"
    else
        local resolved_package=""
        if ! resolve_qoder_package resolved_package "$dry_run" "$QODER_PACKAGE_OVERRIDE" "$QODER_SKIP_PACKAGE_PROBE"; then
            return 1
        fi
        install_source="$resolved_package"
    fi
    install_npm_cli "Qoder CLI" "$install_source" "qodercli" "$dry_run"
}

install_coder_cli() {
    local dry_run="${1:-false}"
    install_npm_cli "Coder CLI" "@qoder/coder" "coder" "$dry_run"
}

main() {
    local interactive_mode="true"
    local target_cli="qoder"
    local dry_run="false"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="${1}"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tool)
                target_cli="${2:-qoder}"
                shift
                ;;
            --package)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}${ERROR_TAG}${NC} $(qoder_text arg_package_required)"
                    return 1
                fi
                QODER_PACKAGE_OVERRIDE="$2"
                shift
                ;;
            --bundle|--from-file)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}${ERROR_TAG}${NC} $(qoder_text arg_bundle_required)"
                    return 1
                fi
                QODER_BUNDLE_OVERRIDE="$2"
                shift
                ;;
            --skip-probe)
                QODER_SKIP_PACKAGE_PROBE="true"
                ;;
            --both|--all)
                target_cli="both"
                ;;
            --dry-run)
                dry_run="true"
                ;;
            *)
                local qoder_arg_unknown
                qoder_printf qoder_arg_unknown arg_unknown "$1"
                echo -e "${YELLOW}${WARN_TAG}${NC} ${qoder_arg_unknown}"
                ;;
        esac
        shift || true
    done

    case "$target_cli" in
        qoder)
            install_qoder_cli "$dry_run"
            ;;
        coder)
            install_coder_cli "$dry_run"
            ;;
        both)
            install_qoder_cli "$dry_run"
            install_coder_cli "$dry_run"
            ;;
        *)
            local qoder_invalid_tool
            qoder_printf qoder_invalid_tool invalid_tool "$target_cli"
            echo -e "${RED}${ERROR_TAG}${NC} ${qoder_invalid_tool}"
            return 1
            ;;
    esac

    if [ "$interactive_mode" != "false" ]; then
        local qoder_summary
        qoder_printf qoder_summary summary_done "$target_cli"
        echo -e "\n${YELLOW}${INFO_TAG}${NC} ${qoder_summary}"
        echo -e "${YELLOW}${INFO_TAG}${NC} $(qoder_text summary_reload)"
        echo -e "${CYAN}$(qoder_text source_hint)${NC}"
        echo -e "${CYAN}$(qoder_text hash_hint)${NC}"
    fi
}

main "$@"
