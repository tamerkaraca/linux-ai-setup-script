# Technology Stack

This document details the core technologies, languages, and frameworks utilized within the AI Development Environment Setup Script project.

## 1. Core Languages and Platforms

-   **Bash:** The primary scripting language for the entire project, responsible for orchestrating installations, configurations, and user interactions. It forms the backbone of the setup process.
-   **Node.js:** Supported as a runtime environment for various AI CLI tools and frameworks. The script includes modules for managing Node.js versions via NVM and installing associated package managers.
-   **Python:** Supported as a core language for many AI/ML tools and libraries. The script provides robust installation and management for Python, pip, and pipx.
-   **PHP:** Included to support development environments that require PHP-based tools or frameworks, such as Composer.
-   **Operating Systems:** The script is designed to be fully compatible with and optimize setups for:
    -   **Linux:** Various distributions leveraging `apt`, `dnf`, `yum`, or `pacman`.
    -   **Windows Subsystem for Linux (WSL):** Specifically tailored to integrate seamlessly within the WSL environment.
    -   **macOS:** Utilizes Homebrew for efficient package management on Apple's operating system.

## 2. Package Managers and Tooling

The project integrates and leverages several key package managers and development tools:

-   **Homebrew:** The de-facto package manager for macOS, also used on Linux. The script utilizes Homebrew for installing system-level dependencies and applications.
-   **pipx:** A tool for installing and running Python applications in isolated environments, ensuring dependencies do not conflict.
-   **npm (Node Package Manager):** The default package manager for Node.js, used for installing a wide array of JavaScript-based AI CLI tools and utilities.
-   **Yarn:** An alternative JavaScript package manager, supported for projects that prefer its features and performance.
-   **pnpm:** Another efficient JavaScript package manager, known for its disk space efficiency and speed.
-   **Bun:** A fast all-in-one JavaScript runtime, bundling a bundler, a transpiler, and a package manager.
-   **Composer:** The dependency manager for PHP, included for PHP development environment setups.

## 3. AI Tools and Frameworks

The script supports the installation and configuration of a comprehensive suite of AI-related command-line interfaces and frameworks:

### AI CLI Tools:

-   **Claude Code:** CLI for interacting with Anthropic's Claude models.
-   **Gemini CLI:** Command-line interface for Google's Gemini models.
-   **OpenCode:** Tooling for AI-powered code generation and assistance.
-   **Qoder:** CLI for code generation and analysis.
-   **Qwen:** Command-line tools for Alibaba's Qwen models.
-   **OpenAI Codex:** Tools for interacting with OpenAI's code generation models.
-   **Cursor Agent:** CLI for the AI-powered code editor, Cursor.
-   **Aider:** AI pair programming in your terminal.
-   **GitHub Copilot CLI:** Command-line interface for GitHub Copilot.
-   **Kilocode:** AI coding assistant.
-   **Auggie:** Code augmentation and generation tool.
-   **Droid:** AI-powered development tools.
-   **Jules:** Google's AI assistant CLI.
-   **Continue:** Open-source AI code assistant.

### AI Frameworks:

-   **SuperGemini Framework:** An advanced framework for leveraging Gemini models.
-   **SuperQwen Framework:** A framework built around Alibaba's Qwen models.
-   **SuperClaude Framework:** A framework designed for integration with Anthropic's Claude models.

## 4. Architectural Considerations

The project itself is structured as a modular shell scripting utility. Its architecture is characterized by:

-   **Modular Design:** Functionality is broken down into small, reusable `.bash` modules (e.g., `modules/cli`, `modules/frameworks`, `modules/utils`). This enhances maintainability and allows for independent development and testing of features.
-   **Platform Detection:** Utilizes `platform_detection.bash` to adapt installation commands and configurations based on the detected operating system (Linux/WSL, macOS) and package manager.
-   **Bilingual Support:** Incorporates mechanisms for multi-language output (English and Turkish), managed through associative arrays and locale detection.
-   **Self-Healing Mechanisms:** Includes logic to handle common environment issues such as CRLF line endings and permission problems, ensuring robustness during execution.
-   **Remote Execution Safety:** Designed to function reliably even when executed via `curl | bash`, ensuring that all necessary modules and helper functions are correctly sourced.
