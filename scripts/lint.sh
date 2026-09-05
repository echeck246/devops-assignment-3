#!/usr/bin/env bash
# ==============================================================================
# lint.sh - Validation and Static Analysis Script
# Part of DevOps Assignment 3: CI/CD Pipeline with GitHub Actions
# Validates repository file structure, syntax (bash -n), and ShellCheck
# ==============================================================================

set -uo pipefail


ERRORS=0

echo "================================================================="
echo "               CI LINTING & VALIDATION PIPELINE                  "
echo "================================================================="

# 1. Check Required Files
echo "[+] Step 1: Checking Required Files..."
REQUIRED_FILES=(
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    "Dockerfile"
    "compose.yaml"
    ".dockerignore"
    ".github/workflows/ci.yml"
    "README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "${file}" ]; then
        echo "  [OK] Found ${file}"
    else
        echo "  [ERROR] Missing mandatory file: ${file}" >&2
        ERRORS=$((ERRORS + 1))
    fi
done

# 2. Syntax Validation with bash -n
echo ""
echo "[+] Step 2: Running Syntax Check (bash -n)..."
SCRIPTS=(
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
)
if [ -f "grade.sh" ]; then
    SCRIPTS+=("grade.sh")
fi

for script in "${SCRIPTS[@]}"; do
    if [ -f "${script}" ]; then
        if bash -n "${script}"; then
            echo "  [OK] Syntax clean: ${script}"
        else
            echo "  [ERROR] Syntax error detected in: ${script}" >&2
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# 3. Optional ShellCheck Static Analysis
echo ""
echo "[+] Step 3: ShellCheck Static Analysis..."
if command -v shellcheck >/dev/null 2>&1; then
    for script in "${SCRIPTS[@]}"; do
        if [ -f "${script}" ]; then
            if shellcheck -e SC1091 "${script}"; then
                echo "  [OK] ShellCheck passed: ${script}"
            else
                echo "  [WARN] ShellCheck found issues in: ${script}" >&2
                # Note: Warnings logged, not blocking unless severe
            fi
        fi
    done
else
    echo "  [SKIP] ShellCheck not installed; skipped optional static analysis."
fi

echo "================================================================="
if [ "${ERRORS}" -eq 0 ]; then
    echo "SUCCESS: All linting and validation checks passed."
    exit 0
else
    echo "FAILURE: ${ERRORS} error(s) detected during linting." >&2
    exit 1
fi
