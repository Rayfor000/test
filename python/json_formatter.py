# Copyright (C) 2026.
"""
Custom-style JSON formatter.

Format rules:
    1. Empty dicts/lists stay compact on a single line: '{}', '[]'.
    2. Single-element dicts/lists stay on one line without increasing
       the indentation depth: '{"key":value}', '[value]'.
    3. Multi-element dicts are expanded with newlines and indentation.
    4. Multi-element lists stay on one line, comma-separated, with each
       element recursively formatted according to its type.
"""

import argparse
import json
import logging
from pathlib import Path
from typing import TypeAlias

# Standard logging configuration.
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

JsonValue: TypeAlias = "dict[str, JsonValue] | list[JsonValue] | str | int | float | bool | None"


def format_custom_json(obj: JsonValue, depth: int = 0, indent_char: str = "\t") -> str:
    """
    Format a Python object as a custom-style JSON string.

    Args:
        obj: The value to format.
        depth: Current indentation depth.
        indent_char: Character used for one indentation level.

    Returns:
        The formatted JSON string.

    """
    if isinstance(obj, dict):
        return _format_dict(obj, depth, indent_char)
    if isinstance(obj, list):
        return _format_list(obj, depth, indent_char)
    return json.dumps(obj, ensure_ascii=False)


def _format_dict(obj: dict[str, JsonValue], depth: int, indent_char: str) -> str:
    """Format a dict according to the compaction rules."""
    if not obj:
        return "{}"
    if len(obj) == 1:
        key, value = next(iter(obj.items()))
        # Keep the depth unchanged for a single element to stay compact.
        value_str = format_custom_json(value, depth, indent_char=indent_char)
        return f'{{"{key}":{value_str}}}'
    next_indent = indent_char * (depth + 1)
    items = [f'{next_indent}"{key}":{format_custom_json(value, depth + 1, indent_char=indent_char)}' for key, value in obj.items()]
    return "{\n" + ",\n".join(items) + "\n" + indent_char * depth + "}"


def _format_list(obj: list[JsonValue], depth: int, indent_char: str) -> str:
    """Format a list according to the compaction rules."""
    if not obj:
        return "[]"
    items = [format_custom_json(item, depth, indent_char=indent_char) for item in obj]
    return f"[{','.join(items)}]"


def process_single_file(file_path: Path) -> bool:
    """
    Read, format, and rewrite a single JSON file.

    Args:
        file_path: Path to the JSON file.

    Returns:
        True on success, False on failure.

    """
    try:
        with file_path.open(encoding="utf-8") as handle:
            data: JsonValue = json.load(handle)
    except json.JSONDecodeError:
        logger.exception("  Failed: %s (invalid JSON syntax)", file_path)
        return False
    except PermissionError:
        logger.exception("  Failed: %s (permission denied)", file_path)
        return False
    except OSError:
        logger.exception("  Failed: %s (I/O error)", file_path)
        return False

    formatted = format_custom_json(data).rstrip("\r\n")

    # Write back with UNIX-style '\n' line endings.
    with file_path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(formatted)

    logger.info("  OK: %s", file_path)
    return True


def process_paths(input_paths: list[str]) -> None:
    """Resolve every given path and process matching JSON files."""
    success_count = 0
    failure_count = 0

    for path_str in input_paths:
        target = Path(path_str)

        if not target.exists():
            logger.warning("Error: path not found: '%s'", path_str)
            continue

        candidates = [target] if target.is_file() else sorted(target.rglob("*.json"))
        if not target.is_file():
            logger.info("Directory detected: '%s', found %d JSON files...", path_str, len(candidates))

        for file_path in candidates:
            if process_single_file(file_path):
                success_count += 1
            else:
                failure_count += 1

    logger.info("Done! Success: %d files, failed: %d files.", success_count, failure_count)


def main() -> None:
    """Parse CLI arguments and run the formatter."""
    parser = argparse.ArgumentParser(description="Custom-style JSON file formatter.")
    parser.add_argument(
        "paths",
        nargs="*",
        help="Files or directories to process. Defaults to the current working directory.",
    )
    args = parser.parse_args()

    if not args.paths:
        current_dir = Path.cwd()
        logger.info("No paths given; scanning the current directory: %s", current_dir)
        process_paths([str(current_dir)])
    else:
        process_paths(args.paths)


if __name__ == "__main__":
    main()
