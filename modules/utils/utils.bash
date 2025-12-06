#!/bin/bash

# Resolve the directory this script lives in so sources work regardless of CWD
script_dir="$(dirname "${BASH_SOURCE[0]}")"
banner_local="$script_dir/banner.bash"

# Prefer local direct source (relative to this file).
if [ -f "$banner_local" ]; then
    # shellcheck source=/dev/null
    source "$banner_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/banner.bash" "modules/utils/banner.bash"
else
    # We can't print a fancy error because the banner functions are what we're trying to source.
    echo "[ERROR] CRITICAL: Unable to load banner.bash (tried $banner_local)" >&2
fi

# Renkli çıktı için tanımlamalar
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m' # No Color
export RED GREEN YELLOW BLUE CYAN NC

# Global text definitions for internationalization





# Log functions
log_info() {
    echo -e "${CYAN}${INFO_TAG}${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}${WARN_TAG}${NC} $1"
}

log_error() {
    echo -e "${RED}${ERROR_TAG}${NC} $1"
}

log_success() {
    echo -e "${GREEN}${SUCCESS_TAG}${NC} $1"
}

export -f log_info log_warning log_error log_success

# Dil ve yerelleştirme ayarları
SUPPORTED_LANGUAGES=(en tr)

nounset_is_enabled() {
    if set -o | grep -Eq '^nounset[[:space:]]+on$'; then
        return 0
    fi
    return 1
}

source_shell_config() {
    local file="$1"
    [ -f "$file" ] || return 1
    local nounset_restore=0
    if nounset_is_enabled; then
        nounset_restore=1
        set +u
    fi
    # shellcheck source=/dev/null
    . "$file"
    if [ $nounset_restore -eq 1 ]; then
        set -u
    fi
    return 0
}

detect_system_language() {
    local locale_value="${LC_ALL:-${LANG:-}}"
    if [[ "$locale_value" =~ ^tr ]]; then
        echo "tr"
    else
        echo "en"
    fi
}

refresh_language_tags() {
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        INFO_TAG="[BİLGİ]"
        WARN_TAG="[UYARI]"
        ERROR_TAG="[HATA]"
        SUCCESS_TAG="[BAŞARILI]"
        NOTE_TAG="[NOT]"
    else
        INFO_TAG="[INFO]"
        WARN_TAG="[WARNING]"
        ERROR_TAG="[ERROR]"
        SUCCESS_TAG="[SUCCESS]"
        NOTE_TAG="[NOTE]"
    fi
    export INFO_TAG WARN_TAG ERROR_TAG SUCCESS_TAG NOTE_TAG
}

set_language() {
    local target_lang="$1"
    for lang in "${SUPPORTED_LANGUAGES[@]}"; do
        if [ "$lang" = "$target_lang" ]; then
            LANGUAGE="$lang"
            export LANGUAGE
            refresh_language_tags
            return 0
        fi
    done
    return 1
}

if [ -z "${LANGUAGE:-}" ]; then
    LANGUAGE="$(detect_system_language)"
fi
export LANGUAGE
refresh_language_tags

get_language_label() {
    case "$1" in
        tr) echo "Türkçe" ;;
        *) echo "English" ;;
    esac
}

# Detailed Logging System
_log_detailed() {
    local level="$1"
    local message="$2"
    local timestamp
    # timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    declare -A color_map
    color_map["INFO"]="$CYAN"
    color_map["WARN"]="$YELLOW"
    color_map["ERROR"]="$RED"
    color_map["SUCCESS"]="$GREEN"

    declare -A tag_map
    tag_map["INFO"]="$INFO_TAG"
    tag_map["WARN"]="$WARN_TAG"
    tag_map["ERROR"]="$ERROR_TAG"
    tag_map["SUCCESS"]="$SUCCESS_TAG"

    local color="${color_map[$level]:-$RED}"
    local tag="${tag_map[$level]:-$ERROR_TAG}"

    # local caller_info
    # if caller_info=$(caller 1); then
    #     local line_num
    #     line_num=$(echo "$caller_info" | awk '{print $1}')
    #     local script_name
    #     script_name=$(basename "$(echo "$caller_info" | awk '{print $3}')" 2>/dev/null || echo "unknown")
    #     message="[${script_name}:${line_num}] ${message}"
    # fi

    echo -e "${color}${tag}${NC} ${message}"
}

