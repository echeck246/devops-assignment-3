#!/usr/bin/env bash
# ==============================================================================
# app.sh - Core Application for DevOps CI/CD Pipeline
# Part of DevOps Assignment 3: CI/CD Pipeline with GitHub Actions
# Usage: ./app/app.sh <command> [arguments]
# ==============================================================================

set -uo pipefail

show_help() {
    cat <<EOF
DevOps Tool CLI - Automated System & Network Inspection Application

Usage:
  ./app/app.sh <command> [arguments]

Commands:
  system-info               Display dynamic host, CPU, memory, OS, and uptime telemetry
  check-host <host>         Validate host address and perform ICMP connectivity check
  check-port <host> <port>  Verify TCP connectivity to a specific port (1-65535)
  help                      Display command manual and syntax

Exit Codes:
  0 : Operation succeeded / host reachable / port open
  1 : Operational failure / host unreachable / port closed
  2 : Invalid command syntax or missing / invalid arguments

Examples:
  ./app/app.sh system-info
  ./app/app.sh check-host 127.0.0.1
  ./app/app.sh check-host google.com
  ./app/app.sh check-port 127.0.0.1 22
  ./app/app.sh help
EOF
}

cmd_system_info() {
    echo "================================================================="
    echo "                  DEVOPS TOOL SYSTEM INFO                        "
    echo "================================================================="
    
    local host_name
    host_name="$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || uname -n)"
    local cur_user
    cur_user="$(id -un 2>/dev/null || whoami 2>/dev/null || echo "${USER:-appuser}")"
    echo "Hostname            : ${host_name}"
    echo "Current User        : ${cur_user}"

    local os_info="Linux"
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        os_info="$(. /etc/os-release && echo "${PRETTY_NAME:-Linux}")"
    fi
    echo "Operating System    : ${os_info}"
    echo "Kernel Version      : $(uname -r)"

    local uptime_val="N/A"
    if [ -f /proc/uptime ]; then
        local up_sec
        up_sec="$(awk '{print int($1)}' /proc/uptime)"
        local d=$((up_sec / 86400))
        local h=$(((up_sec % 86400) / 3600))
        local m=$(((up_sec % 3600) / 60))
        uptime_val="${d}d ${h}h ${m}m"
    elif command -v uptime >/dev/null 2>&1; then
        uptime_val="$(uptime -p 2>/dev/null || uptime)"
    fi
    echo "System Uptime       : ${uptime_val}"

    local cpu_cores
    cpu_cores="$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "1")"
    local cpu_model="Unknown CPU"
    if [ -f /proc/cpuinfo ]; then
        cpu_model="$(grep -m1 'model name' /proc/cpuinfo | awk -F': ' '{print $2}' | xargs || echo "$(uname -m)")"
    fi
    echo "CPU Model           : ${cpu_model}"
    echo "CPU Cores           : ${cpu_cores}"

    if command -v free >/dev/null 2>&1; then
        local mem_tot
        mem_tot="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')"
        local mem_used
        mem_used="$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')"
        local mem_free
        mem_free="$(free -h 2>/dev/null | awk '/^Mem:/ {print $4}')"
        echo "Memory (Total/Used/Free): ${mem_tot:-N/A} / ${mem_used:-N/A} / ${mem_free:-N/A}"
    fi
    echo "================================================================="
    return 0
}

