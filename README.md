# 🌈 AI Development Environment Setup Script

> Single-command bootstrapper for a modern AI workstation on Linux. Interactive menus, remote-safe modules, colorful banners, and bilingual guidance (English & Turkish).

---

## 📚 Table of Contents

1. [English Guide](#-english-guide)
   - [Overview](#overview)
   - [Architecture](#architecture)
   - [Requirements](#requirements)
   - [Installation](#installation)
   - [Primary Menu Reference](#primary-menu-reference)
   - [CLI & Framework Sub-menus](#cli--framework-sub-menus)
   - [Usage Notes](#usage-notes)
   - [Troubleshooting](#troubleshooting)
   - [Contributing](#contributing)
   - [Credits](#credits)
   - [License](#license)
2. [Türkçe Rehber](#-türkçe-rehber)

---

## 🇬🇧 English Guide

### Overview

`setup` prepares a Linux workstation for AI development. It auto-detects the package manager, resolves Windows CRLF line endings, installs system dependencies, bootstraps Python/Node/PHP stacks, and exposes curated menus for AI CLIs (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, OpenAI Codex, Copilot CLI), AI frameworks (SuperGemini, SuperQwen, SuperClaude), GitHub CLI, MCP server maintenance, and GLM-4.6 configuration.

### Architecture

| Component | Description |
|-----------|-------------|
| **Self-healing launcher** | Detects CRLF, re-runs itself after fixing permissions/line endings. |
| **Remote-safe modules** | When invoked via `bash -c "$(curl …)"`, `setup` downloads helper modules to a temp directory and exports helper functions so nested scripts operate as if run locally. |
| **Banner system** | `modules/banner.sh` renders rainbow 3D headers using the `toilet` CLI (auto-installed if missing). |
| **Menu runner** | `run_module` prefers local `./modules/*.sh`; otherwise downloads from GitHub and passes environment variables (`PKG_MANAGER`, `INSTALL_CMD` etc.) to sub-processes. |

### Requirements

- Linux distribution exposing `apt`, `dnf`, `yum`, or `pacman`.
- `bash` 5+, `sudo` rights, internet access.
- `curl` (auto-installed when missing for remote runs).
- Optional: `dos2unix`, `shellcheck`, `jq` (installed automatically when relevant).

`setup` also installs `toilet` for the intro banner the first time it runs.

### Installation

#### 1. Quick One-Liner (recommended)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/setup)"
```

or with `wget`:

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/setup)"
```

#### 2. Local Clone

```bash
git clone https://github.com/tamerkaraca/linux-ai-setup-script.git
cd linux-ai-setup-script
chmod +x setup
bash -n setup && shellcheck setup  # optional
./setup
```

### Primary Menu Reference

| Option | Description |
|--------|-------------|
| `1` | Update system packages + install essentials (`curl`, `wget`, `git`, `jq`, `zip`, compilers). |
| `2` | Install Python toolchain: Python 3, Pip, ensurepip fallback, Pipx, UV; auto-reloads shell RC files. |
| `3` | Install Node.js tooling: NVM, latest LTS node, npm upgrade guard, Bun. |
| `4` | Install AI CLI tools (opens sub-menu). |
| `5` | Install AI frameworks (opens sub-menu; handles Pipx, GLM prompts, tty-safe runs). |
| `6` | Git configuration (name/email, signing, alias suggestions). |
| `7` | GLM-4.6 Claude Code configuration (masked key display, base URL management). |
| `8` | PHP & Composer installer with selectable versions and Laravel-friendly extensions. |
| `9` | GitHub CLI install with official repo keys. |
| `10` | Remove AI frameworks (Super* uninstall + cleanup). |
| `11` | MCP server management (list, clean `~/.gemini`, `~/.qwen`, `~/.claude`). |
| `A` | Install everything sequentially (skips interactive logins, prints summaries). |
| `0` | Exit. |

### CLI & Framework Sub-menus

#### AI CLI Menu
- Multi-select (comma-separated) and “install all” options.
- During batches, installers skip interactive logins and later print a summary reminding you which commands (`claude login`, `gemini auth`, `copilot auth login`, etc.) still need attention.

#### AI Framework Menu
- Ensures Pipx exists.
- Each framework uses `attach_tty_and_run` so pipx-installed binaries (SuperGemini/SuperQwen/SuperClaude) can prompt for API keys even when you launched via curl.
- TTY fallback automatically reuses `/dev/tty` when available.

### Usage Notes

- **Environment reloads:** PATH updates for `pipx`, `uv`, `nvm`, `bun`, `gh`, etc., are appended to `~/.bashrc`, `~/.zshrc`, and `~/.profile`. The script auto-sources whichever exists so new commands are usable immediately.
- **Remote execution:** The menu structure, colorized logs, and sub-modules behave the same whether you cloned locally or piped via curl.
- **API keys:** Super* installers guide you through provider portals (Gemini, Anthropic, OpenAI). GLM configuration masks existing keys (`abcd***wxyz`) and only replaces them if you supply a new value.
- **TTY requirements:** The Claude Code, SuperQwen, and SuperClaude installers now route to `/dev/tty`, preventing Ink-based CLIs from exiting with “Raw mode is not supported”.

### Troubleshooting

| Symptom | Resolution |
|---------|------------|
| `curl: (3) URL rejected: No host part` | Ensure you are on the latest `setup` (≥ `7d4ee0a`). The script now exports `SCRIPT_BASE_URL` and caches modules with fully qualified URLs. |
| `mask_secret: command not found` | Pull latest changes; GLM config now sources `modules/utils.sh` even in remote runs. |
| `SuperQwen install` aborts without prompting | Fixed by `attach_tty_and_run`; rerun option `5` → SuperQwen. |
| `toilet` not found | The script installs it automatically; rerun option `1` or `setup`. |
| CLI still missing after install | Re-open the terminal or run `source ~/.bashrc`; confirm `$PATH` contains `~/.local/bin` and `~/.nvm`. |
| `pip` errors about externally-managed environment | `install_pip` now falls back to `ensurepip`, distro packages, or `get-pip.py --break-system-packages`. Re-run option `2`. |

### Contributing

1. Fork the repository and create a feature branch.
2. Run `shellcheck` on touched scripts plus `bash -n` for syntax checks.
3. Update README/localized docs when adding menus or modules.
4. Submit a PR describing motivation, impacted scripts, and sample output (screenshots/logs for interactive flows help reviewers).
5. For module changes, verify both local and remote (`bash -c "$(curl …)"`) workflows.

### Credits

- **Maintainer:** Tamer Karaca (@tamerkaraca)  
- **ASCII & Banner Styling:** Inspired by `toilet` community themes.  
- **Framework Authors:** SuperGemini/SuperQwen/SuperClaude teams, Anthropic, Google, OpenAI, GitHub Copilot CLI contributors.

### License

This project is licensed under the **MIT License**. See [`LICENSE`](./LICENSE) for full text.

---

## 🇹🇷 Türkçe Rehber

### Genel Bakış

`setup`, Linux tabanlı geliştirici makinelerinde uçtan uca AI ortamı kurar. Paket yöneticisini otomatik saptar, CRLF düzeltir, Python/Node/PHP ekosistemlerini kurar, AI CLI & framework menüleri sunar, GLM-4.6 yapılandırmasını ve MCP temizliğini yönetir.

### Mimari

| Bileşen | Açıklama |
|---------|---------|
| **Kendini onaran başlatıcı** | CRLF algılar, izin/dosya sorunlarını düzeltip script’i yeniden başlatır. |
| **Uzaktan güvenli modüller** | `bash -c "$(curl …)"` yöntemiyle çalıştırıldığında yardımcı modülleri geçici dizine indirir ve alt süreçlerle paylaşır. |
| **Banner sistemi** | `toilet` aracı ile gökkuşağı renkli 3B başlıklar oluşturur (eksikse otomatik kurulur). |
| **Menü çalıştırıcısı** | Önce yerel `./modules/*.sh` dosyalarını, yoksa GitHub sürümlerini kullanır. |

### Gereksinimler

- `apt`, `dnf`, `yum` veya `pacman` içeren Linux dağıtımı.
- `bash` 5+, `sudo` hakları, aktif internet bağlantısı.
- `curl` (uzaktan kurulum için zorunlu).
- `toilet` aracı script tarafından gerekirse otomatik kurulur.

### Kurulum

#### 1. Tek Satırlık Kurulum

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/setup)"
```

veya `wget` ile:

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/tamerkaraca/linux-ai-setup-script/main/setup)"
```

#### 2. Yerel Klon

```bash
git clone https://github.com/tamerkaraca/linux-ai-setup-script.git
cd linux-ai-setup-script
chmod +x setup
bash -n setup && shellcheck setup  # isteğe bağlı
./setup
```

### Ana Menü Özeti

| Seçenek | Açıklama |
|---------|---------|
| `1` | Sistem güncellemesi + temel paketler. |
| `2` | Python + Pip/Pipx/UV kurulumu, PATH güncellemeleri. |
| `3` | Node.js/NVM/Bun kurulumu. |
| `4` | AI CLI araçları (alt menü). |
| `5` | AI Frameworkleri (SuperGemini/SuperQwen/SuperClaude). |
| `6` | Git yapılandırması. |
| `7` | GLM-4.6 ayarları (anahtar maskeleme). |
| `8` | PHP & Composer kurulum sihirbazı. |
| `9` | GitHub CLI. |
| `10` | AI Framework kaldırma menüsü. |
| `11` | MCP sunucularını listeleme/temizleme. |
| `A` | Hepsini sırayla kurar (interaktif girişler daha sonra hatırlatılır). |
| `0` | Çıkış. |

### Alt Menü Detayları

- **AI CLI Menüsü:** Virgülle çoklu seçim yapabilirsiniz. Toplu kurulumda `claude login`, `gemini auth` vb. komutlar özet olarak yazdırılır.
- **AI Framework Menüsü:** Pipx kontrolü yapar, API anahtar istemlerinde `/dev/tty` kullanır; böylece `SuperQwen install` gibi komutlar uzaktan bile bekleme ekranına düşer.

### Kullanım Notları

- **PATH güncellemeleri** script tarafından otomatik `source` edilir; yeni komutlar aynı terminalde erişilebilir.
- **API anahtarları** maskelenerek gösterilir, boş bırakılırsa mevcut değer korunur.
- **TTY gereksinimleri** `attach_tty_and_run` ile çözüldü; artık `Raw mode is not supported` hatası alınmaz.
- **Uzaktan çalışma** sırasında modüller geçici dizine alınır ve tekrar kullanılmak üzere önbelleğe atılır.

### Sorun Giderme

- `curl: (3)` hatası: En güncel `setup` sürümünü kullanın; `SCRIPT_BASE_URL` artık her alt süreçte mevcut.
- `mask_secret` hatası: GLM menüsü artık utils’i otomatik yüklüyor.
- SuperQwen/SuperClaude menüsü girdi beklemiyorsa: Güncel sürüme geçin; `attach_tty_and_run` eklendi.
- Komut bulunamıyorsa: Terminali kapatıp açın veya `source ~/.bashrc` çalıştırın.

### Katkı

1. Fork + branch açın.
2. Script değişikliklerinde `shellcheck` ve `bash -n` çalıştırın.
3. README/TR bölümlerini yeni özelliklerle güncelleyin.
4. PR özetine ekran görüntüsü veya log ekleyin.

### Emek Verenler

- **Geliştirici:** Tamer Karaca  
- **Topluluk:** Super* framework ekipleri, açık kaynak katkıcıları.  
- **Banner:** `toilet` projesi ve ASCII sanatçıları.

### Lisans

Bu proje **MIT Lisansı** ile dağıtılır. Ayrıntılar için [LICENSE](./LICENSE) dosyasına bakın.
