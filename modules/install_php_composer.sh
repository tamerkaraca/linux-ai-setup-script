#!/bin/bash

# Ortak yardımcı fonksiyonları yükle
# shellcheck source=/dev/null
source "/mnt/d/ai/modules/utils.sh"

# PHP sürüm listeleri
PHP_SUPPORTED_VERSIONS=("7.4" "8.1" "8.2" "8.3" "8.4" "8.5")
PHP_EXTENSION_PACKAGES=("mbstring" "zip" "gd" "tokenizer" "curl" "xml" "bcmath" "intl" "sqlite3" "pgsql" "mysql" "fpm")

# PHP deposu ve bağımlılık hazırlığı
ensure_php_repository() {
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    if [ "$PKG_MANAGER" = "apt" ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} PHP için Ondřej Surý deposu kontrol ediliyor..."
        eval "$INSTALL_CMD software-properties-common ca-certificates apt-transport-https lsb-release gnupg"
        if ! grep -R "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q ondrej;
        then
            echo -e "${YELLOW}[BİLGİ]${NC} Ondřej Surý PPA ekleniyor..."
            sudo add-apt-repository -y ppa:ondrej/php
        fi
        sudo apt update
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        if ! rpm -qa | grep -qi remi-release;
        then
            echo -e "${YELLOW}[BİLGİ]${NC} Remi PHP deposu ekleniyor..."
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
                    echo -e "${RED}[HATA]${NC} Fedora sürümü tespit edilemedi."
                    return 1
                fi
            else
                local rhel_version
                rhel_version=$(rpm -E %rhel 2>/dev/null || echo "")
                if [ -n "$rhel_version" ]; then
                    sudo "$PKG_MANAGER" install -y "https://rpms.remirepo.net/enterprise/remi-release-${rhel_version}.rpm"
                else
                    echo -e "${RED}[HATA]${NC} Remi deposu otomatik eklenemedi. Lütfen manuel olarak yapılandırın."
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

register_php_alternative() {
    local version="$1"
    local binary_path="$2"
    if [ ! -x "$binary_path" ]; then
        echo -e "${YELLOW}[UYARI]${NC} $binary_path mevcut değil, alternatives kaydı atlandı."
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
    echo -e "${YELLOW}[BİLGİ]${NC} Composer kurulumu denetleniyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v composer &> /dev/null;
    then
        echo -e "${GREEN}[BAŞARILI]${NC} Composer zaten kurulu: $(composer --version)"
        return 0
    fi

    if ! command -v php &> /dev/null;
    then
        echo -e "${RED}[HATA]${NC} Composer kurulumu için PHP gereklidir. Lütfen önce PHP kurun."
        return 1
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    if [ ! -d "$temp_dir" ]; then
        echo -e "${RED}[HATA]${NC} Geçici dizin oluşturulamadı."
        return 1
    fi

    local installer_path="$temp_dir/composer-setup.php"
    local installer_sig_url="https://composer.github.io/installer.sig"
    local installer_url="https://getcomposer.org/installer"

    echo -e "${YELLOW}[BİLGİ]${NC} Composer installer indiriliyor..."
    local expected_checksum
    expected_checksum=$(curl -sS "$installer_sig_url") || true
    if [ -z "$expected_checksum" ]; then
        echo -e "${RED}[HATA]${NC} Installer imza bilgisi alınamadı."
        rm -rf "$temp_dir"
        return 1
    fi

    if ! php -r "copy('$installer_url', '$installer_path');"; then
        echo -e "${RED}[HATA]${NC} Composer installer indirilemedi."
        rm -rf "$temp_dir"
        return 1
    fi

    local actual_checksum
    actual_checksum=$(php -r "echo hash_file('sha384', '$installer_path');")
    if [ "$expected_checksum" != "$actual_checksum" ]; then
        echo -e "${RED}[HATA]${NC} İmza doğrulaması başarısız! Kurulum iptal edildi."
        rm -rf "$temp_dir"
        return 1
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} Installer doğrulandı, Composer yükleniyor..."
    if ! sudo php "$installer_path" --quiet --install-dir=/usr/local/bin --filename=composer;
    then
        echo -e "${RED}[HATA]${NC} Composer kurulumu başarısız oldu."
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"

    if command -v composer &> /dev/null;
    then
        echo -e "${GREEN}[BAŞARILI]${NC} Composer kurulumu tamamlandı: $(composer --version)"
        echo -e "${CYAN}[BİLGİ]${NC} Composer projeleri oluşturmak için: ${GREEN}composer init${NC}"
        echo -e "${CYAN}[BİLGİ]${NC} Bağımlılık kurmak için: ${GREEN}composer install${NC}"
    else
        echo -e "${YELLOW}[UYARI]${NC} Composer komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        return 1
    fi
}

install_php_version() {
    local version="$1"
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} PHP ${version} ve Laravel eklentileri kuruluyor..."
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
            echo -e "${YELLOW}[UYARI]${NC} Pacman depoları tek PHP sürümünü destekler. Varsayılan php paketi kurulacak."
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
            echo -e "${RED}[HATA]${NC} Bu paket yöneticisi için PHP kurulumu otomatikleştirilmedi."
            return 1
            ;; 
    esac

    local packages=()
    if [ ${#pkg_map[@]} -gt 0 ]; then
        mapfile -t packages < <(printf "%s\n" "${!pkg_map[@]}" | sort)
    fi

    if [ ${#packages[@]} -eq 0 ]; then
        echo -e "${RED}[HATA]${NC} Kurulacak paket bulunamadı."
        return 1
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} Kurulacak paketler: ${GREEN}${packages[*]}${NC}"
    local install_command
    install_command="$INSTALL_CMD ${packages[*]}"
    eval "$install_command"

    if [ ${#skipped_exts[@]} -gt 0 ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Paket gerektirmeyen/atlanan eklentiler: ${CYAN}${skipped_exts[*]}${NC}"
    fi

    local binary_path
    binary_path=$(resolve_php_binary_path "$version") || true
    if [ -n "$binary_path" ]; then
        register_php_alternative "$version" "$binary_path"
    fi
}

# Ana kurulum akışı
main() {
    detect_package_manager # Ensure PKG_MANAGER, INSTALL_CMD are set

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} PHP ve Composer Kurulumu Başlatılıyor..."
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    local php_version_choice
    while true; do
        echo -e "\n${YELLOW}Kurmak istediğiniz PHP sürümünü seçin:${NC}"
        local i=1
        for ver in "${PHP_SUPPORTED_VERSIONS[@]}"; do
            echo -e "  ${GREEN}${i}${NC} - PHP ${ver}"
            i=$((i+1))
        done
        echo -e "  ${RED}0${NC} - İptal"
        read -r -p "Seçiminiz (1-${#PHP_SUPPORTED_VERSIONS[@]}, veya 0): " choice </dev/tty

        if [ "$choice" = "0" ]; then
            echo -e "${YELLOW}[BİLGİ]${NC} PHP ve Composer kurulumu iptal edildi."
            return 0
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#PHP_SUPPORTED_VERSIONS[@]}" ]; then
            php_version_choice="${PHP_SUPPORTED_VERSIONS[$((choice-1))]}"
            break
        else
            echo -e "${RED}[HATA]${NC} Geçersiz seçim. Lütfen tekrar deneyin."
        fi
    done

    install_php_version "$php_version_choice"
    install_composer
    reload_shell_configs
    echo -e "${GREEN}[BAŞARILI]${NC} PHP ve Composer kurulumu tamamlandı!"
}

main
