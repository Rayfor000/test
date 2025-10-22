# .github/release.d/run_release.py

import argparse
import fnmatch
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import NoReturn

import tomllib

# --- Constants ---
MANIFEST_PATH = Path(".github/release-manifest.toml")
DIST_DIR = Path("dist")

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


# --- Release Steps ---


def load_manifest() -> dict:
    """Loads and validates the release manifest."""
    print(f"Loading manifest from: {MANIFEST_PATH}")
    if not MANIFEST_PATH.exists():
        die(f"Manifest file not found at '{MANIFEST_PATH}'.")
    try:
        with MANIFEST_PATH.open("rb") as f:
            return tomllib.load(f)
    except tomllib.TOMLDecodeError as e:
        die(f"Could not parse manifest file: {e}")


def check_for_existing_release(tag: str):
    """Checks if a GitHub release for the given tag already exists."""
    print(f"Checking for existing release with tag '{tag}'...")
    gh_token = os.environ.get("GH_TOKEN")
    if not gh_token:
        die("GH_TOKEN environment variable not set.")

    # `gh release view` exits with 0 if found, non-zero if not found.
    env = {k: v for k, v in os.environ.items() if v is not None}
    env["GITHUB_TOKEN"] = gh_token
    result = subprocess.run(
        ["gh", "release", "view", tag],
        capture_output=True,
        text=True,
        env=env,
    )
    if result.returncode == 0:
        die(f"A release for tag '{tag}' already exists.")
    print("No existing release found. Proceeding.")


def handle_approval(manifest: dict):
    """Handles the manual approval gate if configured."""
    if not manifest.get("release", {}).get("skip_approval", False):
        print("\n" + "=" * 60)
        print("MANUAL APPROVAL REQUIRED")
        print("Review the build artifacts and logs before proceeding.")
        print("=" * 60)
        try:
            response = input("Type 'yes' to continue with the release: ").strip().lower()
            if response != "yes":
                die("Release cancelled by user.", exit_code=0)
        except EOFError:
            die("Approval prompt failed. Cannot continue in non-interactive mode.")
        print("Approval granted. Continuing with release.")


def run_scripts(manifest: dict):
    """Runs the pre-flight check and build scripts defined in the manifest."""
    check_script = manifest.get("check", {}).get("run_script")
    if check_script and Path(check_script).exists():
        print(f"\n--- Running Check Script: {check_script} ---")
        run_command([check_script])
        print("--- Check Script Finished ---")
    else:
        print(f"Check script '{check_script}' not found or not defined. Skipping.")

    build_script = manifest.get("build", {}).get("run_script")
    if build_script and Path(build_script).exists():
        print(f"\n--- Running Build Script: {build_script} ---")
        run_command([build_script])
        print("--- Build Script Finished ---")
    else:
        print(f"Build script '{build_script}' not found or not defined. Skipping.")


def gather_assets(manifest: dict) -> list[Path]:
    """Gathers release assets based on include/exclude rules."""
    print("\n--- Gathering release assets ---")
    asset_config = manifest.get("release", {}).get("assets", {})
    include_patterns = asset_config.get("include", ["*"])
    exclude_patterns = asset_config.get("exclude", [])

    if not DIST_DIR.is_dir():
        print(f"Warning: Distribution directory '{DIST_DIR}' not found. No assets will be included.", file=sys.stderr)
        return []

    all_files = [p for p in DIST_DIR.rglob("*") if p.is_file()]
    included_files = set()

    for pattern in include_patterns:
        included_files.update(p for p in all_files if fnmatch.fnmatch(p.name, pattern))

    for pattern in exclude_patterns:
        # Use a copy for iteration while removing items
        for file_to_check in list(included_files):
            if fnmatch.fnmatch(file_to_check.name, pattern):
                included_files.remove(file_to_check)

    print(f"Found {len(included_files)} assets to include:")
    sorted_assets = sorted(list(included_files))
    for asset in sorted_assets:
        print(f"  - {asset}")
    return sorted_assets


