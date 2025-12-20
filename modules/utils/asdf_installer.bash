#!/bin/bash
set -euo pipefail

# ASDF Version Manager Installer
# Supports: apt, dnf, yum, pacman, brew

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/utils.bash"
platform_local="$script_dir/platform_detection.bash"

if [ -f "$utils_local" ]; then
    source "$utils_local"
elif [ -f "./modules/utils/utils.bash" ]; then
    source "./modules/utils/utils.bash"
else
    echo "[HATA/ERROR] utils.bash yüklenemedi / Unable to load utils.bash" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    source "$platform_local"
elif [ -f "./modules/utils/platform_detection.bash" ]; then
    source "./modules/utils/platform_detection.bash"
fi

: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${NC:=$'\033[0m'}"

ASDF_VERSION="${ASDF_VERSION:-v0.18.0}"
ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

# --- i18n Support ---
declare -A ASDF_TEXT_EN=(
    ["install_title"]="Starting ASDF Version Manager installation..."
    ["already_installed"]="ASDF is already installed:"
    ["installing_deps"]="Installing ASDF dependencies..."
    ["cloning_asdf"]="Cloning ASDF repository..."
    ["downloading_binary"]="Downloading ASDF binary..."
    ["configuring_shell"]="Configuring shell for ASDF..."
    ["shell_configured"]="ASDF shell configuration added to %s"
    ["shell_already_configured"]="ASDF already configured in %s"
    ["install_done"]="ASDF Version Manager installation completed!"
    ["install_failed"]="ASDF installation failed."
    ["version_info"]="ASDF version:"
    
    # Plugin messages
    ["plugin_install_title"]="Installing %s via ASDF..."
    ["plugin_adding"]="Adding %s plugin to ASDF..."
    ["plugin_already_added"]="Plugin %s already added."
    ["plugin_deps"]="Installing %s plugin dependencies..."
    ["installing_version"]="Installing %s version: %s"
    ["setting_global"]="Setting %s %s as global version..."
    ["plugin_done"]="%s installation via ASDF completed!"
    ["plugin_failed"]="%s installation failed."
    
    # Node.js
    ["nodejs_next_steps"]="Node.js Next Steps:"
    ["nodejs_step1"]="Check version: node --version"
    ["nodejs_step2"]="Install another version: asdf install nodejs <version>"
    ["nodejs_step3"]="List versions: asdf list nodejs"
    ["nodejs_step4"]="Set local version: asdf local nodejs <version>"
    
    # Java
    ["java_next_steps"]="Java Next Steps:"
    ["java_step1"]="Check version: java --version"
    ["java_step2"]="List available: asdf list-all java"
    ["java_step3"]="Install specific: asdf install java temurin-21.0.2+13.0.LTS"
    ["java_step4"]="Set JAVA_HOME: export JAVA_HOME=\$(asdf where java)"
    
    # PHP
    ["php_next_steps"]="PHP Next Steps:"
    ["php_step1"]="Check version: php --version"
    ["php_step2"]="List versions: asdf list-all php"
    ["php_step3"]="Install specific: asdf install php 8.3.0"
    ["php_step4"]="Install extensions: pecl install <extension>"
    
    # General
    ["restart_shell"]="Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    ["asdf_usage"]="ASDF Usage Tips:"
    ["asdf_tip1"]="List all plugins: asdf plugin list-all"
    ["asdf_tip2"]="Add plugin: asdf plugin add <name>"
    ["asdf_tip3"]="Install version: asdf install <name> <version>"
    ["asdf_tip4"]="Set global: asdf global <name> <version>"
)

