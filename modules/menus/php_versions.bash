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

# Text definitions for PHP version installation
declare -A PHP_TEXT_EN=(
    ["menu_title"]="PHP Version Installation Menu"
    ["menu_option1"]="Install PHP 7.4"
    ["menu_option2"]="Install PHP 8.1"
    ["menu_option3"]="Install PHP 8.2"
    ["menu_option4"]="Install PHP 8.3"
    ["menu_option5"]="Install PHP 8.4"
    ["menu_option6"]="Install PHP 8.5"
    ["menu_option7"]="Install PHP 8.6"
    ["menu_option8"]="Switch PHP version"
    ["menu_option9"]="Install all PHP versions"
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
)

declare -A PHP_TEXT_TR=(
    ["menu_title"]="PHP Sürüm Kurulum Menüsü"
    ["menu_option1"]="PHP 7.4 kur"
    ["menu_option2"]="PHP 8.1 kur"
    ["menu_option3"]="PHP 8.2 kur"
    ["menu_option4"]="PHP 8.3 kur"
    ["menu_option5"]="PHP 8.4 kur"
    ["menu_option6"]="PHP 8.5 kur"
    ["menu_option7"]="PHP 8.6 kur"
    ["menu_option8"]="PHP sürümü değiştir"
    ["menu_option9"]="Tüm PHP sürümlerini kur"
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

# PHP versions with their installation scripts
declare -A PHP_VERSIONS=(
    ["7.4"]="https://php.new/install/linux/7.4"
    ["8.1"]="https://php.new/install/linux/8.1"
    ["8.2"]="https://php.new/install/linux/8.2"
    ["8.3"]="https://php.new/install/linux/8.3"
    ["8.4"]="https://php.new/install/linux/8.4"
    ["8.5"]="https://php.new/install/linux/8.5"
    ["8.6"]="https://php.new/install/linux/8.6"
)

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
    for version in "${!PHP_VERSIONS[@]}"; do
        if command -v "php${version}" &> /dev/null; then
            php_versions+=("$version")
        elif [ -x "/usr/bin/php${version}" ]; then
            php_versions+=("$version")
        elif [ -x "/usr/local/bin/php${version}" ]; then
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

    # Try different methods to switch PHP version
    local php_binary="php${chosen_version}"
    local success=false

    # Method 1: Check if update-alternatives is available
    if command -v update-alternatives &> /dev/null; then
        if [ -x "/usr/bin/$php_binary" ]; then
            if sudo update-alternatives --set php "/usr/bin/$php_binary" &> /dev/null; then
                success=true
            fi
        fi
    fi

    # Method 2: Create symbolic link
    if [ "$success" = false ]; then
        for path in "/usr/bin/$php_binary" "/usr/local/bin/$php_binary"; do
            if [ -x "$path" ]; then
                sudo ln -sf "$path" /usr/bin/php 2>/dev/null || {
                    # If sudo fails, try in user directory
                    mkdir -p "$HOME/.local/bin"
                    ln -sf "$path" "$HOME/.local/bin/php"
                    export PATH="$HOME/.local/bin:$PATH"
                }
                success=true
                break
            fi
        done
    fi

    # Method 3: Update PATH
    if [ "$success" = false ]; then
        log_warn_detail "Could not update PHP system-wide. Please update your PATH manually."
        log_info_detail "Add the following to your shell profile:"
        log_info_detail "export PATH=\"/path/to/php${chosen_version}:\$PATH\""
    else
        log_success_detail "$(php_text php_switched) ${chosen_version}"

        # Show current PHP version
        if command -v php &> /dev/null; then
            local current_version
            current_version=$(php -v 2>/dev/null | head -n1)
            log_info_detail "Current PHP: $current_version"
        fi
    fi
}

# Install all PHP versions
install_all_php_versions() {
    log_info_detail "$(php_text installing_all)"

    local failed_versions=()
    local successful_versions=()

    for version in "${!PHP_VERSIONS[@]}"; do
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

    # Reload shell configurations
    reload_shell_configs
}

# Main menu function
main() {
    print_heading_panel "$(php_text menu_title)"

    while true; do
        echo
        log_info_detail "$(php_text menu_hint)"
        log_info_detail "  1 - $(php_text menu_option1)"
        log_info_detail "  2 - $(php_text menu_option2)"
        log_info_detail "  3 - $(php_text menu_option3)"
        log_info_detail "  4 - $(php_text menu_option4)"
        log_info_detail "  5 - $(php_text menu_option5)"
        log_info_detail "  6 - $(php_text menu_option6)"
        log_info_detail "  7 - $(php_text menu_option7)"
        log_info_detail "  8 - $(php_text menu_option8)"
        log_info_detail "  9 - $(php_text menu_option9)"
        log_info_detail "  0 - $(php_text menu_option0)"
        echo
        read -r -p "$(php_text prompt_choice): " menu_choice </dev/tty

        if [ -z "$(echo "$menu_choice" | tr -d '[:space:]')" ]; then
            log_warn_detail "$(php_text no_selection)"
            continue
        fi

        IFS=',' read -ra MENU_CHOICES <<< "$menu_choice"
        local exit_menu=false

        for raw_choice in "${MENU_CHOICES[@]}"; do
            choice=$(echo "$raw_choice" | tr -d '[:space:]')
            case "${choice^^}" in
                0)
                    exit_menu=true
                    break
                    ;;
                1)
                    install_php_version "7.4"
                    reload_shell_configs
                    ;;
                2)
                    install_php_version "8.1"
                    reload_shell_configs
                    ;;
                3)
                    install_php_version "8.2"
                    reload_shell_configs
                    ;;
                4)
                    install_php_version "8.3"
                    reload_shell_configs
                    ;;
                5)
                    install_php_version "8.4"
                    reload_shell_configs
                    ;;
                6)
                    install_php_version "8.5"
                    reload_shell_configs
                    ;;
                7)
                    install_php_version "8.6"
                    reload_shell_configs
                    ;;
                8)
                    switch_php_version
                    ;;
                9)
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
    done
}

# Execute main function if script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi