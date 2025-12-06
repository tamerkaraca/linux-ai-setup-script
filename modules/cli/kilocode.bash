#!/bin/bash
set -euo pipefail

: "${KILOCODE_NPM_PACKAGE:=@kilocode/cli}"
: "${KILOCODE_MIN_NODE_VERSION:=18}"
: "${KILOCODE_DOC_URL:=https://kilocode.ai/docs/cli}"

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

: "${GREEN:=$'\033[0;32m'}"
: "${NC:=$'\033[0m'}"

# --- Start: Kilocode-specific logic ---

declare -A KILOCODE_TEXT_EN=(
    ["npm_missing"]="npm command not found. Please run main menu option 3 (Node.js tools) first."
    ["install_title"]="Starting Kilocode CLI installation..."
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
    ["python_compat_warning"]="Python %s detected. Kilocode CLI may fail due to missing distutils module."
    ["python_compat_attempt"]="Attempting installation with fallback options..."
    ["alt_install_no_native"]="Attempting installation without native dependencies..."
    ["alt_install_python312"]="Trying with Python 3.12..."
    ["alt_install_no_optional"]="Trying with npm --no-optional..."
    ["alt_install_failed"]="All installation methods failed"
    ["alt_install_suggest"]="Consider installing Python 3.12 or using a different Node.js version"
    ["alt_install_suggest_cmd"]="Consider installing Python 3.12: sudo apt install python3.12 python3.12-distutils"
)

declare -A KILOCODE_TEXT_TR=(
    ["npm_missing"]="npm komutu bulunamadı. Lütfen ana menüdeki 3. seçenek (Node.js araçları) ile Node.js kurun."
    ["install_title"]="Kilocode CLI kurulumu başlatılıyor..."
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
    ["python_compat_warning"]="Python %s tespit edildi. Kilocode CLI eksik distutils modülü nedeniyle başarısız olabilir."
    ["python_compat_attempt"]="Alternatif kurulum seçenekleri deneniyor..."
    ["alt_install_no_native"]="Native bağımlılıklar olmadan kurulum deneniyor..."
    ["alt_install_python312"]="Python 3.12 ile deneniyor..."
    ["alt_install_no_optional"]="npm --no-optional ile deneniyor..."
    ["alt_install_failed"]="Tüm kurulum yöntemleri başarısız oldu"
    ["alt_install_suggest"]="Python 3.12 kurmayı veya farklı Node.js sürümü kullanmayı düşünün"
    ["alt_install_suggest_cmd"]="Python 3.12 kurmayı düşünün: sudo apt install python3.12 python3.12-distutils"
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

check_python_compatibility() {
    if command -v python3 &> /dev/null; then
        local python_version
        python_version=$(python3 --version 2>/dev/null | sed -E 's/Python ([0-9]+\.[0-9]+).*/\1/')
        if [[ "${python_version}" == "3.13" ]] || [[ "${python_version}" == "3.14" ]]; then
            log_warn_detail "$(kilocode_text python_compat_warning "$python_version")"
            log_info_detail "$(kilocode_text python_compat_attempt)"
            return 1
        fi
    fi
    return 0
}

# --- End: Kilocode-specific logic ---

main() {
    local interactive_mode="true"
    local package_spec="${KILOCODE_NPM_PACKAGE}"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="$1"
        shift
    fi

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

    log_info_detail "$(kilocode_text install_title)"

    require_node_version "$KILOCODE_MIN_NODE_VERSION" "Kilocode CLI" || return 1

    if ! command -v kilocode &>/dev/null; then
        if ! check_python_compatibility; then
            log_info_detail "$(kilocode_text alt_install_no_native)"
            if retry_command "npm install -g --ignore-scripts \"$package_spec\" 2>/dev/null"; then
                log_success_detail "Kilocode CLI installed successfully (without native dependencies)."
            elif command -v python3.12 &>/dev/null; then
                log_info_detail "$(kilocode_text alt_install_python312)"
                if retry_command "PYTHON=/usr/bin/python3.12 npm install -g \"$package_spec\" 2>/dev/null"; then
                    log_success_detail "Kilocode CLI installed successfully (with Python 3.12)."
                else
                    log_info_detail "$(kilocode_text alt_install_no_optional)"
                    if retry_command "npm install -g --no-optional \"$package_spec\" 2>/dev/null"; then
                        log_success_detail "Kilocode CLI installed successfully (without optional dependencies)."
                    else
                        log_error_detail "$(kilocode_text alt_install_failed)"
                        log_info_detail "$(kilocode_text alt_install_suggest)"
                        log_error_detail "$(kilocode_text install_fail \""$package_spec"\")"
                        return 1
                    fi
                fi
            else
                log_info_detail "$(kilocode_text alt_install_no_optional)"
                if retry_command "npm install -g --no-optional \"$package_spec\""; then
                    log_success_detail "Kilocode CLI installed successfully (without optional dependencies)."
                else
                    log_error_detail "$(kilocode_text install_fail \""$package_spec"\")"
                    log_info_detail "$(kilocode_text alt_install_suggest_cmd)"
                    return 1
                fi
            fi
        else
            if ! install_package "Kilocode CLI" "npm" "kilocode" "@kilocode/cli"; then
                 return 1
            fi
        fi
        reload_shell_configs silent
        hash -r 2>/dev/null || true
    fi

    if ! command -v kilocode &> /dev/null; then
        log_error_detail "$(kilocode_text command_missing)"
        return 1
    fi

    log_success_detail "$(kilocode_text version_info "$(kilocode --version 2>/dev/null || echo 'unknown')")"

    log_info_detail "$(kilocode_text feature_intro)"
    log_info_detail "  $(kilocode_text feature_architect)"
    log_info_detail "  $(kilocode_text feature_debug)"
    log_info_detail "  $(kilocode_text feature_auto)"
    log_info_detail "  $(kilocode_text feature_config)"

    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(kilocode_text interactive_prompt)"
        if [ -r /dev/tty ] && [ -w /dev/tty ]; then
            read -r -p "$(kilocode_text launch_question)" launch_config </dev/tty || true
            if [[ "$launch_config" =~ ^[eEyY]$ ]]; then
                kilocode config </dev/tty >/dev/tty 2>&1 || log_warn_detail "$(kilocode_text config_error)"
            else
                log_info_detail "$(kilocode_text config_skip)"
            fi
        else
            log_warn_detail "$(kilocode_text no_tty)"
        fi
        read -r -p "$(kilocode_text press_enter)" </dev/tty || true
    else
        echo
        log_info_detail "$(kilocode_text batch_skip)"
        log_info_detail "$(kilocode_text batch_note "${GREEN}kilocode config${NC}" "${GREEN}kilocode --mode architect${NC}")"
    fi
    
    log_success_detail "$(kilocode_text install_done \""$KILOCODE_DOC_URL"\")"
}

main "$@"