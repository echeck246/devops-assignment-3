#!/usr/bin/env bash
# ==============================================================================
# grade.sh - Automated Grader for Assignment 3: CI/CD Pipeline with GitHub Actions
# TS Academy DevOps Practical Assignments - Total Rubric: 100 Points
# ==============================================================================

set -uo pipefail

TOTAL_SCORE=0
MAX_SCORE=100

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

pass_check() {
    local points="$1"
    local desc="$2"
    TOTAL_SCORE=$((TOTAL_SCORE + points))
    echo -e "  [${GREEN}PASS${NC}] (+${points} pts) ${desc}"
}

fail_check() {
    local points="$1"
    local desc="$2"
    echo -e "  [${RED}FAIL${NC}] (0/${points} pts) ${desc}"
}

section_header() {
    local title="$1"
    local max="$2"
    echo ""
    echo -e "${BOLD}${BLUE}=== Section: ${title} (Max: ${max} pts) ===${NC}"
}

echo "================================================================="
echo -e "${BOLD}       DEVOPS ASSIGNMENT 3: AUTOMATED GRADING SUITE              ${NC}"
echo "================================================================="
echo "Testing environment: $(uname -s) $(uname -r)"
echo "Grading initiated at: $(date)"

# ------------------------------------------------------------------------------
# 1. BASH SCRIPTING (10 Points)
# ------------------------------------------------------------------------------
section_header "Bash Scripting" 10

REQ_FILES=("app/app.sh" "scripts/lint.sh" "scripts/build.sh" "tests/test.sh")
MISSING_SCRIPTS=0
for f in "${REQ_FILES[@]}"; do
    if [ ! -f "${f}" ]; then
        MISSING_SCRIPTS=1
        break
    fi
done

if [ "${MISSING_SCRIPTS}" -eq 0 ]; then
    pass_check 5 "All mandatory Bash application and pipeline scripts exist"
else
    fail_check 5 "Missing one or more required scripts (app.sh, lint.sh, build.sh, test.sh)"
fi

SYNTAX_OK=1
for f in "${REQ_FILES[@]}"; do
    if ! bash -n "${f}" 2>/dev/null; then
        SYNTAX_OK=0
        break
    fi
done

if [ "${SYNTAX_OK}" -eq 1 ]; then
    pass_check 5 "All Bash scripts pass syntax validation (bash -n)"
else
    fail_check 5 "Syntax errors detected in Bash scripts"
fi

# ------------------------------------------------------------------------------
# 2. LINUX / NETWORKING (10 Points)
# ------------------------------------------------------------------------------
section_header "Linux / Networking" 10

SYS_OUT="$(./app/app.sh system-info 2>&1 || true)"
if echo "${SYS_OUT}" | grep -iq "Operating System" && echo "${SYS_OUT}" | grep -iq "Hostname"; then
    pass_check 5 "app.sh system-info collects dynamic Linux host and OS metrics"
else
    fail_check 5 "app.sh system-info output missing expected metrics"
fi

HOST_OUT="$(./app/app.sh check-host 127.0.0.1 2>&1 || true)"
if echo "${HOST_OUT}" | grep -iq "Resolved Address" && echo "${HOST_OUT}" | grep -iq "Connectivity"; then
    pass_check 5 "app.sh check-host performs DNS resolution and connectivity validation"
else
    fail_check 5 "app.sh check-host failed resolution or connectivity check"
fi

# ------------------------------------------------------------------------------
# 3. AUTOMATED TESTS (15 Points)
# ------------------------------------------------------------------------------
section_header "Automated Tests" 15

# Verify at least 8 tests inside tests/test.sh
TEST_COUNT=$(grep -c "run_test" tests/test.sh || true)
if [ "${TEST_COUNT}" -ge 8 ]; then
    pass_check 5 "tests/test.sh contains ${TEST_COUNT} comprehensive test cases (>= 8 required)"
