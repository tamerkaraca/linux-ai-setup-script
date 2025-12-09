#!/bin/bash
set -euo pipefail

: "${AUGGIE_NPM_PACKAGE:=@augmentcode/auggie}"
: "${AUGGIE_MIN_NODE_VERSION:=22}"
: "${AUGGIE_DOC_URL:=https://docs.augmentcode.com/cli/overview}"

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

: "${GREEN:=\033[0;32m}"
: "${NC:=\033[0m}"

# --- Start: Auggie-specific logic ---

declare -A AUGGIE_TEXT_EN=(
    ["install_title"]="Starting Auggie CLI installation..."
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
    ["install_title"]="Auggie CLI kurulumu başlatılıyor..."
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

# --- End: Auggie-specific logic ---

main() {
    local interactive_mode="true"
    local package_spec="${AUGGIE_NPM_PACKAGE}"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

    # Argument parsing is simple, so we keep it here for now.
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --package)
                if [ -z "${2:-}" ]; then
                    log_error_detail "'--package' option requires a value."
                    return 1
                fi
                package_spec="$2"
                shift
                ;;
            *)
                log_warn_detail "Unknown argument: $1"
                ;;
        esac
        shift || true
    done

    log_info_detail "$(auggie_text install_title)"

    require_node_version "$AUGGIE_MIN_NODE_VERSION" "Auggie CLI" || return 1
    
    install_package "Auggie CLI" "npm" "auggie" "$package_spec"
    local install_status=$?

    if [ $install_status -ne 0 ]; then
        log_error_detail "$(auggie_text install_fail \""$package_spec"\")"
        return 1
    fi
    
    if ! command -v auggie &> /dev/null; then
        log_error_detail "$(auggie_text command_missing)"
        return 1
    fi

    log_success_detail "$(auggie_text version_info "$(auggie --version 2>/dev/null || echo 'unknown')")"

    log_info_detail "$(auggie_text feature_intro)"
    log_info_detail "  $(auggie_text feature_login)"
    log_info_detail "  $(auggie_text feature_prompt)"
    log_info_detail "  $(auggie_text feature_print)"
    log_info_detail "  $(auggie_text feature_templates)"

    if [ "$interactive_mode" = true ]; then
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            echo # newline
            log_info_detail "$(auggie_text login_auto)"
            if ! auggie login </dev/tty >/dev/tty 2>&1; then
                log_warn_detail "$(auggie_text login_failed)"
            fi
        else
            log_warn_detail "$(auggie_text no_tty)"
        fi
        read -r -p "$(auggie_text press_enter)" </dev/tty || true
    else
        log_info_detail "$(auggie_text batch_skip \""${GREEN}"auggie login"${NC}"\")"
    fi

    log_success_detail "$(auggie_text install_done \""$AUGGIE_DOC_URL"\")"
}

main "$@"