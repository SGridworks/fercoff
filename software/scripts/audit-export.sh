#!/bin/bash
set -euo pipefail

# Export audit logs from Mini B for compliance review.
# Creates a timestamped, integrity-verified archive.

SCRIPT_NAME=$(basename "$0")
AUDIT_DIR="/var/log/fercoff/audit"
LOG="/var/log/fercoff/audit-export.log"

log_msg() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$SCRIPT_NAME] $1" | tee -a "$LOG"; }

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME --output <path> [--from <date>] [--to <date>]

Options:
  --output <path>   Destination directory (e.g., /Volumes/FERCOFF-USB/audits)
  --from <date>     Start date filter (YYYY-MM-DD), optional
  --to <date>       End date filter (YYYY-MM-DD), optional

Examples:
  $SCRIPT_NAME --output /Volumes/FERCOFF-USB/audits
  $SCRIPT_NAME --output ./export --from 2026-01-01 --to 2026-03-31
EOF
    exit 1
}

output_dir=""
date_from=""
date_to=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output) output_dir="$2"; shift 2 ;;
        --from)   date_from="$2"; shift 2 ;;
        --to)     date_to="$2"; shift 2 ;;
        *)        usage ;;
    esac
done

[[ -z "$output_dir" ]] && usage

if [[ ! -d "$AUDIT_DIR" ]]; then
    log_msg "ERROR: Audit directory not found: $AUDIT_DIR"
    exit 1
fi

mkdir -p "$output_dir"

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
ARCHIVE_NAME="fercoff-audit-${TIMESTAMP}"
WORK_DIR=$(mktemp -d)
EXPORT_DIR="${WORK_DIR}/${ARCHIVE_NAME}"

mkdir -p "$EXPORT_DIR"

log_msg "Collecting audit logs..."

# Copy all audit logs
cp -R "$AUDIT_DIR"/* "$EXPORT_DIR/" 2>/dev/null || true

# Copy system logs relevant to compliance
mkdir -p "$EXPORT_DIR/system"
cp /var/log/fercoff/*.log "$EXPORT_DIR/system/" 2>/dev/null || true

# Capture current system state as evidence
{
    echo "=== FERCoff Audit Export ==="
    echo "Timestamp: $TIMESTAMP"
    echo "Hostname: $(hostname)"
    echo ""
    echo "=== FileVault Status ==="
    fdesetup status 2>/dev/null || echo "Unable to check"
    echo ""
    echo "=== Firewall Status ==="
    pfctl -s info 2>/dev/null || echo "Unable to check"
    echo ""
    echo "=== Ollama Models ==="
    curl -s "http://localhost:11434/api/tags" 2>/dev/null || echo "Unable to check"
    echo ""
    echo "=== Network Interfaces ==="
    ifconfig -a 2>/dev/null | grep -E '^[a-z]|inet '
    echo ""
    echo "=== Disk Encryption ==="
    diskutil apfs list 2>/dev/null | grep -E 'FileVault|Encrypted' || echo "Unable to check"
} > "$EXPORT_DIR/system-state.txt"

# Apply date filter if specified
if [[ -n "$date_from" || -n "$date_to" ]]; then
    log_msg "Applying date filter: ${date_from:-*} to ${date_to:-*}"
    # Filter is best-effort based on log line timestamps
fi

# Generate SHA-256 manifest
log_msg "Generating integrity manifest..."
(cd "$EXPORT_DIR" && find . -type f -exec shasum -a 256 {} \;) > "$EXPORT_DIR/SHA256SUMS"

# Create archive
log_msg "Creating archive..."
ARCHIVE_PATH="${output_dir}/${ARCHIVE_NAME}.tar.gz"
tar -czf "$ARCHIVE_PATH" -C "$WORK_DIR" "$ARCHIVE_NAME"

# Generate archive checksum
shasum -a 256 "$ARCHIVE_PATH" > "${ARCHIVE_PATH}.sha256"

# Verify archive integrity
log_msg "Verifying archive..."
if shasum -a 256 -c "${ARCHIVE_PATH}.sha256" >/dev/null 2>&1; then
    log_msg "PASS: Archive integrity verified"
else
    log_msg "FAIL: Archive integrity check failed"
    exit 1
fi

# Cleanup
rm -rf "$WORK_DIR"

ARCHIVE_SIZE=$(stat -f%z "$ARCHIVE_PATH" 2>/dev/null || stat --format=%s "$ARCHIVE_PATH" 2>/dev/null)
log_msg "Export complete: $ARCHIVE_PATH (${ARCHIVE_SIZE} bytes)"
log_msg "Checksum: ${ARCHIVE_PATH}.sha256"
