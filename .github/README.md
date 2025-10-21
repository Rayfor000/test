# Release Publisher Workflow

## Overview

This document explains the "Release Publisher" GitHub Actions workflow, a powerful, configuration-driven system designed to automate the creation of GitHub Releases.

The workflow is manually triggered and uses a combination of a workflow file (`release-publisher.yml`) and a single, powerful configuration manifest (`release-manifest.toml`) to provide a flexible and robust release process.

---

## File Responsibilities

The automation is powered by the following files located in the `.github` directory:

-   `workflows/release-publisher.yml`

    -   **Role**: **Core Workflow Executor**.
    -   **Description**: This is the main, immutable workflow file that orchestrates the entire release process. It reads its configuration from `release-manifest.toml`, runs the defined jobs (checking, building, releasing), and handles the logic. **You should not modify this file.**

-   `release-manifest.toml`

    -   **Role**: **Single Source of Truth (The "What", "How", and "Where")**.
    -   **Description**: This is the **sole manifest** that configures the entire release. It defines the release contents, pre-flight checks, build steps (including their CI/CD matrix strategies), and other critical behaviors like requiring manual approval.

---

## Usage

The workflow is triggered manually via the `workflow_dispatch` event.

1.  Navigate to the **Actions** tab of the repository.
2.  Select the **Release Publisher** workflow from the list.
3.  Click the **"Run workflow"** dropdown.
4.  Enter the `tag` you wish to create for the release (e.g., `v1.2.3`). This tag **must not** already exist.
5.  Click **"Run workflow"** to start the process.

---

## Configuration Details

### `release-manifest.toml`

As the **single source of truth**, this file consolidates all configuration for the release workflow. Below is a breakdown of each section.

#### `[trigger]`

-   `tag_pattern` (string): A glob pattern to define valid tag formats. While not currently enforced by the workflow, it serves as documentation for your tagging convention.

#### `[release]`

This table controls the metadata and behavior of the final GitHub Release.

-   `skip_approval` (boolean): If `false` (default), the workflow will pause for manual approval. If `true`, it proceeds automatically after the `check` job succeeds.
-   `body_template` (multiline string): A template for the release notes, supporting placeholders like `{{tag}}`, `{{changelog}}`, and `{{assets_links}}`.
-   `[release.assets]`
    -   `include` (array of strings): Glob patterns for files to be included as release assets.
    -   `exclude` (array of strings): Glob patterns to exclude files from the asset list.

#### `[check]` and `[build]`

These tables define the CI/CD jobs. They now fully control the execution environment, including the matrix strategy, which was previously managed in a separate file.

-   `run_script` (string): The path to the executable script that runs your checks or builds.
-   `runs-on` (string): The GitHub Actions runner to use for the job (e.g., `ubuntu-latest`).
-   `matrix` (table): **(Key Feature)** Defines a matrix strategy for the job. The `run_script` will be executed for each combination defined in the matrix.
-   `[check.features.cache]` / `[build.features.cache]`
    -   Enables and configures dependency caching for the job.

---

### Example: Full `release-manifest.toml`

Here is a complete example demonstrating a unified configuration, including a `matrix` strategy for both the `check` and `build` jobs.

```toml
# .github/release-manifest.toml

[trigger]
# Documents the expected tag format, e.g., "v1.2.3"
tag_pattern = "v[0-9]+.[0-9]+.[0-9]+"

[release]
# Set to 'false' to require a manual approval step before publishing.
skip_approval = false

# Defines the assets to include in the release.
[release.assets]
include = ["dist/*", "CHANGELOG.md"]
exclude = ["dist/*.map"]

# Defines the template for the GitHub Release body.
body_template = """
## Release: {{tag}}

**Released on**: {{release_date}}

### Changelog
{{changelog}}

### Assets
{{assets_links}}

### Contributors
{{contributors}}
"""

[check]
# Script to run for pre-flight checks (lint, test, etc.)
run_script = ".github/release.d/python-check.sh"
runs-on = "ubuntu-latest"

# Run checks against multiple Python versions.
matrix = { "python-version" = ["3.9", "3.10", "3.11"] }

[check.features.cache]
enable = true
path = "~/.cache/pip"
key_file = "pyproject.toml"

[build]
# Script to run for building release artifacts.
run_script = ".github/release.d/build-python.sh"
runs-on = "ubuntu-latest"

# Build on multiple operating systems and Python versions.
# The 'include' key allows defining specific combinations.
matrix = { include = [
    { os = "ubuntu-latest", "python-version" = "3.11" },
    { os = "windows-latest", "python-version" = "3.11" },
]}

[build.features.cache]
enable = true
path = "~/.cache/pip"
key_file = "pyproject.toml"
```
