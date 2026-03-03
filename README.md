# FERCoff

## Secure AI Sandbox for Grid Engineers

**Because your data deserves better than "compliance by PowerPoint"**

---

## What Is FERCoff?

FERCoff is a $1,200 hardware setup that lets power engineers run AI analytics on live CEII-protected grid data without ending up on the wrong side of a FERC investigation.

Built by [SGRIDWORKS](https://sgridworks.ai) and open-sourced for the grid engineering community.

---

## The Problem

You have synthetic data. You've trained models. You know AI can help with:
- Anomaly detection on transformer loads
- Predictive maintenance scheduling
- Root cause analysis of grid events
- Natural language queries over SCADA data

**But you can't run any of it on real data** because:
- Your SCADA feeds are CEII-protected
- Cloud LLM APIs are a reportable violation
- Traditional air-gapped AI infrastructure costs $2M+
- Nobody wants to be the test case for NERC CIP compliance

---

## The Solution

Two Mac Minis. One air-gapped sandbox. Zero compliance headaches.

```
┌─────────────────┐     ┌─────────────────┐
│   Mac Mini A    │◄───►│   Mac Mini B    │
│   (Gateway)     │     │  (CEII Sandbox) │
│  $599           │     │  $599           │
│                 │     │                 │
│  • Engineers    │     │  • Air-gapped   │
│    connect here │     │  • Live SCADA   │
│  • Job queue    │     │  • Inference    │
│  • Non-CEII     │     │  • Audit logs   │
└─────────────────┘     └─────────────────┘
       │                       │
       │ Tailscale             │ No external
       │ (encrypted)           │ network
       ▼                       ▼
  Engineers               Your actual
  anywhere                grid data
```

**Total cost: $1,198**  
**Deployment time: 1-2 days**  
**Compliance: CEII-ready out of the box**

---

## Quick Start

### 1. Buy the Hardware

See [`hardware/bom-pilot.md`](hardware/bom-pilot.md) for the complete shopping list (~$1,578 with accessories).

### 2. Deploy the Sandbox

```bash
# Clone this repo
git clone https://github.com/sgridworks/fercoff.git
cd fercoff

# Run the Ansible playbook
ansible-playbook -i inventory/pilot.yml software/ansible/deploy.yml

# Your engineers are ready to go
```

### 3. Connect Your Data

See [`docs/installation/data-ingestion.md`](docs/installation/data-ingestion.md) for USB, Ethernet, and staging server options.

---

## What's in This Repo

| Directory | Contents |
|-----------|----------|
| [`whitepaper/`](whitepaper/) | Complete technical documentation (v3.1) |
| [`hardware/`](hardware/) | BOMs, thermal analysis, rack diagrams |
| [`software/`](software/) | Ansible playbooks, configs, scripts |
| [`compliance/`](compliance/) | NERC CIP mapping, audit templates |
| [`examples/`](examples/) | Sample notebooks for common tasks |
| [`docs/`](docs/) | Installation, operations, troubleshooting |

---

## Documentation

- **[White Paper v3.1](whitepaper/v3.1.md)** — Complete technical specification
- **[Installation Guide](docs/installation/)** — Step-by-step deployment
- **[Operations Manual](docs/operations/)** — Daily workflows, model updates, backups
- **[Troubleshooting](docs/troubleshooting/)** — Common problems and solutions

---

## Compliance

FERCoff is designed for CEII compliance from day one:

- ✅ Air-gapped inference (no cloud APIs)
- ✅ FileVault encryption (XTS-AES-128)
- ✅ Immutable audit logging
- ✅ NERC CIP mapping templates
- ✅ Audit response documentation

See [`compliance/`](compliance/) for complete compliance resources.

---

## Performance

| Model | Speed | Use Case |
|-------|-------|----------|
| Qwen 2.5-3B (Q4) | ~45-50 tok/s | Natural language queries, fast responses |
| Qwen 2.5-7B (Q4) | ~32-35 tok/s | Complex reasoning, root cause analysis |

On Mac Mini M4 (16GB). MLX backend recommended for 1.3-1.5x speedup.

---

## Community

- **Discussions:** [GitHub Discussions](https://github.com/sgridworks/fercoff/discussions)
- **Issues:** [GitHub Issues](https://github.com/sgridworks/fercoff/issues)
- **Security:** [Security Advisories](https://github.com/sgridworks/fercoff/security/advisories)

---

## License

- **Documentation** (whitepaper, docs): [CC-BY-SA 4.0](LICENSE-docs)
- **Code** (scripts, playbooks): [MIT](LICENSE-code)

Commercial use encouraged. Attribution appreciated.

---

## ⚠️ Important Disclaimers

**Not Legal Advice:** FERCoff is a technical reference architecture, not legal advice. We are engineers, not lawyers. Consult your general counsel and compliance team before deploying any system that handles CEII or CIP-protected data.

**Not a Certified Solution:** FERCoff is not NERC-certified, FERC-approved, or officially sanctioned by any regulatory body. It is a well-documented DIY implementation using consumer hardware and open-source software. Your mileage may vary.

**Audit at Your Own Risk:** What works for one utility's audit culture may not work for another. Know your auditors. Document your decisions. Get sign-off from your CISO before going to production.

**No Warranty:** This software and documentation are provided "as is" without warranty of any kind. See [LICENSE-code](LICENSE-code) and [LICENSE-docs](LICENSE-docs) for full terms.

**Security is Your Responsibility:** We disclose known vulnerabilities (like ClawJacked) and mitigation steps, but you are responsible for keeping your deployment patched, monitored, and secure.

---

## About SGRIDWORKS

FERCoff was developed by [SGRIDWORKS](https://sgridworks.ai), the open-source ML/AI playground for power systems engineers.

We built this because we were tired of watching capable engineers stuck with synthetic data while operational insights stayed locked away.

---

**Ready to tell your auditor to FERCoff?**

[Get Started →](docs/installation/quickstart.md)

---

*Remember: Compliance is not a product feature. It's an architecture decision documented well enough to survive audit.*
