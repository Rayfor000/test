# .github/release.d/generate-release-notes.py

import argparse
import os
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

import tomllib

# --- Constants ---
MANIFEST_PATH = Path(".github/release-manifest.toml")

# --- Utility Functions ---


def run_command(command: list[str], check: bool = True, **kwargs) -> subprocess.CompletedProcess:
    """Executes a command and returns its completed process."""
    print(f"Executing: {' '.join(command)}", file=sys.stderr)
    try:
        return subprocess.run(
            command,
            check=check,
            capture_output=True,
            text=True,
            encoding="utf-8",
            **kwargs,
        )
    except FileNotFoundError:
        print(f"Error: Command not found: '{command[0]}'. Is it in your PATH?", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {' '.join(command)}", file=sys.stderr)
        print(f"Stdout: {e.stdout.strip()}", file=sys.stderr)
        print(f"Stderr: {e.stderr.strip()}", file=sys.stderr)
        raise


def die(message: str, exit_code: int = 1) -> NoReturn:
    """Prints an error message to stderr and exits."""
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(exit_code)


def get_previous_tag() -> str:
    """Fetches the most recent git tag."""
    print("--- Determining previous tag ---")
    try:
        # --abbrev=0 removes the commit hash from the tag.
        result = run_command(["git", "describe", "--tags", "--abbrev=0"])
        previous_tag = result.stdout.strip()
        if not previous_tag:
            die("Could not determine the previous tag. 'git describe' returned empty.")
        print(f"Found previous tag: {previous_tag}")
        return previous_tag
    except (subprocess.CalledProcessError, FileNotFoundError):
        die("Could not determine the previous tag. Ensure git is installed and you have at least one tag.")


def main():
    """Generates release notes based on git history and a template."""
    parser = argparse.ArgumentParser(description="Generate release notes.")
    parser.add_argument("--tag", required=True, help="The new tag for the release.")
    parser.add_argument("--notes-file", required=True, type=Path, help="The output file for the release notes.")
    args = parser.parse_args()

    # 1. Load manifest
    print(f"Loading manifest from: {MANIFEST_PATH}")
    if not MANIFEST_PATH.exists():
        die(f"Manifest file not found at '{MANIFEST_PATH}'.")
    try:
        with MANIFEST_PATH.open("rb") as f:
            manifest = tomllib.load(f)
    except tomllib.TOMLDecodeError as e:
        die(f"Could not parse manifest file: {e}")

    # 2. Get previous tag
    previous_tag = get_previous_tag()

    # 3. Generate changelog
    print(f"--- Generating changelog from '{previous_tag}' to '{args.tag}' ---")
    log_command = ["git", "log", f"{previous_tag}..{args.tag}", "--pretty=format:- %s (%h)"]
    changelog_result = run_command(log_command, check=False)
    changelog_content = changelog_result.stdout.strip() or "No changes in this release."

    # 4. Render template
    release_config = manifest.get("release", {})
    body_template = release_config.get("body_template", "Release {{tag}}")
    repo_full_name = os.environ.get("GITHUB_REPOSITORY", "owner/repo")
    owner, repo_name = repo_full_name.split("/", 1)

    # Get contributor template
    contributors_template = release_config.get("contributors", {}).get("template", "")

    replacements = {
        "{{repo_name}}": repo_name,
        "{{owner}}": owner,
        "{{tag}}": args.tag,
        "{{changelog}}": changelog_content,
        "{{assets_links}}": "*(Artifacts are listed below)*",
        "{{contributors}}": contributors_template.replace("{{owner}}", owner).replace("{{repo_name}}", repo_name),
    }

    body = body_template
    for placeholder, value in replacements.items():
        body = body.replace(placeholder, value)

    args.notes_file.write_text(body, encoding="utf-8")
    print(f"Successfully generated release notes at '{args.notes_file}'")


if __name__ == "__main__":
    main()
