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

# --- i18n Support ---
declare -A WINAPP_TEXT_EN=(
    ["not_wsl"]="Not running in WSL, skipping Windows application symlink creation."
    ["sudo_not_found"]="sudo command not found. Skipping Windows application symlink creation."
    ["sudo_no_pass"]="Sudo permissions not available without password. Skipping Windows application symlink creation."
    ["run_later"]="You can run this module manually later with sudo if needed."
    ["creating_symlinks"]="Creating symlinks for Windows applications for easy access from WSL..."
    ["symlink_hint"]="This allows you to launch them by name (e.g., 'code .')"
    ["username_fail"]="Could not automatically determine Windows username."
    ["using_placeholder"]="Using 'USER' as a placeholder. You may need to edit the paths below."
    ["creating_dir"]="Creating directory %s"
    ["creating_symlink"]="Creating symlink for '%s'..."
    ["symlink_created"]="Symlink for '%s' created at %s."
    ["symlink_failed"]="Failed to create symlink for '%s' (sudo required)."
    ["symlink_manual"]="You can create it manually: sudo ln -s '%s' '%s'"
    ["symlink_exists"]="Symlink for '%s' already exists."
    ["exe_not_found"]="Executable for '%s' not found at expected path: %s"
    ["verify_path"]="Please verify the path and re-run the script if needed."
    ["symlink_complete"]="Windows application symlinking process complete."
)

declare -A WINAPP_TEXT_TR=(
    ["not_wsl"]="WSL'de çalışmıyor, Windows uygulama symlink oluşturma atlanıyor."
    ["sudo_not_found"]="sudo komutu bulunamadı. Windows uygulama symlink oluşturma atlanıyor."
    ["sudo_no_pass"]="Sudo izinleri parola olmadan kullanılamıyor. Windows uygulama symlink oluşturma atlanıyor."
    ["run_later"]="Gerekirse bu modülü daha sonra sudo ile manuel olarak çalıştırabilirsiniz."
    ["creating_symlinks"]="WSL'den kolay erişim için Windows uygulamalarına symlink'ler oluşturuluyor..."
    ["symlink_hint"]="Bu, uygulamaları isimleriyle başlatmanızı sağlar (örn: 'code .')"
    ["username_fail"]="Windows kullanıcı adı otomatik olarak belirlenemedi."
    ["using_placeholder"]="Yer tutucu olarak 'USER' kullanılıyor. Aşağıdaki yolları düzenlemeniz gerekebilir."
    ["creating_dir"]="%s dizini oluşturuluyor"
    ["creating_symlink"]="'%s' için symlink oluşturuluyor..."
    ["symlink_created"]="'%s' için symlink %s konumunda oluşturuldu."
    ["symlink_failed"]="'%s' için symlink oluşturulamadı (sudo gerekli)."
    ["symlink_manual"]="Manuel olarak oluşturabilirsiniz: sudo ln -s '%s' '%s'"
    ["symlink_exists"]="'%s' için symlink zaten mevcut."
    ["exe_not_found"]="'%s' için çalıştırılabilir dosya beklenen konumda bulunamadı: %s"
    ["verify_path"]="Lütfen yolu doğrulayın ve gerekirse scripti tekrar çalıştırın."
    ["symlink_complete"]="Windows uygulama symlink işlemi tamamlandı."
)

get_text() {
    local key="$1"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${WINAPP_TEXT_TR[$key]:-${WINAPP_TEXT_EN[$key]:-$key}}"
    else
        printf "%s" "${WINAPP_TEXT_EN[$key]:-$key}"
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

create_windows_app_symlinks() {
    if ! is_wsl_fallback; then
        log_info_detail "$(get_text not_wsl)"
        return
    fi

    if ! command -v sudo &> /dev/null; then
       log_warn_detail "$(get_text sudo_not_found)"
       return 0
    fi
    
    if ! sudo -n true 2>/dev/null; then
       log_warn_detail "$(get_text sudo_no_pass)"
       log_info_detail "$(get_text run_later)"
       return 0
    fi

    log_info "$(get_text creating_symlinks)"
    log_info "$(get_text symlink_hint)"
    
    # -- IMPORTANT --
    # PLEASE VERIFY AND EDIT THE PATHS IN THIS SECTION TO MATCH YOUR WINDOWS INSTALLATION
    # The paths are standard defaults, but they might differ on your system.
    # The key is the WSL path (`/mnt/c/...`), not the Windows path (`C:\...`).
    
    # Get the Windows username. This is a common source of path variation.
    # We attempt to get it automatically, but it can be wrong.
    local windows_user
    windows_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    if [ -z "$windows_user" ]; then
        log_warn_detail "$(get_text username_fail)"
        log_warn_detail "$(get_text using_placeholder)"
        windows_user="USER"
    fi
    
    declare -A app_paths=(
        ["code"]="/mnt/c/Users/${windows_user}/AppData/Local/Programs/Microsoft VS Code/bin/code"
        ["cursor"]="/mnt/c/Users/${windows_user}/AppData/Local/Programs/Cursor/cursor.exe"
        ["idea"]="/mnt/c/Program Files/JetBrains/IntelliJ IDEA Community Edition/bin/idea64.exe"
        # Add other apps here following the same pattern
        # ["trae"]="/path/to/trae.exe"
        # ["windsurf"]="/path/to/windsurf.exe"
        # ["kiro"]="/path/to/kiro.exe"
    )

    local symlink_dir="/usr/local/bin"
    
    # Ensure the symlink directory exists
    if [ ! -d "$symlink_dir" ]; then
        log_info_detail "$(get_text_fmt creating_dir "$symlink_dir")"
        sudo mkdir -p "$symlink_dir"
    fi

    for app_name in "${!app_paths[@]}"; do
        local win_path="${app_paths[$app_name]}"
        local symlink_path="$symlink_dir/$app_name"

        if [ -f "$win_path" ]; then
            if [ ! -L "$symlink_path" ]; then
                log_info_detail "$(get_text_fmt creating_symlink "$app_name")"
                if sudo ln -s "$win_path" "$symlink_path" 2>/dev/null; then
                    log_success_detail "$(get_text_fmt symlink_created "$app_name" "$symlink_path")"
                else
                    log_warn_detail "$(get_text_fmt symlink_failed "$app_name")"
                    log_info_detail "$(get_text_fmt symlink_manual "$win_path" "$symlink_path")"
                fi
            else
                log_info_detail "$(get_text_fmt symlink_exists "$app_name")"
            fi
        else
            log_warn_detail "$(get_text_fmt exe_not_found "$app_name" "$win_path")"
            log_warn_detail "$(get_text verify_path)"
        fi
    done

    log_success "$(get_text symlink_complete)"
}

# Run the function and always exit successfully
create_windows_app_symlinks || true
