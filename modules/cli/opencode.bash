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

# --- Start: OpenCode-specific logic ---

declare -A OPCODE_TEXT_EN=(
    ["install_title"]="Starting OpenCode CLI installation..."
    ["npm_missing"]="npm command not found. Please run the Node.js module first."
    ["install_fail"]="OpenCode CLI npm installation failed."
    ["version_info"]="OpenCode CLI version: %s"
    ["shim_warning"]="OpenCode binary could not be generated; please check your npm prefix."
    ["command_missing"]="'opencode' command is missing. Restart your terminal or update PATH."
    ["interactive_intro"]="You need to sign in to OpenCode CLI now."
    ["interactive_command"]="Run 'opencode login' and finish authentication."
    ["interactive_wait"]="Press Enter once login completes."
    ["manual_skip"]="Authentication skipped in 'Install All' mode."
    ["manual_reminder"]="Please run '${GREEN}opencode login${NC}' manually later."
    ["manual_hint"]="Manual login may be required."
    ["install_done"]="OpenCode CLI installation completed!"
    ["auth_prompt"]="Press Enter to continue..."
    ["already_installed"]="OpenCode CLI is already installed:"
    ["installed_success"]="OpenCode CLI installed:"
    ["shim_not_found"]="Binary 'opencode' not found in '%s'. Attempting to create a shim."
    ["shim_created"]="Successfully created a shim for 'opencode' at '%s'."
    ["shim_fail"]="Could not create shim. Main JS entry not found at '%s'."
)

declare -A OPCODE_TEXT_TR=(
    ["install_title"]="OpenCode CLI kurulumu başlatılıyor..."
    ["npm_missing"]="npm komutu bulunamadı. Lütfen önce Node.js modülünü çalıştırın."
    ["install_fail"]="OpenCode CLI npm paketinin kurulumu başarısız oldu."
    ["version_info"]="OpenCode CLI sürümü: %s"
    ["shim_warning"]="OpenCode binary dosyası oluşturulamadı; npm prefixinizi kontrol edin."
    ["command_missing"]="'opencode' komutu bulunamadı. Terminalinizi yeniden başlatın veya PATH ayarlarınızı kontrol edin."
    ["interactive_intro"]="Şimdi OpenCode CLI'ya giriş yapmanız gerekiyor."
    ["interactive_command"]="Lütfen 'opencode login' komutunu çalıştırın."
    ["interactive_wait"]="Oturum açma tamamlandığında Enter'a basın."
    ["manual_skip"]="'Tümünü Kur' modunda kimlik doğrulama atlandı."
    ["manual_reminder"]="Lütfen daha sonra '${GREEN}opencode login${NC}' komutunu manuel olarak çalıştırın."
    ["manual_hint"]="Manuel oturum açma gerekebilir."
    ["install_done"]="OpenCode CLI kurulumu tamamlandı!"
    ["auth_prompt"]="Devam etmek için Enter'a basın..."
    ["already_installed"]="OpenCode CLI zaten kurulu:"
    ["installed_success"]="OpenCode CLI kuruldu:"
    ["shim_not_found"]="'%s' içinde 'opencode' binary dosyası bulunamadı. Shim oluşturmaya çalışılıyor."
    ["shim_created"]="'%s' konumunda 'opencode' için shim başarıyla oluşturuldu."
    ["shim_fail"]="Shim oluşturulamadı. Ana JS giriş dosyası '%s' konumunda bulunamadı."
)

opencode_text() {
    local key="$1"
    local default_value="${OPCODE_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${OPCODE_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

ensure_npm_ready() {
    if ! command -v npm >/dev/null 2>&1; then
        log_error_detail "$(opencode_text npm_missing)"
        return 1
    fi
    return 0
}

# This custom function creates a binary shim if npm fails to do so.
# This is specific to how the opencode-ai package is structured.
ensure_opencode_binary() {
    local prefix="$1"
    local bin_path="${prefix}/bin/opencode"
    if [ -x "$bin_path" ]; then
        return 0
    fi

    log_warn_detail "$(printf "$(opencode_text shim_not_found)" "${prefix}/bin")"
    local pkg_root="${prefix}/lib/node_modules/opencode-ai"
    local js_entry="${pkg_root}/bin/opencode.js"
    if [ -f "$js_entry" ]; then
        cat > "$bin_path" <<EOF
#!/bin/bash
NODE_BIN="\${NODE_BIN:-node}"
exec "\$NODE_BIN" "$js_entry" "\$@"
EOF
        chmod +x "$bin_path"
        ensure_path_contains_dir "${prefix}/bin" "OpenCode CLI shim"
        log_success_detail "$(printf "$(opencode_text shim_created)" "$bin_path")"
        return 0
    fi
    log_error_detail "$(printf "$(opencode_text shim_fail)" "$js_entry")"
    return 1
}

# --- End: OpenCode-specific logic ---

main() {
    local interactive_mode=${1:-true}
    
    log_info_detail "$(opencode_text install_title)"

    require_node_version 20 "OpenCode CLI" || return 1
    ensure_npm_ready || return 1

    if command -v opencode &> /dev/null; then
        log_success_detail "$(opencode_text already_installed) $(opencode --version)"
    else
        if ! install_package "OpenCode CLI" "npm" "opencode" "opencode-ai"; then
            log_error_detail "$(opencode_text install_fail)"
            return 1
        fi
        
        local install_prefix="$(npm config get prefix -g)"
        ensure_opencode_binary "$install_prefix" || log_warn_detail "$(opencode_text shim_warning)"

        reload_shell_configs silent
        hash -r 2>/dev/null || true

        if command -v opencode &> /dev/null; then
            log_success_detail "$(opencode_text installed_success) $(opencode --version)"
        else
            log_error_detail "$(opencode_text command_missing)"
            return 1
        fi
    fi

    # Proceed with OpenCode-specific post-installation steps (login)
    if [ "$interactive_mode" = true ]; then
        echo
        log_info_detail "$(opencode_text interactive_intro)"
        log_info_detail "$(opencode_text interactive_command)"
        log_info_detail "$(opencode_text interactive_wait)"

        opencode login </dev/tty >/dev/tty 2>&1 || log_warn_detail "$(opencode_text manual_hint)"

        log_info_detail "$(opencode_text auth_prompt)"
        read -r -p "" </dev/tty
    else
        echo
        log_info_detail "$(opencode_text manual_skip)"
        log_info_detail "$(opencode_text manual_reminder)"
    fi

    log_success_detail "$(opencode_text install_done)"
}

main "$@"