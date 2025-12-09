#!/bin/bash
set -euo pipefail

# Check if we're in a remote environment and load helper if needed
if [ -f "./utils/remote_helper.bash" ]; then
    source "./utils/remote_helper.bash"
elif ! declare -f download_file &> /dev/null; then
    # Fallback source_module for when remote_helper isn't available
    source_module() {
        local local_path="$1"
        local remote_rel_path="$2"
        if [ -f "$local_path" ]; then
            # shellcheck source=/dev/null
            source "$local_path"
        else
            if ! command -v curl &> /dev/null; then
                echo "${ERROR_TAG} curl command not found; cannot load module '$remote_rel_path'."
                exit 1
            fi
            local remote_url="${SCRIPT_BASE_URL:-https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main}/${remote_rel_path}"
            # shellcheck disable=SC1090
            source <(curl -fsSL "$remote_url") || {
                echo "${ERROR_TAG} Failed to load module from $remote_url"
                exit 1
            }
        fi
    }
fi

# Load utils if not already loaded
if ! declare -f log_info &> /dev/null; then
    # Try different possible paths for utils.bash
    if [ -f "./utils/utils.bash" ]; then
        source "./utils/utils.bash"
    elif [ -f "./modules/utils/utils.bash" ]; then
        source "./modules/utils/utils.bash"
    elif [ -f "../utils/utils.bash" ]; then
        source "../utils/utils.bash"
    else
        source_module "./modules/utils/utils.bash" "modules/utils/utils.bash"
    fi
fi

detect_platform() {
    local platform=""
    local os_type=""
    local pkg_manager=""
    
    # Detect OS type
    case "$(uname -s)" in
        Darwin*)
            os_type="macos"
            platform="macos"
            ;;
        Linux*)
            os_type="linux"
            # Check if WSL
            if grep -q Microsoft /proc/version 2>/dev/null || grep -q WSL /proc/version 2>/dev/null; then
                platform="wsl"
            else
                platform="linux"
            fi
            ;;
        *)
            echo -e "${RED}${ERROR_TAG}${NC} Unsupported operating system: $(uname -s)" >&2
            return 1
            ;;
    esac
    
    # Detect package manager for Linux
    if [ "$os_type" = "linux" ]; then
        if command -v apt &> /dev/null; then
            pkg_manager="apt"
        elif command -v dnf &> /dev/null; then
            pkg_manager="dnf"
        elif command -v yum &> /dev/null; then
            pkg_manager="yum"
        elif command -v pacman &> /dev/null; then
            pkg_manager="pacman"
        else
            echo -e "${RED}${ERROR_TAG}${NC} No supported package manager found" >&2
            return 1
        fi
    fi
    
    # Export platform variables
    export PLATFORM="$platform"
    export OS_TYPE="$os_type"
    export PKG_MANAGER="$pkg_manager"
    
    # Set platform-specific commands
    if [ "$os_type" = "macos" ]; then
        export UPDATE_CMD="brew update"
        export INSTALL_CMD="brew install"
    elif [ "$pkg_manager" = "apt" ]; then
        export UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
        export INSTALL_CMD="sudo apt install -y"
    elif [ "$pkg_manager" = "dnf" ]; then
        export UPDATE_CMD="sudo dnf update -y"
        export INSTALL_CMD="sudo dnf install -y"
    elif [ "$pkg_manager" = "yum" ]; then
        export UPDATE_CMD="sudo yum update -y"
        export INSTALL_CMD="sudo yum install -y"
    elif [ "$pkg_manager" = "pacman" ]; then
        export UPDATE_CMD="sudo pacman -Syu --noconfirm"
        export INSTALL_CMD="sudo pacman -S --noconfirm"
    fi
    
    log_info "Platform detected: $platform ($os_type)"
    if [ -n "$pkg_manager" ]; then
        log_info "Package manager: $pkg_manager"
    fi
    
    return 0
}

is_macos() {
    if [ -z "${PLATFORM:-}" ]; then
        detect_platform
    fi
    [ "${PLATFORM:-}" = "macos" ]
}

is_linux() {
    if [ -z "${PLATFORM:-}" ]; then
        detect_platform
    fi
    [ "${PLATFORM:-}" = "linux" ]
}

is_wsl() {
    if [ -z "${PLATFORM:-}" ]; then
        detect_platform
    fi
    [ "${PLATFORM:-}" = "wsl" ]
}

check_homebrew() {
    if is_macos; then
        if command -v brew &> /dev/null; then
            log_info "Homebrew is installed: $(brew --version | head -n1)"
            return 0
        else
            log_info "Homebrew is not installed"
            return 1
        fi
    fi
    return 1
}

# Export functions for use in other modules
export -f detect_platform
export -f is_macos
export -f is_linux
export -f is_wsl
export -f check_homebrew