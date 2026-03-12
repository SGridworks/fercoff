# FERCoff Audit Response Template

**This is a template, not legal advice.** Customize all [FILL IN] sections for your organization. Have your compliance team and general counsel review before submitting to any auditor. See [DISCLAIMER.md](../DISCLAIMER.md) for complete terms.

---

## Pre-Audit Checklist

Run these before any audit engagement:

- [ ] Run `health-check.sh --role sandbox` on Mini B -- all checks pass
- [ ] Run `health-check.sh --role gateway` on Mini A -- all checks pass
- [ ] Run `audit-export.sh --output ./audit-evidence` -- archive created
- [ ] Verify FileVault is enabled: `fdesetup status`
- [ ] Verify pf firewall is active: `pfctl -s info`
- [ ] Verify air-gap: `route -n get default` should fail on Mini B
- [ ] Review access list: confirm only authorized users have Tailscale access
- [ ] Confirm audit logs have no gaps in the review period
- [ ] Gather physical security evidence (cabinet lock photos, access log)
- [ ] Confirm model versions match approved configuration

---

## Evidence Collection Guide

Run these commands and save the output for your audit package:

```bash
# On Mini B (Sandbox)
fdesetup status                          > evidence/filevault-status.txt
pfctl -s rules                           > evidence/firewall-rules.txt
pfctl -s info                            > evidence/firewall-info.txt
ifconfig -a                              > evidence/network-interfaces.txt
route -n get default 2>&1               > evidence/route-check.txt
launchctl list | grep fercoff            > evidence/running-services.txt
curl -s localhost:11434/api/tags         > evidence/ollama-models.json
sw_vers                                  > evidence/os-version.txt
diskutil apfs list                       > evidence/disk-encryption.txt
cat /var/log/fercoff/audit/audit.log     > evidence/audit-log.txt

# On Mini A (Gateway)
tailscale status                         > evidence/tailscale-status.txt
pfctl -s rules                           > evidence/gateway-firewall.txt
git -C /opt/fercoff log --oneline -20    > evidence/config-history.txt
```

---

## Section 1: System Description

**Auditor may ask:** "Describe the system and its purpose."

### Template Response

[ORGANIZATION NAME] operates a FERCoff secure AI sandbox for [PURPOSE: e.g., transformer anomaly detection, predictive maintenance analysis]. The system consists of:

- **Gateway Node (Mini A):** Mac Mini M4, located at [LOCATION]. Provides engineer access via Tailscale VPN and job orchestration. Connected to corporate network.
- **Sandbox Node (Mini B):** Mac Mini M4, located at [LOCATION]. Air-gapped from all external networks. Holds CEII-protected data and runs local AI inference using Qwen [MODEL VERSION] via Ollama.
- **Interconnect:** Thunderbolt 4 direct cable (10.0.5.0/24 subnet). No switch, no router.

The system was deployed on [DATE] and is maintained by [RESPONSIBLE PERSON/TEAM].

**Evidence:** Network diagram, hardware inventory, deployment date records.

---

## Section 2: Access Controls

**Auditor may ask:** "Who has access and how is it controlled?"

### Template Response

Access to the FERCoff sandbox is controlled at three layers:

1. **Network access:** Engineers connect to the gateway via Tailscale VPN. Access is restricted by Tailscale ACLs to members of the `[GROUP NAME]` group.
2. **System access:** macOS user accounts with [PASSWORD POLICY: e.g., 12+ characters, rotated quarterly]. No shared accounts.
3. **Sandbox access:** Mini B is only reachable from Mini A over the Thunderbolt bridge. No direct engineer access to Mini B.

**Current authorized users:**

| Name | Role | Access Level | Granted | Last Review |
|------|------|-------------|---------|-------------|
| [FILL IN] | [FILL IN] | [gateway/sandbox/admin] | [DATE] | [DATE] |

Access reviews are conducted [FREQUENCY: e.g., quarterly].

**Evidence:** Tailscale ACL config, macOS user list, access review records.

---

## Section 3: Encryption

**Auditor may ask:** "How is data encrypted at rest and in transit?"

### Template Response

