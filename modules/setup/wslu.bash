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


install_wslu() {
    if ! is_wsl; then
        log_info_detail "Not running in WSL, skipping wslu installation."
        return
    fi

    log_info_detail "Running in WSL, proceeding with wslu installation."

    if ! command -v wslview &> /dev/null; then
        log_info_detail "wslu package not found. Installing..."
        if ! eval "$INSTALL_CMD" wslu; then
            log_error_detail "Failed to install wslu. Please install it manually."
            return 1
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
