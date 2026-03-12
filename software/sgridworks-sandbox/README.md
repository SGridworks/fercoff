# sgridworks-sandbox

Thin Python client and gateway server for FERCoff deployments.

## Components

- **`SecureSandbox`** -- async client for submitting queries to the gateway
- **Gateway server** -- FastAPI app that forwards inference to the air-gapped sandbox
- **Audit log** -- SQLite-backed, append-only query audit trail

## Installation

```bash
# Client only
pip install -e .

# With gateway server
pip install -e ".[server]"
```

## Client Usage

```python
import asyncio
from sgridworks import SecureSandbox

async def main():
    sandbox = SecureSandbox.connect("http://mini-a.local:8000")

    # Submit a query
    result = await sandbox.query(
        "Show transformer T-101 temperature anomalies from the last 24 hours",
        model="qwen2.5:3b",
    )
    print(result.content)

    # Check health
    health = await sandbox.health()
    print(f"Sandbox: {health.sandbox}, Models: {health.models}")

    await sandbox.close()

asyncio.run(main())
```

## Gateway Server

```bash
# Set the sandbox Ollama endpoint
export FERCOFF_OLLAMA_URL=http://10.0.5.2:11434

# Start the gateway
uvicorn sgridworks.gateway:app --host 0.0.0.0 --port 8000
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/query` | Submit a query for inference |
| GET | `/api/v1/models` | List available models |
| GET | `/api/v1/health` | Health check |

## Audit Log

Every query is logged to SQLite with timestamp, user, model, and query hash (not the full query). Export for compliance review:

```python
from sgridworks.audit import AuditLog

log = AuditLog("/var/log/fercoff/audit/audit.sqlite")
entries = log.export_json(since="2026-03-01")
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FERCOFF_OLLAMA_URL` | `http://10.0.5.2:11434` | Sandbox Ollama endpoint |
| `FERCOFF_AUDIT_DB` | `/var/log/fercoff/audit/audit.sqlite` | Audit database path |
