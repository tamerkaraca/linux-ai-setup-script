#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
if [ -f "./modules/utils.sh" ]; then
    source "./modules/utils.sh"
else
    BASE_URL="${BASE_URL:-https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/modules}"
    if command -v curl &> /dev/null; then
        # shellcheck disable=SC1090
        source <(curl -fsSL "$BASE_URL/utils.sh") || true
    fi
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
        echo -e "\n${YELLOW}${INFO_TAG}${NC} PHP için Ondřej Surý deposu kontrol ediliyor..."
        eval "$INSTALL_CMD software-properties-common ca-certificates apt-transport-https lsb-release gnupg"
        if ! grep -R "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q ondrej;
        then
            echo -e "${YELLOW}${INFO_TAG}${NC} Ondřej Surý PPA ekleniyor..."
            sudo add-apt-repository -y ppa:ondrej/php
        fi
        sudo apt update
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        if ! rpm -qa | grep -qi remi-release;
        then
            echo -e "${YELLOW}${INFO_TAG}${NC} Remi PHP deposu ekleniyor..."
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
                    echo -e "${RED}${ERROR_TAG}${NC} Fedora sürümü tespit edilemedi."
                    return 1
                fi
            else
                local rhel_version
                rhel_version=$(rpm -E %rhel 2>/dev/null || echo "")
                if [ -n "$rhel_version" ]; then
                    sudo "$PKG_MANAGER" install -y "https://rpms.remirepo.net/enterprise/remi-release-${rhel_version}.rpm"
                else
                    echo -e "${RED}${ERROR_TAG}${NC} Remi deposu otomatik eklenemedi. Lütfen manuel olarak yapılandırın."
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
        echo -e "${YELLOW}${INFO_TAG}${NC} Sistemde kayıtlı PHP sürümü bulunamadı. Önce kurulum yapın."
        return 1
    fi
    if [ "${#INSTALLED_PHP[@]}" -eq 1 ]; then
        local only_ver only_path
        IFS=':::' read -r only_ver only_path <<< "${INSTALLED_PHP[0]}"
        echo -e "${YELLOW}${INFO_TAG}${NC} Yalnızca PHP ${only_ver} (${only_path}) bulundu; varsayılan zaten bu sürüm."
        return 0
    fi

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} Aktif PHP sürümünü değiştirmek için seçim yapın:"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local idx=1
    for entry in "${INSTALLED_PHP[@]}"; do
        IFS=':::' read -r ver path <<< "$entry"
        echo -e "  ${GREEN}${idx}${NC} - PHP ${ver} (${path})"
        idx=$((idx + 1))
    done
    echo -e "  ${RED}0${NC} - İptal"

    local selection
    read -r -p "Seçiminiz: " selection </dev/tty

    if [ "$selection" = "0" ] || [ -z "$selection" ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} PHP sürüm değiştirme iptal edildi."
        return 0
    fi
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#INSTALLED_PHP[@]}" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} Geçersiz seçim."
        return 1
    fi

    local chosen
    chosen="${INSTALLED_PHP[$((selection-1))]}"
    IFS=':::' read -r chosen_ver chosen_path <<< "$chosen"

    register_php_alternative "$chosen_ver" "$chosen_path"

    if command -v update-alternatives &> /dev/null; then
        if sudo update-alternatives --set php "$chosen_path" >/dev/null 2>&1; then
            echo -e "${GREEN}${SUCCESS_TAG}${NC} PHP varsayılanı PHP ${chosen_ver} olarak güncellendi."
        else
            echo -e "${YELLOW}${WARN_TAG}${NC} update-alternatives başarısız oldu, sembolik bağ güncelleniyor."
            sudo ln -sf "$chosen_path" /usr/bin/php
        fi
    else
        sudo ln -sf "$chosen_path" /usr/bin/php
        echo -e "${GREEN}${INFO_TAG}${NC} /usr/bin/php -> ${chosen_path} olarak güncellendi."
    fi

    if command -v php &> /dev/null; then
        local active
        active=$(php -v 2>/dev/null | head -n1)
        echo -e "${CYAN}${INFO_TAG}${NC} Güncel PHP çıktısı: ${GREEN}${active}${NC}"
    fi
}

