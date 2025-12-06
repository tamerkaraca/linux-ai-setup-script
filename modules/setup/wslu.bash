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
else
    echo "[ERROR] Unable to load platform_detection.bash (tried $platform_local)" >&2
    exit 1 # Keep this exit 1 as it's crucial for WSL check
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


install_wslu() {
    if ! is_wsl; then
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