log_info_detail() { _log_detailed "INFO" "$*"; }
log_warn_detail() { _log_detailed "WARN" "$*"; }
log_error_detail() { _log_detailed "ERROR" "$*"; }
log_success_detail() { _log_detailed "SUCCESS" "$*"; }

export -f log_info_detail log_warn_detail log_error_detail log_success_detail

# Shell and Path management
reload_shell_configs() {
    local mode="${1:-verbose}"
    local candidates=()
    local shell_name
    shell_name=$(basename "${SHELL:-}")

    case "$shell_name" in
        zsh) candidates=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile") ;;
        bash) candidates=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc") ;;
        *) candidates=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile") ;;
    esac

    local sourced_file=""
    for rc_file in "${candidates[@]}"; do
        if source_shell_config "$rc_file"; then
            # sourced_file="$rc_file"
            break
        fi
    done

    if [ "$mode" = "silent" ]; then
        return
    fi
}

ensure_path_contains_dir() {
    local target_dir="$1"
    local reason="${2:-custom path entry}"
    local updated_files=()

    if [[ -z "${target_dir}" ]]; then
        return 0
    fi

    if [[ ":$PATH:" != *":${target_dir}:"* ]]; then
        export PATH="${target_dir}:$PATH"
    fi

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ] && ! grep -Fq "$target_dir" "$rc_file"; then
            {
                echo ""
                echo "# Added by linux-ai-setup-script (${reason})"
                echo "export PATH=\"${target_dir}:\$PATH\""
            } >> "$rc_file"
            updated_files+=("$rc_file")
        fi
    done

    if [ ${#updated_files[@]} -gt 0 ]; then
        log_info_detail "'${target_dir}' added to PATH for future sessions (${updated_files[*]})."
    fi

    hash -r 2>/dev/null || true
}

# Package Management
detect_package_manager() {
    log_info_detail "Detecting operating system and package manager..."
    
    if command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        UPDATE_CMD="sudo dnf upgrade -y"
        INSTALL_CMD="sudo dnf install -y"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        UPDATE_CMD="sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"
        INSTALL_CMD="sudo DEBIAN_FRONTEND=noninteractive apt install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        UPDATE_CMD="sudo yum update -y"
        INSTALL_CMD="sudo yum install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        # UPDATE_CMD="sudo pacman -Syu --noconfirm"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    else
        log_error_detail "No supported package manager was found!"
        exit 1
    fi
    
    log_success_detail "Package manager: $PKG_MANAGER"
}

update_system() {
    log_info_detail "Updating system packages..."
    if [ -n "${UPDATE_CMD:-}" ]; then
        eval "$UPDATE_CMD"
    else
        log_warn_detail "Update command not defined. Skipping system update."
    fi
}
export -f update_system

# Python Tooling
install_python() {
    log_info_detail "Starting Python installation..."
    
    if command -v python3 &> /dev/null; then
        log_success_detail "Python already installed: $(python3 --version)"
        return 0
    fi
    
    log_info_detail "Installing Python 3..."
    eval "$INSTALL_CMD" python3 python3-pip python3-venv
    
    if command -v python3 &> /dev/null; then
        log_success_detail "Python installation completed: $(python3 --version)"
    else
        log_error_detail "Python installation failed!"
        return 1
    fi
}

install_pip() {
    log_info_detail "Starting Pip installation/update..."
    
    if ! command -v python3 &> /dev/null; then
        log_warn_detail "Python is missing, installing it first..."
        if ! install_python; then
            log_error_detail "Python installation failed!"
            return 1
        fi
    fi
    
    log_info_detail "Upgrading pip..."
    
    local pip_upgrade_cmd="python3 -m pip install --upgrade pip"
    
    if ! python3 -m pip --version &> /dev/null; then
        log_warn_detail "Pip not found. Trying to install it..."
        if ! (curl -sS https://bootstrap.pypa.io/get-pip.py | python3); then
            log_error_detail "Pip installation via get-pip.py failed!"
            return 1
        fi
        log_success_detail "Pip installed via get-pip.py."
    fi

    if ! output=$($pip_upgrade_cmd 2>&1); then
        if echo "$output" | grep -q "externally-managed-environment"; then
            log_info_detail "Externally-managed-environment detected, retrying with --break-system-packages..."
            if ! $pip_upgrade_cmd --break-system-packages; then
                log_error_detail "Pip upgrade failed even with --break-system-packages."
                return 1
            fi
        else
            log_error_detail "Pip upgrade failed. Output: $output"
            return 1
        fi
    fi
    
    log_success_detail "Pip version: $(python3 -m pip --version)"
}

install_pipx() {
    log_info_detail "Starting Pipx installation..."
    
    if ! command -v python3 &> /dev/null; then
        log_warn_detail "Python is missing, installing it first..."
        install_python
    fi
    
    if command -v pipx &> /dev/null; then
        log_success_detail "pipx is already installed: $(pipx --version)"
        return 0
    fi
    
    log_info_detail "Installing pipx..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        eval "$INSTALL_CMD" pipx
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        eval "$INSTALL_CMD" pipx
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        eval "$INSTALL_CMD" python-pipx
    else
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
    fi
    
    ensure_path_contains_dir "$HOME/.local/bin" "pipx"
    reload_shell_configs silent
    
    if command -v pipx &> /dev/null; then
        log_success_detail "Pipx installation completed: $(pipx --version 2>/dev/null || echo 'installed')"
    else
        log_error_detail "Pipx installation failed!"
        return 1
    fi
}

install_uv() {
    log_info_detail "Starting UV installation..."

    if command -v uv &>/dev/null; then
        log_success_detail "UV is already installed: $(uv --version)"
        return 0
    fi
    
    log_info_detail "Installing UV via official script..."
    if ! (curl -LsSf https://astral.sh/uv/install.sh | sh); then
        log_error_detail "UV installation failed!"
        return 1
    fi
    
    ensure_path_contains_dir "$HOME/.cargo/bin" "uv"
    reload_shell_configs silent

    if command -v uv &>/dev/null; then
        log_success_detail "UV installation completed: $(uv --version)"
    else
        log_error_detail "UV installation failed!"
        return 1
    fi
}

export -f install_python install_pip install_pipx install_uv

require_node_version() {
    local min_version="$1"
    local tool_name="$2"

    if ! command -v node >/dev/null 2>&1; then
        log_error_detail "Node.js is required for $tool_name but not found."
        log_info_detail "Please install Node.js (v$min_version+) using the main menu."
        return 1
    fi

    local current_version
    current_version=$(node -v | cut -d'v' -f2)
    local current_major
    current_major=$(echo "$current_version" | cut -d'.' -f1)

    if [ "$current_major" -lt "$min_version" ]; then
        log_error_detail "$tool_name requires Node.js v$min_version or higher (current: v$current_version)."
        log_info_detail "Please update Node.js using the main menu."
        return 1
    fi
    return 0
}
export -f require_node_version

install_package() {
    local name="$1"
    local manager="$2"
    local cmd="$3"
    shift 3
    local packages=("$@")

    log_info_detail "Installing $name..."

    if command -v "$cmd" &> /dev/null; then
        log_success_detail "$name is already installed."
        return 0
    fi

    local installed=false
    for package in "${packages[@]}"; do
        log_info_detail "Attempting to install '$package'..."
        case "$manager" in
            npm)
                require_node_version 18 "$name" || return 1
                if npm install -g "$package"; then
                    installed=true
                    break
                fi
                ;;
            pip)
                install_pip || return 1
                if python3 -m pip install "$package"; then
                    installed=true
                    break
                fi
                ;;
            cargo)
                install_uv || return 1
                if uv tool install "$package"; then
                    installed=true
                    break
                fi
                ;;
            pipx)
                install_pipx || return 1
                if pipx install "$package"; then
                    installed=true
                    break
                fi
                ;;
            *)
                log_error_detail "Unsupported package manager: $manager"
                return 1
                ;;
        esac
    done

    if [ "$installed" = false ]; then
        log_error_detail "Failed to install $name after trying all candidates."
        return 1
    fi

    if command -v "$cmd" &> /dev/null; then
        log_success_detail "$name installed successfully."
        return 0
    else
        log_error_detail "$name installed but command '$cmd' not found."
        return 1
    fi
}
export -f install_package

