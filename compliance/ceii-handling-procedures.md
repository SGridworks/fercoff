# CEII Data Handling Procedures

**This document describes technical procedures for handling Critical Energy Infrastructure Information (CEII) within the FERCoff sandbox. It is not legal advice.** Your organization must determine which data qualifies as CEII under 18 CFR 388.113 and implement appropriate policies. See [DISCLAIMER.md](../DISCLAIMER.md) for complete terms.

---

## Data Classification

FERCoff uses a three-tier classification scheme. Your compliance team should map your specific data to these tiers.

| Tier | Classification | Examples | Where It Lives |
|------|---------------|----------|----------------|
| **Tier 1: CEII** | Critical Energy Infrastructure Information | Real-time SCADA feeds, grid topology, relay settings, protection schemes | Mini B only (sandbox) |
| **Tier 2: Sensitive** | Operationally sensitive but not CEII | Aggregated load data, maintenance schedules, anonymized event logs | Mini B preferred, Mini A acceptable |
| **Tier 3: Public** | Non-sensitive, publishable | Synthetic datasets, public weather data, published capacity figures | Either node |

### Classification Decision Guide

Ask these questions:

1. Does this data reveal specific grid topology or configuration? -> Tier 1
2. Could this data help an adversary identify grid vulnerabilities? -> Tier 1
3. Is this data aggregated beyond individual asset identification? -> Tier 2
4. Is this data already publicly available? -> Tier 3

**When in doubt, classify higher.** It is easier to declassify than to recover from a leak.

---

## Ingestion Procedures

### Method 1: USB Transfer (Recommended for Initial Load)

**Use when:** Loading historical data, bulk imports, datasets under 10GB.

1. **Prepare USB on OT network:**
   - Export data from historian/SCADA to encrypted USB drive
   - Use a dedicated USB drive labeled "FERCOFF CEII TRANSFER"
   - Create a manifest file listing all datasets with checksums

2. **Physical transfer:**
   - Walk USB from OT environment to Mini B location
   - Log the transfer: date, time, person, dataset description
   - Two-person rule recommended for Tier 1 data

3. **Import on Mini B:**
   ```bash
   # Mount USB
   # Verify checksums
   shasum -a 256 -c manifest.sha256

   # Copy to data directory
   cp -R /Volumes/USB/data/* /opt/fercoff/data/

   # Unmount and return USB
   diskutil unmount /Volumes/USB
   ```

4. **Post-import:**
   - Verify data integrity on Mini B
   - Securely erase USB: `diskutil secureErase 2 /dev/diskN`
   - Update the data inventory log

### Method 2: Dedicated Ethernet (Real-time Feeds)

**Use when:** Continuous SCADA historian access, real-time analysis.

1. **Physical setup:**
   - Dedicated Ethernet cable from OT historian to Mini B
   - No switch, no router -- point-to-point connection only
   - Label the cable "FERCOFF CEII LINK -- DO NOT DISCONNECT"

2. **Network configuration:**
   - Static IP on dedicated interface (not the Thunderbolt bridge)
   - pf rules allow inbound from historian IP only
   - No outbound traffic permitted on this interface

3. **Data flow:**
   - Historian pushes data to Mini B on schedule
   - Mini B never initiates connections to the historian
   - One-way data flow enforced by pf rules

4. **Monitoring:**
   - Audit logger captures data transfer events
   - Alert on unexpected traffic patterns

### Method 3: Staging Server (Advanced)

**Use when:** Automated pipelines, data validation before sandbox ingestion.

1. Staging server on OT network validates and sanitizes data
2. One-way rsync to Mini B via SSH over dedicated Ethernet
3. Automated checksums and format validation
4. Manual approval gate for Tier 1 data

---

## Access Control Requirements

### Who Can Access CEII on the Sandbox

| Role | Access Level | Authorization |
|------|-------------|---------------|
| Sandbox administrator | Full (SSH, data management) | Written approval from [DESIGNEE] |
| Authorized engineer | Query only (via gateway API) | Added to Tailscale ACL group |
| Auditor | Read-only audit logs | Escorted, time-limited access |
| Vendor | None | No vendor access to sandbox |

### Access Provisioning

1. Engineer requests access through [PROCESS]
2. Manager and CEII custodian approve
3. Admin adds engineer to Tailscale ACL and creates macOS account
4. Engineer completes CEII handling training
5. Access is documented with start date and review date

### Access Review

- Quarterly review of all sandbox access
- Remove access for personnel who no longer need it
- Document all access changes in audit log

---

## Data in Use

### Query Controls

- Engineers submit queries through the gateway API (Mini A)
- The gateway logs every query with user, timestamp, and query hash
- Inference runs on Mini B; raw CEII never crosses to Mini A
- Only aggregated, non-sensitive results return to the engineer
- Output sanitization checks for CEII leakage in responses

### Output Review

Before any analysis result leaves the sandbox:

1. **Automated check:** Output sanitization scans for patterns matching CEII indicators (IP addresses, relay settings, specific asset identifiers)
2. **Manual review (Tier 1):** For queries touching Tier 1 data, results should be reviewed by an authorized person before export
3. **Aggregation threshold:** Results must be aggregated beyond individual asset identification unless the requesting engineer has Tier 1 authorization

---

## Data Destruction

### When to Destroy

- Sandbox decommissioning
- Data retention period expired
- Data no longer needed for authorized purpose
- Hardware being repaired or transferred

### Destruction Procedures

**Software destruction (data only):**
```bash
# Securely overwrite data directory
srm -sz /opt/fercoff/data/*

# Verify deletion
ls -la /opt/fercoff/data/
```

**Hardware destruction (decommission):**
1. Export audit logs for retention: `audit-export.sh --output /Volumes/USB/final-audit`
2. Disable FileVault and decrypt (requires admin password)
3. Erase disk: `diskutil secureErase 4 /dev/disk0` (7-pass if required by policy)
4. Physical destruction if required by your data handling policy
5. Document destruction: date, method, witness, serial numbers

### Destruction Log

Maintain a record of all CEII destruction:

| Date | Dataset | Method | Performed By | Witnessed By | Serial Number |
|------|---------|--------|-------------|-------------|---------------|
| [FILL IN] | [FILL IN] | [Software/Physical] | [FILL IN] | [FILL IN] | [FILL IN] |

---

## Incident Response for CEII Exposure

### Indicators of Potential Exposure

- Unexpected network traffic on Mini B (check `pfctl -s info` counters)
- Unauthorized user in Tailscale or SSH logs
- Physical tamper evidence on Mini B cabinet
- CEII-like content appearing in gateway logs or engineer outputs

### Immediate Response (First 30 Minutes)

1. **Isolate:** Disconnect Thunderbolt cable from Mini B
2. **Preserve:** Do NOT reboot. Export audit logs immediately.
3. **Notify:** Contact [CEII CUSTODIAN] and [CISO]
4. **Document:** Record timeline, actions taken, personnel involved

### Investigation (First 24 Hours)

1. Review all audit logs for the exposure window
2. Identify what data may have been exposed
3. Determine whether data left the sandbox boundary
4. Assess whether the exposure constitutes a reportable incident

### Reporting

If CEII was exposed outside the authorized boundary:
- Notify your CEII custodian immediately
- Follow your organization's CEII incident reporting procedures
- Report to FERC if required under 18 CFR 388.113
- Document the incident and remediation steps

### Recovery

1. Determine root cause
2. Apply fix (update firewall rules, revoke access, patch vulnerability)
3. Re-run `sandbox-init.sh` and `health-check.sh` to verify
4. Document lessons learned
5. Update procedures to prevent recurrence
