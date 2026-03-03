# Hardware Bill of Materials — FERCoff Pilot Deployment

## ⚠️ Disclaimer

**This is a shopping list, not a guarantee.** Buying these components does not make you compliant. Proper deployment, configuration, documentation, and audit preparation are your responsibility. See [DISCLAIMER.md](../DISCLAIMER.md) for complete terms.

---

## Core Components (Required)

| Item | Qty | Unit Cost | Total | SKU / Link | Notes |
|------|-----|-----------|-------|------------|-------|
| **Mac Mini M4 (16GB / 256GB)** | 2 | $599 | $1,198 | [Apple](https://www.apple.com/mac-mini/) | Base config sufficient for pilot |
| **Thunderbolt 4 cable (0.8m)** | 1 | $30 | $30 | Apple MMNG3AM/A | Inter-node link |
| **Cat 6A Ethernet (3ft, 5-pack)** | 1 | $15 | $15 | Amazon Basics | Network connectivity |
| **USB-C hub (Anker 341, 5-in-1)** | 2 | $25 | $50 | Anker A8365 | Peripheral expansion |
| **External SSD (1TB, Samsung T7 Shield)** | 1 | $100 | $100 | Samsung MU-PE1T0S/AM | Backup, model storage |
| **APC Back-UPS 600VA** | 2 | $80 | $160 | APC BE600M1 | Power protection |
| **Subtotal (Core)** | | | **$1,553** | | |

## Optional but Recommended

| Item | Qty | Unit Cost | Total | When You Need It |
|------|-----|-----------|-------|------------------|
| **Spare Mac Mini M4** | 1 | $599 | $599 | Immediately (disaster recovery) |
| **Rackmount shelf (Mac Mini)** | 2 | $75 | $150 | Rack installation |
| **NEMA 4X enclosure w/ cooling** | 1 | $1,500 | $1,500 | Substation deployment (unconditioned) |
| **Owl Cyber Defense data diode** | 1 | $15,000 | $15,000 | Production (replaces Tailscale) |
| **Mac Mini M4 Pro (32GB)** | 1 | $1,399 | $1,399 | When 7B context insufficient |

## Cost Scenarios

| Deployment | Hardware Cost | Notes |
|------------|---------------|-------|
| **Minimal Pilot** | $1,553 | Two Minis, basic accessories |
| **Pilot with Spare** | $2,152 | + hot spare for RTO |
| **Substation-Ready** | $3,652 | + NEMA enclosure, spare |
| **Production-Hardened** | $18,652 | + data diode, 32GB upgrade |

## Where to Buy

- **Apple Business:** Volume pricing, next-day replacement (AppleCare+)
- **Amazon Business:** Fast shipping, easy returns
- **B&H Photo:** No sales tax (NY/NJ除外), good for large orders
- **CDW/SHI:** Enterprise procurement, PO-friendly

## What You Already Have

Assumed available (not in BOM):
- Ethernet switch ports
- Monitor/keyboard for initial setup
- USB drives for offline installs
- Physical security (locked cabinet, access control)

## Upgrade Path

| Limitation | Upgrade | Cost |
|------------|---------|------|
| 7B model runs out of context | Mac Mini M4 Pro 32GB | +$800 |
| Need 14B+ parameter models | Mac Studio M2 Ultra 192GB | +$3,000 |
| Substation too hot/cold | NEMA enclosure HVAC | +$1,500 |
| Audit requires hardware diode | Owl Cyber Defense | +$15,000 |
| 50+ engineers concurrent | Multiple Mini B nodes | +$599-1,399 each |

---

*Last updated: March 2026*  
*See also: [`bom-enterprise.md`](bom-enterprise.md) for production deployments*
