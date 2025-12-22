#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_local="$script_dir/../utils/utils.bash"
platform_local="$script_dir/../utils/platform_detection.bash"

if [ -f "$utils_local" ]; then
    source "$utils_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/utils.bash" "modules/utils/utils.bash"
else
    echo "[HATA/ERROR] utils.bash could not be loaded." >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

# --- Text Definitions ---
declare -A PHP_TEXT_EN=(
    ["menu_title"]="Advanced PHP Installation & Management"
    ["menu_hint"]="You can select multiple versions by number (e.g., 1,5,7) or 'A' for all."
    ["prompt_choice"]="Enter your choice(s)"
    ["installing_php"]="Installing PHP %s..."
    ["installing_deps_for"]="Installing dependencies for PHP %s..."
    ["installing_composer_for"]="Installing Composer for PHP %s..."
    ["ppa_adding"]="Adding ondrej/php PPA..."
    ["ppa_exists"]="ondrej/php PPA already exists."
    ["remi_enabling"]="Enabling Remi repository for PHP %s..."
    ["install_success"]="PHP %s installed successfully."
    ["install_failed"]="Failed to install PHP %s."
    ["composer_success"]="Composer for PHP %s installed successfully."
    ["composer_failed"]="Failed to install Composer for PHP %s."
    ["setting_aliases"]="Setting up aliases for PHP %s..."
    ["alias_added"]="Alias '%s' added to %s."
    ["alias_exists"]="Alias '%s' already exists in %s. Skipping."
    ["invalid_choice"]="Invalid selection: %s"
    ["returning"]="Returning to main menu..."
)
declare -A PHP_TEXT_TR=(
    ["menu_title"]="Gelişmiş PHP Kurulum ve Yönetimi"
    ["menu_hint"]="Numaraları kullanarak birden fazla sürüm seçebilirsiniz (örn: 1,5,7) veya hepsini kurmak için 'A' yazın."
    ["prompt_choice"]="Seçiminiz"
    ["installing_php"]="PHP %s kuruluyor..."
    ["installing_deps_for"]="PHP %s için bağımlılıklar kuruluyor..."
    ["installing_composer_for"]="PHP %s için Composer kuruluyor..."
    ["ppa_adding"]="ondrej/php PPA deposu ekleniyor..."
    ["ppa_exists"]="ondrej/php PPA deposu zaten mevcut."
    ["remi_enabling"]="PHP %s için Remi deposu etkinleştiriliyor..."
    ["install_success"]="PHP %s başarıyla kuruldu."
    ["install_failed"]="PHP %s kurulumu başarısız oldu."
    ["composer_success"]="PHP %s için Composer başarıyla kuruldu."
    ["composer_failed"]="PHP %s için Composer kurulumu başarısız oldu."
    ["setting_aliases"]="PHP %s için kısayollar ayarlanıyor..."
    ["alias_added"]="'%s' kısayolu %s dosyasına eklendi."
    ["alias_exists"]="'%s' kısayolu %s içinde zaten var. Atlanıyor."
    ["invalid_choice"]="Geçersiz seçim: %s"
    ["returning"]="Ana menüye dönülüyor..."
)

php_text() {
    local key="$1"
    # Provide a default value from the English map in case the key is missing
    local default_value="${PHP_TEXT_EN[$key]:-$key}"
    
    if [ "${LANGUAGE:-en}" = "tr" ]; then
        # If language is Turkish, use the Turkish map, falling back to the default
        printf "%s" "${PHP_TEXT_TR[$key]:-$default_value}"
    else
        # Otherwise, use the English/default value
        printf "%s" "$default_value"
    fi
}

# --- Core Logic ---

PHP_VERSIONS=("7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3" "8.4" "8.5" "8.6")

# Add a unique alias to a shell config file if it doesn't exist
add_alias_if_not_exists() {
    local shell_config_file="$1"
    local alias_name="$2"
    local alias_command="$3"
    local alias_line="alias ${alias_name}='${alias_command}'"
    local marker="# PHP Aliases by linux-ai-setup-script"

    if ! grep -q "alias ${alias_name}=" "$shell_config_file" 2>/dev/null; then
        # Add a marker if it's the first time
        if ! grep -q "$marker" "$shell_config_file" 2>/dev/null; then
            echo -e "\n$marker" >> "$shell_config_file"
        fi
        echo "$alias_line" >> "$shell_config_file"
        log_info_detail "$(php_text 'alias_added' "$alias_name" "$shell_config_file")"
    else
        log_info_detail "$(php_text 'alias_exists' "$alias_name" "$shell_config_file")"
    fi
}

# Setup aliases for a specific PHP version
setup_php_aliases() {
    local version="$1"
    local short_ver="${version//./}"
    local php_executable="/usr/bin/php${version}"
    local composer_path="/usr/local/bin/composer-${version}.phar"

    if is_macos; then
        php_executable="/usr/local/opt/php@${version}/bin/php"
    fi
    
    log_info_detail "$(php_text 'setting_aliases' "$version")"

    for shell_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$shell_file" ]; then
            add_alias_if_not_exists "$shell_file" "p${short_ver}" "${php_executable}"
            add_alias_if_not_exists "$shell_file" "c${short_ver}" "${php_executable} ${composer_path}"
            add_alias_if_not_exists "$shell_file" "art${short_ver}" "${php_executable} artisan"
        fi
    done
}

