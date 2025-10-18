# GlocalText

GlocalText is a powerful command-line tool that automates text translation using a highly intuitive, **firewall-style `rules` system**. It processes text by evaluating a list of rules from top to bottom, giving you precise, predictable control over your localization workflow.

---

## Table of Contents

-   [Introduction](#introduction)
-   [Key Features](#key-features)
-   [Installation](#installation)
-   [Configuration (`config.yaml`)](#configuration-configyaml)
-   [Usage](#usage)
-   [Contributors](#contributors)
-   [Contributing](#contributing)
-   [License](#license)

---

## Introduction

GlocalText is a powerful command-line tool that automates text translation using a highly intuitive, **firewall-style `rules` system**. It processes text by evaluating a list of rules from top to bottom, giving you precise, predictable control over your localization workflow.

At its core, the logic is simple: **for most actions, the first rule that matches wins**. When GlocalText extracts a piece of text, it checks your `rules` one by one. When it finds a matching rule for an action like `skip` or `replace`, it executes it and immediately stops processing for that text.

However, the `modify` action behaves differently. It allows for **chainable pre-processing**. A `modify` rule will alter the text and then pass the _modified_ text back into the rules engine, allowing subsequent rules (including other `modify` rules) to act on it before it is finally sent for translation. This enables powerful, step-by-step text manipulation.

This design offers several key advantages:

1.  **Predictable Control**: You know exactly which rule will apply. There's no complex logic to manage—just a straightforward, top-down priority list.
2.  **Flexible Matching**: Define how a rule identifies text. You can use `exact` for a perfect match or `contains` to find a substring. A `match` condition can be a **single string** or a **list of strings**, allowing for flexible `OR` logic.
3.  **Default Action**: If no rules match a piece of text, it is sent to the configured translation provider for automated translation.

This unified, firewall-inspired `rules` engine provides a clear and powerful way to manage your entire translation workflow, from protecting brand names to providing authoritative manual translations.

## Key Features

-   **Unified Firewall `rules` Engine**: A single, powerful system to control your entire translation workflow.
-   **Top-Down Priority**: Rules are evaluated from top to bottom—the first rule that matches wins, providing predictable and precise control.
-   **Flexible Matching**: Match text with `exact` (full string) or `contains` (substring). The condition can be a single string or a list for flexible `OR` logic.
-   **Clear Actions**: Define clear actions:
    -   `skip`: Protects brands, code, and variables from being translated.
    -   `replace`: Provides an authoritative, final translation, skipping the API.
    -   `modify`: Pre-processes text by replacing a matched segment before sending it for translation.
-   **Multiple Provider Support**: Configure and use different translation providers like Google Translate and Google Gemini.
-   **Task-Based Configuration**: Define multiple, independent translation tasks in a single configuration file.
-   **Glob Pattern Matching**: Precisely include or exclude files for translation using `glob` patterns.
-   **Flexible Output Control**: Choose to either modify original files directly (`in_place: true`) or create new, translated versions in a specified path (`in_place: false`).
-   **Incremental Translation**: Save time and cost by only translating new or modified content.

## Configuration (`config.yaml`)

### `output`

-   **`in_place`**: A boolean indicating whether to modify files directly (`true`) or write them to a separate directory (`false`). Defaults to `true`.
-   **`path`**: The output directory path. Required if `in_place` is `false`.
-   **`filename_suffix`**: A suffix to add to the output filenames (e.g., `_translated`).
-   **`incremental`**: A boolean (`true` or `false`) to enable or disable incremental translation for this task. When enabled, only new or modified text fragments are sent for translation, saving time and cost. Defaults to `false`.

### API Key Configuration

API keys are configured under the `providers` section. GlocalText follows a clear priority for API key resolution:

1.  **Environment Variable**: It will first check for a dedicated environment variable (e.g., `GEMINI_API_KEY`).
2.  **Configuration File**: If the environment variable is not set, it will use the `api_key` specified in the `config.yaml` file.

This approach allows for flexibility in development (using the config file) and security in production (using environment variables).

## Usage

### Command-Line Options

-   `--config <path>` or `-c <path>`: Specifies the path to your `config.yaml` file. Defaults to `config.yaml` in the current directory.
-   `--debug [LOG_DIR_PATH]`: Enables detailed debug logging. If an optional directory path is provided, the debug log will be saved to `glocaltext_debug.log` inside that directory. Otherwise, debug information is printed to the console.

## Contributors

<a href="https://github.com/OG-Open-Source/GlocalText/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=OG-Open-Source/GlocalText" />
</a>

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## License

### Primary Project License

The main source code and documentation in this repository are licensed under the [MIT License](https://opensource.org/license/MIT).

### Third-Party Components and Attributions

This project utilizes external components or code whose copyright and licensing requirements must be separately adhered to:

| Component Name                    | Source / Author | License Type | Location of License Document     | Hash Values                      |
| :-------------------------------- | :-------------- | :----------- | :------------------------------- | -------------------------------- |
| OG-Open-Source README.md Template | OG-Open-Source  | MIT          | /licenses/OG-Open-Source/LICENSE | 120aee1912f4c2c51937f4ea3c449954 |

---

© 2025 [OG-Open-Source](https://github.com/OG-Open-Source). All rights reserved.
