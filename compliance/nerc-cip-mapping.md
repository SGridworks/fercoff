# NERC CIP Standards Mapping for FERCoff

**This is engineering guidance, not legal advice.** Consult your compliance team and general counsel before relying on this mapping for audit preparation. See [DISCLAIMER.md](../DISCLAIMER.md) for complete terms.

---

## Coverage Summary

| CIP Standard | Description | FERCoff Coverage |
|--------------|-------------|-----------------|
| CIP-003 | Security Management Controls | Partial |
| CIP-004 | Personnel and Training | Out of Scope |
| CIP-005 | Electronic Security Perimeters | Full |
| CIP-006 | Physical Security | Partial |
| CIP-007 | System Security Management | Partial |
| CIP-008 | Incident Reporting and Response | Partial |
| CIP-009 | Recovery Plans | Partial |
| CIP-010 | Configuration Change Management | Full |
| CIP-011 | Information Protection | Full |
| CIP-013 | Supply Chain Risk Management | Partial |

**Full** = architecture directly addresses the requirement with documented controls.
**Partial** = architecture supports the requirement but needs site-specific procedures.
**Out of Scope** = organizational process, not addressable by technical architecture.

---

## CIP-003: Security Management Controls

Requires a documented cyber security policy and assignment of responsibility.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Documented security policy | Repo provides baseline policy templates | `compliance/` directory | Policy must be customized to your org |
| R2: Designated senior manager | Not applicable (organizational) | N/A | You must designate a responsible person |
| R3: Exceptions process | Not applicable (organizational) | N/A | Your compliance team owns this |
| R4: Network security management | pf firewall on both nodes, deny-all on sandbox | `pf.conf`, `pfctl -s rules` | Must document change approval process |

---

## CIP-004: Personnel and Training

Requires personnel risk assessment and security awareness training.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Security awareness | Not applicable (organizational) | N/A | Provide training to all sandbox users |
| R2: Training program | Not applicable (organizational) | N/A | Include FERCoff in your CIP training |
| R3: Personnel risk assessment | Not applicable (organizational) | N/A | Background checks per your policy |
| R4: Access management | Tailscale ACLs, macOS user accounts | ACL config, user list | Must maintain access roster |

**FERCoff's role:** Provides the access control mechanism (Tailscale ACLs, SSH keys). Your organization must manage who gets access and why.

---

## CIP-005: Electronic Security Perimeters

Requires defined electronic security perimeters and access points.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: ESP definition | Sandbox (Mini B) is the ESP boundary. Air-gapped, no external routes. | Network diagram, `pf.conf`, `ifconfig` | None -- architecture directly implements this |
| R2: Remote access management | Tailscale with ACLs on gateway. No remote access to sandbox. | Tailscale ACL config, `pf.conf` | Document Tailscale as the remote access solution |
| R3: Vendor remote access | No vendor access to sandbox by design | Firewall rules | Document vendor access policy (should be: none) |

**This is FERCoff's strongest area.** The air-gapped sandbox with pf firewall enforcement is a textbook ESP implementation.

---

## CIP-006: Physical Security

Requires physical security plan for BES Cyber Systems.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Physical security plan | Guidance for locked cabinet, access logging | Deployment docs | You must implement physical controls at your site |
| R2: Visitor control | Not applicable (depends on facility) | N/A | Facility-level control |
| R3: Maintenance and testing | Health check scripts verify system state | `health-check.sh` output logs | Schedule regular physical inspections |

**FERCoff provides:** Guidance on physical placement, tamper-evident seals, locked cabinets. **You provide:** The actual physical security at your site.

---

## CIP-007: System Security Management

Requires security patch management, malware prevention, and security event monitoring.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Ports and services | Minimal services on sandbox. pf blocks all unnecessary ports. | `pf.conf`, `launchctl list` | Document running services inventory |
| R2: Security patch management | Model updates via USB with GPG verification | `model-update.sh` logs | macOS patches need manual USB transfer process |
| R3: Malware prevention | Air-gap prevents network-based malware. No USB autorun. | Air-gap verification logs | Consider XProtect configuration |
| R4: Security event monitoring | Audit logger captures system state every 5 minutes | `audit.log` | Forward alerts to your SOC if applicable |
| R5: System access controls | macOS user accounts, FileVault, Tailscale ACLs | `fdesetup status`, user list | Enforce password policy |

---

## CIP-008: Incident Reporting and Response

Requires incident response plan and reporting procedures.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Incident response plan | Audit export script preserves evidence | `audit-export.sh` output | Must write org-specific incident response plan |
| R2: Incident response testing | Health check scripts serve as regular verification | `health-check.sh` schedule | Must conduct annual tabletop exercises |
| R3: Incident notification | Not applicable (organizational) | N/A | Know your reporting obligations (E-ISAC, CISA) |

---

## CIP-009: Recovery Plans

Requires documented recovery plans for BES Cyber Systems.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Recovery plan | Documented in operations guide. Spare Mini + USB backup. | Recovery procedure docs | Must test recovery annually |
| R2: Recovery plan implementation | Ansible playbooks enable repeatable rebuild | `deploy.yml`, model backups | Must maintain current USB backup |
| R3: Recovery plan testing | Health check verifies system state post-recovery | `health-check.sh` results | Must document test results |

**Recovery target:** Full rebuild from spare Mac Mini + USB backup in under 2 hours.

---

## CIP-010: Configuration Change Management

Requires configuration change management and vulnerability assessments.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Configuration change management | Ansible playbooks are version-controlled in Git | Git history, `deploy.yml` | Enforce change approval process |
| R2: Configuration monitoring | Audit logger tracks system state continuously | `audit.log` entries | Review logs weekly |
| R3: Vulnerability assessments | Model updates via verified USB, no network exposure | Update logs | Conduct periodic review of dependencies |

**FERCoff's approach:** Git-versioned Ansible is the configuration baseline. Any drift from the playbook is detectable and correctable.

---

## CIP-011: Information Protection

Requires identification and protection of BES Cyber System Information.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Information protection | CEII stays on air-gapped sandbox. FileVault encrypts at rest. | `fdesetup status`, network diagram | Must classify your data per CEII rules |
| R2: BES Cyber System Information disposal | Documented data destruction procedure | Disposal records | Must securely wipe before decommission |

**This is FERCoff's core value proposition.** The air-gapped architecture ensures CEII physically cannot leave the sandbox.

---

## CIP-013: Supply Chain Risk Management

Requires supply chain risk management plan.

| Requirement | FERCoff Implementation | Evidence | Gap |
|-------------|----------------------|----------|-----|
| R1: Supply chain risk management plan | Apple hardware (known vendor), open-source software (auditable) | BOM, software inventory | Must document vendor risk assessment |
| R2: Vendor risk assessment | Ollama, Qwen are open-source and auditable | License files, source repos | Conduct your own assessment of model provenance |
| R3: Vendor notification process | N/A for open-source components | N/A | Monitor GitHub security advisories |

**Note:** Using consumer hardware (Mac Mini) and open-source software simplifies supply chain risk compared to enterprise AI infrastructure with proprietary firmware and drivers.

---

## How to Use This Mapping

1. **Review with your compliance team** -- they know your audit culture
2. **Fill in the gaps** -- most gaps are organizational processes, not technical controls
3. **Collect evidence** -- run `audit-export.sh` before any audit
4. **Document decisions** -- if you deviate from this mapping, document why
5. **Update annually** -- NERC CIP standards evolve; revisit this mapping each year
