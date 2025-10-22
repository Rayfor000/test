# .github/release.d/parse_config_outputs.py

import sys
from pathlib import Path

import tomllib

# --- Constants ---
MANIFEST_PATH = Path(".github/release-manifest.toml")


def main():
    """
    Parses the release manifest to extract specific configuration values
    and prints them to stdout for use in GitHub Actions outputs.
    """
    if not MANIFEST_PATH.exists():
        print(f"Error: Manifest file not found at '{MANIFEST_PATH}'.", file=sys.stderr)
        sys.exit(1)

    try:
        with MANIFEST_PATH.open("rb") as f:
            manifest = tomllib.load(f)
    except tomllib.TOMLDecodeError as e:
        print(f"Error: Could not parse manifest file: {e}", file=sys.stderr)
        sys.exit(1)

    # Get the 'skip_approval' value, defaulting to False if not present.
    # The output must be a lowercase string 'true' or 'false' for GitHub Actions 'if' conditions.
    skip_approval = manifest.get("release", {}).get("skip_approval", False)
    print(f"skip_approval={'true' if skip_approval else 'false'}")


if __name__ == "__main__":
    main()