else
    fail_check 5 "tests/test.sh has fewer than 8 test cases (found: ${TEST_COUNT})"
fi

# Verify executable permissions
if [ -x "tests/test.sh" ] && [ -x "app/app.sh" ] && [ -x "scripts/lint.sh" ] && [ -x "scripts/build.sh" ]; then
    pass_check 5 "Executable permissions (+x) verified on scripts and test suite"
else
    fail_check 5 "Missing executable permissions on application or test scripts"
fi

# Run test suite
echo -n "  Running student test suite (./tests/test.sh) ... "
if ./tests/test.sh >/dev/null 2>&1; then
    echo "Done."
    pass_check 5 "All automated tests in ./tests/test.sh passed successfully"
else
    echo "Failed."
    fail_check 5 "One or more tests in ./tests/test.sh failed"
fi

# ------------------------------------------------------------------------------
# 4. DOCKERFILE (15 Points)
# ------------------------------------------------------------------------------
section_header "Dockerfile" 15

if [ -f "Dockerfile" ] && grep -E -iq "^FROM (alpine|debian:.*slim|ubuntu:.*minimal)" Dockerfile; then
    pass_check 5 "Lightweight Linux base image specified in Dockerfile"
else
    fail_check 5 "Dockerfile missing or base image is not lightweight"
fi

if grep -iq "ENTRYPOINT" Dockerfile && grep -iq "app.sh" Dockerfile; then
    pass_check 5 "ENTRYPOINT properly configured for application execution"
else
    fail_check 5 "ENTRYPOINT missing or not targeting app.sh"
fi

# Build Docker image
echo -n "  Building Docker image 'devops-tool:latest' ... "
if docker build -t devops-tool:latest . >/dev/null 2>&1; then
    echo "Done."
    pass_check 5 "Docker image builds cleanly with tag 'devops-tool:latest'"
else
    echo "Failed."
    fail_check 5 "Docker image build failed"
fi

# ------------------------------------------------------------------------------
# 5. DOCKER PRACTICES (10 Points)
# ------------------------------------------------------------------------------
section_header "Docker Practices" 10

if [ -f ".dockerignore" ] && grep -q "\.git" .dockerignore; then
    pass_check 5 ".dockerignore is present and excludes git and temporary files"
else
    fail_check 5 ".dockerignore is missing or incomplete"
fi

# Run scripts/build.sh smoke tests
echo -n "  Executing build and smoke test script (./scripts/build.sh) ... "
if ./scripts/build.sh >/dev/null 2>&1; then
    echo "Done."
    pass_check 5 "scripts/build.sh executes image build and smoke tests (including invalid cmd check)"
else
    echo "Failed."
    fail_check 5 "scripts/build.sh failed during execution"
fi

# ------------------------------------------------------------------------------
# 6. GITHUB ACTIONS (20 Points)
# ------------------------------------------------------------------------------
section_header "GitHub Actions" 20

WORKFLOW=".github/workflows/ci.yml"
if [ -f "${WORKFLOW}" ]; then
    pass_check 5 ".github/workflows/ci.yml exists"
else
    fail_check 5 "Workflow file missing"
fi

# Check triggers
if grep -iq "push:" "${WORKFLOW}" && grep -iq "pull_request:" "${WORKFLOW}"; then
    pass_check 5 "CI workflow triggers on both push and pull_request events"
else
    fail_check 5 "CI workflow missing push or pull_request trigger"
fi

# Check jobs
HAS_VALIDATE=$(grep -c "validate:" "${WORKFLOW}" || true)
HAS_TEST=$(grep -c "test:" "${WORKFLOW}" || true)
HAS_DOCKER=$(grep -c "docker:" "${WORKFLOW}" || true)

if [ "${HAS_VALIDATE}" -ge 1 ] && [ "${HAS_TEST}" -ge 1 ] && [ "${HAS_DOCKER}" -ge 1 ]; then
    pass_check 10 "All 3 required CI jobs defined: validate, test, and docker"
