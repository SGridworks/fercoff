# Troubleshooting

## Connectivity Issues

### Can't connect to Mini B from Mini A

**Symptoms:** `ping 10.0.5.2` times out, SSH fails.

**Check:**
```bash
# Is the Thunderbolt bridge configured?
ifconfig bridge0

# Is the cable connected?
networksetup -listallhardwareports | grep -A2 "Thunderbolt"

# Is Mini B powered on?
# (No remote way to check -- verify physically)
```

**Fix:**
- Unplug and replug the Thunderbolt cable
- Re-run: `sudo networksetup -setmanual "Thunderbolt Bridge" 10.0.5.1 255.255.255.0`
- Verify Mini B has `10.0.5.2` configured

### Tailscale can't reach Mini A

**Check:**
```bash
tailscale status
tailscale ping mini-a
brew services list | grep tailscale
```

**Fix:**
- Restart Tailscale: `brew services restart tailscale`
- Re-authenticate: `sudo tailscale up`
- Check firewall: `sudo pfctl -s rules`

## Ollama Issues

### Model won't load

**Symptoms:** `ollama run qwen2.5:7b` fails or is extremely slow.

**Check:**
```bash
# Available memory
vm_stat | head -5

# Running models
curl -s localhost:11434/api/tags | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin),indent=2))"

# Model size
ollama list
```

**Fix:**
- Use 3B instead of 7B (fits in 16GB with room to spare)
- Close other applications consuming memory
- Restart Ollama: kill the process and restart

### Slow inference

**Symptoms:** Responses take 30+ seconds for short prompts.

**Check:**
```bash
# CPU temperature (thermal throttling)
sudo powermetrics --samplers smc -i 1 -n 1 | grep -i temp

# GPU utilization
sudo powermetrics --samplers gpu_power -i 1 -n 1
```

**Fix:**
- Ensure adequate ventilation (Mac Mini needs airflow at the bottom)
- Check ambient temperature (operating range: 0-35C)
- Use 3B model for speed-sensitive queries

## Security Issues

### FileVault recovery

**Symptoms:** Mini B won't boot, asks for recovery key.

**Fix:**
1. Enter the recovery key (stored in your facility safe)
2. If recovery key is lost: the data is unrecoverable (this is by design)
3. Rebuild from spare Mini + USB backup

### pf firewall not active

**Check:**
```bash
sudo pfctl -s info
# Should show "Status: Enabled"
```

**Fix:**
```bash
sudo pfctl -f /etc/pf.conf
sudo pfctl -e
```

### Air-gap breach suspected

**Symptoms:** Unexpected entries in audit log, Mini B has a default route.

**Immediate response:**
1. Disconnect Thunderbolt cable
2. Do NOT reboot
3. Export audit logs: `sudo /opt/fercoff/software/scripts/audit-export.sh --output /Volumes/USB/incident`
4. Follow incident response procedures in `compliance/ceii-handling-procedures.md`

## Audit Log Issues

### Audit log full

**Check:**
```bash
du -sh /var/log/fercoff/audit/
df -h /
```

**Fix:**
1. Export current logs: `audit-export.sh --output /Volumes/USB/archive`
2. After confirmed export, truncate old entries (keep recent 90 days)
3. Verify disk space recovered

### Gaps in audit log

**Possible causes:**
- Audit logger daemon crashed
- Mini B was powered off
- Clock skew

**Fix:**
```bash
# Check daemon status
launchctl list | grep fercoff

# Reload if needed
sudo launchctl load /Library/LaunchDaemons/ai.fercoff.audit-logger.plist

# Check system uptime for unexpected reboots
uptime
last reboot
```

## Getting Help

- **GitHub Discussions:** https://github.com/sgridworks/fercoff/discussions
- **GitHub Issues:** https://github.com/sgridworks/fercoff/issues