declare -A ASDF_TEXT_TR=(
    ["install_title"]="ASDF Sürüm Yöneticisi kurulumu başlatılıyor..."
    ["already_installed"]="ASDF zaten kurulu:"
    ["installing_deps"]="ASDF bağımlılıkları kuruluyor..."
    ["cloning_asdf"]="ASDF deposu klonlanıyor..."
    ["downloading_binary"]="ASDF binary indiriliyor..."
    ["configuring_shell"]="Kabuk ASDF için yapılandırılıyor..."
    ["shell_configured"]="ASDF kabuk yapılandırması %s dosyasına eklendi"
    ["shell_already_configured"]="ASDF zaten %s dosyasında yapılandırılmış"
    ["install_done"]="ASDF Sürüm Yöneticisi kurulumu tamamlandı!"
    ["install_failed"]="ASDF kurulumu başarısız oldu."
    ["version_info"]="ASDF sürümü:"
    
    # Plugin messages
    ["plugin_install_title"]="%s ASDF üzerinden kuruluyor..."
    ["plugin_adding"]="%s eklentisi ASDF'ye ekleniyor..."
    ["plugin_already_added"]="%s eklentisi zaten ekli."
    ["plugin_deps"]="%s eklentisi bağımlılıkları kuruluyor..."
    ["installing_version"]="%s sürümü kuruluyor: %s"
    ["setting_global"]="%s %s global sürüm olarak ayarlanıyor..."
    ["plugin_done"]="%s ASDF üzerinden kurulumu tamamlandı!"
    ["plugin_failed"]="%s kurulumu başarısız oldu."
    
    # Node.js
    ["nodejs_next_steps"]="Node.js Sonraki Adımlar:"
    ["nodejs_step1"]="Sürümü kontrol et: node --version"
    ["nodejs_step2"]="Başka sürüm kur: asdf install nodejs <sürüm>"
    ["nodejs_step3"]="Sürümleri listele: asdf list nodejs"
    ["nodejs_step4"]="Yerel sürüm ayarla: asdf local nodejs <sürüm>"
    
    # Java
    ["java_next_steps"]="Java Sonraki Adımlar:"
    ["java_step1"]="Sürümü kontrol et: java --version"
    ["java_step2"]="Mevcut sürümleri listele: asdf list-all java"
    ["java_step3"]="Belirli sürüm kur: asdf install java temurin-21.0.2+13.0.LTS"
    ["java_step4"]="JAVA_HOME ayarla: export JAVA_HOME=\$(asdf where java)"
    
    # PHP
    ["php_next_steps"]="PHP Sonraki Adımlar:"
    ["php_step1"]="Sürümü kontrol et: php --version"
    ["php_step2"]="Sürümleri listele: asdf list-all php"
    ["php_step3"]="Belirli sürüm kur: asdf install php 8.3.0"
    ["php_step4"]="Eklenti kur: pecl install <eklenti>"
    
    # General
    ["restart_shell"]="Lütfen terminalinizi yeniden başlatın veya şunu çalıştırın: source ~/.bashrc (veya ~/.zshrc)"
    ["asdf_usage"]="ASDF Kullanım İpuçları:"
    ["asdf_tip1"]="Tüm eklentileri listele: asdf plugin list-all"
    ["asdf_tip2"]="Eklenti ekle: asdf plugin add <isim>"
    ["asdf_tip3"]="Sürüm kur: asdf install <isim> <sürüm>"
    ["asdf_tip4"]="Global ayarla: asdf global <isim> <sürüm>"
)

asdf_text() {
    local key="$1"
    local default_value="${ASDF_TEXT_EN[$key]:-$key}"
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        printf "%s" "${ASDF_TEXT_TR[$key]:-$default_value}"
    else
        printf "%s" "$default_value"
    fi
}

asdf_text_fmt() {
    local key="$1"
    shift
    local fmt
    fmt=$(asdf_text "$key")
    # shellcheck disable=SC2059
    printf "$fmt" "$@"
}

# --- Installation Functions ---

install_asdf_deps() {
    log_info_detail "$(asdf_text installing_deps)"
    
    case "${PKG_MANAGER:-}" in
        apt)
            sudo apt-get update -y >/dev/null 2>&1
            sudo apt-get install -y git curl bash >/dev/null 2>&1
            ;;
        dnf|dnf5)
            sudo dnf install -y git curl bash >/dev/null 2>&1
            ;;
        yum)
            sudo yum install -y git curl bash >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -S --noconfirm git curl bash >/dev/null 2>&1
            ;;
        brew)
            brew install coreutils git curl >/dev/null 2>&1
            ;;
        *)
            log_warn_detail "Unknown package manager, skipping dependency installation"
            ;;
    esac
}