# Enhanced retry command with WSL-specific fixes
retry_command() {
    local -i n=1
    local -i max_attempts=5
    local delay=1
    local cmd="$@"

    # Check if this is a curl command and add WSL-specific options
    if [[ "$cmd" == *"curl"* ]]; then
        # Add --connect-timeout and --max-time for better timeout handling
        if [[ "$cmd" != *"--connect-timeout"* ]]; then
            cmd="${cmd//curl /curl --connect-timeout 10 --max-time 60 }"
        fi
        # Add --retry for curl's built-in retry mechanism
        if [[ "$cmd" != *"--retry"* ]]; then
            cmd="${cmd//curl /curl --retry 3 --retry-delay 1 }"
        fi
    fi

    while true; do
        # Pre-flight checks for WSL environments
        if [[ "$cmd" == *"curl"* ]] && grep -qi microsoft /proc/version 2>/dev/null; then
            # Check available disk space before attempting download
            local target_dir
            target_dir=$(echo "$cmd" | grep -oE '\-o [^[:space:]]+' | cut -d' ' -f2 | xargs dirname 2>/dev/null || echo "/tmp")
            if [ ! -d "$target_dir" ]; then
                target_dir="/tmp"
            fi

            local available_space
            available_space=$(df "$target_dir" | awk 'NR==2 {print $4}')
            if [ "$available_space" -lt 1024 ]; then  # Less than 1MB
                log_error_detail "Insufficient disk space in $target_dir"
                return 1
            fi

            # Test network connectivity
            if ! ping -c 1 raw.githubusercontent.com >/dev/null 2>&1; then
                log_warn_detail "Network connectivity issue detected"
            fi
        fi

        if eval "$cmd"; then
            return 0
        else
            if (( n < max_attempts )); then
                log_warn_detail "Command failed. Attempt $n/$max_attempts. Retrying in $delay seconds..."
                sleep "$delay"
                ((n++))
                delay=$((delay * 2))

                # For WSL, add extra delay and cleanup between retries
                if grep -qi microsoft /proc/version 2>/dev/null; then
                    sleep 2
                    # Clear any partial downloads
                    if [[ "$cmd" == *"-o "* ]]; then
                        local target_file
                        target_file=$(echo "$cmd" | grep -oE '\-o [^[:space:]]+' | cut -d' ' -f2)
                        [ -f "$target_file" ] && rm -f "$target_file"
                    fi
                fi
            else
                log_error_detail "The command has failed after $n attempts: $cmd"
                return 1
            fi
        fi
    done
}

