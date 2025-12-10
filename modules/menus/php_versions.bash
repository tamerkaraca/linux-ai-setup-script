#!/bin/bash

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

CURRENT_LANG="${LANGUAGE:-en}"

# Helper function to run commands with TTY attached
attach_tty_and_run() {
    if [ -e /dev/tty ] && [ -r /dev/tty ]; then
        "$@" </dev/tty
    else
        "$@"
    fi
}

# Text definitions for PHP version installation
declare -A PHP_TEXT_EN=(
    ["menu_title"]="PHP Version Installation Menu"
    ["menu_option_70"]="Install PHP 7.0"
    ["menu_option_71"]="Install PHP 7.1"
    ["menu_option_72"]="Install PHP 7.2"
    ["menu_option_73"]="Install PHP 7.3"
    ["menu_option_74"]="Install PHP 7.4"
    ["menu_option_80"]="Install PHP 8.0"
    ["menu_option_81"]="Install PHP 8.1"
    ["menu_option_82"]="Install PHP 8.2"
    ["menu_option_83"]="Install PHP 8.3"
    ["menu_option_84"]="Install PHP 8.4"
    ["menu_option_85"]="Install PHP 8.5"
    ["menu_option_switch"]="Switch PHP version"
    ["menu_option_all"]="Install all PHP versions"
    ["menu_option0"]="Return to main menu"
    ["menu_hint"]="Select PHP version to install or manage"
    ["prompt_choice"]="Your choice"
    ["returning"]="Returning to the main menu..."
    ["invalid_choice"]="Invalid selection."
    ["no_selection"]="No selection detected."
    ["installing_php"]="Installing PHP"
    ["php_installed"]="PHP installation completed"
    ["switching_php"]="Switching active PHP version"
    ["no_php_installed"]="No PHP versions found. Please install a PHP version first."
    ["select_php_version"]="Select active PHP version:"
    ["php_switched"]="Successfully switched to PHP"
    ["installing_all"]="Installing all PHP versions..."
    ["alias_header"]="# PHP Version Aliases (for CLI)"
    ["alias_composer_header"]="# Composer Aliases"
    ["aliases_added"]="PHP aliases added to"
    ["aliases_exist"]="PHP aliases already exist in"
    ["setting_up_aliases"]="Setting up PHP shell aliases..."
)

declare -A PHP_TEXT_TR=(
    ["menu_title"]="PHP Sürüm Kurulum Menüsü"
    ["menu_option_70"]="PHP 7.0 kur"
    ["menu_option_71"]="PHP 7.1 kur"
    ["menu_option_72"]="PHP 7.2 kur"
    ["menu_option_73"]="PHP 7.3 kur"
    ["menu_option_74"]="PHP 7.4 kur"
    ["menu_option_80"]="PHP 8.0 kur"
    ["menu_option_81"]="PHP 8.1 kur"
    ["menu_option_82"]="PHP 8.2 kur"
    ["menu_option_83"]="PHP 8.3 kur"
    ["menu_option_84"]="PHP 8.4 kur"
    ["menu_option_85"]="PHP 8.5 kur"
    ["menu_option_switch"]="PHP sürümü değiştir"
    ["menu_option_all"]="Tüm PHP sürümlerini kur"
    ["menu_option0"]="Ana menüye dön"
    ["menu_hint"]="Kurulum veya yönetim için PHP sürümünü seçin"
    ["prompt_choice"]="Seçiminiz"
    ["returning"]="Ana menüye dönülüyor..."
    ["invalid_choice"]="Geçersiz seçim."
    ["no_selection"]="Bir seçim yapılmadı."
    ["installing_php"]="PHP kuruluyor"
    ["php_installed"]="PHP kurulumu tamamlandı"
    ["switching_php"]="Aktif PHP sürümü değiştiriliyor"
    ["no_php_installed"]="PHP sürümü bulunamadı. Lütfen önce bir PHP sürümü kurun."
    ["select_php_version"]="Aktif PHP sürümünü seçin:"
    ["php_switched"]="Başarıyla PHP sürümüne geçildi"
    ["installing_all"]="Tüm PHP sürümleri kuruluyor..."
    ["alias_header"]="# PHP Sürüm Aliasları (CLI için)"
    ["alias_composer_header"]="# Composer Aliasları"
    ["aliases_added"]="PHP aliasları eklendi:"
    ["aliases_exist"]="PHP aliasları zaten mevcut:"
    ["setting_up_aliases"]="PHP shell aliasları ayarlanıyor..."
)