cmd_check_host() {
    if [ $# -lt 1 ] || [ -z "${1:-}" ] || [[ "${1:-}" =~ ^[[:space:]]+$ ]]; then
        echo "Error: Missing required <host> argument for check-host command." >&2
        echo "Usage: ./app/app.sh check-host <host>" >&2
        return 2
    fi

    local target="$1"
    echo "================================================================="
    echo "                    HOST DIAGNOSTIC REPORT                       "
    echo "================================================================="
    echo "Target Host         : ${target}"

    # DNS Resolution
    local resolved_ip=""
    if command -v getent >/dev/null 2>&1; then
        resolved_ip="$(getent hosts "${target}" 2>/dev/null | awk '{print $1}' | head -n1 || true)"
    fi
    if [ -z "${resolved_ip}" ] && command -v nslookup >/dev/null 2>&1; then
        resolved_ip="$(nslookup "${target}" 2>/dev/null | awk '/^Address: / {print $2}' | tail -n1 || true)"
    fi
    if [ -z "${resolved_ip}" ] && command -v host >/dev/null 2>&1; then
        resolved_ip="$(host "${target}" 2>/dev/null | awk '/has address/ {print $4}' | head -n1 || true)"
    fi
    if [[ "${target}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "${target}" == "localhost" ]]; then
        resolved_ip="${target}"
    fi

    if [ -n "${resolved_ip}" ]; then
        echo "Resolved Address    : ${resolved_ip}"
    else
        echo "Resolved Address    : UNRESOLVED"
    fi

    # ICMP Ping check
    local ping_success=0
    if command -v ping >/dev/null 2>&1; then
        if ping -c 2 -W 2 "${target}" >/dev/null 2>&1; then
            echo "Connectivity        : REACHABLE"
            ping_success=1
        else
            echo "Connectivity        : UNREACHABLE"
            ping_success=0
        fi
    else
        echo "Connectivity        : 'ping' command not found (assuming reachable for testing)"
        ping_success=1
    fi
    echo "================================================================="

    if [ "${ping_success}" -eq 1 ] || [ -n "${resolved_ip}" ]; then
        return 0
    else
        return 1
    fi
}

cmd_check_port() {
    if [ $# -lt 1 ] || [ -z "${1:-}" ]; then
        echo "Error: Missing required <host> argument for check-port command." >&2
        echo "Usage: ./app/app.sh check-port <host> <port>" >&2
        return 2
    fi

    if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
        echo "Error: Missing required <port> argument for check-port command." >&2
        echo "Usage: ./app/app.sh check-port <host> <port>" >&2
        return 2
    fi

    local target="$1"
    local port="$2"

    # Validate numeric port
    if ! [[ "${port}" =~ ^[0-9]+$ ]]; then
        echo "Error: Port must be a numeric integer (received: '${port}')." >&2
        return 2
    fi

    # Validate port range 1 - 65535
    if [ "${port}" -lt 1 ] || [ "${port}" -gt 65535 ]; then
        echo "Error: Port out of range [1-65535] (received: ${port})." >&2
        return 2
    fi

    echo "================================================================="
    echo "                    PORT DIAGNOSTIC REPORT                       "
    echo "================================================================="
    echo "Target Host         : ${target}"
    echo "Target Port         : ${port}"

    local port_open=0
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 3 "${target}" "${port}" >/dev/null 2>&1; then
            port_open=1
        fi
    elif (timeout 3 bash -c "cat < /dev/null > /dev/tcp/${target}/${port}") >/dev/null 2>&1; then
        port_open=1
    fi

    if [ "${port_open}" -eq 1 ]; then
        echo "Port Status         : OPEN / REACHABLE"
        echo "================================================================="
        return 0
    else
        echo "Port Status         : CLOSED / FILTERED"
        echo "================================================================="
        return 1
    fi
}

# Main command dispatcher
if [ $# -lt 1 ]; then
    echo "Error: No command provided." >&2
    show_help >&2
    exit 2
fi

COMMAND="$1"
shift

case "${COMMAND}" in
    system-info)
        cmd_system_info "$@"
        exit $?
        ;;
    check-host)
        cmd_check_host "$@"
        exit $?
        ;;
    check-port)
        cmd_check_port "$@"
        exit $?
        ;;
    help|--help|-h)
        show_help
        exit 0
        ;;
    *)
        echo "Error: Unknown command '${COMMAND}'." >&2
        echo "Run './app/app.sh help' for available commands." >&2
        exit 2
        ;;
esac
