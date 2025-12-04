#!/bin/bash
set -euo pipefail

# Load utils if not already loaded
if ! declare -f log_info &> /dev/null; then
    # Find the utils.sh script, checking a few possible locations
    UTIL_SCRIPT=""
    if [ -f "./modules/utils.sh" ]; then
        UTIL_SCRIPT="./modules/utils.sh"
    elif [ -f "$(dirname "$0")/utils.sh" ]; then
        UTIL_SCRIPT="$(dirname "$0")/utils.sh"
    fi

    if [ -n "$UTIL_SCRIPT" ]; then
        # shellcheck source=/dev/null
        source "$UTIL_SCRIPT"
    else
        echo "[ERROR] utils.sh not found. Cannot proceed." >&2
        exit 1
    fi
fi

# Load platform detection if not already loaded
if ! declare -f is_wsl &> /dev/null; then
    # Find the platform_detection.sh script
    PLATFORM_SCRIPT=""
    if [ -f "./modules/platform_detection.sh" ]; then
        PLATFORM_SCRIPT="./modules/platform_detection.sh"
    elif [ -f "$(dirname "$0")/platform_detection.sh" ]; then
        PLATFORM_SCRIPT="$(dirname "$0")/platform_detection.sh"
    fi

    if [ -n "$PLATFORM_SCRIPT" ]; then
        # shellcheck source=/dev/null
        source "$PLATFORM_SCRIPT"
        detect_platform
    else
        echo "[ERROR] platform_detection.sh not found. Cannot proceed." >&2
        exit 1
    fi
fi


install_wslu() {
    if ! is_wsl; then
        log_info "Not running in WSL, skipping wslu installation."
        return
    fi

    log_info "Running in WSL, proceeding with wslu installation."

    if ! command -v wslview &> /dev/null; then
        log_info "wslu package not found. Installing..."
        if ! eval "$INSTALL_CMD" wslu; then
            log_error "Failed to install wslu. Please install it manually."
            return 1
        fi
        log_success "wslu installed successfully."
    else
        log_info "wslu is already installed."
    fi

    log_info "Configuring BROWSER environment variable for WSL."

    local browser_export='export BROWSER="/usr/bin/wslview"'
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q 'export BROWSER="/usr/bin/wslview"' "$rc_file"; then
                log_info "Adding BROWSER export to $rc_file"
                echo '' >> "$rc_file"
                echo "# Set BROWSER to wslview for WSL integration" >> "$rc_file"
                echo "$browser_export" >> "$rc_file"
            else
                log_info "BROWSER export already exists in $rc_file."
            fi
        fi
    done

    log_success "WSL browser integration configured. Please restart your shell or run 'source ~/.bashrc' (or ~/.zshrc)."
}

install_wslu
