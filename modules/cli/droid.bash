#!/bin/bash
set -euo pipefail

DOC_URL="https://docs.factory.ai/cli/getting-started/quickstart"
INSTALL_SCRIPT_URL="https://app.factory.ai/cli"

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

CURRENT_LANG="${LANGUAGE:-en}"
if [ "$CURRENT_LANG" != "tr" ]; then
    : # Placeholders if needed later
fi

declare -A DROID_TEXT_EN=(
    [title]="Starting Droid CLI installation..."
    [already_installed]="Droid CLI is already installed"
    [curl_note]="Downloading and running the official Factory installer:"
    [install_failed]="Droid CLI installation failed. Please retry or follow the manual steps:"
    [success]="Droid CLI installation completed"
    [tips_header]="Quick usage tips:"
    [tip_launch]="• Launch the interactive UI: droid"
    [tip_exec]="• Headless/CI mode: droid exec \"<command>\""
    [tip_docs]="• Docs: https://docs.factory.ai/cli/getting-started/quickstart"
    [path_warn]="Droid CLI executable not found on PATH. Please reopen your terminal or follow the official docs."
    [xdg_check]="Checking for xdg-utils (required on Linux)..."
    [xdg_install]="Installing xdg-utils automatically..."
    [xdg_manual]="xdg-utils is missing. Please install it manually (e.g., sudo apt-get install xdg-utils) and rerun this option."
    [xdg_note]="Linux users: Ensure xdg-utils is installed for proper functionality. Install with: sudo apt-get install xdg-utils"
)

declare -A DROID_TEXT_TR=(
    [title]="Droid CLI kurulumu başlatılıyor..."
    [already_installed]="Droid CLI zaten kurulu"
    [curl_note]="Resmi Factory kurulum betiği indiriliyor ve çalıştırılıyor:"
    [install_failed]="Droid CLI kurulumu başarısız oldu. Lütfen tekrar deneyin veya dokümanı izleyin:"
    [success]="Droid CLI kurulumu tamamlandı"
    [tips_header]="Hızlı kullanım ipuçları:"
    [tip_launch]="• Etkileşimli arayüz: droid"
    [tip_exec]="• Headless/CI modu: droid exec \"<komut>\""
    [tip_docs]="• Doküman: https://docs.factory.ai/cli/getting-started/quickstart"
    [path_warn]="Droid CLI komutu PATH içinde bulunamadı. Terminalinizi kapatıp açın veya resmi dokümandaki adımları izleyin."
    [xdg_check]="Linux ortamında xdg-utils paketi kontrol ediliyor..."
    [xdg_install]="xdg-utils paketi otomatik kuruluyor..."
    [xdg_manual]="xdg-utils bulunamadı. Lütfen manuel olarak kurun (örn: sudo apt-get install xdg-utils) ve menüyü tekrar çalıştırın."
    [xdg_note]="Linux kullanıcıları için: Droid'in doğru çalışması adına xdg-utils paketini kurun. Örnek komut: sudo apt-get install xdg-utils"
)

droid_text() {
    local key="$1"
    local default_value="${DROID_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        echo "${DROID_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

droid_ensure_xdg_utils() {
    if command -v xdg-open >/dev/null 2>&1; then
        return 0
    fi

    log_info_detail "$(droid_text xdg_check)"

    case "${PKG_MANAGER:-}" in
        apt|dnf|yum|pacman)
            log_info_detail "$(droid_text xdg_install)"
            if ! eval "$INSTALL_CMD xdg-utils"; then
                log_warn_detail "$(droid_text xdg_manual)"
                return 1
            fi
            ;;
        *)
            log_warn_detail "$(droid_text xdg_manual)"
            return 1
            ;;
    esac

    return 0
}

install_droid_cli() {
    log_info_detail "$(droid_text title)"
    log_info_detail "$(droid_text xdg_note)"

    if command -v droid >/dev/null 2>&1; then
        log_success_detail "$(droid_text already_installed): $(droid --version 2>/dev/null || echo \"unknown version\")"
        return 0
    fi

    droid_ensure_xdg_utils || true

    log_info_detail "$(droid_text curl_note)"
    log_info_detail "  curl -fsSL ${INSTALL_SCRIPT_URL} | sh"

    if ! curl -fsSL "$INSTALL_SCRIPT_URL" | sh; then
        log_error_detail "$(droid_text install_failed) ${DOC_URL}"
        return 1
    fi

    local candidate_dirs=("$HOME/.local/bin" "$HOME/.factory/bin")
    for dir in "${candidate_dirs[@]}"; do
        if [ -d "$dir" ]; then
            ensure_path_contains_dir "$dir" "Droid CLI"
        fi
    done
    export PATH="$HOME/.local/bin:$HOME/.factory/bin:$PATH"
    hash -r 2>/dev/null || true

    if ! command -v droid >/dev/null 2>&1; then
        log_warn_detail "$(droid_text path_warn)"
        return 1
    fi

    log_success_detail "$(droid_text success): $(droid --version 2>/dev/null || echo \"unknown version\")"
    log_info_detail "$(droid_text tips_header)"
    log_info_detail "  $(droid_text tip_launch)"
    log_info_detail "  $(droid_text tip_exec)"
    log_info_detail "  $(droid_text tip_docs)"
}

main() {
    install_droid_cli
}

main
