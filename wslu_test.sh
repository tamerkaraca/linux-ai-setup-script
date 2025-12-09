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
    echo "[ERROR] Unable to load utils.bash (tried multiple locations)" >&2
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
    echo "[ERROR] Unable to load platform_detection.bash (tried multiple locations)" >&2
    exit 1
fi

configure_wsl_conf() {
    if ! is_wsl; then
        return
    fi

    log_info_detail "Configuring wsl.conf to optimize WSL/Windows interop..."

    local wsl_conf_content="[boot]\nsystemd=true\n\n[interop]\nappendWindowsPath = false\n"
    local wsl_conf_file="/etc/wsl.conf"

    # Use a temporary file to assemble the new content
    local temp_conf
    temp_conf=$(mktemp)

    # Pre-populate with the desired state
    echo "$wsl_conf_content" > "$temp_conf"

    # Check if the file exists and if changes are actually needed
    if [ -f "$wsl_conf_file" ] && cmp -s "$temp_conf" "$wsl_conf_file"; then
        log_info_detail "wsl.conf is already correctly configured."
        rm "$temp_conf"
        return
    fi

    log_info_detail "Writing new configuration to $wsl_conf_file..."
    # Use sudo to write the final content to the system location
    # Quoting the here-string marker ensures variables inside aren't expanded
    sudo tee "$wsl_conf_file" > /dev/null < "$temp_conf"

    rm "$temp_conf"

    log_success_detail "wsl.conf configured. A WSL restart is required for changes to take effect."
    log_info_detail "You can restart WSL by running 'wsl.exe --shutdown' in PowerShell or CMD."
}


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
        log_info_detail "Not running in WSL, skipping wslu installation."
        return
    fi

    # It's better to configure wsl.conf first
    configure_wsl_conf

    log_info_detail "Running in WSL, proceeding with wslu installation."

    if ! command -v wslview &> /dev/null; then
        log_info_detail "wslu package not found. Installing..."
        if ! sudo -v; then # Check for sudo permissions upfront
             log_warn_detail "Sudo permissions not available. Skipping wslu installation."
             log_info_detail "Note: wslu is optional and provides WSL browser integration."
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
                log_error_detail "No supported package manager found for wslu installation."
                return 1
            fi
        fi
        
        if ! eval "$INSTALL_CMD" wslu; then
            log_warn_detail "Failed to install wslu. This is optional for WSL browser integration."
            log_info_detail "You can install wslu manually later with: sudo apt install wslu"
            return 0  # Don't fail the entire installation for an optional package
        fi
        log_success_detail "wslu installed successfully."
    else
        log_info_detail "wslu is already installed."
    fi
    
    log_info_detail "Configuring BROWSER environment variable for WSL."

    local browser_export='export BROWSER="/usr/bin/wslview"'
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q 'export BROWSER="/usr/bin/wslview"' "$rc_file"; then
                log_info_detail "Adding BROWSER export to $rc_file"
                echo '' >> "$rc_file"
                echo "# Set BROWSER to wslview for WSL integration" >> "$rc_file"
                echo "$browser_export" >> "$rc_file"
            else
                log_info_detail "BROWSER export already exists in $rc_file."
            fi
        fi
    done

    log_success_detail "WSL browser integration configured. Please restart your shell or run 'source ~/.bashrc' (or ~/.zshrc)."
}

install_wslu


