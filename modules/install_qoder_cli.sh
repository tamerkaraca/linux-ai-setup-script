#!/bin/bash
set -euo pipefail

: "${NPM_LAST_INSTALL_PREFIX:=}"
: "${QODER_NPM_PACKAGE:=}"
: "${QODER_CLI_BUNDLE:=}"
: "${QODER_SKIP_NPM_PROBE:=false}"

QODER_PACKAGE_OVERRIDE="${QODER_NPM_PACKAGE}"
QODER_BUNDLE_OVERRIDE="${QODER_CLI_BUNDLE}"
QODER_SKIP_PACKAGE_PROBE="${QODER_SKIP_NPM_PROBE}"

# Ortak yardımcı fonksiyonları yükle
UTILS_PATH="./modules/utils.sh"
if [ ! -f "$UTILS_PATH" ] && [ -n "${BASH_SOURCE[0]:-}" ]; then
    UTILS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
fi
# shellcheck source=/dev/null
[ -f "$UTILS_PATH" ] && source "$UTILS_PATH"

# Renk değişkenleri yoksa tanımla (uzaktan çalıştırmalarda set -u güvenli)
: "${RED:=$'\033[0;31m'}"
: "${GREEN:=$'\033[0;32m'}"
: "${YELLOW:=$'\033[1;33m'}"
: "${BLUE:=$'\033[0;34m'}"
: "${CYAN:=$'\033[0;36m'}"
: "${NC:=$'\033[0m'}"

MIN_NPM_VERSION="${MIN_NPM_VERSION:-9.0.0}"

# Basit semver karşılaştırması (a >= b)
semver_ge() {
    local version_a="$1"
    local version_b="$2"
    if [ "$version_a" = "$version_b" ]; then
        return 0
    fi
    if [ "$(printf '%s\n%s\n' "$version_a" "$version_b" | sort -V | head -n1)" = "$version_b" ]; then
        return 0
    fi
    return 1
}

ensure_npm_available() {
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}[HATA]${NC} npm bulunamadı. Lütfen Node.js ve npm'i kurun (Ana Menü -> 3. Node.js ve İlgili Araçları Kur)."
        return 1
    fi
}

ensure_modern_npm() {
    local dry_run="${1:-false}"
    local current_version
    current_version=$(npm -v 2>/dev/null | tr -d '[:space:]')
    if [ -z "$current_version" ]; then
        echo -e "${RED}[HATA]${NC} npm sürümü okunamadı."
        return 1
    fi

    if semver_ge "$current_version" "$MIN_NPM_VERSION"; then
        return 0
    fi

    echo -e "${YELLOW}[UYARI]${NC} Mevcut npm sürümü (${current_version}) minimum gereksinim (${MIN_NPM_VERSION}) altında."
    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} npm install -g npm@latest (kullanıcı prefix)"
        return 0
    fi

    echo -e "${YELLOW}[BİLGİ]${NC} npm güncelleniyor..."
    if npm_install_global_with_fallback "npm@latest" "npm" true; then
        echo -e "${GREEN}[BAŞARILI]${NC} npm sürümü güncellendi: $(npm -v 2>/dev/null)"
        return 0
    fi

    echo -e "${RED}[HATA]${NC} npm güncellemesi başarısız oldu."
    return 1
}

install_npm_cli() {
    local display_name="$1"
    local npm_package="$2"
    local binary_name="$3"
    local dry_run="${4:-false}"

    echo -e "\n${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}[BİLGİ]${NC} ${display_name} kurulumu başlatılıyor (referans: https://docs.qoder.com/cli/quick-start)"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    if command -v "$binary_name" &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} ${display_name} zaten kurulu: $("$binary_name" --version 2>/dev/null)"
        return 0
    fi

    ensure_npm_available || return 1
    ensure_modern_npm "$dry_run" || return 1

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} npm install -g ${npm_package}"
    else
        echo -e "${YELLOW}[BİLGİ]${NC} ${display_name} npm ile kuruluyor..."
        if npm_install_global_with_fallback "$npm_package" "$display_name"; then
            echo -e "${GREEN}[BAŞARILI]${NC} ${display_name} kurulumu tamamlandı."
            reload_shell_configs silent
        else
            echo -e "${RED}[HATA]${NC} ${display_name} kurulumu başarısız oldu."
            return 1
        fi
    fi

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[BİLGİ]${NC} Kurulum atlandı (dry-run)."
        return 0
    fi

    if command -v "$binary_name" &> /dev/null; then
        echo -e "${GREEN}[BAŞARILI]${NC} ${display_name} başarıyla kuruldu: $("$binary_name" --version 2>/dev/null)"
    else
        echo -e "${RED}[HATA]${NC} ${display_name} kuruldu ancak '${binary_name}' komutu bulunamadı. PATH ayarlarınızı kontrol edin."
        echo -e "${YELLOW}[BİLGİ]${NC} Lütfen terminalinizi yeniden başlatın veya aşağıdaki komutları çalıştırın:"
        echo -e "${CYAN}  source ~/.bashrc${NC} (veya kullandığınız shell yapılandırma dosyası, örneğin ~/.zshrc)"
        echo -e "${CYAN}  hash -r${NC} (shell'in komut önbelleğini temizlemek için)"
        return 1
    fi
}

