#!/usr/bin/env bash
# ==============================================================================
# tests/test.sh - Automated Application Test Suite
# Part of DevOps Assignment 3: CI/CD Pipeline with GitHub Actions
# Tests all subcommands, edge cases, input validation, and exit codes
# ==============================================================================

set -uo pipefail

APP="./app/app.sh"
PASSED=0
FAILED=0

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

run_test() {
    local test_num="$1"
    local desc="$2"
    local cmd="$3"
    local expected_exit="$4"
    local expected_pattern="$5"

    echo -ne "Test ${test_num}: ${desc} ... "
    
    set +e
    local output
    output=$(eval "${cmd}" 2>&1)
    local actual_exit=$?
    set -e

    local exit_ok=0
    if [ "${actual_exit}" -eq "${expected_exit}" ]; then
        exit_ok=1
    fi

    local pattern_ok=0
    if [ -z "${expected_pattern}" ] || echo "${output}" | grep -E -iq "${expected_pattern}"; then
        pattern_ok=1
    fi

    if [ "${exit_ok}" -eq 1 ] && [ "${pattern_ok}" -eq 1 ]; then
        echo -e "${GREEN}PASS${NC} (exit code: ${actual_exit})"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} (expected: ${expected_exit}, got: ${actual_exit})"
        if [ "${pattern_ok}" -eq 0 ]; then
            echo -e "  Pattern '${expected_pattern}' not found in output: ${output}"
        fi
        FAILED=$((FAILED + 1))
    fi
}

echo "================================================================="
echo -e "${BOLD}              APPLICATION AUTOMATED TEST SUITE                   ${NC}"
echo "================================================================="
echo "Application: ${APP}"
echo "-----------------------------------------------------------------"

# Test 1: Help command
run_test "1" "Help command display and exit 0" \
    "${APP} help" \
    0 \
    "Usage:|Commands:|system-info|check-host|check-port|help"

# Test 2: System info display
run_test "2" "System info output and exit 0" \
    "${APP} system-info" \
    0 \
    "Hostname|Operating System|Kernel Version|CPU"

# Test 3: Invalid command check -> exit 2
run_test "3" "Invalid command handling -> exit 2" \
    "${APP} unknown-command-xyz" \
    2 \
    "Error: Unknown command"

# Test 4: Missing host argument -> exit 2
run_test "4" "Missing host argument for check-host -> exit 2" \
    "${APP} check-host" \
    2 \
    "Error: Missing required <host> argument"

# Test 5: Valid host check (127.0.0.1) -> exit 0
run_test "5" "Valid host resolution and ping check (127.0.0.1) -> exit 0" \
    "${APP} check-host 127.0.0.1" \
    0 \
    "Resolved Address|Connectivity"

# Test 6: Missing port argument -> exit 2
run_test "6" "Missing port argument for check-port -> exit 2" \
    "${APP} check-port 127.0.0.1" \
    2 \
    "Error: Missing required <port> argument"

# Test 7: Non-numeric port -> exit 2
run_test "7" "Non-numeric port argument ('notaport') -> exit 2" \
    "${APP} check-port 127.0.0.1 notaport" \
    2 \
    "Error: Port must be a numeric integer"

# Test 8: Out-of-range port -> exit 2
run_test "8" "Out-of-range port argument ('70000') -> exit 2" \
    "${APP} check-port 127.0.0.1 70000" \
    2 \
    "Error: Port out of range"

# Test 9: Negative/Zero port -> exit 2
run_test "9" "Out-of-range port argument ('0') -> exit 2" \
    "${APP} check-port 127.0.0.1 0" \
    2 \
    "Error: Port out of range"

# Test 10: Empty string command -> exit 2
run_test "10" "No command passed -> exit 2" \
    "${APP}" \
    2 \
    "Error: No command provided"

echo "-----------------------------------------------------------------"
echo "Test Execution Summary: ${PASSED} passed, ${FAILED} failed"
echo "================================================================="

if [ "${FAILED}" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}ALL TESTS PASSED SUCCESSFULLY!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}SOME TESTS FAILED.${NC}"
    exit 1
fi