php_text() {
    local key="$1"
    local default_value="${PHP_TEXT_EN[$key]:-$key}"
    if [ "$CURRENT_LANG" = "tr" ]; then
        echo "${PHP_TEXT_TR[$key]:-$default_value}"
    else
        echo "$default_value"
    fi
}

# PHP versions with their installation scripts (7.0 to 8.5)
declare -A PHP_VERSIONS=(
    ["7.0"]="https://php.new/install/linux/7.0"
    ["7.1"]="https://php.new/install/linux/7.1"
    ["7.2"]="https://php.new/install/linux/7.2"
    ["7.3"]="https://php.new/install/linux/7.3"
    ["7.4"]="https://php.new/install/linux/7.4"
    ["8.0"]="https://php.new/install/linux/8.0"
    ["8.1"]="https://php.new/install/linux/8.1"
    ["8.2"]="https://php.new/install/linux/8.2"
    ["8.3"]="https://php.new/install/linux/8.3"
    ["8.4"]="https://php.new/install/linux/8.4"
    ["8.5"]="https://php.new/install/linux/8.5"
)

# Ordered list for menu display
PHP_VERSION_ORDER=("7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3" "8.4" "8.5")

# Find the correct php binary path for a version
find_php_binary() {
    local version="$1"
    local short_version="${version//./}"  # 7.4 -> 74
    
    # Check various paths including Herd-lite
    for path in "/usr/bin/php${version}" "/usr/bin/php${short_version}" \
                "/usr/local/bin/php${version}" "/usr/local/bin/php${short_version}" \
                "$HOME/.local/bin/php${version}" \
                "$HOME/.config/herd-lite/bin/php${version}" \
                "$HOME/.config/herd-lite/bin/php${short_version}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # Check if phpXX command exists
    if command -v "php${short_version}" &>/dev/null; then
        command -v "php${short_version}"
        return 0
    fi
    
    # Check for generic php if version matches current
    if command -v php &>/dev/null; then
        local current_php_version
        current_php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
        if [ "$current_php_version" = "$version" ]; then
            command -v php
            return 0
        fi
    fi
    
    return 1
}

# Find composer path
find_composer() {
    for path in "/usr/local/bin/composer" "/usr/bin/composer" \
                "$HOME/.composer/vendor/bin/composer" \
                "$HOME/.local/bin/composer" \
                "$HOME/.config/composer/vendor/bin/composer" \
                "$HOME/.config/herd-lite/bin/composer"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    if command -v composer &>/dev/null; then
        command -v composer
        return 0
    fi
    
    return 1
}

