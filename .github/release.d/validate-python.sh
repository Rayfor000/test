#!/bin/bash
# This script runs the validation steps for the Python project.
set -e

echo "--- Installing Linter and Test Dependencies ---"
python -m pip install --upgrade pip
python -m pip install ruff pytest

echo "--- Linting with Ruff ---"
ruff check .

# echo "--- Running Tests with Pytest ---"
# pytest