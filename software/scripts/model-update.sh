#!/bin/bash
set -euo pipefail

# Transfer Ollama models to air-gapped Mini B via USB.
# Handles export (on Mini A) and import (on Mini B) with GPG verification.

SCRIPT_NAME=$(basename "$0")
LOG="/var/log/fercoff/model-update.log"
STAGING_DIR="/opt/fercoff/staging/models"

log_msg() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$SCRIPT_NAME] $1" | tee -a "$LOG"; }

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  export  --model <name> --usb <mount-path>
      Export an Ollama model from Mini A to USB with GPG signature.

  import  --usb <mount-path>
      Import and verify all models from USB on Mini B.

Examples:
  $SCRIPT_NAME export --model qwen2.5:7b --usb /Volumes/FERCOFF-USB
  $SCRIPT_NAME import --usb /Volumes/FERCOFF-USB
EOF
    exit 1
}

validate_usb() {
    local usb_path="$1"
    if [[ ! -d "$usb_path" ]]; then
        log_msg "ERROR: USB mount point not found: $usb_path"
        exit 1
    fi
    log_msg "USB validated: $usb_path"
}

do_export() {
    local model="" usb_path=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --model) model="$2"; shift 2 ;;
            --usb)   usb_path="$2"; shift 2 ;;
            *)       usage ;;
        esac
    done

    [[ -z "$model" || -z "$usb_path" ]] && usage

    validate_usb "$usb_path"

    local safe_name
    safe_name=$(echo "$model" | tr ':/' '-')
    local export_file="${usb_path}/models/${safe_name}.bin"

    mkdir -p "${usb_path}/models"

    log_msg "Pulling latest $model..."
    ollama pull "$model"

    log_msg "Exporting $model to $export_file..."
    ollama cp "$model" "$export_file"

    log_msg "Generating GPG signature..."
    gpg --armor --detach-sign "$export_file"

    log_msg "Generating SHA-256 checksum..."
    shasum -a 256 "$export_file" > "${export_file}.sha256"

    log_msg "Export complete: $export_file"
    log_msg "Signature: ${export_file}.asc"
    log_msg "Checksum: ${export_file}.sha256"
}

do_import() {
    local usb_path=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --usb) usb_path="$2"; shift 2 ;;
            *)     usage ;;
        esac
    done

    [[ -z "$usb_path" ]] && usage

    validate_usb "$usb_path"

    local model_dir="${usb_path}/models"
    if [[ ! -d "$model_dir" ]]; then
        log_msg "ERROR: No models directory on USB"
        exit 1
    fi

    mkdir -p "$STAGING_DIR"

    local model_count=0
    for model_file in "$model_dir"/*.bin; do
        [[ -f "$model_file" ]] || continue

        local base
        base=$(basename "$model_file")
        log_msg "Processing $base..."

        # Verify GPG signature
        if [[ -f "${model_file}.asc" ]]; then
            log_msg "Verifying GPG signature..."
            if ! gpg --verify "${model_file}.asc" "$model_file" 2>/dev/null; then
                log_msg "ERROR: GPG verification failed for $base -- skipping"
                continue
            fi
            log_msg "GPG signature valid"
        else
            log_msg "WARNING: No GPG signature for $base"
        fi

        # Verify SHA-256
        if [[ -f "${model_file}.sha256" ]]; then
            log_msg "Verifying checksum..."
            if ! shasum -a 256 -c "${model_file}.sha256" 2>/dev/null; then
                log_msg "ERROR: Checksum mismatch for $base -- skipping"
                continue
            fi
            log_msg "Checksum valid"
        fi

        # Copy to staging and load
        cp "$model_file" "$STAGING_DIR/"
        local model_name
        model_name=$(echo "${base%.bin}" | tr '-' ':' | sed 's/:/:/')

        log_msg "Loading $model_name into Ollama..."
        ollama cp "$STAGING_DIR/$base" "$model_name"

        # Smoke test
        log_msg "Running smoke test..."
        local test_result
        test_result=$(ollama run "$model_name" "Reply with exactly: OK" 2>&1 | head -1)
        log_msg "Smoke test response: $test_result"

        model_count=$((model_count + 1))
    done

    log_msg "Import complete: $model_count model(s) loaded"
}

# -- Main --
[[ $# -lt 1 ]] && usage

command="$1"
shift

case "$command" in
    export) do_export "$@" ;;
    import) do_import "$@" ;;
    *)      usage ;;
esac