# Setup PHP aliases in shell config files
setup_php_aliases() {
    log_info_detail "$(php_text setting_up_aliases)"
    
    local shell_config=""
    local alias_marker="# PHP Version Aliases"
    
    # Determine which shell config file to use
    if [ -f "$HOME/.zshrc" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_config="$HOME/.bashrc"
    else
        # Create .bashrc if neither exists
        shell_config="$HOME/.bashrc"
        touch "$shell_config"
    fi
    
    # Check if aliases already exist
    if grep -q "$alias_marker" "$shell_config" 2>/dev/null; then
        # Remove existing PHP aliases block and recreate
        local temp_file
        temp_file=$(mktemp)
        sed '/# PHP Version Aliases/,/^$/d' "$shell_config" > "$temp_file"
        sed '/# PHP Sürüm Aliasları/,/^$/d' "$temp_file" > "$shell_config"
        rm -f "$temp_file"
    fi
    
    # Build aliases for installed PHP versions
    local php_aliases=""
    local composer_aliases=""
    local composer_path
    composer_path=$(find_composer)
    
    for version in "${PHP_VERSION_ORDER[@]}"; do
        local php_path
        if php_path=$(find_php_binary "$version"); then
            local short_version="${version//./}"  # 7.4 -> 74
            
            # PHP alias: p74, p80, etc.
            php_aliases+="alias p${short_version}='${php_path}'\n"
            
            # Composer alias: c74, c80, etc.
            if [ -n "$composer_path" ]; then
                composer_aliases+="alias c${short_version}='${php_path} ${composer_path}'\n"
            fi
        fi
    done
    
    # Only add if we have aliases
    if [ -n "$php_aliases" ]; then
        {
            echo ""
            echo "$(php_text alias_header)"
            echo -e "$php_aliases"
            if [ -n "$composer_aliases" ]; then
                echo "$(php_text alias_composer_header)"
                echo -e "$composer_aliases"
            fi
        } >> "$shell_config"
        
        log_success_detail "$(php_text aliases_added) $shell_config"
        
        # Show added aliases
        echo ""
        log_info_detail "$(php_text alias_header)"
        echo -e "$php_aliases" | while read -r line; do
            [ -n "$line" ] && log_info_detail "  $line"
        done
        
        if [ -n "$composer_aliases" ]; then
            log_info_detail "$(php_text alias_composer_header)"
            echo -e "$composer_aliases" | while read -r line; do
                [ -n "$line" ] && log_info_detail "  $line"
            done
        fi
    fi
}

# Install specific PHP version
install_php_version() {
    local version="$1"
    local install_url="${PHP_VERSIONS[$version]}"

    if [ -z "$install_url" ]; then
        log_error_detail "Unsupported PHP version: $version"
        return 1
    fi

    log_info_detail "$(php_text installing_php) ${version}..."
    log_info_detail "Installation URL: $install_url"

    # Execute the installation script
    if attach_tty_and_run "/bin/bash -c \"$(curl -fsSL $install_url)\""; then
        log_success_detail "$(php_text php_installed) ${version}"
        # Setup aliases after successful installation
        setup_php_aliases
        return 0
    else
        log_error_detail "Failed to install PHP $version"
        return 1
    fi
}

# List installed PHP versions
list_installed_php_versions() {
    local php_versions=()

    # Check for php binaries in common paths
    for version in "${PHP_VERSION_ORDER[@]}"; do
        if find_php_binary "$version" &>/dev/null; then
            php_versions+=("$version")
        fi
    done

    if [ ${#php_versions[@]} -eq 0 ]; then
        return 1
    fi

    printf '%s\n' "${php_versions[@]}"
    return 0
}

# Switch between PHP versions
switch_php_version() {
    local installed_versions
    if ! installed_versions=$(list_installed_php_versions 2>/dev/null); then
        log_warn_detail "$(php_text no_php_installed)"
        return 1
    fi

    if [ -z "$installed_versions" ]; then
        log_warn_detail "$(php_text no_php_installed)"
        return 1
    fi

    log_info_detail "$(php_text switching_php)..."
    log_info_detail "$(php_text select_php_version)"

    local versions_array
    readarray -t versions_array <<< "$installed_versions"

    local idx=1
    for version in "${versions_array[@]}"; do
        log_info_detail "  ${idx} - PHP ${version}"
        idx=$((idx + 1))
    done
    log_info_detail "  0 - İptal/Cancel"

    local selection
    read -r -p "$(php_text prompt_choice): " selection </dev/tty

    if [ "$selection" = "0" ] || [ -z "$selection" ]; then
        log_info_detail "PHP sürüm değiştirme iptal edildi."
        return 0
    fi

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#versions_array[@]}" ]; then
        log_error_detail "$(php_text invalid_choice): $selection"
        return 1
    fi

    local chosen_version="${versions_array[$((selection-1))]}"
    local php_binary
    php_binary=$(find_php_binary "$chosen_version")
    local success=false

    # Method 1: Check if update-alternatives is available
    if command -v update-alternatives &> /dev/null; then
        if [ -n "$php_binary" ]; then
            if sudo update-alternatives --set php "$php_binary" &> /dev/null; then
                success=true
            fi
        fi
    fi

    # Method 2: Create symbolic link
    if [ "$success" = false ] && [ -n "$php_binary" ]; then
        sudo ln -sf "$php_binary" /usr/bin/php 2>/dev/null || {
            # If sudo fails, try in user directory
            mkdir -p "$HOME/.local/bin"
            ln -sf "$php_binary" "$HOME/.local/bin/php"
            export PATH="$HOME/.local/bin:$PATH"
        }
        success=true
    fi

    if [ "$success" = true ]; then
        log_success_detail "$(php_text php_switched) ${chosen_version}"

        # Show current PHP version
        if command -v php &> /dev/null; then
            local current_version
            current_version=$(php -v 2>/dev/null | head -n1)
            log_info_detail "Current PHP: $current_version"
        fi
    else
        log_warn_detail "Could not update PHP system-wide. Please update your PATH manually."
    fi
}

# Install all PHP versions
install_all_php_versions() {
    log_info_detail "$(php_text installing_all)"

    local failed_versions=()
    local successful_versions=()

    for version in "${PHP_VERSION_ORDER[@]}"; do
        log_info_detail "Installing PHP $version..."
        if install_php_version "$version"; then
            successful_versions+=("$version")
        else
            failed_versions+=("$version")
        fi
        echo  # Add spacing between installations
    done

    log_success_detail "Successfully installed: ${successful_versions[*]}"
    if [ ${#failed_versions[@]} -gt 0 ]; then
        log_error_detail "Failed to install: ${failed_versions[*]}"
    fi

    # Setup aliases for all installed versions
    setup_php_aliases
    
    # Reload shell configurations
    reload_shell_configs
}

# Main menu function
main() {
    print_heading_panel "$(php_text menu_title)"

    while true; do
        echo
        log_info_detail "$(php_text menu_hint)"
        echo
        log_info_detail "  ${GREEN}PHP 7.x:${NC}"
        log_info_detail "    1 - $(php_text menu_option_70)"
        log_info_detail "    2 - $(php_text menu_option_71)"
        log_info_detail "    3 - $(php_text menu_option_72)"
        log_info_detail "    4 - $(php_text menu_option_73)"
        log_info_detail "    5 - $(php_text menu_option_74)"
        echo
        log_info_detail "  ${GREEN}PHP 8.x:${NC}"
        log_info_detail "    6 - $(php_text menu_option_80)"
        log_info_detail "    7 - $(php_text menu_option_81)"
        log_info_detail "    8 - $(php_text menu_option_82)"
        log_info_detail "    9 - $(php_text menu_option_83)"
        log_info_detail "   10 - $(php_text menu_option_84)"
        log_info_detail "   11 - $(php_text menu_option_85)"
        echo
        log_info_detail "  ${YELLOW}Yönetim/Management:${NC}"
        log_info_detail "   S - $(php_text menu_option_switch)"
        log_info_detail "   A - $(php_text menu_option_all)"
        log_info_detail "   0 - $(php_text menu_option0)"
        echo
        read -r -p "$(php_text prompt_choice): " menu_choice </dev/tty

        if [ -z "$(echo "$menu_choice" | tr -d '[:space:]')" ]; then
            log_warn_detail "$(php_text no_selection)"
            continue
        fi

        IFS=',' read -ra MENU_CHOICES <<< "$menu_choice"
        local exit_menu=false

        for raw_choice in "${MENU_CHOICES[@]}"; do
            choice=$(echo "$raw_choice" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
            case "$choice" in
                0)
                    exit_menu=true
                    break
                    ;;
                1)
                    install_php_version "7.0"
                    ;;
                2)
                    install_php_version "7.1"
                    ;;
                3)
                    install_php_version "7.2"
                    ;;
                4)
                    install_php_version "7.3"
                    ;;
                5)
                    install_php_version "7.4"
                    ;;
                6)
                    install_php_version "8.0"
                    ;;
                7)
                    install_php_version "8.1"
                    ;;
                8)
                    install_php_version "8.2"
                    ;;
                9)
                    install_php_version "8.3"
                    ;;
                10)
                    install_php_version "8.4"
                    ;;
                11)
                    install_php_version "8.5"
                    ;;
                S)
                    switch_php_version
                    ;;
                A)
                    install_all_php_versions
                    ;;
                *)
                    log_error_detail "$(php_text invalid_choice): $raw_choice"
                    ;;
            esac
        done

        if [ "$exit_menu" = true ]; then
            log_info_detail "$(php_text returning)"
            break
        fi
        
        # Prompt to continue
        read -r -p "$(php_text prompt_choice) [Enter]: " _tmp </dev/tty || true
    done
}

# Execute main function if script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi