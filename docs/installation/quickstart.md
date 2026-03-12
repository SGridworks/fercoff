# Quickstart Guide

You have two Mac Minis on your desk. Here is how to turn them into a CEII-compliant AI sandbox in about 2 hours.

## What You Need

- 2x Mac Mini M4 (16GB/256GB)
- 1x Thunderbolt 4 cable (0.8m)
- 1x USB drive (16GB+, for offline package transfer)
- Ethernet cables for Mini A network connection
- A monitor and keyboard (shared, for initial setup)

---

## Phase 1: Mini A (Gateway) Setup -- 30 minutes

Mini A is your internet-connected gateway. Engineers connect here.

### 1.1 macOS Initial Setup

Boot Mini A, complete macOS setup. Create an admin account (e.g., `fercoff-admin`). Connect to your network via Ethernet.

### 1.2 Install Homebrew and Dependencies

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install node@22 tailscale ollama git ansible
```

### 1.3 Set Up Tailscale

```bash
brew services start tailscale
sudo tailscale up
tailscale status
```

### 1.4 Pull Qwen Model

```bash
brew services start ollama
ollama pull qwen2.5:3b
ollama list
```

### 1.5 Clone FERCoff

```bash
git clone https://github.com/sgridworks/fercoff.git /opt/fercoff
cd /opt/fercoff
```

### 1.6 Configure Thunderbolt IP

Connect the Thunderbolt 4 cable between Mini A and Mini B.

```bash
sudo networksetup -setmanual "Thunderbolt Bridge" 10.0.5.1 255.255.255.0
ifconfig bridge0
```

---

## Phase 2: Prepare USB for Mini B -- 15 minutes

Mini B is air-gapped, so everything must go via USB.

```bash
mkdir -p /Volumes/USB/models /Volumes/USB/bin

# Export models
ollama cp qwen2.5:3b /Volumes/USB/models/qwen2.5-3b.bin
gpg --armor --detach-sign /Volumes/USB/models/qwen2.5-3b.bin

# Copy Ollama binary and FERCoff repo
cp $(which ollama) /Volumes/USB/bin/ollama
cp -R /opt/fercoff /Volumes/USB/fercoff

# Generate checksums
cd /Volumes/USB && find . -type f ! -name 'SHA256SUMS' -exec shasum -a 256 {} \; > SHA256SUMS
```

See [offline-packages.md](offline-packages.md) for the full package list.

---

## Phase 3: Mini B (Sandbox) Setup -- 45 minutes

Mini B is your air-gapped sandbox. CEII data lives here.

### 3.1 macOS Initial Setup

Boot Mini B, create admin account (`fercoff-admin`). **Do not connect to WiFi.**

### 3.2 Disable WiFi Permanently

```bash
sudo networksetup -setairportpower en0 off
networksetup -getairportpower en0
# Expected: Wi-Fi Power (en0): Off
```

### 3.3 Configure Thunderbolt IP

```bash
sudo networksetup -setmanual "Thunderbolt Bridge" 10.0.5.2 255.255.255.0
ping -c 3 10.0.5.1
```

### 3.4 Install from USB

```bash
cd /Volumes/USB
shasum -a 256 -c SHA256SUMS
sudo cp bin/ollama /usr/local/bin/ollama && sudo chmod +x /usr/local/bin/ollama
sudo cp -R fercoff /opt/fercoff
```

### 3.5 Load Models

```bash
ollama serve &
gpg --verify /Volumes/USB/models/qwen2.5-3b.bin.asc
ollama cp /Volumes/USB/models/qwen2.5-3b.bin qwen2.5:3b
ollama run qwen2.5:3b "Reply with exactly: OK"
```

### 3.6 Enable FileVault

```bash
sudo fdesetup enable -user fercoff-admin
```

Save the recovery key in a sealed envelope in your facility safe.

### 3.7 Configure Firewall

```bash
# Copy and edit pf.conf (replace Jinja vars with actual IPs)
sudo cp /opt/fercoff/software/ansible/roles/sandbox/templates/pf.conf.j2 /etc/pf.conf
# Edit: {{ gateway_ip }} -> 10.0.5.1, {{ sandbox_ip }} -> 10.0.5.2, {{ ollama_port }} -> 11434
sudo pfctl -f /etc/pf.conf && sudo pfctl -e
```

### 3.8 Run Initialization

```bash
sudo /opt/fercoff/software/scripts/sandbox-init.sh
```

---

## Phase 4: Verification -- 15 minutes

### 4.1 Health Checks

```bash
# On Mini A
/opt/fercoff/software/scripts/health-check.sh --role gateway

# On Mini B (via SSH from Mini A)
ssh fercoff-admin@10.0.5.2 '/opt/fercoff/software/scripts/health-check.sh --role sandbox'
```

### 4.2 Test End-to-End Query

From Mini A:

```bash
curl -X POST http://10.0.5.2:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:3b","messages":[{"role":"user","content":"What is a transformer bushing?"}],"stream":false}'
```

### 4.3 Verify Air-Gap

On Mini B -- all external tests MUST fail:

```bash
ping -c 1 8.8.8.8        # Must fail: "No route to host"
host google.com           # Must fail: timeout
ping -c 1 10.0.5.1       # Must succeed: reply from Mini A
```

### 4.4 Check Audit Log

```bash
cat /var/log/fercoff/audit/audit.log
```

---

## Done

Your FERCoff sandbox is operational. Next steps:

1. Load your data -- see [daily workflow](../operations/daily-workflow.md)
2. Try the examples -- `examples/` has Jupyter notebooks
3. Set up the gateway API -- install sgridworks-sandbox on Mini A
4. Schedule health checks -- add to cron on both nodes

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Can't ping Mini B | Check `ifconfig bridge0` on both nodes |
| Ollama not responding | Run `ollama serve &` or load LaunchDaemon |
| FileVault enable fails | Check `fdesetup status` |
| pf rules won't load | Validate with `pfctl -nf /etc/pf.conf` |
| USB not mounting | Use APFS or ExFAT format |

For more, see [common-issues.md](../troubleshooting/common-issues.md).
