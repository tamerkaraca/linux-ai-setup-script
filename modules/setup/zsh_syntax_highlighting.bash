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
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

declare -A ZSH_SYNTAX_HIGHLIGHTING_TEXT_EN=(
    ["install_title"]="Starting Zsh Syntax Highlighting installation..."
    ["zsh_missing"]="Zsh is not installed. Please install Zsh first."
    ["already_installed"]="Zsh Syntax Highlighting is already installed."
    ["install_fail"]="Zsh Syntax Highlighting installation failed."
    ["install_success"]="Zsh Syntax Highlighting installed successfully!"
    ["config_info"]="Plugin configured in ~/.zshrc"
    ["reload_info"]="Run 'source ~/.zshrc' or restart terminal to apply changes"
    ["install_done"]="Zsh Syntax Highlighting installation completed!"
)

declare -A ZSH_SYNTAX_HIGHLIGHTING_TEXT_TR=(
    ["install_title"]="Zsh Sözdizimi Vurgulama kurulumu başlatılıyor..."
    ["zsh_missing"]="Zsh kurulu değil. Lütfen önce Zsh kurun."
    ["already_installed"]="Zsh Sözdizimi Vurgulama zaten kurulu."
    ["install_fail"]="Zsh Sözdizimi Vurgulama kurulumu başarısız oldu."
    ["install_success"]="Zsh Sözdizimi Vurgulama başarıyla kuruldu!"
    ["config_info"]="Eklenti ~/.zshrc dosyasında yapılandırıldı"
    ["reload_info"]="Değişiklikleri uygulamak için 'source ~/.zshrc' çalıştırın veya terminali yeniden başlatın"
    ["install_done"]="Zsh Sözdizimi Vurgulama kurulumu tamamlandı!"
)

zsh_syntax_highlighting_text() {
    local key="$1"
    local default_value="${ZSH_SYNTAX_HIGHLIGHTING_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${ZSH_SYNTAX_HIGHLIGHTING_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_zsh_syntax_highlighting() {
    log_info_detail "$(zsh_syntax_highlighting_text install_title)"
    
    # Check if zsh is installed
    if ! command -v zsh >/dev/null 2>&1; then
        log_error_detail "$(zsh_syntax_highlighting_text zsh_missing)"
        return 1
    fi

    # Check if already installed
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [ -d "$plugin_dir" ]; then
        log_success_detail "$(zsh_syntax_highlighting_text already_installed)"
        log_info_detail "$(zsh_syntax_highlighting_text config_info)"
        log_info_detail "$(zsh_syntax_highlighting_text reload_info)"
        return 0
    fi

    # Create custom plugins directory if it doesn't exist
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    mkdir -p "$custom_dir"

    # Clone the repository
    log_info_detail "Cloning Zsh Syntax Highlighting repository..."
    if ! git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"; then
        log_error_detail "$(zsh_syntax_highlighting_text install_fail)"
        return 1
    fi

    # Add plugin to .zshrc if not already present
    local zshrc_file="$HOME/.zshrc"
    if [ -f "$zshrc_file" ]; then
        # Check if plugin is already in the plugins list
        if ! grep -q "zsh-syntax-highlighting" "$zshrc_file"; then
            log_info_detail "Adding plugin to ~/.zshrc..."
            
            # Find plugins line and add zsh-syntax-highlighting
            if grep -q "^plugins=(" "$zshrc_file"; then
                # Add to existing plugins list
                sed -i '/^plugins=(/ s/)/ zsh-syntax-highlighting)/' "$zshrc_file"
            else
                # Add plugins line if it doesn't exist
                echo -e "\n# Zsh Syntax Highlighting plugin\nplugins=(zsh-syntax-highlighting)" >> "$zshrc_file"
            fi
        fi

        # Add source command at the end of .zshrc if not already present
        if ! grep -q "zsh-syntax-highlighting.zsh" "$zshrc_file"; then
            log_info_detail "Adding source command to ~/.zshrc..."
            echo -e "\n# Zsh Syntax Highlighting\nsource ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$zshrc_file"
        fi
    else
        # Create .zshrc with plugin
        log_info_detail "Creating ~/.zshrc with plugin configuration..."
        cat > "$zshrc_file" << EOF
# Zsh Syntax Highlighting plugin
plugins=(zsh-syntax-highlighting)

# Source Zsh Syntax Highlighting
source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Source Oh My Zsh if it exists
if [ -f "\$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    source "\$HOME/.oh-my-zsh/oh-my-zsh.sh"
fi
EOF
    fi

    log_success_detail "$(zsh_syntax_highlighting_text install_success)"
    log_info_detail "$(zsh_syntax_highlighting_text config_info)"
    log_info_detail "$(zsh_syntax_highlighting_text reload_info)"
    log_success_detail "$(zsh_syntax_highlighting_text install_done)"
}

main() {
    install_zsh_syntax_highlighting "$@"
}

main "$@"