install_asdf() {
    if command -v asdf &>/dev/null; then
        log_success_detail "$(asdf_text already_installed) $(asdf --version 2>/dev/null || echo 'unknown')"
        return 0
    fi
    
    log_info_detail "$(asdf_text install_title)"
    
    # Install dependencies
    install_asdf_deps
    
    # Install based on package manager
    case "${PKG_MANAGER:-}" in
        brew)
            log_info_detail "$(asdf_text downloading_binary)"
            if brew install asdf >/dev/null 2>&1; then
                log_success_detail "ASDF installed via Homebrew"
            else
                log_error_detail "$(asdf_text install_failed)"
                return 1
            fi
            ;;
        pacman)
            log_info_detail "$(asdf_text cloning_asdf)"
            if command -v yay &>/dev/null; then
                yay -S --noconfirm asdf-vm >/dev/null 2>&1
            elif command -v paru &>/dev/null; then
                paru -S --noconfirm asdf-vm >/dev/null 2>&1
            else
                # Manual AUR install
                local tmp_dir=$(mktemp -d)
                git clone https://aur.archlinux.org/asdf-vm.git "$tmp_dir/asdf-vm" >/dev/null 2>&1
                (cd "$tmp_dir/asdf-vm" && makepkg -si --noconfirm) >/dev/null 2>&1
                rm -rf "$tmp_dir"
            fi
            ;;
        *)
            # Download binary method (works for most Linux distros)
            log_info_detail "$(asdf_text downloading_binary)"
            local arch=$(uname -m)
            local os=$(uname -s | tr '[:upper:]' '[:lower:]')
            
            case "$arch" in
                x86_64) arch="amd64" ;;
                aarch64|arm64) arch="arm64" ;;
            esac
            
            local download_url="https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-${os}-${arch}.tar.gz"
            local install_dir="$HOME/.local/bin"
            mkdir -p "$install_dir"
            
            if curl -fsSL "$download_url" | tar -xz -C "$install_dir" asdf 2>/dev/null; then
                chmod +x "$install_dir/asdf"
                ensure_path_contains_dir "$install_dir" "ASDF binary"
            else
                log_error_detail "$(asdf_text install_failed)"
                return 1
            fi
            ;;
    esac
    
    # Configure shell
    configure_asdf_shell
    
    # Reload configs
    reload_shell_configs silent
    hash -r 2>/dev/null || true
    
    # Verify installation
    if command -v asdf &>/dev/null; then
        log_success_detail "$(asdf_text version_info) $(asdf --version 2>/dev/null)"
        log_success_detail "$(asdf_text install_done)"
        
        # Show usage tips
        echo
        log_info_detail "$(asdf_text asdf_usage)"
        log_info_detail "  ${GREEN}•${NC} $(asdf_text asdf_tip1)"
        log_info_detail "  ${GREEN}•${NC} $(asdf_text asdf_tip2)"
        log_info_detail "  ${GREEN}•${NC} $(asdf_text asdf_tip3)"
        log_info_detail "  ${GREEN}•${NC} $(asdf_text asdf_tip4)"
        echo
        log_warn_detail "$(asdf_text restart_shell)"
    else
        log_error_detail "$(asdf_text install_failed)"
        return 1
    fi
}

configure_asdf_shell() {
    log_info_detail "$(asdf_text configuring_shell)"
    
    local shims_export='export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"'
    local completion_bash='. <(asdf completion bash)'
    local completion_zsh='. <(asdf completion zsh)'
    
    # Configure bash
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "asdf" "$HOME/.bashrc" 2>/dev/null; then
            {
                echo ''
                echo '# ASDF Version Manager'
                echo "$shims_export"
                echo "$completion_bash"
            } >> "$HOME/.bashrc"
            log_success_detail "$(asdf_text_fmt shell_configured "$HOME/.bashrc")"
        else
            log_info_detail "$(asdf_text_fmt shell_already_configured "$HOME/.bashrc")"
        fi
    fi
    
    # Configure zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "asdf" "$HOME/.zshrc" 2>/dev/null; then
            {
                echo ''
                echo '# ASDF Version Manager'
                echo "$shims_export"
                echo "$completion_zsh"
            } >> "$HOME/.zshrc"
            log_success_detail "$(asdf_text_fmt shell_configured "$HOME/.zshrc")"
        else
            log_info_detail "$(asdf_text_fmt shell_already_configured "$HOME/.zshrc")"
        fi
    fi
}

