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
    echo "[ERROR] Unable to load utils.bash (tried $utils_local)" >&2
    exit 1
fi

if [ -f "$platform_local" ]; then
    # shellcheck source=/dev/null
    source "$platform_local"
elif declare -f source_module > /dev/null 2>&1; then
    source_module "utils/platform_detection.bash" "modules/utils/platform_detection.bash"
fi

CURRENT_LANG="${LANGUAGE:-en}"


declare -A PHP_TEXT_EN=(
    ["menu_title"]="PHP & Composer Installation Menu"
    ["menu_option1"]="Install PHP + Composer"
    ["menu_option2"]="Switch default PHP version"
    ["menu_option3"]="Install Composer only"
    ["menu_option0"]="Return to main menu"
    ["menu_hint"]="Use commas for multiple selections (e.g., 1,2)."
    ["prompt_choice"]="Your choice"
    ["returning"]="Returning to the main menu..."
    ["invalid_choice"]="Invalid selection."
    ["no_selection"]="No selection detected."
)

declare -A PHP_TEXT_TR=(
    ["menu_title"]="PHP & Composer Kurulum Menüsü"
    ["menu_option1"]="PHP + Composer kur"
    ["menu_option2"]="Varsayılan PHP sürümünü değiştir"
    ["menu_option3"]="Sadece Composer kur"
    ["menu_option0"]="Ana menüye dön"
    ["menu_hint"]="Birden fazla seçim için virgül kullanın (örn: 1,2)."
    ["prompt_choice"]="Seçiminiz"
    ["returning"]="Ana menüye dönülüyor..."
    ["invalid_choice"]="Geçersiz seçim."
    ["no_selection"]="Bir seçim yapılmadı."
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


# PHP sürüm listeleri
PHP_SUPPORTED_VERSIONS=("7.4" "8.1" "8.2" "8.3" "8.4" "8.5")
PHP_EXTENSION_PACKAGES=("mbstring" "zip" "gd" "tokenizer" "curl" "xml" "bcmath" "intl" "sqlite3" "pgsql" "mysql" "fpm")

# PHP deposu ve bağımlılık hazırlığı
ensure_php_repository() {

    if [ "$PKG_MANAGER" = "apt" ]; then
        log_info_detail "PHP için Ondřej Surý deposu kontrol ediliyor..."
        eval "$INSTALL_CMD software-properties-common ca-certificates apt-transport-https lsb-release gnupg"
        if ! grep -R "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q ondrej;
        then
            log_info_detail "Ondřej Surý PPA ekleniyor..."
            sudo add-apt-repository -y ppa:ondrej/php
        fi
        sudo apt update
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        if ! rpm -qa | grep -qi remi-release;
        then
            log_info_detail "Remi PHP deposu ekleniyor..."
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
            fi
            if [ "${ID:-}" = "fedora" ]; then
                local fedora_ver
                fedora_ver="${VERSION_ID:-}"
                if [ -z "$fedora_ver" ]; then
                    fedora_ver=$(rpm -E %fedora 2>/dev/null || echo "")
                fi
                if [ -n "$fedora_ver" ]; then
                    sudo "$PKG_MANAGER" install -y "https://rpms.remirepo.net/fedora/remi-release-${fedora_ver}.rpm"
                else
                    log_error_detail "Fedora sürümü tespit edilemedi."
                    return 1
                fi
            else
                local rhel_version
                rhel_version=$(rpm -E %rhel 2>/dev/null || echo "")
                if [ -n "$rhel_version" ]; then
                    sudo "$PKG_MANAGER" install -y "https://rpms.remirepo.net/enterprise/remi-release-${rhel_version}.rpm"
                else
                    log_warn_detail "Remi deposu otomatik eklenemedi. Lütfen manuel olarak yapılandırın."
                    return 1
                fi
            fi
        fi
    fi

    return 0
}

# PHP sürümü için binary yolu
resolve_php_binary_path() {
    local version="$1"
    local short_version
    short_version=$(echo "$version" | tr -d '.')
    local candidates=(
        "/usr/bin/php${version}"
        "/usr/bin/php${short_version}"
        "/usr/local/bin/php${version}"
        "/opt/remi/php${short_version}/root/usr/bin/php"
    )
    for candidate in "${candidates[@]}"; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

list_installed_php_versions() {
    declare -A installed=()
    for ver in "${PHP_SUPPORTED_VERSIONS[@]}"; do
        local path
        path=$(resolve_php_binary_path "$ver") || true
        if [ -n "$path" ]; then
            installed["$ver"]="$path"
        fi
    done
    if [ "${#installed[@]}" -eq 0 ]; then
        return 1
    fi
    for ver in "${!installed[@]}"; do
        printf "%s:::%s\n" "$ver" "${installed[$ver]}"
    done | sort
    return 0
}

switch_php_version() {
    mapfile -t INSTALLED_PHP < <(list_installed_php_versions 2>/dev/null)
    if [ "${#INSTALLED_PHP[@]}" -eq 0 ]; then
        log_info_detail "Sistemde kayıtlı PHP sürümü bulunamadı. Önce kurulum yapın."
        return 1
    fi
    if [ "${#INSTALLED_PHP[@]}" -eq 1 ]; then
        local only_ver only_path
        IFS=':::' read -r only_ver only_path <<< "${INSTALLED_PHP[0]}"
        log_info_detail "Yalnızca PHP ${only_ver} (${only_path}) bulundu; varsayılan zaten bu sürüm."
        return 0
    fi

    log_info_detail "Aktif PHP sürümünü değiştirmek için seçim yapın:"

    local idx=1
    for entry in "${INSTALLED_PHP[@]}"; do
        IFS=':::' read -r ver path <<< "$entry"
        log_info_detail "  ${idx} - PHP ${ver} (${path})"
        idx=$((idx + 1))
    done
    log_info_detail "  0 - İptal"

    local selection
    read -r -p "Seçiminiz: " selection </dev/tty

    if [ "$selection" = "0" ] || [ -z "$selection" ]; then
        log_info_detail "PHP sürüm değiştirme iptal edildi."
        return 0
    fi
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#INSTALLED_PHP[@]}" ]; then
        log_error_detail "Geçersiz seçim."
        return 1
    fi

    local chosen
    chosen="${INSTALLED_PHP[$((selection-1))]}"
    IFS=':::' read -r chosen_ver chosen_path <<< "$chosen"

    register_php_alternative "$chosen_ver" "$chosen_path"

    if command -v update-alternatives &> /dev/null; then
        if sudo update-alternatives --set php "$chosen_path" >/dev/null 2>&1; then
            log_success_detail "PHP varsayılanı PHP ${chosen_ver} olarak güncellendi."
        else
            log_warn_detail "update-alternatives başarısız oldu, sembolik bağ güncelleniyor."
            sudo ln -sf "$chosen_path" /usr/bin/php
        fi
    else
        sudo ln -sf "$chosen_path" /usr/bin/php
        log_info_detail "/usr/bin/php -> ${chosen_path} olarak güncellendi."
    fi

    if command -v php &> /dev/null; then
        local active
        active=$(php -v 2>/dev/null | head -n1)
        log_info_detail "Güncel PHP çıktısı: ${active}"
    fi
}

register_php_alternative() {
    local version="$1"
    local binary_path="$2"
    if [ ! -x "$binary_path" ]; then
        log_warn_detail "$binary_path mevcut değil, alternatives kaydı atlandı."
        return 1
    fi
    local priority
    priority=$(echo "$version" | tr -d '.')
    if command -v update-alternatives &> /dev/null;
    then
        sudo update-alternatives --install /usr/bin/php php "$binary_path" "$priority" >/dev/null 2>&1
    else
        sudo ln -sf "$binary_path" /usr/bin/php
    fi
}

install_composer() {
    log_info_detail "Composer kurulumu denetleniyor..."

    if command -v composer &> /dev/null;
    then
        log_success_detail "Composer zaten kurulu: $(composer --version)"
        return 0
    fi

    if ! command -v php &> /dev/null;
    then
        log_error_detail "Composer kurulumu için PHP gereklidir. Lütfen önce PHP kurun."
        return 1
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    if [ ! -d "$temp_dir" ]; then
        log_error_detail "Geçici dizin oluşturulamadı."
        return 1
    fi

    local installer_path="$temp_dir/composer-setup.php"
    local installer_sig_url="https://composer.github.io/installer.sig"
    local installer_url="https://getcomposer.org/installer"

    log_info_detail "Composer installer indiriliyor..."
    local expected_checksum
    expected_checksum=$(curl -sS "$installer_sig_url") || true
    if [ -z "$expected_checksum" ]; then
        log_error_detail "Installer imza bilgisi alınamadı."
        rm -rf "$temp_dir"
        return 1
    fi

    if ! php -r "copy('$installer_url', '$installer_path');"; then
        log_error_detail "Composer installer indirilemedi."
        rm -rf "$temp_dir"
        return 1
    fi

    local actual_checksum
    actual_checksum=$(php -r "echo hash_file('sha384', '$installer_path');")
    if [ "$expected_checksum" != "$actual_checksum" ]; then
        log_error_detail "İmza doğrulaması başarısız! Kurulum iptal edildi."
        rm -rf "$temp_dir"
        return 1
    fi

    log_info_detail "Installer doğrulandı, Composer yükleniyor..."
    if ! sudo php "$installer_path" --quiet --install-dir=/usr/local/bin --filename=composer;
    then
        log_error_detail "Composer kurulumu başarısız oldu."
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"

    if command -v composer &> /dev/null;
    then
        log_success_detail "Composer kurulumu tamamlandı: $(composer --version)"
        log_info_detail "Composer projeleri oluşturmak için: ${GREEN}composer init${NC}"
        log_info_detail "Bağımlılık kurmak için: ${GREEN}composer install${NC}"
    else
        log_warn_detail "Composer komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi
}

install_php_version() {
    local version="$1"
    log_info_detail "PHP ${version} ve Laravel eklentileri kuruluyor..."

    ensure_php_repository || return 1

    declare -A pkg_map=()
    local skipped_exts=()

    case "$PKG_MANAGER" in
        apt)
            pkg_map["php${version}"]=1
            pkg_map["php${version}-cli"]=1
            pkg_map["php${version}-common"]=1
            pkg_map["php${version}-fpm"]=1
            for ext in "${PHP_EXTENSION_PACKAGES[@]}"; do
                local pkg_name=""
                case "$ext" in
                    fpm)
                        continue
                        ;; 
                    tokenizer)
                        skipped_exts+=("tokenizer (PHP çekirdeği ile geliyor)")
                        continue
                        ;; 
                    *)
                        pkg_name="php${version}-${ext}"
                        ;; 
                esac
                pkg_map["$pkg_name"]=1
            done
            ;; 
        dnf|yum)
            local rpm_suffix
            rpm_suffix=$(echo "$version" | tr -d '.')
            local base="php${rpm_suffix}-php"
            pkg_map["${base}"]=1
            pkg_map["${base}-cli"]=1
            pkg_map["${base}-common"]=1
            pkg_map["${base}-fpm"]=1
            for ext in "${PHP_EXTENSION_PACKAGES[@]}"; do
                local ext_name="$ext"
                case "$ext" in
                    fpm)
                        continue
                        ;; 
                    tokenizer)
                        skipped_exts+=("tokenizer (php-common içinde)")
                        continue
                        ;; 
                    mysql)
                        ext_name="mysqlnd"
                        ;; 
                esac
                pkg_map["${base}-${ext_name}"]=1
            done
            ;; 
        pacman)
            log_warn_detail "Pacman depoları tek PHP sürümünü destekler. Varsayılan php paketi kurulacak."
            pkg_map["php"]=1
            pkg_map["php-fpm"]=1
            pkg_map["php-intl"]=1
            pkg_map["php-gd"]=1
            pkg_map["php-pgsql"]=1
            pkg_map["php-sqlite"]=1
            pkg_map["php-curl"]=1
            pkg_map["php-zip"]=1
            pkg_map["php-bcmath"]=1
            pkg_map["php-mbstring"]=1
            pkg_map["php-xml"]=1
            pkg_map["php-mysql"]=1
            ;; 
        *)
            log_error_detail "Bu paket yöneticisi için PHP kurulumu otomatikleştirilmedi."
            return 1
            ;; 
    esac

    local packages=()
    if [ ${#pkg_map[@]} -gt 0 ]; then
        mapfile -t packages < <(printf "%s\n" "${!pkg_map[@]}" | sort)
    fi

    if [ ${#packages[@]} -eq 0 ]; then
        log_error_detail "Kurulacak paket bulunamadı."
        return 1
    fi

    log_info_detail "Kurulacak paketler: ${GREEN}${packages[*]}${NC}"
    local install_command
    install_command="$INSTALL_CMD ${packages[*]}"
    eval "$install_command"

    if [ ${#skipped_exts[@]} -gt 0 ]; then
        log_info_detail "Paket gerektirmeyen/atlanan eklentiler: ${CYAN}${skipped_exts[*]}${NC}"
    fi

    local binary_path
    binary_path=$(resolve_php_binary_path "$version") || true
    if [ -n "$binary_path" ]; then
        register_php_alternative "$version" "$binary_path"
    fi
}

# Ana kurulum akışı
main() {
    print_heading_panel "$(php_text menu_title)"

    while true; do
        log_info_detail "$(php_text menu_hint)"
        log_info_detail "  1 - $(php_text menu_option1)"
        log_info_detail "  2 - $(php_text menu_option2)"
        log_info_detail "  3 - $(php_text menu_option3)"
        log_info_detail "  0 - $(php_text menu_option0)"
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
                local selected_versions=()
                while true; do
                    log_info_detail "Kurmak istediğiniz PHP sürümünü seçin:"
                    local i=1
                    for ver in "${PHP_SUPPORTED_VERSIONS[@]}"; do
                        log_info_detail "  ${i} - PHP ${ver}"
                        i=$((i+1))
                    done
                    log_info_detail "  0 - İptal"
                    read -r -p "Seçiminiz (örn: 1 veya 1,3,5): " choice </dev/tty

                    if [ "$choice" = "0" ]; then
                        selected_versions=()
                        break
                    fi

                    if [ -z "$(echo "$choice" | tr -d '[:space:]')" ]; then
                        log_warn_detail "Bir seçim yapmadınız."
                        continue
                    fi

                    IFS=',' read -ra VERSION_CHOICES <<< "$choice"
                    local valid=true
                    local tmp_versions=()
                    for c in "${VERSION_CHOICES[@]}"; do
                        c=$(echo "$c" | tr -d '[:space:]')
                        if ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 1 ] || [ "$c" -gt "${#PHP_SUPPORTED_VERSIONS[@]}" ]; then
                            log_error_detail "Geçersiz seçim: $c"
                            valid=false
                            break
                        fi
                        tmp_versions+=("${PHP_SUPPORTED_VERSIONS[$((c-1))]}")
                    done

                    if [ "$valid" = true ] && [ "${#tmp_versions[@]}" -gt 0 ]; then
                        selected_versions=("${tmp_versions[@]}")
                        break
                    fi
                done

                if [ "${#selected_versions[@]}" -gt 0 ]; then
                    for php_version_choice in "${selected_versions[@]}"; do
                        install_php_version "$php_version_choice" || continue
                    done
                    install_composer
                    reload_shell_configs
                fi
                ;;
                2)
                    switch_php_version
                ;;
                3)
                    install_composer
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

main
