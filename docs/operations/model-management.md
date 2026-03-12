# Model Management

## Available Models

| Model | Size | Speed (M4 16GB) | Best For |
|-------|------|-----------------|----------|
| qwen2.5:3b | ~2 GB | ~45-50 tok/s | Fast queries, simple analysis, natural language search |
| qwen2.5:7b | ~4.5 GB | ~32-35 tok/s | Complex reasoning, root cause analysis, report generation |

Start with 3B. Use 7B when you need deeper analysis or longer context.

## Updating Models on Air-Gapped Mini B

### Using the Script

```bash
# On Mini A: pull latest and export to USB
./software/scripts/model-update.sh export --model qwen2.5:3b --usb /Volumes/FERCOFF-USB

# Walk USB to Mini B

# On Mini B: verify and load
./software/scripts/model-update.sh import --usb /Volumes/FERCOFF-USB
```

### Manual Process

```bash
# Mini A
ollama pull qwen2.5:7b
ollama cp qwen2.5:7b /Volumes/USB/models/qwen2.5-7b.bin
gpg --armor --detach-sign /Volumes/USB/models/qwen2.5-7b.bin
shasum -a 256 /Volumes/USB/models/qwen2.5-7b.bin > /Volumes/USB/models/qwen2.5-7b.bin.sha256

# Mini B
gpg --verify /Volumes/USB/models/qwen2.5-7b.bin.asc
shasum -a 256 -c /Volumes/USB/models/qwen2.5-7b.bin.sha256
ollama cp /Volumes/USB/models/qwen2.5-7b.bin qwen2.5:7b
```

## Testing New Models

Before putting a new model into production use:

```bash
# Run smoke test
ollama run qwen2.5:7b "What is the rated voltage of a typical distribution transformer?"

# Test with a domain-specific prompt
ollama run qwen2.5:7b "Explain the significance of acetylene in transformer DGA results."

# Verify performance
time ollama run qwen2.5:7b "Summarize the key failure modes of SF6 circuit breakers." --verbose
```

## Rollback

If a new model produces poor results:

```bash
# List available models
ollama list

# Remove problematic version
ollama rm qwen2.5:7b

# Restore from USB backup
ollama cp /Volumes/BACKUP-USB/models/qwen2.5-7b-previous.bin qwen2.5:7b
```

## Upgrade Path

| When | Upgrade To | Cost |
|------|-----------|------|
| 7B context insufficient | Mac Mini M4 Pro 32GB | +$800 |
| Need 14B+ models | Mac Studio M2 Ultra 192GB | +$3,000 |
| New Qwen release | Same hardware, new weights | $0 (USB transfer) |