# --- Plugin Installation Functions ---

install_nodejs_deps() {
    log_info_detail "$(asdf_text_fmt plugin_deps "Node.js")"
    case "${PKG_MANAGER:-}" in
        apt)
            sudo apt-get install -y dirmngr gpg curl gawk >/dev/null 2>&1
            ;;
        dnf|dnf5|yum)
            sudo ${PKG_MANAGER:-dnf} install -y gnupg2 curl gawk >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -S --noconfirm gnupg curl gawk >/dev/null 2>&1
            ;;
        brew)
            brew install gpg gawk >/dev/null 2>&1
            ;;
    esac
}

install_java_deps() {
    log_info_detail "$(asdf_text_fmt plugin_deps "Java")"
    case "${PKG_MANAGER:-}" in
        apt)
            sudo apt-get install -y curl unzip >/dev/null 2>&1
            ;;
        dnf|dnf5|yum)
            sudo ${PKG_MANAGER:-dnf} install -y curl unzip >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -S --noconfirm curl unzip >/dev/null 2>&1
            ;;
        brew)
            brew install curl >/dev/null 2>&1
            ;;
    esac
}

install_php_deps() {
    log_info_detail "$(asdf_text_fmt plugin_deps "PHP")"
    case "${PKG_MANAGER:-}" in
        apt)
            sudo apt-get install -y autoconf bison build-essential curl gettext git \
                libgd-dev libcurl4-openssl-dev libedit-dev libicu-dev libjpeg-dev \
                libmysqlclient-dev libonig-dev libpng-dev libpq-dev libreadline-dev \
                libsqlite3-dev libssl-dev libxml2-dev libzip-dev openssl pkg-config \
                re2c zlib1g-dev mlocate >/dev/null 2>&1 || \
            sudo apt-get install -y autoconf bison build-essential curl gettext git \
                libgd-dev libcurl4-openssl-dev libedit-dev libicu-dev libjpeg-dev \
                libmysqlclient-dev libonig-dev libpng-dev libpq-dev libreadline-dev \
                libsqlite3-dev libssl-dev libxml2-dev libzip-dev openssl pkg-config \
                re2c zlib1g-dev plocate >/dev/null 2>&1 || true
            ;;
        dnf|dnf5|yum)
            sudo ${PKG_MANAGER:-dnf} install -y autoconf bison gcc gcc-c++ git curl \
                libcurl-devel libicu-devel libjpeg-devel libpng-devel libxml2-devel \
                libzip-devel oniguruma-devel openssl-devel readline-devel sqlite-devel \
                zlib-devel >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -S --noconfirm base-devel curl git libxml2 openssl >/dev/null 2>&1
            ;;
    esac
}

