#!/bin/bash
# This script handles the build process for Python projects.
set -e

echo "--- Installing Build Dependencies ---"
python -m pip install --upgrade pip
python -m pip install build

echo "--- Building Distributions ---"
python -m build