#!/bin/bash
set -euo pipefail

# Resolve the directory this script lives in
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/../utils/utils.bash"
source "$script_dir/../utils/platform_detection.bash"

create_windows_app_symlinks() {
    if ! is_wsl; then
        log_info_detail "Not running in WSL, skipping Windows application symlink creation."
        return
    fi

    if ! command -v sudo &> /dev/null || ! sudo -v; then
       log_error_detail "Sudo permissions are required to create symlinks in /usr/local/bin."
       log_error_detail "Please run the script with sudo or enter your password when prompted."
       exit 1
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
        log_warning_detail "Could not automatically determine Windows username."
        log_warning_detail "Using 'USER' as a placeholder. You may need to edit the paths below."
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
            log_warning_detail "Executable for '$app_name' not found at expected path: $win_path"
            log_warning_detail "Please verify the path and re-run the script if needed."
        fi
    done

    log_success "Windows application symlinking process complete."
}

create_windows_app_symlinks
