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
    log_error "Unable to load utils.bash (tried multiple locations)"
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

create_windows_app_symlinks() {
    if ! is_wsl_fallback; then
        log_info_detail "Not running in WSL, skipping Windows application symlink creation."
        return
    fi

    if ! command -v sudo &> /dev/null; then
       log_warn_detail "sudo command not found. Skipping Windows application symlink creation."
       return 0
    fi
    
    if ! sudo -n true 2>/dev/null; then
       log_warn_detail "Sudo permissions not available without password. Skipping Windows application symlink creation."
       log_info_detail "You can run this module manually later with sudo if needed."
       return 0
    fi

    log_info "Creating symlinks for Windows applications for easy access from WSL..."
    log_info "This allows you to launch them by name (e.g., 'code .')"
    
    # -- IMPORTANT --
    # PLEASE VERIFY AND EDIT THE PATHS IN THIS SECTION TO MATCH YOUR WINDOWS INSTALLATION
    # The paths are standard defaults, but they might differ on your system.
    # The key is the WSL path (`/mnt/c/...`), not the Windows path (`C:\...`).
    
    # Get the Windows username. This is a common source of path variation.
    # We attempt to get it automatically, but it can be wrong.
    local windows_user
    windows_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    if [ -z "$windows_user" ]; then
        log_warn_detail "Could not automatically determine Windows username."
        log_warn_detail "Using 'USER' as a placeholder. You may need to edit the paths below."
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
        log_info_detail "Creating directory $symlink_dir"
        sudo mkdir -p "$symlink_dir"
    fi

    for app_name in "${!app_paths[@]}"; do
        local win_path="${app_paths[$app_name]}"
        local symlink_path="$symlink_dir/$app_name"

        if [ -f "$win_path" ]; then
            if [ ! -L "$symlink_path" ]; then
                log_info_detail "Creating symlink for '$app_name'..."
                sudo ln -s "$win_path" "$symlink_path"
                log_success_detail "Symlink for '$app_name' created at $symlink_path."
            else
                log_info_detail "Symlink for '$app_name' already exists."
            fi
        else
            log_warn_detail "Executable for '$app_name' not found at expected path: $win_path"
            log_warn_detail "Please verify the path and re-run the script if needed."
        fi
    done

    log_success "Windows application symlinking process complete."
}

create_windows_app_symlinks
