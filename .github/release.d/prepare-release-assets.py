# .github/release.d/prepare-release-assets.py
import fnmatch
import os
import sys
from pathlib import Path

import toml


def get_all_files(directory):
    """Recursively gets all files in a directory."""
    file_paths = []
    for root, _, files in os.walk(directory):
        for file in files:
            # Create a relative path from the starting directory
            relative_path = Path(root).relative_to(directory) / file
            file_paths.append(str(relative_path).replace("\\", "/"))
    return file_paths


def filter_files(files, include_patterns, exclude_patterns):
    """Filters files based on include and exclude glob patterns."""
    included_files = set()
    for pattern in include_patterns:
        included_files.update(fnmatch.filter(files, pattern))

    excluded_files = set()
    for pattern in exclude_patterns:
        excluded_files.update(fnmatch.filter(files, pattern))

    return sorted(list(included_files - excluded_files))


def main():
    """
    Main function to prepare release assets.
    1. Reads asset patterns from release-manifest.toml.
    2. Scans all files in the current directory.
    3. Filters files based on include/exclude patterns.
    4. Sets the 'final_assets' output for GitHub Actions.
    """
    try:
        manifest_path = ".github/release-manifest.toml"
        with open(manifest_path) as f:
            manifest = toml.load(f)

        asset_config = manifest.get("release", {}).get("assets", {})
        include_patterns = asset_config.get("include", [])
        exclude_patterns = asset_config.get("exclude", [])

        if not include_patterns:
            print("No 'include' patterns found in manifest. Exiting.", file=sys.stderr)
            output_value = ""
        else:
            all_files = get_all_files(".")
            final_assets = filter_files(all_files, include_patterns, exclude_patterns)
            # Quote each file path to handle spaces
            output_value = " ".join(f'"{asset}"' for asset in final_assets)

        # Set the output for GitHub Actions using the environment file
        github_output = os.getenv("GITHUB_OUTPUT")
        if github_output:
            with open(github_output, "a") as f:
                # The output needs to be a single line
                f.write(f"final_assets={output_value}\n")
            print("Successfully set 'final_assets' output.", file=sys.stderr)
        else:
            # Fallback for local testing
            print("GITHUB_OUTPUT not set. Printing to stdout instead.", file=sys.stderr)
            print(f"Final assets: {output_value}")

    except Exception as e:
        print(f"Error preparing release assets: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
