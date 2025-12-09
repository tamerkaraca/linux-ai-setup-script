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
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

# Bu modül, Claude Code CLI'ı kurar ve etkileşimli oturum açma için TTY erişimini doğrular.
# utils.sh'deki evrensel 'install_package' fonksiyonunu ve ardından
# bu scripte özel TTY/login mantığını kullanır.

# --- Start: Claude-specific post-install logic ---

declare -A CLAUDE_TEXT_EN=(
    ["require_login_prompt"]="You need to sign in to Claude Code now."
    ["run_claude_login"]="Please run 'claude login' and finish authentication."
    ["press_enter"]="Press Enter to continue..."
    ["skip_auth_all"]="Authentication skipped in 'Install All' mode."
    ["manual_login"]="Please run '${GREEN}claude login${NC}' manually later."
    ["tty_missing"]="No TTY detected; cannot run 'claude login' in-script."
    ["login_hint"]="Tip: run 'claude login' directly in your terminal."
    ["login_error"]="'claude login' failed. Ink-based UIs may require raw terminal mode."
    ["install_done"]="Claude Code installation and configuration finished!"
)

declare -A CLAUDE_TEXT_TR=(
    ["require_login_prompt"]="Şimdi Claude Code'a giriş yapmanız gerekiyor."
    ["run_claude_login"]="Lütfen 'claude login' komutunu çalıştırın ve oturumu tamamlayın."
    ["press_enter"]="Devam etmek için Enter'a basın..."
    ["skip_auth_all"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_login"]="Lütfen daha sonra '${GREEN}claude login${NC}' komutunu manuel olarak çalıştırın."
    ["tty_missing"]="TTY bulunamadı; 'claude login' script içinde çalıştırılamıyor."
    ["login_hint"]="İpucu: Terminalinizde doğrudan 'claude login' komutunu çalıştırın."
    ["login_error"]="'claude login' sırasında hata oluştu. Ink arayüzleri ham terminal moduna ihtiyaç duyabilir."
    ["install_done"]="Claude Code kurulumu ve yapılandırması tamamlandı!"
)

claude_text() {
    local key="$1"
    local default_value="${CLAUDE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        echo "${CLAUDE_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

supporting_tty() {
    [[ -t 0 || -t 1 || -t 2 ]] || { [ -e /dev/tty ] && [ -r /dev/tty ] && [ -w /dev/tty ]; }
}

run_claude_login() {
    if ! supporting_tty; then
        log_warn_detail "$(claude_text tty_missing)"
        log_info_detail "$(claude_text manual_login)"
        return 0
    fi

    if ! claude login </dev/tty >/dev/tty 2>&1; then
        log_error_detail "$(claude_text login_error)"
        log_info_detail "$(claude_text login_hint)"
        return 1
    fi
}

# --- End: Claude-specific post-install logic ---

main() {
    local interactive_mode=${1:-true}

    # Use the universal installer from utils.sh
    # It handles checking for existence, prerequisites (like npm), and installation.
    require_node_version 20 "Claude Code CLI" || return 1
    install_package "Claude Code CLI" "npm" "claude" "@anthropic-ai/claude-code"
    local install_status=$?

    # If installation failed, exit
    if [ $install_status -ne 0 ]; then
        log_error_detail "Claude Code CLI installation failed. Aborting post-install steps."
        return 1
    fi
    
    # If the command is still not found after successful install (e.g. PATH issue), exit.
    if ! command -v claude &> /dev/null; then
        log_error_detail "Claude command not found after installation. Aborting post-install steps."
        return 1
    fi

    # Proceed with Claude-specific post-installation steps (login)
    if [ "$interactive_mode" = true ]; then
        echo # Add a newline for readability
        log_info_detail "$(claude_text require_login_prompt)"
        log_info_detail "$(claude_text run_claude_login)"
        log_info_detail "$(claude_text press_enter)"
        
        run_claude_login || true

        log_info_detail "$(claude_text press_enter)"
        read -r -p "" </dev/tty
    else
        echo # Add a newline for readability
        log_info_detail "$(claude_text skip_auth_all)"
        log_info_detail "$(claude_text manual_login)"
    fi
    
    log_success_detail "$(claude_text install_done)"
}

main "$@"