else
    fail_check 10 "Workflow missing one or more required jobs (validate, test, docker)"
fi

# ------------------------------------------------------------------------------
# 7. JOB DEPENDENCIES (5 Points)
# ------------------------------------------------------------------------------
section_header "Job Dependencies" 5

TEST_NEEDS=$(grep -A 5 "test:" "${WORKFLOW}" | grep -c "needs:.*validate" || true)
DOCKER_NEEDS=$(grep -A 5 "docker:" "${WORKFLOW}" | grep -c "needs:.*test" || true)

if [ "${TEST_NEEDS}" -ge 1 ] && [ "${DOCKER_NEEDS}" -ge 1 ]; then
    pass_check 5 "Sequential job dependencies strictly enforced (validate -> test -> docker via needs:)"
else
    fail_check 5 "Job dependencies not properly configured with needs:"
fi

# ------------------------------------------------------------------------------
# 8. ERROR HANDLING (5 Points)
# ------------------------------------------------------------------------------
section_header "Error Handling" 5

set +e
./app/app.sh invalid_command_xyz >/dev/null 2>&1
E1=$?
./app/app.sh check-host >/dev/null 2>&1
E2=$?
./app/app.sh check-port 127.0.0.1 notanumber >/dev/null 2>&1
E3=$?
./app/app.sh check-port 127.0.0.1 99999 >/dev/null 2>&1
E4=$?
set -e

if [ "${E1}" -eq 2 ] && [ "${E2}" -eq 2 ] && [ "${E3}" -eq 2 ] && [ "${E4}" -eq 2 ]; then
    pass_check 5 "Exit code 2 returned on all invalid commands, missing args, and out-of-range ports"
else
    fail_check 5 "Invalid input did not return exit code 2 (got: ${E1}, ${E2}, ${E3}, ${E4})"
fi

# ------------------------------------------------------------------------------
# 9. GIT WORKFLOW (5 Points)
# ------------------------------------------------------------------------------
section_header "Git Workflow" 5

COMMIT_COUNT=0
if [ -d ".git" ]; then
    COMMIT_COUNT="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
fi

if [ "${COMMIT_COUNT}" -ge 5 ]; then
    pass_check 5 "Git history verified with ${COMMIT_COUNT} commits (>= 5 required)"
else
    fail_check 5 "Fewer than 5 Git commits detected (found: ${COMMIT_COUNT})"
fi

# ------------------------------------------------------------------------------
# 10. README DOCUMENTATION (5 Points)
# ------------------------------------------------------------------------------
section_header "README Documentation" 5

README_OK=0
if [ -s "README.md" ] && \
   grep -iq "ci pipeline" README.md && \
   grep -iq "failure" README.md && \
   grep -iq "lint" README.md; then
    README_OK=1
fi

if [ "${README_OK}" -eq 1 ]; then
    pass_check 5 "README.md thoroughly documents architecture, CI pipeline, and CI failure demo"
else
    fail_check 5 "README.md missing required documentation sections or CI failure demo"
fi

# ------------------------------------------------------------------------------
# FINAL SCORE CALCULATION
# ------------------------------------------------------------------------------
echo ""
echo "================================================================="
echo -e "${BOLD}                     FINAL GRADE REPORT                          ${NC}"
echo "================================================================="
if [ "${TOTAL_SCORE}" -eq "${MAX_SCORE}" ]; then
    echo -e "Final Score: ${GREEN}${BOLD}${TOTAL_SCORE} / ${MAX_SCORE} (100% - PERFECT SCORE)${NC}"
else
    echo -e "Final Score: ${YELLOW}${BOLD}${TOTAL_SCORE} / ${MAX_SCORE}${NC}"
fi
echo "================================================================="

if [ "${TOTAL_SCORE}" -eq "${MAX_SCORE}" ]; then
    exit 0
else
    exit 1
fi
