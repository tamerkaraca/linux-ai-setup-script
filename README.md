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

`setup` prepares a Linux workstation for AI development. It auto-detects the package manager, resolves Windows CRLF line endings, installs system dependencies, bootstraps Python/Node/PHP stacks, and exposes curated menus for AI CLIs (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, Cursor Agent, Cline, Aider, OpenAI Codex, Copilot CLI), AI frameworks (SuperGemini, SuperQwen, SuperClaude), GitHub CLI, MCP server maintenance, and GLM-4.6 configuration.

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
| `3` | Install Node.js tooling: NVM, latest LTS node, npm upgrade guard, Bun. |
| `4` | Install AI CLI tools (opens sub-menu). |
| `5` | Install AI frameworks (opens sub-menu; handles Pipx, GLM prompts, tty-safe runs). |
| `6` | Git configuration (name/email, signing, alias suggestions). |
| `7` | Claude Code provider menu (GLM-4.6 or Moonshot kimi-k2 with masked key + base URL helpers). |
| `8` | PHP & Composer installer with selectable versions and Laravel-friendly extensions. |
| `9` | GitHub CLI install with official repo keys. |
| `10` | Remove AI frameworks (Super* uninstall + cleanup). |
| `11` | MCP server management (list, clean `~/.gemini`, `~/.qwen`, `~/.claude`). |
| `A` | Install everything sequentially (skips interactive logins, prints summaries). |
| `0` | Exit. |

### CLI & Framework Sub-menus

#### AI CLI Menu
The sub-menu accepts comma-separated selections (`1,3,7`) or a `14` shortcut that installs every CLI sequentially. Interactive runs pause for logins, whereas batch runs remember the missing auth commands and print them in a summary (`claude login`, `gemini auth`, `cursor-agent login`, `cline login`, `aider --help`, `openspec init`, `copilot auth login`, etc.).

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
| `9` | Aider CLI | Installs the `aider-chat` package via pipx (Node.js ≥ 18 guard) and reminds you to export provider API keys before running `aider`. |
| `10` | GitHub Copilot CLI | Installs via npm and prints both `copilot auth login` and `copilot auth activate` reminders. |
| `11` | OpenSpec CLI | Installs `@fission-ai/openspec` globally (Node.js ≥ 18) so you can run `openspec init/plan/sync`. |
| `12` | Contains Studio Agents | Syncs the Contains Studio `.md` agents into `~/.claude/agents` (restart Claude Code afterward). |
| `13` | Wes Hobson Agents | Installs the `wshobson/agents` collection into `~/.claude/agents` (restart Claude Code afterward). |
| `14` | Install every CLI | Runs options `1-13` in batch mode (logins skipped, summary printed at the end). |
| `13` | Wes Hobson Agents | Installs the `wshobson/agents` collection into `~/.claude/agents` (restart Claude Code afterward). |
| `14` | Install every CLI | Runs options `1-13` in batch mode (logins skipped, summary printed at the end). |