install_asdf_plugin() {
    local plugin_name="$1"
    local plugin_url="$2"
    local version="${3:-latest}"
    local deps_func="$4"
    local next_steps_key="$5"
    
    # Ensure asdf is installed
    if ! command -v asdf &>/dev/null; then
        install_asdf || return 1
        # Source the new config
        export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    fi
    
    log_info_detail "$(asdf_text_fmt plugin_install_title "$plugin_name")"
    
    # Install dependencies
    if [ -n "$deps_func" ] && declare -f "$deps_func" >/dev/null 2>&1; then
        $deps_func
    fi
    
    # Add plugin
    log_info_detail "$(asdf_text_fmt plugin_adding "$plugin_name")"
    if asdf plugin list 2>/dev/null | grep -q "^${plugin_name}$"; then
        log_info_detail "$(asdf_text_fmt plugin_already_added "$plugin_name")"
    else
        if ! asdf plugin add "$plugin_name" "$plugin_url" 2>/dev/null; then
            log_error_detail "$(asdf_text_fmt plugin_failed "$plugin_name")"
            return 1
        fi
    fi
    
    # Install version
    local install_version="$version"
    if [[ "$version" == "latest:"* ]]; then
        # Handle "latest:prefix" format (e.g., "latest:temurin-" for Java)
        local prefix="${version#latest:}"
        install_version=$(asdf latest "$plugin_name" "$prefix" 2>/dev/null || echo "$version")
    elif [ "$version" = "latest" ]; then
        install_version=$(asdf latest "$plugin_name" 2>/dev/null || echo "latest")
    fi
    
    log_info_detail "$(asdf_text_fmt installing_version "$plugin_name" "$install_version")"
    if ! asdf install "$plugin_name" "$install_version" 2>&1; then
        log_error_detail "$(asdf_text_fmt plugin_failed "$plugin_name")"
        return 1
    fi
    
    # Set global version (asdf v0.18+ uses 'set', older uses 'global')
    log_info_detail "$(asdf_text_fmt setting_global "$plugin_name" "$install_version")"
    local asdf_version
    asdf_version=$(asdf --version 2>/dev/null | grep -oP 'v\K[0-9]+\.[0-9]+' | head -1)
    if [[ "$(printf '%s\n0.18\n' "$asdf_version" | sort -V | head -1)" == "0.18" ]]; then
        # ASDF v0.18+ uses 'set' command
        asdf set "$plugin_name" "$install_version" 2>/dev/null || asdf global "$plugin_name" "$install_version" 2>/dev/null || true
    else
        # Older ASDF uses 'global' command
        asdf global "$plugin_name" "$install_version" 2>/dev/null || asdf set "$plugin_name" "$install_version" 2>/dev/null || true
    fi
    
    # Reshim
    asdf reshim "$plugin_name" 2>/dev/null || true
    
    log_success_detail "$(asdf_text_fmt plugin_done "$plugin_name")"
    
    # Show next steps
    echo
    log_info_detail "$(asdf_text "${next_steps_key}_next_steps")"
    log_info_detail "  ${GREEN}•${NC} $(asdf_text "${next_steps_key}_step1")"
    log_info_detail "  ${GREEN}•${NC} $(asdf_text "${next_steps_key}_step2")"
    log_info_detail "  ${GREEN}•${NC} $(asdf_text "${next_steps_key}_step3")"
    log_info_detail "  ${GREEN}•${NC} $(asdf_text "${next_steps_key}_step4")"
}

install_nodejs_via_asdf() {
    install_asdf_plugin "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git" "latest" "install_nodejs_deps" "nodejs"
}

install_java_via_asdf() {
    # Use Temurin (Eclipse Adoptium) as default - "latest:temurin-" gets the latest Temurin LTS
    install_asdf_plugin "java" "https://github.com/halcyon/asdf-java.git" "latest:temurin-" "install_java_deps" "java"
}

install_php_via_asdf() {
    # Note: asdf-php plugin is incompatible with ASDF v0.18+
    # Redirect users to the dedicated PHP installation menu
    local msg_title msg_reason msg_use_menu
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        msg_title="PHP ASDF Eklentisi Uyumsuz"
        msg_reason="asdf-php eklentisi ASDF v0.18+ ile uyumlu değil."
        msg_use_menu="PHP kurmak için ana menüden seçenek 9'u (PHP Sürümleri) kullanın."
    else
        msg_title="PHP ASDF Plugin Incompatible"
        msg_reason="The asdf-php plugin is not compatible with ASDF v0.18+."
        msg_use_menu="To install PHP, use option 9 (PHP Versions) from the main menu."
    fi
    
    echo
    log_warn_detail "$msg_title"
    log_warn_detail "$msg_reason"
    log_info_detail "$msg_use_menu"
    echo
    return 0
}

# --- Main ---
main() {
    local action="${1:-install}"
    
    case "$action" in
        install|asdf)
            install_asdf
            ;;
        nodejs|node)
            install_nodejs_via_asdf
            ;;
        java)
            install_java_via_asdf
            ;;
        php)
            install_php_via_asdf
            ;;
        all)
            install_asdf
            install_nodejs_via_asdf
            install_java_via_asdf
            install_php_via_asdf
            ;;
        *)
            log_error_detail "Unknown action: $action"
            return 1
            ;;
    esac
}

# Only run main if this script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
