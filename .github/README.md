# Release Publisher Workflow

## Overview

This document explains the "Release Publisher" GitHub Actions workflow, a powerful, configuration-driven system designed to automate the creation of GitHub Releases.

The workflow is manually triggered and uses a combination of a main workflow file, a TOML manifest for release configuration, and a YAML file for matrix strategies to provide a flexible and robust release process.

---

## File Responsibilities

The automation is powered by three key files located in the `.github` directory:

-   `workflows/release-publisher.yml`

    -   **Role**: **Core Workflow Executor**.
    -   **Description**: This is the main, immutable workflow file that orchestrates the entire release process. It reads the configuration from the other two files, runs the defined jobs (checking, building, releasing), and handles the logic. **You should not modify this file.**

-   `release-manifest.toml`

    -   **Role**: **Primary Configuration (The "What" and "How")**.
    -   **Description**: This is the single source of truth for your release. It defines what the release contains (e.g., release notes template, asset files), how the pre-flight checks and builds are performed, and other release behaviors like requiring manual approval.

-   `actions-config.yml`
    -   **Role**: **Supplemental Matrix Strategy**.
    -   **Description**: This file complements the manifest by defining the matrix strategies for the `check` and `build` jobs. This allows you to easily run these jobs across different operating systems, language versions, or architectures without cluttering the main manifest file.

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

This file controls the core aspects of the release. Below is a breakdown of each section.

#### `[trigger]`

-   `tag_pattern` (string): A glob pattern to define valid tag formats. While not currently enforced by the workflow, it serves as documentation for your tagging convention.

#### `[release]`

-   `skip_approval` (boolean): If `false` (default), the workflow will pause for manual approval in a "release" environment before building and publishing. If `true`, it proceeds automatically after the "check" job succeeds.
-   `body_template` (multiline string): A template for the release notes. It supports the following placeholders:

    -   `{{tag}}`: The release tag being created.
    -   `{{changelog}}`: Automatically generated from git commit history between the new tag and the previous one.
    -   `{{assets_links}}`: A markdown list of links to the uploaded release assets.
    -   `{{contributors}}`: A placeholder for contributor information (see `[release.contributors]`).
    -   `{{release_date}}`: A placeholder for the release date (see `[release.date]`).

-   `[release.changelog]`

    -   `previous_tag_strategy` (string): Defines how to find the previous tag for generating the changelog. Currently supports `"latest"`.

-   `[release.assets]`
    -   `include` (array of strings): A list of glob patterns for files to be included as release assets.
    -   `exclude` (array of strings): A list of glob patterns to exclude files that might otherwise match an `include` pattern.

#### `[check]`

This section configures the pre-flight "Check & Test" job.

-   `run_script` (string): The path to the executable script that runs your checks (e.g., linting, tests).
-   `runs-on` (string): The GitHub Actions runner to use for the check job.
-   `[check.features.cache]`
    -   `enable` (boolean): If `true`, enables dependency caching.
    -   `path` (string): The path to the directory to cache.
    -   `key_file` (string): The file whose hash is used to generate the cache key (e.g., `pyproject.toml`, `package-lock.json`).

#### `[build]`

This section configures the "Build and Release" job.

-   `run_script` (string): The path to the executable script that builds your release artifacts. The script will be run for each `target` defined in the `actions-config.yml` build matrix.
-   `runs-on` (string): The GitHub Actions runner to use for the build job.
-   `[build.features.cache]`
    -   Same structure and purpose as the `[check]` cache, but for the build environment.

### `actions-config.yml`

This file provides the matrix configurations for the jobs defined in the manifest.

#### `check`

-   `matrix` (mapping): Defines the matrix for the `check` job. The workflow will create a job for each possible combination of the provided keys (e.g., `os`, `python-version`).

```yaml
check:
    matrix:
        os: [ubuntu-latest, windows-latest]
        python-version: ["3.9", "3.10"]
```

#### `build`

-   `matrix` (mapping): Defines the matrix for the `build` job. The `run_script` from the manifest will be executed for each `target` in this list.

```yaml
build:
    matrix:
        target: [x86_64, arm64]
```
