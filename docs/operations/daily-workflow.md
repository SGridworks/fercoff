# Daily Workflow

## Engineer Workflow

### Connect

```bash
# From your laptop, SSH to the gateway via Tailscale
ssh fercoff-admin@mini-a
```

### Write and Submit Queries

Option 1 -- Direct Ollama (simple):
```bash
curl -X POST http://10.0.5.2:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:3b","messages":[{"role":"user","content":"Your query here"}],"stream":false}'
```

Option 2 -- Gateway API (recommended, with audit logging):
```python
from sgridworks import SecureSandbox

sandbox = SecureSandbox.connect("http://localhost:8000")
result = await sandbox.query("Analyze transformer T-101 load patterns")
```

Option 3 -- Jupyter notebook:
```bash
cd /opt/fercoff/examples
jupyter notebook --ip=0.0.0.0 --port=8888
```

### Review Results

Results from the sandbox contain aggregated, non-sensitive output. For Tier 1 CEII queries, review output before exporting per your data handling procedures.

## Operational Schedule

| Task | Frequency | Who | How |
|------|-----------|-----|-----|
| Health check | Daily | Automated (cron) | `health-check.sh` on both nodes |
| Audit log review | Weekly | Admin | Review `/var/log/fercoff/audit/audit.log` |
| Model updates | Monthly or as needed | Admin | `model-update.sh` via USB |
| Audit export | Monthly | Admin | `audit-export.sh` to USB |
| Backup | Weekly | Admin | Copy configs to USB |
| Physical inspection | Quarterly | Admin | Check cabinet, seals, cables |

## Model Updates

See `software/scripts/model-update.sh` and [model-management.md](model-management.md).

Monthly cadence recommended:
1. Check for new Qwen releases
2. Export from Mini A to USB
3. Verify and load on Mini B
4. Run smoke tests
5. Log the update

## Backup Procedures

### What to Back Up

| Data | From | Method |
|------|------|--------|
| Ansible configs | Mini A | Git push (already version-controlled) |
| pf.conf | Both | Copy to USB |
| Tailscale config | Mini A | Export from admin console |
| Ollama models | Mini B | Export to USB |
| Audit logs | Mini B | `audit-export.sh` to USB |

### What NOT to Back Up to External Media

- CEII data (stays on Mini B)
- Unredacted query logs (may contain CEII context)

## Log Review Checklist

Weekly, review the audit log on Mini B:

- [ ] No unexpected users in query logs
- [ ] No gaps in heartbeat entries (5-minute interval)
- [ ] FileVault status consistently "On"
- [ ] pf status consistently active
- [ ] Ollama status consistently 200
- [ ] No unusual error patterns
