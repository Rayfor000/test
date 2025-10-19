"""
Dynamically generates release notes based on a TOML manifest and git history.

This script is designed to be called from a GitHub Actions workflow. It reads
a manifest file, gathers information from environment variables and git,
replaces placeholders in a template, and prints the final release notes
body to stdout.
"""

import os
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

try:
    import toml
except ImportError:
    print("Error: 'toml' package is not installed. Please run 'pip install toml'", file=sys.stderr)
    sys.exit(1)


def get_git_changelog(config: dict, current_tag: str) -> str:
    """
    Generates a changelog by comparing the current tag with the previous one.

    Args:
        config: The 'release.changelog' section of the manifest.
        current_tag: The current git tag (GITHUB_REF_NAME).

    Returns:
        A formatted string of commit messages, or a default message if no
        changes are found or an error occurs.
    """
    git_executable = shutil.which("git")
    if not git_executable:
        raise RuntimeError("git executable not found in PATH")

    try:
        # Get all tags sorted by version descending
        tags_result = subprocess.run([git_executable, "tag", "--sort=-v:refname"], capture_output=True, text=True, check=True, encoding="utf-8") # noqa: S603
        tags = tags_result.stdout.strip().split("\n")

        previous_tag = None
        if current_tag in tags:
            try:
                current_index = tags.index(current_tag)
                if current_index + 1 < len(tags):
                    previous_tag = tags[current_index + 1]
            except (ValueError, IndexError):
                pass  # Should not happen if tag is in list

        # Define the pretty format for git log
        log_format = "- %s (%h)"

        # Determine the git log command based on previous_tag
        if previous_tag:
            diff_method = config.get("diff_method", "..")
            if diff_method not in ["..", "..."]:
                diff_method = ".."

            command = [git_executable, "log", f"--pretty=format:{log_format}", f"{previous_tag}{diff_method}{current_tag}"]
        else:
            # First release, get all logs up to the current tag
            command = [git_executable, "log", f"--pretty=format:{log_format}", current_tag]

        # We trust the tag names from the GitHub environment not to contain malicious shell characters.
        # The arguments are passed as a list, which prevents shell injection.
        changelog_result = subprocess.run(command, capture_output=True, text=True, check=True, encoding="utf-8")  # noqa: S603

        changelog = changelog_result.stdout.strip()
        return changelog if changelog else "No changes in this release."

    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Warning: Git command failed: {e}", file=sys.stderr)
        return "No changes in this release."


def get_release_date(config: dict) -> str:
    """
    Generates a formatted, timezone-aware release date string.

    Args:
        config: The 'release.date' section of the manifest.

    Returns:
        An ISO 8601 formatted date string, enclosed in backticks.
    """
    tz_str = config.get("timezone", "+00:00")
    try:
        sign = -1 if "-" in tz_str else 1
        hours, minutes = map(int, tz_str.replace("+", "").replace("-", "").split(":"))
        tz_offset = timedelta(hours=hours, minutes=minutes) * sign
        tz = timezone(tz_offset)
    except Exception:
        tz = timezone.utc

    now = datetime.now(timezone.utc).astimezone(tz)
    # Format to ISO 8601 with 6 digits for microseconds
    iso_date = now.isoformat(timespec="microseconds")
    return f"`{iso_date}`"


def main():
    """
    Main function to generate and print release notes.
    """
    # 1. Read environment variables
    github_repo = os.getenv("GITHUB_REPOSITORY")
    current_tag = os.getenv("GITHUB_REF_NAME")
    manifest_path_str = os.getenv("MANIFEST_PATH")

    if not github_repo:
        print("Error: Missing GITHUB_REPOSITORY environment variable.", file=sys.stderr)
        sys.exit(1)
    if not current_tag:
        print("Error: Missing GITHUB_REF_NAME environment variable.", file=sys.stderr)
        sys.exit(1)
    if not manifest_path_str:
        print("Error: Missing MANIFEST_PATH environment variable.", file=sys.stderr)
        sys.exit(1)

    try:
        owner, repo_name = github_repo.split("/")
    except ValueError:
        print(f"Error: Invalid GITHUB_REPOSITORY format: {github_repo}", file=sys.stderr)
        sys.exit(1)

    # 2. Read and parse the manifest file
    manifest_path = Path(manifest_path_str)
    if not manifest_path.is_file():
        print(f"Error: Manifest file not found at '{manifest_path_str}'", file=sys.stderr)
        sys.exit(1)

    manifest = toml.load(manifest_path)
    release_config = manifest.get("release", {})
    body_template = release_config.get("body_template", "")

    # 3. Prepare variables for substitution
    changelog_config = release_config.get("changelog", {})
    contributors_config = release_config.get("contributors", {})
    assets_config = release_config.get("assets", {})
    date_config = release_config.get("date", {})

    # Handle contributors template
    contributors_template = contributors_config.get("template", "")
    contributors = contributors_template.replace("{{owner}}", owner).replace("{{repo_name}}", repo_name)

    # Handle assets links
    assets_links = ""
    asset_file_name = assets_config.get("associate", {}).get("assets_links")
    if asset_file_name:
        asset_path = manifest_path.parent / asset_file_name
        if asset_path.is_file():
            assets_links = asset_path.read_text(encoding="utf-8")

    # 4. Perform all substitutions
    replacements = {
        "{{tag}}": current_tag,
        "{{repo_name}}": repo_name,
        "{{owner}}": owner,
        "{{changelog}}": get_git_changelog(changelog_config, current_tag),
        "{{contributors}}": contributors,
        "{{assets_links}}": assets_links,
        "{{release_date}}": get_release_date(date_config),
    }

    final_body = body_template
    for placeholder, value in replacements.items():
        final_body = final_body.replace(placeholder, value)

    # 5. Print final body to stdout
    print(final_body)


if __name__ == "__main__":
    main()
