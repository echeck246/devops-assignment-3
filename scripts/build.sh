#!/usr/bin/env bash
# ==============================================================================
# build.sh - Docker Build and Smoke Test Script
# Part of DevOps Assignment 3: CI/CD Pipeline with GitHub Actions
# Builds devops-tool image and executes automated container smoke tests
# ==============================================================================

set -euo pipefail

IMAGE_NAME="devops-tool:latest"

echo "================================================================="
echo "               DOCKER BUILD & SMOKE TEST PIPELINE                "
echo "================================================================="

# 1. Build the Docker Image
echo "[+] Step 1: Building Docker image '${IMAGE_NAME}'..."
docker build -t "${IMAGE_NAME}" .
echo "  [OK] Image build completed successfully."

# 2. Smoke Test: Help command
echo ""
echo "[+] Step 2: Smoke test - 'help' command..."
HELP_OUT="$(docker run --rm "${IMAGE_NAME}" help 2>&1)"
if echo "${HELP_OUT}" | grep -iq "Usage:"; then
    echo "  [OK] Container help command passed."
else
    echo "  [ERROR] Container help command failed." >&2
    echo "  Output: ${HELP_OUT}" >&2
    exit 1
fi

# 3. Smoke Test: System-info command
echo ""
echo "[+] Step 3: Smoke test - 'system-info' command..."
SYS_OUT="$(docker run --rm "${IMAGE_NAME}" system-info 2>&1)"
if echo "${SYS_OUT}" | grep -iq "Hostname"; then
    echo "  [OK] Container system-info command passed."
else
    echo "  [ERROR] Container system-info command failed." >&2
    echo "  Output: ${SYS_OUT}" >&2
    exit 1
fi

# 4. Smoke Test: Invalid command handling (must exit 2)
echo ""
echo "[+] Step 4: Smoke test - Invalid command handling ('invalid-cmd')..."
set +e
docker run --rm "${IMAGE_NAME}" invalid-cmd >/dev/null 2>&1
INVALID_EXIT=$?
set -e

if [ "${INVALID_EXIT}" -eq 2 ]; then
    echo "  [OK] Container properly handled invalid command with exit code 2."
else
    echo "  [ERROR] Container returned unexpected exit code ${INVALID_EXIT} for invalid command (expected 2)." >&2
    exit 1
fi

echo "================================================================="
echo "SUCCESS: Docker image built and all smoke tests passed."
exit 0
