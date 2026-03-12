#!/bin/bash
set -euo pipefail

# First-time initialization for Mini B (sandbox node).
# Run this AFTER Ansible provisioning to verify and finalize setup.
# Must be run locally on Mini B with sudo.

SCRIPT_NAME=$(basename "$0")
FERCOFF_BASE="/opt/fercoff"
LOG_DIR="/var/log/fercoff"
AUDIT_DIR="/var/log/fercoff/audit"
DATA_DIR="/opt/fercoff/data"
BACKUP_DIR="/opt/fercoff/backups"

log_msg() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$SCRIPT_NAME] $1"; }

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (sudo $0)"
    exit 1
fi

echo "FERCoff Sandbox Initialization"
echo "=============================="
echo ""

# -- Step 1: Verify air-gap --
log_msg "Verifying air-gap..."

if route -n get default &>/dev/null; then
    log_msg "FATAL: Default route found. This node must be air-gapped."
    log_msg "Remove all network connections except Thunderbolt to Mini A."
    exit 1
fi

# Verify no DNS resolution (true air-gap test)
if host google.com &>/dev/null; then
    log_msg "FATAL: DNS resolution working. Node is not air-gapped."
    exit 1
fi

log_msg "Air-gap verified: no default route, no DNS resolution"

# -- Step 2: Verify WiFi is off --
wifi_power=$(networksetup -getairportpower en0 2>/dev/null | awk '{print $NF}' || echo "unknown")
if [[ "$wifi_power" != "Off" ]]; then
    log_msg "Disabling WiFi..."
    networksetup -setairportpower en0 off
fi
log_msg "WiFi: disabled"

# -- Step 3: Create directory structure --
log_msg "Creating directory structure..."

for dir in "$FERCOFF_BASE" "$LOG_DIR" "$AUDIT_DIR" "$DATA_DIR" "$BACKUP_DIR"; do
    mkdir -p "$dir"
    log_msg "Created: $dir"
done

# -- Step 4: Set audit directory permissions --
log_msg "Configuring audit directory..."

chmod 755 "$AUDIT_DIR"
# macOS append-only flag -- prevents deletion of log entries
chflags sappend "$AUDIT_DIR" 2>/dev/null || log_msg "WARNING: Could not set append-only flag (may require SIP adjustment)"

# -- Step 5: Initialize audit log --
AUDIT_LOG="$AUDIT_DIR/audit.log"
if [[ ! -f "$AUDIT_LOG" ]]; then
    {
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) INIT FERCoff sandbox initialized"
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) INIT hostname=$(hostname) os=$(sw_vers -productVersion)"
    } > "$AUDIT_LOG"
    log_msg "Audit log initialized: $AUDIT_LOG"
else
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) REINIT sandbox-init.sh re-run" >> "$AUDIT_LOG"
    log_msg "Audit log already exists, appended re-init marker"
fi

# -- Step 6: Verify FileVault --
log_msg "Checking FileVault..."

fv_status=$(fdesetup status 2>/dev/null || echo "unknown")
if echo "$fv_status" | grep -q "FileVault is On"; then
    log_msg "FileVault: enabled (XTS-AES-128)"
else
    log_msg "WARNING: FileVault is not enabled."
    log_msg "Run: sudo fdesetup enable -user <admin-user>"
    log_msg "Store the recovery key securely offline."
fi

# -- Step 7: Verify pf firewall --
log_msg "Checking firewall..."

if pfctl -s info &>/dev/null; then
    log_msg "pf firewall: active"
else
    log_msg "Enabling pf firewall..."
    pfctl -e 2>/dev/null || true
    pfctl -f /etc/pf.conf 2>/dev/null || log_msg "WARNING: Could not load pf rules"
fi

# -- Step 8: Verify Ollama --
log_msg "Checking Ollama..."

if curl -s -o /dev/null -w "%{http_code}" "http://localhost:11434/api/tags" 2>/dev/null | grep -q "200"; then
    models=$(curl -s "http://localhost:11434/api/tags" | python3 -c "import sys,json; [print(f'  - {m[\"name\"]}') for m in json.loads(sys.stdin.read()).get('models',[])]" 2>/dev/null || echo "  (unable to list)")
    log_msg "Ollama: running"
    echo "$models"
else
    log_msg "WARNING: Ollama not responding. Load models from USB."
fi

# -- Summary --
echo ""
echo "=============================="
log_msg "Initialization complete"
log_msg "Next steps:"
log_msg "  1. Load models from USB if not already loaded (see model-update.sh)"
log_msg "  2. Run health-check.sh --role sandbox to verify all systems"
log_msg "  3. Submit a test query from Mini A to verify end-to-end"