# Fallback download function using wget when curl fails
download_with_fallback() {
    local url="$1"
    local output="$2"
    local max_attempts=3

    for ((i=1; i<=max_attempts; i++)); do
        # Try curl first
        if curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 --retry-delay 1 \
           --user-agent "linux-ai-setup-script" "$url" -o "$output" 2>/dev/null; then
            return 0
        fi

        # Fallback to wget if available
        if command -v wget &> /dev/null; then
            if wget --timeout=10 --tries=2 --user-agent="linux-ai-setup-script" \
                    -qO "$output" "$url" 2>/dev/null; then
                return 0
            fi
        fi

        if [ $i -lt $max_attempts ]; then
            log_warn_detail "Download attempt $i/$max_attempts failed, retrying..."
            sleep 2
        fi
    done

    log_error_detail "Failed to download after $max_attempts attempts: $url"
    return 1
}
export -f retry_command
export -f download_with_fallback

clean_windows_paths_from_rc() {
    log_info_detail "Cleaning Windows paths from shell configs..."

    # Clean current PATH for this session
    local original_path="$PATH"
    local new_path=""
    new_path=$(echo "$original_path" | tr ':' '\n' | grep -v '^/mnt/' | tr '\n' ':' | sed 's/:$//')
    export PATH="$new_path"

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            # Backup the original file
            cp "$rc_file" "${rc_file}.bak"
            
            # Remove lines that export a PATH containing /mnt/
            sed -i '/export PATH=.*\/mnt\//d' "$rc_file"
            
            log_success_detail "Cleaned Windows paths from $rc_file."
        fi
    done
}
export -f clean_windows_paths_from_rc

# Other functions follow...
# ...
