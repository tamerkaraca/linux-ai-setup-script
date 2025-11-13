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
   - [Genel Bakış](#genel-bakış)
   - [Mimari](#mimari)
   - [Gereksinimler](#gereksinimler)
   - [Kurulum](#kurulum)
   - [Ana Menü Özeti](#ana-menü-özeti)
   - [Alt Menü Detayları](#alt-menü-detayları)
   - [Kullanım Notları](#kullanım-notları)
   - [Sorun Giderme](#sorun-giderme)
   - [Katkı](#katkı)
   - [Emek Verenler](#emek-verenler)
   - [Lisans](#lisans)

---

## 🇬🇧 English Guide

### Overview

`setup` prepares a Linux workstation for AI development. It auto-detects the package manager, resolves Windows CRLF line endings, installs system dependencies, bootstraps Python/Node/PHP stacks, and exposes curated menus for AI CLIs, AI frameworks, and auxiliary tools. The UI is bilingual: English is the default, Turkish is auto-selected when your locale starts with `tr`, and you can toggle languages anytime via menu option `L`.

### Architecture

| Component | Description |
|-----------|-------------|
| **Self-healing launcher** | Detects CRLF, re-runs itself after fixing permissions/line endings. |
| **Remote-safe modules** | When invoked via `bash -c "$(curl …)"`, `setup` downloads helper modules to a temp directory and exports helper functions so nested scripts operate as if run locally. |
| **Banner system** | `modules/banner.sh` now renders wide box-drawing panels with pure Bash, so no external banner CLI has to be installed. |
| **Menu runner** | `run_module` prefers local `./modules/*.sh`; otherwise downloads from GitHub and passes environment variables (`PKG_MANAGER`, `INSTALL_CMD` etc.) to sub-processes. |

### Requirements

- Linux distribution exposing `apt`, `dnf`, `yum`, or `pacman`.
- `bash` 5+, `sudo` rights, internet access.
- `curl` (auto-installed when missing for remote runs).
- Optional: `dos2unix`, `shellcheck`, `jq` (installed automatically when relevant).

The banner renderer ships with the repo, so no extra packages are fetched just to print headers.

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
| `3` | Open the Node.js tooling sub-menu (NVM + Node LTS, Bun, CLI extras). |
| `4` | Install AI CLI tools (opens sub-menu). |
| `5` | Install AI frameworks (opens sub-menu; handles Pipx, GLM prompts, tty-safe runs). |
| `6` | Git configuration (name/email, signing, alias suggestions). |
| `7` | Claude Code provider menu (GLM-4.6 or Moonshot kimi-k2 with masked key + base URL helpers). |
| `8` | Install Auxiliary AI Tools (OpenSpec, Agents, etc.). |
| `9` | Install PHP and Composer with selectable versions and Laravel-friendly extensions. |
| `10` | Install GitHub CLI with official repo keys. |
| `11` | Remove AI frameworks (Super* uninstall + cleanup). |
| `12` | MCP server management (list, clean `~/.gemini`, `~/.qwen`, `~/.claude`). |
| `L` | Switch the interface language (English ↔ Türkçe, auto-detected default). |
| `A` | Install everything sequentially (skips interactive logins, prints summaries). |
| `0` | Exit. |

### CLI & Framework Sub-menus

#### Node.js Tooling Menu
Option `3` now opens an interactive menu that accepts comma-separated selections (`1,3`) and also exposes a `4` shortcut to run every component. Each choice calls the hardened installers under `modules/install_nodejs_tools.sh`, so you can mix-and-match without re-running the entire stack.

| Option | Component | Highlights |
|--------|-----------|------------|
| `1` | Node.js via NVM | Installs/updates NVM, refreshes shell RC files, and installs the latest LTS release. |
| `2` | Bun runtime | Runs Bun’s official installer, adds `~/.bun/bin` to PATH, and prints the detected version. |
| `3` | Node CLI extras | Enables Corepack and installs `pnpm` + `yarn` globally, perfect for repo scripts and CI. |
| `4` | Install every component | Executes options `1-3` sequentially. |
| `0` | Return to main menu | No changes applied. |

#### AI CLI Menu
The sub-menu accepts comma-separated selections (`1,3,7`) or a `14` shortcut that installs every CLI sequentially. Interactive runs pause for logins, whereas batch runs remember the missing auth commands and print them in a summary.

| Option | Tool | Highlights |
|--------|------|------------|
| `1` | Claude Code CLI | Attaches to `/dev/tty` so Anthropic’s Ink prompts work even during remote runs. |
| `2` | Gemini CLI | Requires Node.js ≥ 20, performs npm fallback installs, and reminds you to run `gemini auth`. |
| `3` | OpenCode CLI | Handles remote-safe installs for the OpenCode beta tooling and prints `opencode login` hints. |
| `4` | Qoder CLI | Probes several npm scopes and accepts overrides (`QODER_NPM_PACKAGE`, `QODER_CLI_BUNDLE`, `--skip-probe`) plus local bundle installs. |
| `5` | Qwen CLI | Enforces Node.js ≥ 18, bootstraps Node when missing, and uses `/dev/tty` for `qwen login` prompts with a `--package` override. |
| `6` | OpenAI Codex CLI | Installs Codex/Cursor helpers and points you to the ChatGPT or `OPENAI_API_KEY` auth flow. |
| `7` | Cursor Agent CLI | Requires Node.js ≥ 18, installs `cursor-agent` via npm, and reminds you to run `cursor-agent login` (interactive runs open `/dev/tty`). |
| `8` | Cline CLI | Requires Node.js ≥ 18, installs the `@cline/cli` package, and prompts for `cline login` only during interactive runs. |
| `9` | Aider CLI | Uses the official `aider-install` script for a robust installation, handling Python versions and dependencies automatically. |
| `10` | GitHub Copilot CLI | Installs via npm and prints both `copilot auth login` and `copilot auth activate` reminders. |
| `11` | Kilocode CLI | Installs `@kilocode/cli`, enforces Node.js ≥ 18, and prints reminders to run `kilocode config` plus architect/debug/auto modes. |
| `12` | Auggie CLI | Installs `@augmentcode/auggie` (Node.js ≥ 22) and walks through `auggie login`, `.augment/commands`, and CI-friendly flags. |
| `13` | Droid CLI | Provides Factory’s quickstart instructions for installing the droid CLI (interactive terminal) and reminds you to follow the official guide. |
| `14` | Install every CLI | Runs options `1-13` in batch mode (logins skipped, summary printed at the end). |

#### Auxiliary AI Tools Menu
This new menu, accessible via option `8` in the main menu, groups together tools for spec-driven development and agent libraries.

| Option | Tool | Highlights |
|--------|------|------------|
| `1` | OpenSpec CLI | Installs `@fission-ai/openspec` globally (Node.js ≥ 18) so you can run `openspec init/plan/sync`. |
| `2` | specify-cli | Installs GitHub's `specify-cli` from `spec-kit` using `uv`. Requires Python tools to be installed. |
| `3` | Contains Studio Agents | Syncs the Contains Studio `.md` agents into `~/.claude/agents` (restart Claude Code afterward). |
| `4` | Wes Hobson Agents | Installs the `wshobson/agents` collection into `~/.claude/agents` (restart Claude Code afterward). |
| `5` | Install All | Installs all auxiliary tools sequentially. |

#### AI Framework Menu
The framework menu ensures `pipx` exists (installing Python first if necessary), then lets you provision individual Super* stacks or all of them in one go. Each installer routes prompts through `/dev/tty`, so API-key input works even when `setup` was piped through `curl`.

| Option | Framework | Highlights |
|--------|-----------|------------|
| `1` | SuperGemini | Installs the Gemini-native workflow via `pipx`, including login hints and PATH refresh. |
| `2` | SuperQwen | Wraps the official installer with `attach_tty_and_run` so Qwen credentials can be entered safely. |
| `3` | SuperClaude | Provides the Anthropic toolkit with the same TTY safeguards and cleanup helpers. |
| `4` | Install every framework | Sequentially installs all three frameworks (duplicate runs are skipped gracefully). |

### Usage Notes

- **Language toggle:** English is the default, Turkish is auto-detected when your locale starts with `tr`, and you can flip languages anytime via menu option `L`.
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
| Aider CLI install fails | The script now uses the official `aider-install` script, which is more robust. If it still fails, check the logs from the installer. |
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
- **Framework Authors:** SuperGemini/SuperQwen/SuperClaude teams, Anthropic, Google, OpenAI, GitHub Copilot CLI contributors.

### License

This project is licensed under the **MIT License**. See [`LICENSE`](./LICENSE) for full text.

---

## 🇹🇷 Türkçe Rehber

### Genel Bakış

`setup`, Linux tabanlı geliştirici makinelerinde uçtan uca AI ortamı kurar. Paket yöneticisini otomatik saptar, CRLF düzeltir, Python/Node/PHP ekosistemlerini kurar, AI CLI & framework menüleri sunar. Arayüz iki dillidir: varsayılan İngilizcedir, sistem dili `tr` ile başlıyorsa otomatik olarak Türkçe açılır ve menüdeki `L` seçeneğiyle anında dil değiştirebilirsiniz.

### Mimari

| Bileşen | Açıklama |
|---------|---------|
| **Kendini onaran başlatıcı** | CRLF algılar, izin/dosya sorunlarını düzeltip script’i yeniden başlatır. |
| **Uzaktan güvenli modüller** | `bash -c "$(curl …)"` yöntemiyle çalıştırıldığında yardımcı modülleri geçici dizine indirir ve alt süreçlerle paylaşır. |
| **Banner sistemi** | `modules/banner.sh`, kutu çizgileriyle geniş panoları doğrudan Bash içinde çizer; ek paket gerektirmez. |
| **Menü çalıştırıcısı** | Önce yerel `./modules/*.sh` dosyalarını, yoksa GitHub sürümlerini kullanır. |

### Gereksinimler

- `apt`, `dnf`, `yum` veya `pacman` içeren Linux dağıtımı.
- `bash` 5+, `sudo` hakları, aktif internet bağlantısı.
- `curl` (uzaktan kurulum için zorunlu).
- Banner panelleri depo ile birlikte gelir; ekstra bir ASCII aracı kurmanıza gerek kalmaz.

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
| `3` | Node.js araç alt menüsü (NVM + Node LTS, Bun, CLI ekstraları). |
| `4` | AI CLI araçları (alt menü). |
| `5` | AI Frameworkleri (SuperGemini/SuperQwen/SuperClaude). |
| `6` | Git yapılandırması. |
| `7` | Claude Code sağlayıcı menüsü (GLM-4.6 veya Moonshot kimi-k2 ayarları). |
| `8` | Yardımcı AI Araçlarını Kur (OpenSpec, Ajanlar, vb.). |
| `9` | PHP & Composer kurulum sihirbazı. |
| `10` | GitHub CLI. |
| `11` | AI Framework kaldırma menüsü. |
| `12` | MCP sunucularını listeleme/temizleme. |
| `L` | Dili değiştir (varsayılan İngilizce, `tr` lokalli sistemlerde otomatik Türkçe açılır). |
| `A` | Hepsini sırayla kurar (interaktif girişler daha sonra hatırlatılır). |
| `0` | Çıkış. |

### Alt Menü Detayları

#### Node.js Araç Menüsü
`3` numaralı seçenek artık çoklu seçim desteği olan bir alt menü açar. Virgülle ayrılmış girişler (`1,3`) desteklenir ve `4` kısayolu tüm bileşenleri ardışık olarak kurar.

| Seçenek | Bileşen | Detaylar |
|---------|---------|----------|
| `1` | Node.js (NVM + LTS) | NVM’i kurar/günceller, shell RC dosyalarını ayarlar ve son LTS Node sürümünü yükler. |
| `2` | Bun runtime | Resmî Bun kurulum betiğini çalıştırır, `~/.bun/bin` dizinini PATH’e ekler ve sürümü gösterir. |
| `3` | Node CLI ekstraları | Corepack’i etkinleştirir, `pnpm` ve `yarn`’ı global olarak kurar; CI çalışmaları için idealdir. |
| `4` | Tüm bileşenler | `1-3` seçeneklerini sırayla çalıştırır. |
| `0` | Ana menü | Değişiklik yapılmadan geri dönülür. |

#### AI CLI Menüsü
Virgülle ayrılmış seçimleri (`1,3,7`) ve tüm araçlar için `14` kısayolunu kabul eder. Toplu kurulumlar interaktif oturum açma adımlarını atlar fakat gereken komutları özet olarak yazdırır.

| Seçenek | Araç | Detaylar |
|---------|------|----------|
| `1` | Claude Code CLI | Anthropic’in Ink tabanlı arayüzünü `/dev/tty` üzerinden açar, uzaktan çalıştırmalarda bile kesinti olmaz. |
| `2` | Gemini CLI | Node.js ≥ 20 gereksinimini kontrol eder, npm fallback kurulumları yapar ve `gemini auth` hatırlatması verir. |
| `3` | OpenCode CLI | Beta OpenCode araçlarını uzaktan güvenli şekilde kurar ve `opencode login` komutunu hatırlatır. |
| `4` | Qoder CLI | Birden çok npm paket adını dener; `QODER_NPM_PACKAGE` gibi override seçeneklerini destekler. |
| `5` | Qwen CLI | Node.js ≥ 18 şartını uygular, gerekirse Node kurulumunu başlatır, `/dev/tty` ile `qwen login` akışını yönetir. |
| `6` | OpenAI Codex CLI | Codex/Cursor yardımcılarını yükler, ChatGPT veya `OPENAI_API_KEY` tabanlı giriş akışını açıklar. |
| `7` | Cursor Agent CLI | Node.js ≥ 18 gerektirir, `cursor-agent` paketini npm ile kurar ve interaktif modda `cursor-agent login` komutunu çalıştırır. |
| `8` | Cline CLI | Node.js ≥ 18 gerektirir, `@cline/cli` paketini kurar ve sadece etkileşimli çalışmalarda `cline login` komutunu tetikler. |
| `9` | Aider CLI | Kurulum için resmi `aider-install` betiğini kullanır, bu sayede Python sürümleri ve bağımlılıklar otomatik olarak yönetilir. |
| `10` | GitHub Copilot CLI | npm global kurulumunu otomatik yapar, `copilot auth login` ve `copilot auth activate` komutlarını hatırlatır. |
| `11` | Kilocode CLI | `@kilocode/cli` paketini kurar, `kilocode config` / architect-debug modları için yönergeler verir. |
| `12` | Auggie CLI | `@augmentcode/auggie` paketini Node.js ≥ 22 doğrulaması ile kurar, `auggie login` ve `.augment/commands` içeriğini hatırlatır. |
| `13` | Droid CLI | Factory'nin droid istemcisi için quickstart bağlantısını ve manuel komutları gösterir. |
| `14` | Hepsini Kur | `1-13` arasındaki tüm CLI araçlarını ardışık, login atlayan batch modunda çalıştırır. |

#### Yardımcı AI Araçları Menüsü
Ana menüdeki `8` numaralı seçenekle erişilen bu yeni menü, spesifikasyon odaklı geliştirme araçlarını ve ajan kütüphanelerini bir araya getirir.

| Seçenek | Araç | Detaylar |
|---------|------|------------|
| `1` | OpenSpec CLI | `@fission-ai/openspec` paketini global kurar (Node.js ≥ 18); `openspec init/plan/sync` komutlarını kullanabilirsiniz. |
| `2` | specify-cli | GitHub'ın `spec-kit` deposundan `specify-cli` aracını `uv` ile kurar. Python araçlarının kurulu olmasını gerektirir. |
| `3` | Contains Studio Agents | Contains Studio ajanlarını `~/.claude/agents/` klasörüne senkronize eder (kurulum sonrası Claude Code'u yeniden başlatın). |
| `4` | Wes Hobson Agents | `wshobson/agents` koleksiyonunu `~/.claude/agents/` klasörüne kopyalar (Claude Code'u yeniden başlatın). |
| `5` | Hepsini Kur | Tüm yardımcı araçları sırayla kurar. |

#### AI Framework Menüsü
Önce `pipx` ve gerekirse Python kurulumunu doğrular, ardından Super* framework’lerini tek tek veya toplu olarak kurar. API anahtar istemleri `/dev/tty` üzerinden aktığı için `curl | bash` senaryolarında bile güvenli şekilde giriş yapabilirsiniz.

| Seçenek | Framework | Detaylar |
|---------|-----------|----------|
| `1` | SuperGemini | `pipx` ile kurulur, PATH güncellemesini ve gerekli login komutlarını otomatik özetler. |
| `2` | SuperQwen | `attach_tty_and_run` ile sarıldığı için Qwen kimlik doğrulamaları kesintisiz ilerler. |
| `3` | SuperClaude | Aynı TTY korumalarıyla Anthropic araçlarını kurar, gerekirse temizleme yordamları sağlar. |
| `4` | Hepsini Kur | Tüm Super* framework’lerini arka arkaya kurar; daha önce kurulanlar atlanır veya güncellenir. |

### Kullanım Notları

- **Dil geçişi:** Varsayılan dil İngilizce’dir; yerel ayarlarınız `tr` ile başlıyorsa menü Türkçe açılır ve `L` seçeneğiyle anında dil değiştirebilirsiniz.
- **PATH güncellemeleri** script tarafından otomatik `source` edilir; yeni komutlar aynı terminalde erişilebilir.
- **API anahtarları** maskelenerek gösterilir, boş bırakılırsa mevcut değer korunur.
- **TTY gereksinimleri** `attach_tty_and_run` ile çözüldü; artık `Raw mode is not supported` hatası alınmaz.
- **Uzaktan çalışma** sırasında modüller geçici dizine alınır ve tekrar kullanılmak üzere önbelleğe atılır.

### Sorun Giderme

- `curl: (3)` hatası: En güncel `setup` sürümünü kullanın; `SCRIPT_BASE_URL` artık her alt süreçte mevcut.
- `mask_secret` hatası: GLM menüsü artık utils’i otomatik yüklüyor.
- SuperQwen/SuperClaude menüsü girdi beklemiyorsa: Güncel sürüme geçin; `attach_tty_and_run` eklendi.
- Aider CLI kurulumu başarısız olursa: Betik artık daha sağlam olan resmi `aider-install` betiğini kullanıyor. Hata devam ederse, yükleyicinin loglarını kontrol edin.
- Komut bulunamıyorsa: Terminali kapatıp açın veya `source ~/.bashrc` çalıştırın.

### Katkı

1. Fork + branch açın.
2. Script değişikliklerinde `shellcheck` ve `bash -n` çalıştırın.
3. README/TR bölümlerini yeni özelliklerle güncelleyin.
4. PR özetine ekran görüntüsü veya log ekleyin.

### Emek Verenler

- **Geliştirici:** Tamer Karaca  
- **Framework Ekipleri:** SuperGemini/SuperQwen/SuperClaude, Anthropic, Google, OpenAI, GitHub Copilot CLI katkıcıları

### Lisans

Bu proje **MIT Lisansı** ile dağıtılır. Ayrıntılar için [LICENSE](./LICENSE) dosyasına bakın.