##### Claude Code CLI
Anthropic’s Claude Code CLI (https://github.com/anthropics/claude-code) ships the same Ink-based workflow you see in the Claude desktop app. The installer attaches `/dev/tty` before launching `claude login`, preventing “Raw mode is not supported” errors when you run the script remotely. Sample usage:

```bash
claude login
claude run --model claude-3-5-sonnet-latest
claude chat src/index.ts
```

The CLI respects `ANTHROPIC_API_KEY` and `CLAUDE_API_KEY`, so you can preload them in non-interactive environments.

##### Gemini CLI
Google’s Gemini CLI (https://github.com/google-gemini/gemini-cli) drives all Gemini API workflows from a single binary. We require Node.js ≥ 20 per Google’s guidance, install the `@google/gemini-cli` package via npm with fallback prefixes, and run `gemini auth` only when interactive. Popular commands:

```bash
gemini auth
gemini generate --model gemini-1.5-pro "Summarize docs/ADR.md"
gemini chat my-session
```

The CLI stores credentials in `~/.config/gemini`, which the installer highlights if you need to copy tokens between machines.

##### OpenCode CLI
OpenCode (https://github.com/opencode-ai/opencode) offers a community-driven set of automations for building and shipping AI assistants. Our installer downloads the latest npm package, prints `opencode login` reminders, and notes that you can set `OPENAI_API_KEY`/`ANTHROPIC_API_KEY` to bypass login prompts. Example:

```bash
opencode login
opencode agent create --template turbo-docs
opencode agent run turbo-docs
```

Because OpenCode frequently publishes beta builds, the installer honors `NPM_CONFIG_REGISTRY` if you mirror packages internally.

##### Qoder CLI
Qoder’s CLI (https://docs.qoder.com/cli/quick-start) lets you scaffold and manage “Qoder Agents.” The installer tries several npm scopes (`@qoderhq/qoder`, `@qoderhq/cli`, etc.), or you can specify `QODER_NPM_PACKAGE`, `QODER_CLI_BUNDLE`, `--package`, or `--bundle` to pin a particular artifact. Interactive runs still call `qoder login`, but batch runs just emit reminders:

```bash
qoder login
qoder project create --template agent-proto
qoder project deploy my-agent
```

Each successful install prints the resolved npm package name so you can track which scope worked on your mirror.

##### Qwen CLI
Qwen’s official CLI (https://github.com/QwenLM/qwen-code) exposes the Qwen Code models and Qwen Agents from any terminal. We enforce Node.js ≥ 18, bootstrap Node when missing, and run `qwen login` through `/dev/tty` so QR-code prompts display correctly. Sample usage:

```bash
qwen login
qwen run --model qwen2.5-coder:latest "Explain the diff in utils.sh"
qwen history list
```

Air-gapped installs can pass `--package <tarball>` or `QWEN_NPM_PACKAGE` to point at an internal registry.

##### OpenAI Codex CLI
OpenAI’s Codex CLI (https://github.com/openai/codex) provides the “codex”, “suggest”, and “auto edit” flows from the Codex Labs preview. Our installer installs `@openai/codex`, then offers a guided login flow: either “Sign in with ChatGPT” or `OPENAI_API_KEY`. Typical commands:

```bash
codex --suggest --file index.js
codex --auto-edit --model o3-mini
OPENAI_API_KEY=sk-... codex
```

If you store API keys in shell rc files, the installer appends the `export OPENAI_API_KEY=...` line for you.

##### GitHub Copilot CLI
GitHub’s Copilot CLI (https://github.com/github/copilot-cli?locale=en-US) lets you run `copilot explain`, `copilot tests`, and `copilot helm` in your terminal. The installer uses npm to install `@githubnext/github-copilot-cli`, prints both `copilot auth login` and `copilot auth activate`, and reminds you that certain commands require `gh` scopes. Example:

```bash
copilot auth login
copilot explain src/main.rs
copilot tests src/api/*
```

Credentials are stored under `~/.config/github-copilot-cli`, so you can copy them between machines if needed.

##### Cursor Agent CLI
Cursor’s official CLI exposes the editor’s “AI pair-programmer” features inside any terminal session. The installer enforces Node.js ≥ 18, falls back to npm’s user prefix when the global prefix is read-only, and reloads your shell so `cursor-agent` is immediately available. During interactive runs it opens `/dev/tty` and launches `cursor-agent login`; in batch mode it skips the login and prints a reminder so pipelines never block. Example flows:

```bash
cursor-agent run --prompt "Refactor utils.sh for readability"
cursor-agent status
cursor-agent logout
```

All workspaces and rate limits match what you see at https://cursor.com/cli.

##### Cline CLI
Cline (https://cline.bot/cline-cli) provides a multi-agent coding workflow driven by the `@cline/cli` package. Our installer mirrors the Cursor flow: it checks Node.js ≥ 18 (bootstrapping Node automatically when possible), installs the CLI globally via `npm_install_global_with_fallback`, and only invokes `cline login` when stdin/stdout are attached to a TTY. Batch installs simply print `cline login` instructions at the end. After logging in you can spin up workspaces or chat-driven refactors:

```bash
cline init my-playground
cline chat --prompt "Generate integration tests for payments.ts"
cline upgrade
```

Batches reuse your npm cache, so `install_ai_cli_tools_menu all` remains fast.

##### Aider CLI
Aider (https://aider.chat/docs/install.html) is a GPT-powered pair-programming tool distributed as the `aider-chat` Python package. Even though it runs on Python, the installer enforces Node.js ≥ 18 to stay aligned with the repo baseline (and because most users install Cursor/Cline alongside it). After passing the Node check, the script ensures pipx + Python exist, installs `aider-chat`, reloads your shell, and prints reminders to set environment variables such as `OPENAI_API_KEY`, `AIDER_ANTHROPIC_API_KEY`, or `ANTHROPIC_API_KEY`. Interactive runs pause so you can paste keys immediately; batch runs simply remind you to export them later. Typical commands:

```bash
aider --help
aider --model gpt-4o-mini app/main.py
OPENAI_API_KEY=sk-... aider --architect "Plan a plugin architecture"
```

Because Aider is pipx-managed, upgrades are as easy as `pipx upgrade aider-chat`.

##### Claude Code Providers (Option 7)
Option `7` in the primary menu now opens a mini-menu that targets two officially documented workflows:

- **GLM-4.6 via z.ai (https://z.ai/model-api):** The script creates `~/.claude/settings.json`, masks the existing `ANTHROPIC_AUTH_TOKEN`, injects the official base URL (`https://api.z.ai/api/anthropic`), and pins `ANTHROPIC_DEFAULT_*` models to `GLM-4.6` / `GLM-4.5-Air`, matching GLM Coding Plan guidance.
- **Moonshot kimi-k2 via platform.moonshot.ai (https://platform.moonshot.ai/docs/guide/agent-support#install-claude-code):** Before writing the config, the module enforces Node.js ≥ 18 (Moonshot also installs its own Claude Code CLI build) and optionally reinstalls `@anthropic-ai/claude-code`. It then prompts for your Moonshot API key, automatically sets the base URL to `https://api.moonshot.ai/anthropic`, and captures the preferred model (`kimi-k2-0711-preview` or `kimi-k2-turbo-preview`). All values are written back to `~/.claude/settings.json`, so rerunning the menu simply masks existing keys if you need to rotate secrets later on.

Both flows surface the upstream documentation links and keep the key in place if you press Enter, which makes credential rotation painless.

#### OpenSpec CLI (AI CLI Option 11)

Option `11` installs the [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec) globally via npm (`npm install -g @fission-ai/openspec`). OpenSpec brings spec-driven development to Claude Code, Cursor, Gemini CLI, etc., so you draft change proposals in `openspec/changes/`, agree on specs, and then have the AI implement tasks referencing those specs.

- Requires Node.js ≥ 18 and `npm` (the installer upgrades npm if it’s older than 9.x).
- Exposes commands such as `openspec init`, `openspec plan`, `openspec apply <change>`, and `openspec archive <change> --yes`.
- Use natural-language prompts inside Claude Code (“Use OpenSpec to plan add-profile-filters”) or run the CLI directly.
- Run option `12` or `13` afterward if you also want the Contains Studio or Wes Hobson agent packs.

#### Contains Studio Agents for Claude Code (AI CLI Option 12)

AI CLI option `12` clones the [Contains Studio agents](https://github.com/contains-studio/agents) repository and copies every `.md` manifest into `~/.claude/agents`. Restart Claude Code after the sync so the agents show up in the sidebar.

- Requires `git`; rerun the option any time to pull the latest changes (uses `rsync -a --delete`).
- Agents are categorized by department (engineering, design, marketing, ops, etc.).
- Manual alternative:

```bash
git clone https://github.com/contains-studio/agents.git
cp -r agents/* ~/.claude/agents/
```

#### Wes Hobson Agents for Claude Code (AI CLI Option 13)

Option `13` installs the [wshobson/agents](https://github.com/wshobson/agents) repository into `~/.claude/agents`. This pack focuses on practical delivery, growth, and product ops roles; restart Claude Code after syncing so the new entries appear in the Agents sidebar.

- Requires `git`; the installer mirrors the repo via `rsync -a --delete`, so rerunning the option refreshes your local library.
- Manual alternative:

```bash
git clone https://github.com/wshobson/agents.git
cp -r agents/* ~/.claude/agents/
```

#### AI Framework Menu
The framework menu ensures `pipx` exists (installing Python first if necessary), then lets you provision individual Super* stacks or all of them in one go. Each installer routes prompts through `/dev/tty`, so API-key input works even when `setup` was piped through `curl`.

| Option | Framework | Highlights |
|--------|-----------|------------|
| `1` | SuperGemini | Installs the Gemini-native workflow via `pipx`, including login hints and PATH refresh. |
| `2` | SuperQwen | Wraps the official installer with `attach_tty_and_run` so Qwen credentials can be entered safely. |
| `3` | SuperClaude | Provides the Anthropic toolkit with the same TTY safeguards and cleanup helpers. |
| `4` | Install every framework | Sequentially installs all three frameworks (duplicate runs are skipped gracefully). |

### Usage Notes

- **Environment reloads:** PATH updates for `pipx`, `uv`, `nvm`, `bun`, `gh`, etc., are appended to `~/.bashrc`, `~/.zshrc`, and `~/.profile`. The script auto-sources whichever exists so new commands are usable immediately.
- **Remote execution:** The menu structure, colorized logs, and sub-modules behave the same whether you cloned locally or piped via curl.
- **API keys:** Super* installers guide you through provider portals (Gemini, Anthropic, OpenAI). GLM configuration masks existing keys (`abcd***wxyz`) and only replaces them if you supply a new value.
- **TTY requirements:** The Claude Code, SuperQwen, and SuperClaude installers now route to `/dev/tty`, preventing Ink-based CLIs from exiting with “Raw mode is not supported”.
- **Qoder CLI overrides:** When the npm registry is slow to publish a package, pass `QODER_NPM_PACKAGE`, `QODER_CLI_BUNDLE`, `--package`, `--bundle`, or `--skip-probe` so `install_qoder_cli` knows exactly what to install.
- **Qwen CLI guardrails:** `install_qwen_cli` enforces Node.js ≥ 18, can bootstrap Node automatically, and exposes a `--package` override for air-gapped environments—all while keeping `/dev/tty` attached for `qwen login`.

### Troubleshooting

| Symptom | Resolution |
|---------|------------|
| `curl: (3) URL rejected: No host part` | Ensure you are on the latest `setup` (≥ `7d4ee0a`). The script now exports `SCRIPT_BASE_URL` and caches modules with fully qualified URLs. |
| `mask_secret: command not found` | Pull latest changes; GLM config now sources `modules/utils.sh` even in remote runs. |
| `SuperQwen install` aborts without prompting | Fixed by `attach_tty_and_run`; rerun option `5` → SuperQwen. |
| Qoder CLI npm probe fails | Provide the package via `QODER_NPM_PACKAGE`, `install_qoder_cli --package @custom/cli`, or point to a local tarball with `--bundle /path/qoder.tgz`. |
| Qwen CLI complains about Node.js | Run menu option `3` or let `install_qwen_cli` bootstrap Node; it requires Node.js ≥ 18 before running `npm install -g @qwen-code/qwen-code`. |
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

`setup`, Linux tabanlı geliştirici makinelerinde uçtan uca AI ortamı kurar. Paket yöneticisini otomatik saptar, CRLF düzeltir, Python/Node/PHP ekosistemlerini kurar, AI CLI & framework menüleri sunar (Claude Code, Gemini CLI, OpenCode, Qoder, Qwen, Cursor Agent, Cline, OpenAI Codex, Copilot CLI), GLM-4.6 yapılandırmasını ve MCP temizliğini yönetir.

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
| `3` | Node.js/NVM/Bun kurulumu. |
| `4` | AI CLI araçları (alt menü). |
| `5` | AI Frameworkleri (SuperGemini/SuperQwen/SuperClaude). |
| `6` | Git yapılandırması. |
| `7` | Claude Code sağlayıcı menüsü (GLM-4.6 veya Moonshot kimi-k2 ayarları). |
| `8` | PHP & Composer kurulum sihirbazı. |
| `9` | GitHub CLI. |
| `10` | AI Framework kaldırma menüsü. |
| `11` | MCP sunucularını listeleme/temizleme. |
| `A` | Hepsini sırayla kurar (interaktif girişler daha sonra hatırlatılır). |
| `0` | Çıkış. |

### Alt Menü Detayları

#### AI CLI Menüsü
Virgülle ayrılmış seçimleri (`1,3,7`) ve tüm araçlar için `14` kısayolunu kabul eder. Toplu kurulumlar interaktif oturum açma adımlarını atlar fakat gereken komutları (`claude login`, `gemini auth`, `cursor-agent login`, `cline login`, `aider --help`, `openspec init`, `copilot auth login` vb.) özet olarak yazdırır.

| Seçenek | Araç | Detaylar |
|---------|------|----------|
| `1` | Claude Code CLI | Anthropic’in Ink tabanlı arayüzünü `/dev/tty` üzerinden açar, uzaktan çalıştırmalarda bile kesinti olmaz. |
| `2` | Gemini CLI | Node.js ≥ 20 gereksinimini kontrol eder, npm fallback kurulumları yapar ve `gemini auth` hatırlatması verir. |
| `3` | OpenCode CLI | Beta OpenCode araçlarını uzaktan güvenli şekilde kurar ve `opencode login` komutunu hatırlatır. |
| `4` | Qoder CLI | Birden çok npm paket adını dener; `QODER_NPM_PACKAGE`, `QODER_CLI_BUNDLE`, `--package`, `--bundle`, `--skip-probe` gibi override seçeneklerini destekler. |
| `5` | Qwen CLI | Node.js ≥ 18 şartını uygular, gerekirse Node kurulumunu başlatır, `/dev/tty` ile `qwen login` akışını yönetir ve `--package` override’ını destekler. |
| `6` | OpenAI Codex CLI | Codex/Cursor yardımcılarını yükler, ChatGPT veya `OPENAI_API_KEY` tabanlı giriş akışını açıklar. |
| `7` | Cursor Agent CLI | Node.js ≥ 18 gerektirir, `cursor-agent` paketini npm ile kurar ve interaktif modda `/dev/tty` üzerinden `cursor-agent login` komutunu çalıştırır. |
| `8` | Cline CLI | Node.js ≥ 18 gerektirir, `@cline/cli` paketini kurar ve sadece etkileşimli çalışmalarda `cline login` komutunu tetikler. |
| `9` | Aider CLI | Pipx üzerinden `aider-chat` paketini kurar (Node.js ≥ 18 kontrolü sonrası) ve API anahtarlarını export etmeniz gerektiğini hatırlatır. |
| `10` | GitHub Copilot CLI | npm global kurulumunu otomatik yapar, `copilot auth login` ve `copilot auth activate` komutlarını hatırlatır. |
| `11` | OpenSpec CLI | `@fission-ai/openspec` paketini global kurar (Node.js ≥ 18); `openspec init/plan/sync` komutlarını kullanabilirsiniz. |
| `12` | Contains Studio Agents | Contains Studio ajanlarını `~/.claude/agents/` klasörüne senkronize eder (kurulum sonrası Claude Code'u yeniden başlatın). |
| `13` | Wes Hobson Agents | wshobson/agents koleksiyonunu `~/.claude/agents/` klasörüne kopyalar (Claude Code'u yeniden başlatın). |
| `14` | Hepsini Kur | `1-13` arasındaki tüm CLI araçlarını ardışık, login atlayan batch modunda çalıştırır. |

##### Claude Code CLI
Anthropic’in Claude Code CLI aracı (https://github.com/anthropics/claude-code), Claude masaüstündeki Ink tabanlı deneyimi terminale taşır. Kurulum sırasında `/dev/tty` bağlandığı için “Raw mode is not supported” hatası alınmaz ve `claude login` komutu uzaktan bile sorunsuz çalışır:

```bash
claude login
claude run --model claude-3-5-sonnet-latest
claude chat src/index.ts
```

`ANTHROPIC_API_KEY` veya `CLAUDE_API_KEY` değişkenlerini önceden ayarlarsanız, toplu kurulumlarda giriş adımını atlayabilirsiniz.

##### Gemini CLI
Google Gemini CLI (https://github.com/google-gemini/gemini-cli) tüm Gemini API iş akışlarını tek bir komutla yönetmenizi sağlar. Google’ın önerisi doğrultusunda Node.js ≥ 20 şartı aranır, `@google/gemini-cli` npm paketi fallback prefix desteği ile kurulur ve `gemini auth` sadece etkileşimli oturumda çalıştırılır:

```bash
gemini auth
gemini generate --model gemini-1.5-pro "docs/ADR.md dosyasını özetle"
gemini chat ekip-oturumu
```

Kimlik doğrulama bilgileri `~/.config/gemini` dizinine kaydedilir; kurulum çıktısı bu klasörü vurgular.

##### OpenCode CLI
OpenCode (https://github.com/opencode-ai/opencode) topluluk odaklı ajan şablonları sağlar. Installer en güncel npm paketini kurar, `opencode login` hatırlatması yapar ve gerekiyorsa `OPENAI_API_KEY`/`ANTHROPIC_API_KEY` değişkenleri ile girişin otomatik yapılabileceğini belirtir:

```bash
opencode login
opencode agent create --template turbo-docs
opencode agent run turbo-docs
```

Kurumsal aynalar kullanıyorsanız `NPM_CONFIG_REGISTRY` değişkeni desteklenir.

##### Qoder CLI
Qoder CLI (https://docs.qoder.com/cli/quick-start) ile “Qoder Agents” projeleri oluşturup yönetebilirsiniz. Installer çeşitli npm scope’larını dener; gerekirse `QODER_NPM_PACKAGE`, `QODER_CLI_BUNDLE`, `--package` veya `--bundle` parametreleriyle paket adı sabitlenebilir. Örnek komutlar:

```bash
qoder login
qoder project create --template agent-proto
qoder project deploy my-agent
```

Kurulum sonunda hangi npm paketinden kurulum yapıldığı yazdırılır.

##### Qwen CLI
Qwen Code CLI (https://github.com/QwenLM/qwen-code), Qwen modellerini terminalden kullanmanıza olanak tanır. Node.js ≥ 18 kontrol edilir, eksikse Node kurulumu tetiklenir ve `qwen login` komutu `/dev/tty` üzerinden çalıştırılır:

```bash
qwen login
qwen run --model qwen2.5-coder:latest "utils.sh değişikliklerini açıkla"
qwen history list
```

Kapalı ağlarda `--package <tarball>` veya `QWEN_NPM_PACKAGE` ile iç registry kullanılabilir.

##### OpenAI Codex CLI
OpenAI Codex CLI (https://github.com/openai/codex) “codex”, “suggest” ve “auto edit” modlarını sunar. Installer `@openai/codex` paketini kurar ve iki kimlik yöntemi sağlar: “Sign in with ChatGPT” veya `OPENAI_API_KEY`. Örnek:

```bash
codex --suggest --file index.js
codex --auto-edit --model o3-mini
OPENAI_API_KEY=sk-... codex
```

İstenirse API anahtarı otomatik olarak shell rc dosyalarına eklenir.

##### GitHub Copilot CLI
GitHub Copilot CLI (https://github.com/github/copilot-cli?locale=en-US) terminalden `copilot explain`, `copilot tests` gibi komutları çalıştırmanızı sağlar. Installer npm üzerinden `@githubnext/github-copilot-cli` paketini kurar, `copilot auth login` ve `copilot auth activate` komutlarını hatırlatır:

```bash
copilot auth login
copilot explain src/main.rs
copilot tests src/api/*
```

Kimlik bilgilerinin `~/.config/github-copilot-cli` altında tutulduğunu da loglarda belirtiyoruz.

##### Cursor Agent CLI
Cursor’un resmi terminal aracı, editördeki “AI pair-programmer” deneyimini komut satırına taşır. Kurulum Node.js ≥ 18 kontrolü yapar, gerekirse npm kullanıcı prefix’ine düşer ve shell yeniden yüklendiği için `cursor-agent` komutu anında kullanılabilir. Etkileşimli modda `/dev/tty` üzerinden `cursor-agent login` çalıştırılır; toplu kurulumlar ise giriş adımını atlayıp kullanıcıyı bilgilendirir. Örnek kullanım:

```bash
cursor-agent run --prompt "utils.sh dosyasını sadeleştir"
cursor-agent status
cursor-agent logout
```

Workspace ve kota limitleri https://cursor.com/cli üzerindeki hesapla aynıdır.

##### Cline CLI
Cline (https://cline.bot/cline-cli), çoklu ajan tabanlı kodlama akışlarını `@cline/cli` paketi ile sunar. Installer Node.js ≥ 18 şartını doğrular (mümkünse Node’u otomatik kurar), npm global kurulumunda fallback uygular ve yalnızca etkileşimli oturumlarda `cline login` komutunu tetikler. Toplu kurulumlar giriş adımını atlayarak `cline login` hatırlatması basar. Giriş yaptıktan sonra:

```bash
cline init proje-deneme
cline chat --prompt "payments.ts için entegrasyon testleri yaz"
cline upgrade
```

Böylece terminalden Cline agent’larını yönetebilir, sohbet tabanlı refaktör süreçleri başlatabilirsiniz.

##### Aider CLI
Aider (https://aider.chat/docs/install.html), GPT tabanlı eş programlama deneyimini pipx ile dağıtılan `aider-chat` paketi üzerinden sunar. Installer Node.js ≥ 18 şartını doğrular (repo standartları ile uyumlu), pipx + Python’un kurulu olduğundan emin olur ve paketi yükledikten sonra shell’i yeniden yükler. Etkileşimli modda script, `OPENAI_API_KEY`, `AIDER_ANTHROPIC_API_KEY` gibi değişkenleri export etmeniz için bekler; toplu modda ise yalnızca hatırlatma mesajı verir. Örnek kullanım:

```bash
aider --help
aider --model gpt-4o-mini app/main.py
OPENAI_API_KEY=sk-... aider --architect "Eklenti mimarisi tasarla"
```

Pipx sayesinde `pipx upgrade aider-chat` komutuyla güncelleyebilirsiniz.

##### Claude Code Sağlayıcıları (Seçenek 7)
Ana menüdeki `7` numaralı seçenek artık iki resmi senaryoyu kapsayan küçük bir menü açar:

- **GLM-4.6 (z.ai)** – https://z.ai/model-api üzerinden alınan API key’i maskeleyerek `~/.claude/settings.json` dosyasına yazar, `ANTHROPIC_BASE_URL` değerini otomatik olarak `https://api.z.ai/api/anthropic` şeklinde ayarlar ve `ANTHROPIC_DEFAULT_*` modellerini GLM-4.6/GLM-4.5-Air olarak belirler.
- **Moonshot kimi-k2** – https://platform.moonshot.ai/docs/guide/agent-support#install-claude-code rehberindeki adımlara göre önce Node.js ≥ 18 koşulunu doğrular (gerekirse Claude Code CLI’yi yeniden kurmayı teklif eder), ardından Moonshot API key’inizi ister ve taban URL’yi otomatik olarak `https://api.moonshot.ai/anthropic` olarak ayarlar; sonrasında tercih edilen modeli (`kimi-k2-0711-preview` veya `kimi-k2-turbo-preview`) kaydeder. Tüm değerler `~/.claude/settings.json` dosyasına yazıldığı için daha sonra sadece Enter’a basarak anahtarları koruyabilirsiniz.

Ek Bilgiler:

- **Menü Yolu:** `setup` ana menüsü → `7` (“Claude Code Sağlayıcı Yapılandırması”) → `1` (GLM-4.6/z.ai) veya `2` (Moonshot kimi-k2).
- **İstenen bilgiler:** Her iki akış da yalnızca API key sorar (varsa maskelemiş şekilde gösterilir). GLM senaryosunda `ANTHROPIC_BASE_URL` değeri otomatik olarak `https://api.z.ai/api/anthropic` yapılır; Moonshot’ta ise `https://api.moonshot.ai/anthropic` yazılır ve hangi kimi modelinin kullanılacağı seçilir.
- **CLI yenileme:** Moonshot seçeneği, resmi dokümana uygun olarak Node.js ≥ 18 doğrulaması yapar ve gerekirse `@anthropic-ai/claude-code` paketini npm ile yeniden kurmayı teklif eder.
- **Sonuç:** `~/.claude/settings.json` dosyası yeniden oluşturulur; token, base URL, timeout ve varsayılan modeller güncellenir, böylece `claude` komutu seçtiğiniz sağlayıcıyı anında kullanır.

#### Claude Code İçin Contains Studio Ajanları (Seçenek 12)

AI CLI menüsündeki `12` numaralı seçenek, [Contains Studio agents](https://github.com/contains-studio/agents) deposunu klonlayarak tüm `.md` ajan tanımlarını `~/.claude/agents/` dizinine kopyalar. Kurulumdan sonra Claude Code’u yeniden başlatarak yeni ajanların görünmesini sağlayabilirsiniz.

- Script `git` gerektirir; en güncel ajanları almak için istediğiniz zaman tekrar çalıştırabilirsiniz.
- Kopyalama işlemi `rsync -a --delete` ile yapıldığı için yerel klasörünüz depo ile aynı içerikte olur.
- Manuel yüklemek isterseniz:

```bash
git clone https://github.com/contains-studio/agents.git
cp -r agents/* ~/.claude/agents/
```

Depo, ajanları departmanlara göre (engineering, design, marketing vb.) sınıflandırdığı için Claude Code’un “Agents” panelinde kategorize bir şekilde listelenir.

#### Claude Code İçin Wes Hobson Ajanları (Seçenek 13)

AI CLI menüsündeki `13` numaralı seçenek, [wshobson/agents](https://github.com/wshobson/agents) deposunu `~/.claude/agents/` dizinine kopyalar. Bu koleksiyon, ürün teslimi, büyüme ve operasyon süreçlerine odaklanan ajanlar içerir; senkronizasyon sonrasında Claude Code’u yeniden başlatarak ajanları görebilirsiniz.

- `git` gerektirir ve `rsync -a --delete` ile yerel klasörü depo ile eşitler.
- Manuel kurulum için:

```bash
git clone https://github.com/wshobson/agents.git
cp -r agents/* ~/.claude/agents/
```

Böylece Contains Studio paketine ek olarak Wes Hobson’un ajan kitaplığı da kullanılabilir hale gelir.

#### OpenSpec CLI (AI CLI Seçenek 11)

AI CLI menüsündeki `11` numaralı seçenek, [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec) aracını npm üzerinden kurar (`npm install -g @fission-ai/openspec`). OpenSpec CLI, spesifikasyon odaklı geliştirme akışını Claude Code, Gemini CLI, Cursor vb. araçlara taşır; API anahtarı gerektirmez. (Contains Studio ajanları için aynı menüdeki `12` numaralı seçeneği kullanın.)

Kurulum adımları:

1. Node.js ≥ 18 ve `npm` varlığını doğrular, ardından CLI’ı global olarak yükler.
2. Kullanım hatırlatmaları basar:

```bash
openspec init          # depo içinde OpenSpec klasörünü başlatır
openspec plan          # değişiklik planı oluşturur
openspec sync          # spesifikasyonları güncel tutar
```

CLI kurulduktan sonra spesifikasyon odaklı akışı kullanabilir; ihtiyaç halinde Contains Studio ajanlarını yüklemek için `12` numaralı seçeneği çalıştırabilirsiniz.

Her iki akış da ilgili dokümantasyon bağlantılarını gösterir ve mevcut anahtarlarınızı maskeleyerek hızlıca rota değiştirmenize olanak tanır.

#### AI Framework Menüsü
Önce `pipx` ve gerekirse Python kurulumunu doğrular, ardından Super* framework’lerini tek tek veya toplu olarak kurar. API anahtar istemleri `/dev/tty` üzerinden aktığı için `curl | bash` senaryolarında bile güvenli şekilde giriş yapabilirsiniz.

| Seçenek | Framework | Detaylar |
|---------|-----------|----------|
| `1` | SuperGemini | `pipx` ile kurulur, PATH güncellemesini ve gerekli login komutlarını otomatik özetler. |
| `2` | SuperQwen | `attach_tty_and_run` ile sarıldığı için Qwen kimlik doğrulamaları kesintisiz ilerler. |
| `3` | SuperClaude | Aynı TTY korumalarıyla Anthropic araçlarını kurar, gerekirse temizleme yordamları sağlar. |
| `4` | Hepsini Kur | Tüm Super* framework’lerini arka arkaya kurar; daha önce kurulanlar atlanır veya güncellenir. |

### Kullanım Notları

- **PATH güncellemeleri** script tarafından otomatik `source` edilir; yeni komutlar aynı terminalde erişilebilir.
- **API anahtarları** maskelenerek gösterilir, boş bırakılırsa mevcut değer korunur.
- **TTY gereksinimleri** `attach_tty_and_run` ile çözüldü; artık `Raw mode is not supported` hatası alınmaz.
- **Qoder CLI override’ları** için `QODER_NPM_PACKAGE`, `QODER_CLI_BUNDLE`, `--package`, `--bundle` veya `--skip-probe` parametrelerini kullanarak doğru paketi/dosyayı seçebilirsiniz.
- **Qwen CLI korumaları** Node.js ≥ 18 şartını uygular, gerekirse Node’u otomatik kurar ve kapalı ortamlarda `--package` ile özel bir npm paketi gösterebilirsiniz; `qwen login` istemleri `/dev/tty` üzerinden akar.
- **Uzaktan çalışma** sırasında modüller geçici dizine alınır ve tekrar kullanılmak üzere önbelleğe atılır.

### Sorun Giderme

- `curl: (3)` hatası: En güncel `setup` sürümünü kullanın; `SCRIPT_BASE_URL` artık her alt süreçte mevcut.
- `mask_secret` hatası: GLM menüsü artık utils’i otomatik yüklüyor.
- SuperQwen/SuperClaude menüsü girdi beklemiyorsa: Güncel sürüme geçin; `attach_tty_and_run` eklendi.
- Qoder CLI paketi bulunamadı: `QODER_NPM_PACKAGE` değişkenini ayarlayın, `install_qoder_cli --package @custom/cli` veya `--bundle /yol/qoder.tgz` seçeneklerini kullanın.
- Qwen CLI Node.js uyarısı veriyor: Menünün `3` numaralı seçeneğiyle Node.js kurun ya da `install_qwen_cli`’nin otomatik kurulumuna izin verin; işlem Node.js ≥ 18 gerektirir.
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
