#!/bin/bash
set -e

echo "=============================================="
echo "Running Build..."
echo "OS: $RUNNER_OS"
echo "Target: $TARGET"
echo "=============================================="

# Simulate creating a build artifact
ARTIFACT_NAME="build-artifact-${RUNNER_OS}-${TARGET}.txt"
echo "This is a build artifact for ${TARGET} on ${RUNNER_OS}." > $ARTIFACT_NAME
echo "Created artifact: $ARTIFACT_NAME"

# Simulate creating a release notes file to be associated
echo "- [${ARTIFACT_NAME}](./path/to/${ARTIFACT_NAME})" >> release_notes.md

echo "Build completed successfully."
