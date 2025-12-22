#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in so sources work regardless of CWD
current_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$current_script_dir/../utils/utils.bash"
platform_local="$current_script_dir/../utils/platform_detection.bash"

# When running remotely, we might be in a different directory structure
# Check multiple possible locations for utils
utils_loaded=false
platform_loaded=false

# Load remote helper if available
if [ -f "./utils/remote_helper.bash" ]; then
    source "./utils/remote_helper.bash"
fi

# Try to load utils from various possible locations
for utils_path in "$utils_local" "$current_script_dir/../../utils/utils.bash" "$current_script_dir/utils/utils.bash" "./utils/utils.bash" "/tmp/utils.bash"; do
    if [ -f "$utils_path" ]; then
        # shellcheck source=/dev/null
        source "$utils_path"
        utils_loaded=true
        break
    fi
done

# If still not loaded, try source_module
if [ "$utils_loaded" = false ] && declare -f source_module > /dev/null 2>&1; then
    if source_module "utils/utils.bash" "modules/utils/utils.bash"; then
        utils_loaded=true
    fi
fi

if [ "$utils_loaded" = false ]; then
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried multiple locations)"
    exit 1
fi

# Try to load platform_detection from various possible locations
for platform_path in "$platform_local" "$current_script_dir/../../utils/platform_detection.bash" "$current_script_dir/utils/platform_detection.bash" "./utils/platform_detection.bash" "/tmp/platform_detection.bash"; do
    if [ -f "$platform_path" ]; then
        # shellcheck source=/dev/null
        source "$platform_path"
        platform_loaded=true
        break
    fi
done

# If still not loaded, try source_module
if [ "$platform_loaded" = false ] && declare -f source_module > /dev/null 2>&1; then
    if source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"; then
        platform_loaded=true
    fi
fi

# Platform detection is crucial for WSL check
if [ "$platform_loaded" = false ]; then
    echo "[HATA/ERROR] platform_detection.bash yüklenemedi / Unable to load platform_detection.bash (tried multiple locations)"
    exit 1
fi

# --- i18n Support ---
declare -A WSLU_TEXT_EN=(
    ["not_wsl"]="Not running in WSL, skipping wslu installation."
    ["running_wsl"]="Running in WSL, proceeding with wslu installation."
    ["wslu_not_found"]="wslu package not found. Installing..."
    ["sudo_not_available"]="Sudo permissions not available. Skipping wslu installation."
    ["wslu_optional"]="Note: wslu is optional and provides WSL browser integration."
    ["wslu_install_failed"]="Failed to install wslu. This is optional for WSL browser integration."
    ["wslu_manual_hint"]="You can install wslu manually later with: sudo apt install wslu"
    ["wslu_installed"]="wslu installed successfully."
    ["wslu_already"]="wslu is already installed."
    ["config_browser"]="Configuring BROWSER environment variable for WSL."
    ["adding_browser"]="Adding BROWSER export to %s"
    ["browser_exists"]="BROWSER export already exists in %s."
    ["browser_done"]="WSL browser integration configured. Please restart your shell or run 'source ~/.bashrc' (or ~/.zshrc)."
    ["no_pkg_manager"]="No supported package manager found for wslu installation."
)

declare -A WSLU_TEXT_TR=(
    ["not_wsl"]="WSL'de çalışmıyor, wslu kurulumu atlanıyor."
    ["running_wsl"]="WSL'de çalışıyor, wslu kurulumuna devam ediliyor."
    ["wslu_not_found"]="wslu paketi bulunamadı. Kuruluyor..."
    ["sudo_not_available"]="Sudo izinleri mevcut değil. wslu kurulumu atlanıyor."
    ["wslu_optional"]="Not: wslu isteğe bağlıdır ve WSL tarayıcı entegrasyonu sağlar."
    ["wslu_install_failed"]="wslu kurulamadı. Bu WSL tarayıcı entegrasyonu için isteğe bağlıdır."
    ["wslu_manual_hint"]="wslu'yu daha sonra manuel olarak kurabilirsiniz: sudo apt install wslu"
    ["wslu_installed"]="wslu başarıyla kuruldu."
    ["wslu_already"]="wslu zaten kurulu."
    ["config_browser"]="WSL için BROWSER ortam değişkeni yapılandırılıyor."
    ["adding_browser"]="BROWSER export %s dosyasına ekleniyor"
    ["browser_exists"]="BROWSER export zaten %s dosyasında mevcut."
    ["browser_done"]="WSL tarayıcı entegrasyonu yapılandırıldı. Lütfen kabuğunuzu yeniden başlatın veya 'source ~/.bashrc' (veya ~/.zshrc) çalıştırın."
    ["no_pkg_manager"]="wslu kurulumu için desteklenen paket yöneticisi bulunamadı."
)

get_text() {
    local key="$1"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${WSLU_TEXT_TR[$key]:-${WSLU_TEXT_EN[$key]:-$key}}"
    else
        printf "%s" "${WSLU_TEXT_EN[$key]:-$key}"
    fi
}

get_text_fmt() {
    local key="$1"
    shift
    local fmt
    fmt=$(get_text "$key")
    # shellcheck disable=SC2059
    printf "$fmt" "$@"
}
# --- End i18n Support ---


# Fallback WSL detection if platform detection fails
is_wsl_fallback() {
    if command -v is_wsl &> /dev/null && is_wsl; then
        return 0
    elif grep -q Microsoft /proc/version 2>/dev/null || grep -q WSL /proc/version 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

install_wslu() {
    if ! is_wsl_fallback; then
        log_info_detail "$(get_text not_wsl)"
        return
    fi

    log_info_detail "$(get_text running_wsl)"

    if ! command -v wslview &> /dev/null; then
        log_info_detail "$(get_text wslu_not_found)"
        if ! sudo -v; then # Check for sudo permissions upfront
             log_warn_detail "$(get_text sudo_not_available)"
             log_info_detail "$(get_text wslu_optional)"
             return 0
        fi
        
        # Ensure INSTALL_CMD is available
        if [ -z "${INSTALL_CMD:-}" ]; then
            # Fallback to common package managers
            if command -v apt &> /dev/null; then
                INSTALL_CMD="sudo apt install -y"
            elif command -v dnf &> /dev/null; then
                INSTALL_CMD="sudo dnf install -y"
            elif command -v yum &> /dev/null; then
                INSTALL_CMD="sudo yum install -y"
            else
                log_error_detail "$(get_text no_pkg_manager)"
                return 1
            fi
        fi
        
        if ! eval "$INSTALL_CMD" wslu; then
            log_warn_detail "$(get_text wslu_install_failed)"
            log_info_detail "$(get_text wslu_manual_hint)"
            return 0  # Don't fail the entire installation for an optional package
        fi
        log_success_detail "$(get_text wslu_installed)"
    else
        log_info_detail "$(get_text wslu_already)"
    fi
    
    log_info_detail "$(get_text config_browser)"

    local browser_export='export BROWSER="/usr/bin/wslview"'
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q 'export BROWSER="/usr/bin/wslview"' "$rc_file"; then
                log_info_detail "$(get_text_fmt adding_browser "$rc_file")"
                echo '' >> "$rc_file"
                echo "# Set BROWSER to wslview for WSL integration" >> "$rc_file"
                echo "$browser_export" >> "$rc_file"
            else
                log_info_detail "$(get_text_fmt browser_exists "$rc_file")"
            fi
        fi
    done

    log_success_detail "$(get_text browser_done)"
}

install_wslu
