#!/bin/bash
set -e
echo "=============================================="
echo "Running Build..."
echo "OS: $RUNNER_OS"
echo "Target: $TARGET"
echo "=============================================="
python -m pip install build
python -m build
echo "Build completed successfully."
