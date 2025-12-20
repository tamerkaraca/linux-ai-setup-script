# Product Guidelines

This document outlines the core principles governing the communication, visual identity, and development of the AI Development Environment Setup Script. Adherence to these guidelines ensures a consistent, professional, and high-quality user experience.

## 1. Prose Style and Communication Tone

All user-facing communication, including documentation, in-script messages, and error outputs, must be **Formal and Technical**.

-   **Precision:** Language should be unambiguous, precise, and technically accurate. Avoid jargon where simpler terms suffice, but do not oversimplify complex technical concepts.
-   **Clarity:** Prioritize clear and direct communication. Instructions and explanations should be easy to follow and logically structured.
-   **Professionalism:** Maintain a professional and objective tone. Avoid overly casual language, colloquialisms, or humor.
-   **Audience:** Assume the user has a technical background but may not be an expert in every tool or platform. Provide necessary context without being patronizing.

## 2. Visual Identity and CLI Output

The script's command-line interface (CLI) must be **Informative and Structured**. The primary goal is to convey information effectively, not to create a visually elaborate experience.

-   **Structured Output:** Employ clear, hierarchical structures for presenting information. Use headers, lists, and tables to organize output logically. For example, menus should be numbered, and results should be presented with clear labels.
-   **Purposeful Use of Color:** Color should be used sparingly and with clear intent. Reserve specific colors to indicate status:
    -   **Green:** Success, completion, and positive outcomes.
    -   **Yellow:** Warnings, potential issues, or steps requiring user attention.
    -   **Red:** Errors, failures, and critical alerts.
    -   **Blue/Cyan:** Informational messages, section headers, or prompts.
-   **Readability:** Ensure that all text output is highly readable, with appropriate line spacing and indentation. Avoid long, unbroken blocks of text.
-   **Minimalism:** While the output should be structured, it should not be cluttered. ASCII art and decorative banners should be used judiciously, primarily at the start of the script, to avoid distracting from the core information.

## 3. Contribution Guidelines

To maintain the project's quality, stability, and maintainability, all contributions must exhibit **Strict Adherence to Standards**.

-   **Coding Conventions:** All shell scripts must conform to the existing coding style. This includes variable naming, function structure, and commenting practices.
-   **Validation and Linting:** Before submission, all modified shell scripts MUST be validated for syntax (`bash -n`) and best practices (`shellcheck`). Contributions that fail these checks will not be accepted.
-   **Testing:** Contributors are responsible for thoroughly testing their changes. This includes verifying functionality on all supported platforms (Linux, WSL, macOS) and ensuring that both local and remote execution (`curl | bash`) workflows are unaffected.
-   **Documentation:** Any changes that affect the user experience, add new features, or alter existing functionality must be accompanied by corresponding updates to the `README.md` and any other relevant documentation, in both English and Turkish.
-   **Commit Discipline:** Commit messages should be clear, concise, and follow a conventional format (e.g., `feat(cli): Add support for new tool`). Atomic commits are preferred.
-   **Pull Requests:** Pull requests must include a clear description of the changes, the motivation behind them, and evidence of testing (e.g., logs, screenshots).