resolve_qoder_package() {
    local -n resolved_ref=$1
    local dry_run="${2:-false}"
    local explicit_package="${3:-}"
    local skip_probe="${4:-false}"
    local -a candidates=(
        "@qoderhq/qoder"
        "@qoderhq/cli"
        "@qoder/cli"
        "qoder-cli"
        "qoder"
    )

    if [ -n "$explicit_package" ]; then
        resolved_ref="$explicit_package"
        echo -e "${YELLOW}[BİLGİ]${NC} Qoder CLI paketi override edildi: ${explicit_package}"
        return 0
    fi

    if [ "$dry_run" = true ]; then
        resolved_ref="${candidates[0]}"
        echo -e "${YELLOW}[DRY-RUN]${NC} Varsayılan npm paketi: ${resolved_ref}"
        return 0
    fi

    if [ "$skip_probe" = "true" ]; then
        resolved_ref="${candidates[0]}"
        echo -e "${YELLOW}[UYARI]${NC} npm kayıt kontrolü atlandı. Varsayılan paket kullanılacak: ${resolved_ref}"
        echo -e "${YELLOW}[BİLGİ]${NC} Özel bir paket belirtmek için 'QODER_NPM_PACKAGE' veya '--package' parametresini kullanabilirsiniz."
        return 0
    fi

    local candidate
    for candidate in "${candidates[@]}"; do
        if npm view "$candidate" version >/dev/null 2>&1; then
            resolved_ref="$candidate"
            echo -e "${YELLOW}[BİLGİ]${NC} npm paketi bulundu: ${candidate}"
            return 0
        fi
    done

    resolved_ref="${candidates[0]}"
    echo -e "${YELLOW}[UYARI]${NC} npm kaydında doğrulanmış bir Qoder CLI paketi bulunamadı. Varsayılan paket kullanılacak: ${resolved_ref}"
    echo -e "${YELLOW}[BİLGİ]${NC} Bilinen paket adını 'QODER_NPM_PACKAGE=\"<paket>\"' veya '--package <paket>' ile belirtebilirsiniz."
    echo -e "${YELLOW}[BİLGİ]${NC} Güncel talimatlar için: https://docs.qoder.com/cli/quick-start"
    return 0
}

install_qoder_cli() {
    local dry_run="${1:-false}"
    if [ "$dry_run" != true ]; then
        ensure_npm_available || return 1
    fi
    local install_source=""
    if [ -n "$QODER_BUNDLE_OVERRIDE" ]; then
        if [ "$dry_run" = true ]; then
            echo -e "${YELLOW}[DRY-RUN]${NC} Yerel Qoder CLI paketi kullanılacak: ${QODER_BUNDLE_OVERRIDE}"
        else
            if [ ! -e "$QODER_BUNDLE_OVERRIDE" ]; then
                echo -e "${RED}[HATA]${NC} '--bundle' ile belirtilen dosya bulunamadı: ${QODER_BUNDLE_OVERRIDE}"
                return 1
            fi
            echo -e "${YELLOW}[BİLGİ]${NC} Yerel Qoder CLI paketi kullanılıyor: ${QODER_BUNDLE_OVERRIDE}"
        fi
        install_source="$QODER_BUNDLE_OVERRIDE"
    else
        local resolved_package=""
        if ! resolve_qoder_package resolved_package "$dry_run" "$QODER_PACKAGE_OVERRIDE" "$QODER_SKIP_PACKAGE_PROBE"; then
            return 1
        fi
        install_source="$resolved_package"
    fi
    install_npm_cli "Qoder CLI" "$install_source" "qoder" "$dry_run"
}

install_coder_cli() {
    local dry_run="${1:-false}"
    install_npm_cli "Coder CLI" "@qoder/coder" "coder" "$dry_run"
}

main() {
    local interactive_mode="true"
    local target_cli="qoder"
    local dry_run="false"

    if [[ $# -gt 0 && "$1" != --* ]]; then
        interactive_mode="${1}"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tool)
                target_cli="${2:-qoder}"
                shift
                ;;
            --package)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}[HATA]${NC} '--package' seçeneği bir değer gerektirir."
                    return 1
                fi
                QODER_PACKAGE_OVERRIDE="$2"
                shift
                ;;
            --bundle|--from-file)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}[HATA]${NC} '--bundle' seçeneği bir dosya yolu gerektirir."
                    return 1
                fi
                QODER_BUNDLE_OVERRIDE="$2"
                shift
                ;;
            --skip-probe)
                QODER_SKIP_PACKAGE_PROBE="true"
                ;;
            --both|--all)
                target_cli="both"
                ;;
            --dry-run)
                dry_run="true"
                ;;
            *)
                echo -e "${YELLOW}[UYARI]${NC} Bilinmeyen argüman: $1"
                ;;
        esac
        shift || true
    done

    case "$target_cli" in
        qoder)
            install_qoder_cli "$dry_run"
            ;;
        coder)
            install_coder_cli "$dry_run"
            ;;
        both)
            install_qoder_cli "$dry_run"
            install_coder_cli "$dry_run"
            ;;
        *)
            echo -e "${RED}[HATA]${NC} Geçersiz --tool değeri: ${target_cli}. 'qoder', 'coder' veya 'both' kullanın."
            return 1
            ;;
    esac

    if [ "$interactive_mode" != "false" ]; then
        echo -e "\n${YELLOW}[BİLGİ]${NC} ${target_cli} CLI kurulum adımları tamamlandı."
        echo -e "${YELLOW}[BİLGİ]${NC} Kurulumun tam olarak etkili olması için lütfen terminalinizi yeniden başlatın veya aşağıdaki komutları çalıştırın:"
        echo -e "${CYAN}  source ~/.bashrc${NC} (veya kullandığınız shell yapılandırma dosyası, örneğin ~/.zshrc)"
        echo -e "${CYAN}  hash -r${NC} (shell'in komut önbelleğini temizlemek için)"
    fi
}

main "$@"