register_php_alternative() {
    local version="$1"
    local binary_path="$2"
    if [ ! -x "$binary_path" ]; then
        echo -e "${YELLOW}${WARN_TAG}${NC} $binary_path mevcut değil, alternatives kaydı atlandı."
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
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} Composer kurulumu denetleniyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v composer &> /dev/null;
    then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} Composer zaten kurulu: $(composer --version)"
        return 0
    fi

    if ! command -v php &> /dev/null;
    then
        echo -e "${RED}${ERROR_TAG}${NC} Composer kurulumu için PHP gereklidir. Lütfen önce PHP kurun."
        return 1
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    if [ ! -d "$temp_dir" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} Geçici dizin oluşturulamadı."
        return 1
    fi

    local installer_path="$temp_dir/composer-setup.php"
    local installer_sig_url="https://composer.github.io/installer.sig"
    local installer_url="https://getcomposer.org/installer"

    echo -e "${YELLOW}${INFO_TAG}${NC} Composer installer indiriliyor..."
    local expected_checksum
    expected_checksum=$(curl -sS "$installer_sig_url") || true
    if [ -z "$expected_checksum" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} Installer imza bilgisi alınamadı."
        rm -rf "$temp_dir"
        return 1
    fi

    if ! php -r "copy('$installer_url', '$installer_path');"; then
        echo -e "${RED}${ERROR_TAG}${NC} Composer installer indirilemedi."
        rm -rf "$temp_dir"
        return 1
    fi

    local actual_checksum
    actual_checksum=$(php -r "echo hash_file('sha384', '$installer_path');")
    if [ "$expected_checksum" != "$actual_checksum" ]; then
        echo -e "${RED}${ERROR_TAG}${NC} İmza doğrulaması başarısız! Kurulum iptal edildi."
        rm -rf "$temp_dir"
        return 1
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} Installer doğrulandı, Composer yükleniyor..."
    if ! sudo php "$installer_path" --quiet --install-dir=/usr/local/bin --filename=composer;
    then
        echo -e "${RED}${ERROR_TAG}${NC} Composer kurulumu başarısız oldu."
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"

    if command -v composer &> /dev/null;
    then
        echo -e "${GREEN}${SUCCESS_TAG}${NC} Composer kurulumu tamamlandı: $(composer --version)"
        echo -e "${CYAN}${INFO_TAG}${NC} Composer projeleri oluşturmak için: ${GREEN}composer init${NC}"
        echo -e "${CYAN}${INFO_TAG}${NC} Bağımlılık kurmak için: ${GREEN}composer install${NC}"
    else
        echo -e "${YELLOW}${WARN_TAG}${NC} Composer komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi
}

install_php_version() {
    local version="$1"
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${INFO_TAG}${NC} PHP ${version} ve Laravel eklentileri kuruluyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

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
            echo -e "${YELLOW}${WARN_TAG}${NC} Pacman depoları tek PHP sürümünü destekler. Varsayılan php paketi kurulacak."
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
            echo -e "${RED}${ERROR_TAG}${NC} Bu paket yöneticisi için PHP kurulumu otomatikleştirilmedi."
            return 1
            ;; 
    esac

    local packages=()
    if [ ${#pkg_map[@]} -gt 0 ]; then
        mapfile -t packages < <(printf "%s\n" "${!pkg_map[@]}" | sort)
    fi

    if [ ${#packages[@]} -eq 0 ]; then
        echo -e "${RED}${ERROR_TAG}${NC} Kurulacak paket bulunamadı."
        return 1
    fi

    echo -e "${YELLOW}${INFO_TAG}${NC} Kurulacak paketler: ${GREEN}${packages[*]}${NC}"
    local install_command
    install_command="$INSTALL_CMD ${packages[*]}"
    eval "$install_command"

    if [ ${#skipped_exts[@]} -gt 0 ]; then
        echo -e "${YELLOW}${INFO_TAG}${NC} Paket gerektirmeyen/atlanan eklentiler: ${CYAN}${skipped_exts[*]}${NC}"
    fi

    local binary_path
    binary_path=$(resolve_php_binary_path "$version") || true
    if [ -n "$binary_path" ]; then
        register_php_alternative "$version" "$binary_path"
    fi
}

# Ana kurulum akışı
main() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║%*s║${NC}\n" -43 " $(php_text menu_title) "
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    while true; do
        echo -e "\n${YELLOW}$(php_text menu_hint)${NC}"
        echo -e "  ${GREEN}1${NC} - $(php_text menu_option1)"
        echo -e "  ${GREEN}2${NC} - $(php_text menu_option2)"
        echo -e "  ${GREEN}3${NC} - $(php_text menu_option3)"
        echo -e "  ${RED}0${NC} - $(php_text menu_option0)"
        read -r -p "${YELLOW}$(php_text prompt_choice):${NC} " menu_choice </dev/tty

        if [ -z "$(echo "$menu_choice" | tr -d '[:space:]')" ]; then
            echo -e "${YELLOW}${WARN_TAG}${NC} $(php_text no_selection)"
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
                    echo -e "\n${YELLOW}Kurmak istediğiniz PHP sürümünü seçin:${NC}"
                    local i=1
                    for ver in "${PHP_SUPPORTED_VERSIONS[@]}"; do
                        echo -e "  ${GREEN}${i}${NC} - PHP ${ver}"
                        i=$((i+1))
                    done
                    echo -e "  ${RED}0${NC} - İptal"
                    read -r -p "Seçiminiz (örn: 1 veya 1,3,5): " choice </dev/tty

                    if [ "$choice" = "0" ]; then
                        selected_versions=()
                        break
                    fi

                    if [ -z "$(echo "$choice" | tr -d '[:space:]')" ]; then
                        echo -e "${YELLOW}${WARN_TAG}${NC} Bir seçim yapmadınız."
                        continue
                    fi

                    IFS=',' read -ra VERSION_CHOICES <<< "$choice"
                    local valid=true
                    local tmp_versions=()
                    for c in "${VERSION_CHOICES[@]}"; do
                        c=$(echo "$c" | tr -d '[:space:]')
                        if ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 1 ] || [ "$c" -gt "${#PHP_SUPPORTED_VERSIONS[@]}" ]; then
                            echo -e "${RED}${ERROR_TAG}${NC} Geçersiz seçim: $c"
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
                    echo -e "${RED}${ERROR_TAG}${NC} $(php_text invalid_choice): $raw_choice"
                    ;;
            esac
        done

        if [ "$exit_menu" = true ]; then
            echo -e "${YELLOW}${INFO_TAG}${NC} $(php_text returning)"
            break
        fi
    done
}

main
