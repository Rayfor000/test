import argparse
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Set, Type, TypeVar, overload

# Third-party imports
try:
    import toml
except ImportError:
    print("Error: 'toml' library is required. Please install it using 'pip install toml'", file=sys.stderr)
    sys.exit(1)

# --- Constants ---
MANIFEST_PATH = Path(".github/release-manifest.toml")

# --- Utility Functions ---


def run_command(command: list[str], check: bool = True) -> subprocess.CompletedProcess:
    """
    Executes a command and returns its completed process.
    - command: A list of strings representing the command and its arguments.
    - check: If True, raises CalledProcessError on non-zero exit codes.
    """
    print(f"Executing: {' '.join(command)}", file=sys.stderr)
    try:
        return subprocess.run(command, check=check, capture_output=True, text=True, encoding="utf-8")
    except FileNotFoundError:
        print(f"Error: Command not found: '{command[0]}'. Is it installed and in your PATH?", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {' '.join(command)}", file=sys.stderr)
        print(f"Stdout: {e.stdout.strip()}", file=sys.stderr)
        print(f"Stderr: {e.stderr.strip()}", file=sys.stderr)
        raise


T = TypeVar("T")


@overload
def get_config(manifest: Dict[str, Any], key: str, expected_type: Type[T]) -> T: ...


@overload
def get_config(manifest: Dict[str, Any], key: str, expected_type: Type[T], default: T) -> T: ...


def get_config(manifest: Dict[str, Any], key: str, expected_type: Type[T], default: Any = None) -> T:
    """
    Safely retrieves and validates a nested key from the manifest dictionary.
    """
    keys = key.split(".")
    value: Any = manifest
    for k in keys:
        if not isinstance(value, dict) or k not in value:
            if default is not None:
                return default
            print(f"Error: Missing required configuration key '{key}' in {MANIFEST_PATH}", file=sys.stderr)
            sys.exit(1)
        value = value[k]

    if not isinstance(value, expected_type):
        print(f"Error: Configuration key '{key}' has wrong type. Expected {expected_type.__name__}, got {type(value).__name__}.", file=sys.stderr)
        sys.exit(1)
    return value


# --- Core Logic Functions ---


def parse_arguments() -> argparse.Namespace:
    """Parses command-line arguments for the release script."""
    parser = argparse.ArgumentParser(description="Create a new GitHub release.")
    parser.add_argument("--tag", required=True, help="The tag to create the release for (e.g., v1.0.0)")
    parser.add_argument("--previous-tag", required=True, help="The previous tag for changelog generation.")
    return parser.parse_args()


def check_existing_release(tag: str):
    """Exits if a GitHub release for the given tag already exists."""
    print(f"Checking for existing release with tag '{tag}'...")
    try:
        run_command(["gh", "release", "view", tag], check=True)
        print(f"Error: A release for tag '{tag}' already exists.", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError:
        # This is expected if the release does not exist
        print("No existing release found. Proceeding.")


def handle_approval(skip_approval: bool):
    """Pauses for manual user approval if not skipped."""
    if not skip_approval:
        print("\n" + "=" * 50)
        print("Manual Approval Required")
        print("=" * 50)
        print("Review the configuration and build logs above.")
        response = input("Type 'yes' to approve and create the release: ")
        if response.lower() != "yes":
            print("Release cancelled by user.", file=sys.stderr)
            sys.exit(0)
    else:
        print("Approval skipped via configuration.")


def run_build(build_script: str):
    """Executes the build script defined in the manifest."""
    script_path = Path(build_script)
    if not script_path.is_file():
        print(f"Error: Build script not found at '{build_script}'", file=sys.stderr)
        sys.exit(1)

    # Ensure the script is executable
    script_path.chmod(script_path.stat().st_mode | 0o111)

    print(f"Running build script: {build_script}")
    try:
        # We pass the full path to the script to run_command
        run_command([str(script_path.resolve())], check=True)
        print("Build completed successfully.")
    except subprocess.CalledProcessError:
        print("Error: Build script failed.", file=sys.stderr)
        sys.exit(1)


def find_asset_files(include_patterns: List[str], exclude_patterns: List[str]) -> List[str]:
    """Finds asset files based on include/exclude glob patterns."""
    root_dir = Path(os.getcwd())
    print(f"Searching for assets in '{root_dir}'...")

    final_files: Set[Path] = set()
    for pattern in include_patterns:
        # Search in the current directory and dist/ by default
        for search_dir in [root_dir, root_dir / "dist"]:
            if search_dir.is_dir():
                for path in search_dir.glob(pattern):
                    if path.is_file():
                        final_files.add(path)

    excluded_files: Set[Path] = set()
    for pattern in exclude_patterns:
        for search_dir in [root_dir, root_dir / "dist"]:
            if search_dir.is_dir():
                for path in search_dir.glob(pattern):
                    if path.is_file():
                        excluded_files.add(path)

    asset_paths = sorted(list(final_files - excluded_files))
    print(f"Found {len(asset_paths)} assets to include.")
    for p in asset_paths:
        print(f"  - {p.relative_to(root_dir)}")
    return [str(p) for p in asset_paths]


def generate_changelog(previous_tag: str, current_tag: str) -> str:
    """Generates a changelog from Git history between two tags."""
    print(f"Generating changelog from '{previous_tag}' to '{current_tag}'...")
    if not previous_tag or not current_tag:
        return "Changelog generation skipped: missing previous or current tag."

    command = ["git", "log", f"{previous_tag}..{current_tag}", "--pretty=format:- %s (%h)"]
    result = run_command(command, check=False)  # Don't exit on error, just return empty
    if result.returncode != 0:
        print("Warning: Git log command failed. Changelog may be empty.", file=sys.stderr)
        return ""
    return result.stdout.strip()


def render_release_notes(manifest: dict, tag: str, previous_tag: str, assets: List[str]) -> str:
    """Renders the release notes body from the template in the manifest."""
    print("Rendering release notes...")
    body_template = get_config(manifest, "release.body_template", str, "")
    if not body_template:
        print("Warning: 'release.body_template' is empty in manifest.", file=sys.stderr)
        return ""

    repo_full_name = os.environ.get("GITHUB_REPOSITORY", "owner/repo")
    owner, repo_name = repo_full_name.split("/", 1)

    # --- Prepare placeholder values ---
    release_date = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    changelog_content = generate_changelog(previous_tag, tag)

    # Generate asset links
    asset_links = []
    for asset_file in assets:
        filename = Path(asset_file).name
        link = f"- [{filename}](https://github.com/{repo_full_name}/releases/download/{tag}/{filename})"
        asset_links.append(link)
    assets_links_content = "\n".join(asset_links)

    # Generate contributors link
    contributors_template = get_config(manifest, "release.contributors.template", str, "")
    contributors_content = str(contributors_template).replace("{{owner}}", owner).replace("{{repo_name}}", repo_name)

    # --- Render the template ---
    replacements = {
        "{{repo_name}}": repo_name,
        "{{owner}}": owner,
        "{{tag}}": tag,
        "{{release_date}}": release_date,
        "{{changelog}}": changelog_content,
        "{{assets_links}}": assets_links_content,
        "{{contributors}}": contributors_content,
    }

    body = body_template
    for placeholder, value in replacements.items():
        body = body.replace(placeholder, value)

    return body


def create_github_release(tag: str, notes_content: str, assets: List[str]):
    """Creates the GitHub release using the gh CLI."""
    print("Preparing to create GitHub release...")
    with tempfile.NamedTemporaryFile(mode="w+", delete=False, suffix=".md", encoding="utf-8") as notes_file:
        notes_file.write(notes_content)
        notes_filepath = notes_file.name

    try:
        command = ["gh", "release", "create", tag, "--notes-file", notes_filepath]
        # Add all asset file paths to the command
        command.extend(assets)

        print("Executing final gh release create command...")
        run_command(command, check=True)
        print("\n" + "=" * 50)
        print(f"Successfully created release '{tag}'!")
        print("=" * 50)

    finally:
        # Clean up the temporary file
        os.remove(notes_filepath)


def main():
    """Main function to orchestrate the release process."""
    # --- 1. Initial Setup ---
    args = parse_arguments()
    try:
        with open(MANIFEST_PATH, encoding="utf-8") as f:
            manifest = toml.load(f)
    except (FileNotFoundError, toml.TomlDecodeError) as e:
        print(f"Error: Could not read or parse manifest file at '{MANIFEST_PATH}'. {e}", file=sys.stderr)
        sys.exit(1)

    # --- 2. Pre-flight Checks ---
    check_existing_release(args.tag)

    # --- 3. Approval ---
    skip_approval = get_config(manifest, "release.skip_approval", bool, False)
    handle_approval(skip_approval)

    # --- 4. Build ---
    build_script = get_config(manifest, "build.run_script", str, ".github/release.d/build-python.sh")
    run_build(build_script)

    # --- 5. Prepare Assets & Notes ---
    include = get_config(manifest, "release.assets.include", list, [])
    exclude = get_config(manifest, "release.assets.exclude", list, [])
    final_assets = find_asset_files(include, exclude)
    release_notes = render_release_notes(manifest, args.tag, args.previous_tag, final_assets)

    # --- 6. Create Release ---
    create_github_release(args.tag, release_notes, final_assets)


if __name__ == "__main__":
    main()
