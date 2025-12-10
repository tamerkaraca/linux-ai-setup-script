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

declare -A POWERLEVEL10K_TEXT_EN=(
    ["install_title"]="Starting Powerlevel10k installation..."
    ["zsh_missing"]="Zsh is not installed. Please install Zsh first."
    ["already_installed"]="Powerlevel10k is already installed."
    ["install_fail"]="Powerlevel10k installation failed."
    ["install_success"]="Powerlevel10k installed successfully!"
    ["config_info"]="Theme configured in ~/.zshrc"
    ["setup_info"]="Run 'p10k configure' to customize the theme"
    ["reload_info"]="Run 'source ~/.zshrc' or restart terminal to apply changes"
    ["install_done"]="Powerlevel10k installation completed!"
)

declare -A POWERLEVEL10K_TEXT_TR=(
    ["install_title"]="Powerlevel10k kurulumu başlatılıyor..."
    ["zsh_missing"]="Zsh kurulu değil. Lütfen önce Zsh kurun."
    ["already_installed"]="Powerlevel10k zaten kurulu."
    ["install_fail"]="Powerlevel10k kurulumu başarısız oldu."
    ["install_success"]="Powerlevel10k başarıyla kuruldu!"
    ["config_info"]="Tema ~/.zshrc dosyasında yapılandırıldı"
    ["setup_info"]="Temayı özelleştirmek için 'p10k configure' çalıştırın"
    ["reload_info"]="Değişiklikleri uygulamak için 'source ~/.zshrc' çalıştırın veya terminali yeniden başlatın"
    ["install_done"]="Powerlevel10k kurulumu tamamlandı!"
)

powerlevel10k_text() {
    local key="$1"
    local default_value="${POWERLEVEL10K_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${POWERLEVEL10K_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

install_powerlevel10k() {
    log_info_detail "$(powerlevel10k_text install_title)"
    
    # Check if zsh is installed
    if ! command -v zsh >/dev/null 2>&1; then
        log_error_detail "$(powerlevel10k_text zsh_missing)"
        return 1
    fi

    # Check if already installed
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ -d "$theme_dir" ]; then
        log_success_detail "$(powerlevel10k_text already_installed)"
        log_info_detail "$(powerlevel10k_text config_info)"
        log_info_detail "$(powerlevel10k_text setup_info)"
        log_info_detail "$(powerlevel10k_text reload_info)"
        return 0
    fi

    # Create custom themes directory if it doesn't exist
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"
    mkdir -p "$custom_dir"

    # Clone the repository
    log_info_detail "Cloning Powerlevel10k repository..."
    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"; then
        log_error_detail "$(powerlevel10k_text install_fail)"
        return 1
    fi

    # Set theme in .zshrc
    local zshrc_file="$HOME/.zshrc"
    if [ -f "$zshrc_file" ]; then
        log_info_detail "Setting Powerlevel10k theme in ~/.zshrc..."
        
        # Comment out existing ZSH_THEME lines
        sed -i 's/^ZSH_THEME=/# ZSH_THEME=/' "$zshrc_file"
        
        # Add Powerlevel10k theme
        if grep -q "powerlevel10k" "$zshrc_file"; then
            log_info_detail "Powerlevel10k theme already configured in ~/.zshrc"
        else
            echo -e "\n# Powerlevel10k theme\nZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> "$zshrc_file"
        fi
    else
        # Create .zshrc with Powerlevel10k theme
        log_info_detail "Creating ~/.zshrc with Powerlevel10k theme..."
        cat > "$zshrc_file" << 'EOF'
# Powerlevel10k theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Source Oh My Zsh if it exists
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
fi
EOF
    fi

    log_success_detail "$(powerlevel10k_text install_success)"
    log_info_detail "$(powerlevel10k_text config_info)"
    log_info_detail "$(powerlevel10k_text setup_info)"
    log_info_detail "$(powerlevel10k_text reload_info)"
    log_success_detail "$(powerlevel10k_text install_done)"
}

main() {
    install_powerlevel10k "$@"
}

main "$@"