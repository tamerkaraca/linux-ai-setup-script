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

# Bu betik artık tüm kurulum mantığı için utils.sh içerisindeki
# evrensel 'install_package' fonksiyonunu kullanır.

main() {
    # Görünen ad, paket türü, kontrol edilecek binary adı ve denenecek paket adayları
    install_package "Qoder CLI" "npm" "qodercli" \
        "@qoder-ai/qodercli" \
        "@qoderhq/qoder" \
        "@qoderhq/cli" \
        "@qoder/cli" \
        "qoder-cli" \
        "qoder"
}

# Betiği çalıştır
main "$@"