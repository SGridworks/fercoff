"""FERCoff Gateway API server -- runs on Mini A, forwards inference to Mini B."""

from __future__ import annotations

import hashlib
import os
import time
import uuid
from datetime import datetime, timezone

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from sgridworks.audit import AuditLog
from sgridworks.models import HealthStatus, JobState, ModelInfo, QueryRequest, QueryResponse

OLLAMA_URL = os.environ.get("FERCOFF_OLLAMA_URL", "http://10.0.5.2:11434")
AUDIT_DB = os.environ.get("FERCOFF_AUDIT_DB", "/var/log/fercoff/audit/audit.sqlite")

app = FastAPI(title="FERCoff Gateway", version="0.1.0")
audit = AuditLog(AUDIT_DB)


@app.post("/api/v1/query")
async def submit_query(req: QueryRequest) -> QueryResponse:
    """Submit a query to the air-gapped sandbox for inference."""
    job_id = uuid.uuid4().hex[:12]
    start = time.monotonic()

    messages = []
    if req.context:
        messages.append({"role": "system", "content": req.context})
    messages.append({"role": "user", "content": req.prompt})

    async with httpx.AsyncClient(timeout=120.0) as client:
        try:
            resp = await client.post(
                f"{OLLAMA_URL}/api/chat",
                json={"model": req.model, "messages": messages, "stream": False},
            )
            resp.raise_for_status()
        except httpx.HTTPError as e:
            audit.record(
                user=req.user, model=req.model, prompt=req.prompt,
                response_length=0, duration_ms=int((time.monotonic() - start) * 1000),
                metadata={"error": str(e), "job_id": job_id},
            )
            raise HTTPException(status_code=502, detail=f"Sandbox unavailable: {e}")

    duration_ms = int((time.monotonic() - start) * 1000)
    result = resp.json()
    content = result.get("message", {}).get("content", "")

    audit.record(
        user=req.user, model=req.model, prompt=req.prompt,
        response_length=len(content), duration_ms=duration_ms,
        metadata={"job_id": job_id},
    )

    return QueryResponse(
        job_id=job_id,
        state=JobState.COMPLETED,
        content=content,
        model=req.model,
        duration_ms=duration_ms,
    )


@app.get("/api/v1/models")
async def list_models() -> list[ModelInfo]:
    """List models available on the sandbox."""
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            resp = await client.get(f"{OLLAMA_URL}/api/tags")
            resp.raise_for_status()
        except httpx.HTTPError:
            raise HTTPException(status_code=502, detail="Cannot reach sandbox Ollama")

    models = resp.json().get("models", [])
    return [
        ModelInfo(
            name=m["name"],
            size_bytes=m.get("size"),
            modified_at=m.get("modified_at"),
        )
        for m in models
    ]


@app.get("/api/v1/health")
async def health_check() -> HealthStatus:
    """Check gateway and sandbox health."""
    sandbox_ok = False
    ollama_ok = False
    models: list[str] = []

    async with httpx.AsyncClient(timeout=5.0) as client:
        try:
            resp = await client.get(f"{OLLAMA_URL}/api/tags")
            if resp.status_code == 200:
                sandbox_ok = True
                ollama_ok = True
                models = [m["name"] for m in resp.json().get("models", [])]
        except httpx.HTTPError:
            pass

    return HealthStatus(
        gateway=True,
        sandbox=sandbox_ok,
        ollama=ollama_ok,
        models=models,
    )