- **At rest:** Mini B uses FileVault full-disk encryption (XTS-AES-128). Recovery key is stored [LOCATION: e.g., in a sealed envelope in the facility safe].
- **In transit (gateway to engineers):** Tailscale provides WireGuard-based encryption for all traffic between engineers and the gateway.
- **In transit (gateway to sandbox):** Thunderbolt direct cable. No network traversal. Data cannot be intercepted without physical access to the cable.

**Evidence:** `fdesetup status` output, Tailscale configuration, network diagram.

---

## Section 4: Network Isolation

**Auditor may ask:** "How is CEII data prevented from leaving the secure boundary?"

### Template Response

Mini B (sandbox) is air-gapped with the following controls:

1. **No WiFi:** Wireless interface permanently disabled (`networksetup -setairportpower en0 off`).
2. **No default route:** No gateway configured. No path to the internet.
3. **pf firewall:** Deny-all outbound policy. Only accepts inbound from Mini A on port 11434 (Ollama) and port 22 (SSH for maintenance).
4. **Physical isolation:** Located in [LOCATION] with [PHYSICAL CONTROLS: e.g., locked cabinet, badge access].

Air-gap is verified daily by the automated health check, which confirms no default route and no DNS resolution.

**Evidence:** `pf.conf`, `route -n get default` output, `ifconfig` output, health check logs.

---

## Section 5: Audit Logging

**Auditor may ask:** "What is logged and how are logs protected?"

### Template Response

The FERCoff audit logger records system state every 5 minutes to `/var/log/fercoff/audit/audit.log`. Each entry includes:

- Timestamp (UTC)
- Ollama status
- FileVault status
- pf firewall status

All queries submitted to the sandbox are logged by the gateway with:
- Timestamp, submitting user, model used
- Query hash (SHA-256, not the full query for data protection)
- Response metadata (length, duration)

Logs are append-only (macOS `sappend` flag on the audit directory). Logs are retained for [RETENTION PERIOD: e.g., 365 days] and exported monthly to [ARCHIVE LOCATION].

**Evidence:** `audit.log` sample, `ls -lO /var/log/fercoff/audit/`, log retention policy.

---

## Section 6: Physical Security

**Auditor may ask:** "How is the hardware physically protected?"

### Template Response

| Control | Implementation |
|---------|---------------|
| Location | [BUILDING, ROOM, RACK/CABINET] |
| Access control | [BADGE READER / LOCK / KEY] |
| Access logging | [ELECTRONIC LOG / SIGN-IN SHEET] |
| Tamper evidence | [TAMPER-EVIDENT SEALS ON USB PORTS] |
| Environmental | [HVAC / TEMPERATURE MONITORING] |
| Inspection frequency | [QUARTERLY / MONTHLY] |

**Evidence:** Facility photos, access log, inspection records, seal verification log.

---

## Section 7: Incident Response

**Auditor may ask:** "What is your incident response process for this system?"

### Template Response

FERCoff incidents follow [ORGANIZATION]'s standard incident response plan with these system-specific additions:

| Scenario | Response |
|----------|----------|
| Sandbox compromise suspected | Isolate Mini B (disconnect Thunderbolt), export audit logs, notify [CONTACT] |
| Physical theft of Mini B | FileVault protects data at rest. Report to [CONTACT]. Invoke recovery plan. |
| Unauthorized access detected | Revoke Tailscale access, review audit logs, notify [CONTACT] |
| Model integrity concern | Revert to last known-good model via USB backup |

Incident response contact: [NAME, PHONE, EMAIL]

Last incident response drill: [DATE]

**Evidence:** Incident response plan, drill records, contact list.

---

## Section 8: Change Management

**Auditor may ask:** "How are changes to the system controlled?"

### Template Response

All FERCoff configuration is managed via Ansible playbooks stored in a Git repository. Changes follow this process:

1. Engineer proposes change via Git pull request
2. [APPROVER] reviews and approves
3. Change is applied via `ansible-playbook deploy.yml`
4. Health check verifies system state post-change
5. Change is documented in Git history

Model updates follow a separate process (see `model-update.sh`) with GPG signature verification.

Last configuration change: [DATE, DESCRIPTION]

**Evidence:** Git log, PR history, health check logs post-change.
