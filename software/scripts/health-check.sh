#!/bin/bash
set -euo pipefail

# Health check for FERCoff nodes.
# Runs on either gateway (Mini A) or sandbox (Mini B).
# Detects role automatically based on network configuration.

SCRIPT_NAME=$(basename "$0")
LOG="/var/log/fercoff/health-check.log"
OLLAMA_PORT=11434
PASS=0
FAIL=0

log_msg() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$SCRIPT_NAME] $1" | tee -a "$LOG" 2>/dev/null || echo "$1"; }

check() {
    local name="$1"
    local result="$2"
    if [[ "$result" == "PASS" ]]; then
        PASS=$((PASS + 1))
        printf "  [PASS] %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        printf "  [FAIL] %s\n" "$name"
    fi
}

detect_role() {
    # Sandbox has no default route; gateway does
    if route -n get default &>/dev/null; then
        echo "gateway"
    else
        echo "sandbox"
    fi
}

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [--role gateway|sandbox] [--json]

Options:
  --role <role>   Force role detection (default: auto-detect)
  --json          Output results as JSON

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME --role sandbox
  $SCRIPT_NAME --json
EOF
    exit 1
}

role=""
json_output=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --role) role="$2"; shift 2 ;;
        --json) json_output=true; shift ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

[[ -z "$role" ]] && role=$(detect_role)

echo "FERCoff Health Check -- role: $role"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "---"

# -- Common checks --

# Ollama
ollama_status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${OLLAMA_PORT}/api/tags" 2>/dev/null || echo "000")
if [[ "$ollama_status" == "200" ]]; then
    check "Ollama responding" "PASS"
else
    check "Ollama responding (status: $ollama_status)" "FAIL"
fi

# Disk space (fail if < 10% free)
disk_pct=$(df -h / | awk 'NR==2 {gsub(/%/,""); print $5}')
if [[ "$disk_pct" -lt 90 ]]; then
    check "Disk space (${disk_pct}% used)" "PASS"
else
    check "Disk space (${disk_pct}% used -- critically low)" "FAIL"
fi

# pf firewall
if pfctl -s info &>/dev/null; then
    check "pf firewall active" "PASS"
else
    check "pf firewall active" "FAIL"
fi

# FERCoff directories
if [[ -d /var/log/fercoff && -d /opt/fercoff ]]; then
    check "FERCoff directories exist" "PASS"
else
    check "FERCoff directories exist" "FAIL"
fi

# -- Role-specific checks --

if [[ "$role" == "gateway" ]]; then
    echo ""
    echo "Gateway-specific checks:"

    # Tailscale
    if tailscale status &>/dev/null; then
        check "Tailscale connected" "PASS"
    else
        check "Tailscale connected" "FAIL"
    fi

    # Thunderbolt link to sandbox
    if ping -c 1 -W 2 10.0.5.2 &>/dev/null; then
        check "Thunderbolt link to sandbox" "PASS"
    else
        check "Thunderbolt link to sandbox" "FAIL"
    fi

    # Sandbox Ollama reachable
    sandbox_ollama=$(curl -s -o /dev/null -w "%{http_code}" "http://10.0.5.2:${OLLAMA_PORT}/api/tags" 2>/dev/null || echo "000")
    if [[ "$sandbox_ollama" == "200" ]]; then
        check "Sandbox Ollama reachable" "PASS"
    else
        check "Sandbox Ollama reachable (status: $sandbox_ollama)" "FAIL"
    fi

elif [[ "$role" == "sandbox" ]]; then
    echo ""
    echo "Sandbox-specific checks:"

    # FileVault
    fv_status=$(fdesetup status 2>/dev/null || echo "unknown")
    if echo "$fv_status" | grep -q "FileVault is On"; then
        check "FileVault enabled" "PASS"
    else
        check "FileVault enabled ($fv_status)" "FAIL"
    fi

    # Air-gap verification (must NOT have default route)
    if ! route -n get default &>/dev/null; then
        check "Air-gap (no default route)" "PASS"
    else
        check "Air-gap (no default route)" "FAIL"
    fi

    # WiFi disabled
    wifi_power=$(networksetup -getairportpower en0 2>/dev/null | awk '{print $NF}' || echo "unknown")
    if [[ "$wifi_power" == "Off" ]]; then
        check "WiFi disabled" "PASS"
    else
        check "WiFi disabled (currently: $wifi_power)" "FAIL"
    fi

    # Audit log exists and is being written
    audit_log="/var/log/fercoff/audit/audit.log"
    if [[ -f "$audit_log" ]]; then
        last_entry=$(tail -1 "$audit_log" 2>/dev/null || echo "")
        if [[ -n "$last_entry" ]]; then
            check "Audit log active" "PASS"
        else
            check "Audit log active (empty)" "FAIL"
        fi
    else
        check "Audit log exists" "FAIL"
    fi
fi

# -- Summary --
echo ""
echo "---"
total=$((PASS + FAIL))
echo "Results: $PASS/$total passed"

if [[ "$FAIL" -gt 0 ]]; then
    log_msg "Health check: $PASS/$total passed, $FAIL FAILED"
    exit 1
else
    log_msg "Health check: all $total checks passed"
    exit 0
fi