def generate_release_notes(manifest: dict, tag: str) -> Path:
    """Generates the release notes and returns the path to the notes file."""
    print("\n--- Generating Release Notes ---")
    # 1. Get previous tag
    try:
        result = run_command(["git", "describe", "--tags", "--abbrev=0"])
        previous_tag = result.stdout.strip()
        if not previous_tag:
            die("Could not determine the previous tag. 'git describe' returned empty.")
        print(f"Found previous tag: {previous_tag}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        die("Could not determine the previous tag. Ensure git is installed and you have at least one tag.")

    # 2. Generate changelog
    print(f"Generating changelog from '{previous_tag}' to '{tag}'...")
    log_command = ["git", "log", f"{previous_tag}..{tag}", "--pretty=format:- %s (%h)"]
    changelog_result = run_command(log_command, check=False)
    changelog_content = changelog_result.stdout.strip() or "No changes in this release."

    # 3. Render template
    release_config = manifest.get("release", {})
    body_template = release_config.get("body_template", "Release {{tag}}")
    repo_full_name = os.environ.get("GITHUB_REPOSITORY", "owner/repo")
    owner, repo_name = repo_full_name.split("/", 1)
    release_date = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    # Get contributor template
    contributors_template = release_config.get("contributors", {}).get("template", "")

    replacements = {
        "{{repo_name}}": repo_name,
        "{{owner}}": owner,
        "{{tag}}": tag,
        "{{release_date}}": release_date,
        "{{changelog}}": changelog_content,
        "{{assets_links}}": "*(Artifacts are listed below)*",
        "{{contributors}}": contributors_template.replace("{{owner}}", owner).replace("{{repo_name}}", repo_name),
    }

    body = body_template
    for placeholder, value in replacements.items():
        body = body.replace(placeholder, value)

    notes_file = Path("release_notes.md")
    notes_file.write_text(body, encoding="utf-8")
    print(f"Successfully generated release notes at '{notes_file}'")
    return notes_file


def create_github_release(tag: str, notes_file: Path, assets: list[Path]):
    """Constructs and executes the `gh release create` command."""
    print("\n--- Creating GitHub Release ---")
    gh_token = os.environ.get("GH_TOKEN")
    if not gh_token:
        die("GH_TOKEN environment variable not set.")

    command = [
        "gh",
        "release",
        "create",
        tag,
        "--title",
        f"Release {tag}",
        "--notes-file",
        str(notes_file),
    ]
    # Add assets to the command
    for asset in assets:
        command.append(str(asset))

    print("Executing `gh release create`...")
    env = {k: v for k, v in os.environ.items() if v is not None}
    env["GITHUB_TOKEN"] = gh_token
    run_command(command, env=env)
    print("\n✅ Release created successfully!")


# --- Main Orchestrator ---


def main():
    """Main function to orchestrate the release process."""
    parser = argparse.ArgumentParser(description="A unified script to manage the release process.")
    parser.add_argument("--tag", required=True, help="The tag to create the release for (e.g., v1.0.0).")
    args = parser.parse_args()

    # Step 1: Load configuration
    manifest = load_manifest()

    # Step 2: Pre-flight checks
    check_for_existing_release(args.tag)

    # Step 3: Run check and build scripts
    run_scripts(manifest)

    # Step 4: Approval gate
    handle_approval(manifest)

    # Step 5: Generate release notes (before gathering assets to include notes file)
    notes_file = generate_release_notes(manifest, args.tag)

    # Step 6: Gather assets
    assets = gather_assets(manifest)

    # Also add the notes file itself as an asset if not already excluded
    if notes_file.name not in [p.name for p in assets]:
        # Check against exclude patterns before adding
        exclude_patterns = manifest.get("release", {}).get("assets", {}).get("exclude", [])
        if not any(fnmatch.fnmatch(notes_file.name, p) for p in exclude_patterns):
            assets.append(notes_file)

    # Step 7: Create the release
    create_github_release(args.tag, notes_file, assets)


if __name__ == "__main__":
    main()
