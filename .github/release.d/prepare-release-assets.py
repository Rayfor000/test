"""
Prepares a list of release assets based on include/exclude patterns from a TOML file.
"""

import argparse
import os
import sys
from pathlib import Path

# Add the toml library from the vendored location
sys.path.insert(0, str(Path(__file__).parent.parent / "vendored"))
import tomli


def get_asset_patterns(manifest_path: Path) -> tuple[list[str], list[str]]:
    """
    Reads asset inclusion and exclusion patterns from the release manifest.

    Args:
        manifest_path: Path to the TOML manifest file.

    Returns:
        A tuple containing two lists: include patterns and exclude patterns.
    """
    if not manifest_path.is_file():
        print(f"Error: Manifest file not found at '{manifest_path}'", file=sys.stderr)
        sys.exit(1)

    try:
        with open(manifest_path, "rb") as f:
            manifest = tomli.load(f)

        release_config = manifest.get("release", {})
        assets_config = release_config.get("assets", {})

        include_patterns = assets_config.get("include", [])
        exclude_patterns = assets_config.get("exclude", [])

        if not isinstance(include_patterns, list) or not isinstance(exclude_patterns, list):
            print("Error: 'release.assets.include' and 'release.assets.exclude' must be arrays of strings.", file=sys.stderr)
            sys.exit(1)

        return include_patterns, exclude_patterns
    except tomli.TOMLDecodeError:
        print(f"Error: Could not decode TOML file at '{manifest_path}'", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)


def find_files(root_dir: Path, include_patterns: list[str], exclude_patterns: list[str]) -> list[str]:
    """
    Finds files matching the patterns.

    Args:
        root_dir: The root directory to start searching from.
        include_patterns: A list of glob patterns to include.
        exclude_patterns: A list of glob patterns to exclude.

    Returns:
        A list of file paths that match the criteria.
    """
    final_files = set()

    for pattern in include_patterns:
        for path in root_dir.glob(pattern):
            if path.is_file():
                final_files.add(str(path))

    excluded_files = set()
    for pattern in exclude_patterns:
        for path in root_dir.glob(pattern):
            if path.is_file():
                excluded_files.add(str(path))

    return sorted(list(final_files - excluded_files))


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Filter files for release based on a TOML manifest.")
    parser.add_argument(
        "manifest",
        type=Path,
        help="Path to the .toml release manifest file.",
    )
    args = parser.parse_args()

    include, exclude = get_asset_patterns(args.manifest)

    # We assume the script runs from the repository root
    workspace_dir = Path(os.getcwd())

    final_asset_list = find_files(workspace_dir, include, exclude)

    # Output for GitHub Actions
    print("\n".join(final_asset_list))


if __name__ == "__main__":
    main()
