# Network Configuration

## Topology

```
                        Internet
                           |
                     [Your LAN/Switch]
                           |
                     +-----------+
                     |  Mini A   |  192.168.x.x (LAN)
                     |  Gateway  |  10.0.5.1 (Thunderbolt)
                     +-----+-----+
                           | Thunderbolt 4 (direct cable)
                     +-----+-----+
                     |  Mini B   |  10.0.5.2 (Thunderbolt only)
                     |  Sandbox  |  No other network
                     +-----------+
```

## Thunderbolt IP Bridge

macOS exposes the Thunderbolt cable as a "Thunderbolt Bridge" network interface.

### Setup

```bash
# Mini A
sudo networksetup -setmanual "Thunderbolt Bridge" 10.0.5.1 255.255.255.0

# Mini B
sudo networksetup -setmanual "Thunderbolt Bridge" 10.0.5.2 255.255.255.0

# Verify from either side
ping -c 3 10.0.5.X
```

## Tailscale (Mini A Only)

Provides encrypted remote access for engineers. Mini B does NOT run Tailscale.

### ACL Configuration

In the Tailscale admin console:

```json
{
  "acls": [
    {"action": "accept", "src": ["group:fercoff-engineers"], "dst": ["tag:fercoff-gateway:*"]}
  ],
  "tagOwners": {"tag:fercoff-gateway": ["autogroup:admin"]},
  "groups": {"group:fercoff-engineers": ["user1@example.com"]}
}
```

```bash
sudo tailscale up --advertise-tags=tag:fercoff-gateway
```

## pf Firewall

### Mini A -- allow outbound, restrict sandbox access

Key rules: allow all outbound, allow Tailscale inbound, allow Ollama to Mini B, block everything else to Mini B.

### Mini B -- deny all outbound (air-gap enforcement)

Key rules: block ALL outbound, allow inbound from 10.0.5.1 on ports 11434 and 22 only, block all WiFi/Ethernet interfaces.

### Management

```bash
sudo pfctl -nf /etc/pf.conf   # validate
sudo pfctl -f /etc/pf.conf    # apply
sudo pfctl -e                  # enable
sudo pfctl -s rules            # view active rules
```

## Verifying the Air-Gap

Run on Mini B -- every external test MUST fail:

```bash
route -n get default 2>&1     # "not in table"
host google.com               # timeout
ping -c 1 -W 2 8.8.8.8       # "No route to host"
ping -c 1 10.0.5.1            # MUST succeed
```

## Common Issues

| Issue | Fix |
|-------|-----|
| Bridge not visible | Unplug/replug Thunderbolt cable, check System Settings > Network |
| Bridge shows "Not Connected" | Run `networksetup -setmanual` command |
| Mini B can reach internet | Disable WiFi, remove extra Ethernet cables |
| Tailscale can't reach Mini A | Check `pfctl -s rules` |