# Install Composer for a specific PHP version
install_composer_for_version() {
    local version="$1"
    local php_executable="/usr/bin/php${version}"
    local composer_phar="/usr/local/bin/composer-${version}.phar"
    
    if is_macos; then
        php_executable="/usr/local/opt/php@${version}/bin/php"
    fi

    log_info_detail "$(php_text 'installing_composer_for' "$version")"

    if [ -f "$composer_phar" ]; then
        log_success_detail "Composer for PHP $version already exists."
        return 0
    fi
    
    if curl -sS https://getcomposer.org/installer | "$php_executable"; then
        sudo mv composer.phar "$composer_phar"
        log_success_detail "$(php_text 'composer_success' "$version")"
    else
        log_error_detail "$(php_text 'composer_failed' "$version")"
        return 1
    fi
}

# Install a specific PHP version and its components
install_php_version() {
    local version="$1"
    log_info_detail "$(php_text 'installing_php' "$version")"

    # Comprehensive list of extensions for Laravel
    local pkgs_apt="php${version} php${version}-cli php${version}-common php${version}-intl php${version}-zip php${version}-curl php${version}-xml php${version}-mbstring php${version}-mysql php${version}-pgsql php${version}-bcmath php${version}-gd php${version}-redis php${version}-imagick php${version}-dom"
    
    # Sodium is built-in since PHP 7.2, only add it for older versions
    if [[ "$(echo -e "${version}\n7.2" | sort -V | head -n1)" != "7.2" ]]; then
        pkgs_apt+=" php${version}-sodium"
    fi

    local pkgs_dnf="php php-cli php-common php-intl php-zip php-curl php-xml php-mbstring php-mysqlnd php-pgsql php-bcmath php-gd php-pecl-redis php-imagick php-sodium php-dom"
    local system_deps="zip unzip"

    if is_macos; then
        brew install zip unzip p7zip
        if ! brew install "php@${version}"; then
            log_error_detail "$(php_text 'install_failed' "$version")"
            return 1
        fi
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo apt-get install -y $system_deps p7zip-full
        if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
            log_info_detail "$(php_text 'ppa_adding')"
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository -y ppa:ondrej/php
            sudo apt-get update
        else
            log_info_detail "$(php_text 'ppa_exists')"
        fi
        log_info_detail "$(php_text 'installing_deps_for' "$version")"
        if ! sudo apt-get install -y --allow-downgrades $pkgs_apt; then
             log_error_detail "$(php_text 'install_failed' "$version")"
             return 1
        fi
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        sudo dnf -y install $system_deps p7zip
        log_info_detail "$(php_text 'remi_enabling' "$version")"
        sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
        sudo dnf -y module reset php
        sudo dnf -y module enable "php:remi-${version}"
        log_info_detail "$(php_text 'installing_deps_for' "$version")"
        if ! sudo dnf -y install $pkgs_dnf; then
             log_error_detail "$(php_text 'install_failed' "$version")"
             return 1
        fi
    else
        log_error "Unsupported package manager: $PKG_MANAGER"
        return 1
    fi

    log_success_detail "$(php_text 'install_success' "$version")"
    
    if install_composer_for_version "$version"; then
        setup_php_aliases "$version"
    fi
}

# --- UI Functions ---

display_menu() {
    print_heading_panel "$(php_text menu_title)"
    echo
    local i=0
    for version in "${PHP_VERSIONS[@]}"; do
        i=$((i + 1))
        printf "  ${GREEN}%2d${NC} - PHP %s\n" "$i" "$version"
    done
    echo
    echo "  ${YELLOW}A${NC} - Install All Versions"
    echo "  ${YELLOW}0${NC} - Return to Main Menu"
    echo
    log_info_detail "$(php_text menu_hint)"
    echo
}

# --- Main Loop ---

main() {
    while true; do
        display_menu
        read -r -p "$(php_text prompt_choice): " choice_input </dev/tty

        if [ -z "$(echo "$choice_input" | tr -d '[:space:]')" ]; then
            continue
        fi

        if [[ "$choice_input" =~ ^[aA]$ ]]; then
            for version in "${PHP_VERSIONS[@]}"; do
                install_php_version "$version"
            done
            continue
        fi

        if [[ "$choice_input" == "0" ]]; then
            log_info_detail "$(php_text returning)"
            break
        fi

        IFS=',' read -ra selections <<< "$choice_input"
        for selection in "${selections[@]}"; do
            selection=$(echo "$selection" | tr -d '[:space:]')
            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#PHP_VERSIONS[@]} ]; then
                version_to_install="${PHP_VERSIONS[$((selection - 1))]}"
                install_php_version "$version_to_install"
            else
                log_error_detail "$(php_text 'invalid_choice' "$selection")"
            fi
        done
        
        log_success_detail "Selected PHP operations complete."
        read -r -p "Press Enter to continue..." _tmp </dev/tty
    done
}

detect_platform
main
