#!/bin/bash
set -e

echo "=============================================="
echo "Running Check..."
echo "OS: $RUNNER_OS"
echo "Python Version: $PYTHON_VERSION"
echo "=============================================="

python --version
# Add your actual test commands here
pip install ruff
ruff format .
ruff check . --unsafe-fixes --fix

echo "Check completed successfully."
