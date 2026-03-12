# Offline Package Preparation

How to prepare a USB drive with everything Mini B needs for air-gapped installation.

## USB Directory Structure

```
/Volumes/FERCOFF-USB/
  models/
    qwen2.5-3b.bin          Ollama model export
    qwen2.5-3b.bin.asc      GPG signature
    qwen2.5-7b.bin           (optional, 4.5GB)
    qwen2.5-7b.bin.asc
  bin/
    ollama                   Ollama binary
  fercoff/                   Full repo clone
  signing-key.pub            GPG public key
  SHA256SUMS                 Integrity manifest
```

## Step-by-Step (Run on Mini A)

### 1. Format USB

```bash
diskutil eraseDisk ExFAT FERCOFF-USB /dev/diskN
```

### 2. Export Models

```bash
ollama pull qwen2.5:3b
ollama pull qwen2.5:7b  # optional
mkdir -p /Volumes/FERCOFF-USB/models
ollama cp qwen2.5:3b /Volumes/FERCOFF-USB/models/qwen2.5-3b.bin
```

### 3. Sign with GPG

```bash
gpg --quick-gen-key "FERCoff Model Signing" ed25519
gpg --armor --detach-sign /Volumes/FERCOFF-USB/models/qwen2.5-3b.bin
gpg --export --armor "FERCoff Model Signing" > /Volumes/FERCOFF-USB/signing-key.pub
```

### 4. Copy Binaries and Repo

```bash
mkdir -p /Volumes/FERCOFF-USB/bin
cp $(which ollama) /Volumes/FERCOFF-USB/bin/ollama
cp -R /opt/fercoff /Volumes/FERCOFF-USB/fercoff
```

### 5. Generate Manifest

```bash
cd /Volumes/FERCOFF-USB
find . -type f ! -name 'SHA256SUMS' -exec shasum -a 256 {} \; > SHA256SUMS
```

### 6. Eject

```bash
diskutil unmount /Volumes/FERCOFF-USB
```

## On Mini B

```bash
cd /Volumes/FERCOFF-USB
shasum -a 256 -c SHA256SUMS
gpg --import signing-key.pub
gpg --verify models/qwen2.5-3b.bin.asc
sudo cp bin/ollama /usr/local/bin/ollama && sudo chmod +x /usr/local/bin/ollama
sudo cp -R fercoff /opt/fercoff
```

## Updates

Use `software/scripts/model-update.sh` for subsequent model transfers:

```bash
# Mini A
./software/scripts/model-update.sh export --model qwen2.5:7b --usb /Volumes/FERCOFF-USB

# Mini B
./software/scripts/model-update.sh import --usb /Volumes/FERCOFF-USB
```
