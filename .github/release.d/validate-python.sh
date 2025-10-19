#!/bin/bash
# This script runs the validation steps for the Python project.
set -e

echo "--- Checking Python Version ---"
MIN_PYTHON_VERSION="3.8"
# Get the current Python version in a format like "3.9"
CURRENT_PYTHON_VERSION=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')

# Compare versions
if [ "$(printf '%s\n' "$MIN_PYTHON_VERSION" "$CURRENT_PYTHON_VERSION" | sort -V | head -n1)" != "$MIN_PYTHON_VERSION" ]; then
	echo "Error: Your Python version is $CURRENT_PYTHON_VERSION, but this project requires at least $MIN_PYTHON_VERSION." >&2
	exit 1
else
	echo "Python version $CURRENT_PYTHON_VERSION is compatible."
fi

echo "--- Installing Linter and Test Dependencies ---"
python -m pip install --upgrade pip
python -m pip install ruff pytest

echo "--- Linting with Ruff ---"
ruff check .

# echo "--- Running Tests with Pytest ---"
# pytest
