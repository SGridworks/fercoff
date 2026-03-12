"""SecureSandbox client -- thin wrapper for submitting queries to the FERCoff gateway."""

from __future__ import annotations

import hashlib
from typing import Any

import httpx

from sgridworks.models import HealthStatus, ModelInfo, QueryRequest, QueryResponse


class SecureSandbox:
    """Client for the FERCoff gateway API."""

    def __init__(self, gateway_url: str, api_key: str | None = None) -> None:
        self._base_url = gateway_url.rstrip("/")
        headers = {}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        self._client = httpx.AsyncClient(
            base_url=self._base_url,
            headers=headers,
            timeout=120.0,
        )

    @classmethod
    def connect(cls, gateway_url: str = "http://localhost:8000", api_key: str | None = None) -> SecureSandbox:
        """Create a new sandbox connection."""
        return cls(gateway_url=gateway_url, api_key=api_key)

    async def query(
        self,
        prompt: str,
        model: str = "qwen2.5:3b",
        context: str | None = None,
        user: str = "anonymous",
    ) -> QueryResponse:
        """Submit a natural language query to the sandbox."""
        req = QueryRequest(prompt=prompt, model=model, context=context, user=user)
        resp = await self._client.post("/api/v1/query", json=req.model_dump())
        resp.raise_for_status()
        return QueryResponse.model_validate(resp.json())

    async def explain(self, data: dict[str, Any] | str, context: str | None = None) -> str:
        """Send data to the LLM for explanation."""
        if isinstance(data, dict):
            import json
            data_str = json.dumps(data, indent=2, default=str)
        else:
            data_str = str(data)

        prompt = f"Analyze and explain the following data:\n\n{data_str}"
        if context:
            prompt += f"\n\nContext: {context}"

        result = await self.query(prompt)
        return result.content or ""

    async def list_models(self) -> list[ModelInfo]:
        """List available models on the sandbox."""
        resp = await self._client.get("/api/v1/models")
        resp.raise_for_status()
        return [ModelInfo.model_validate(m) for m in resp.json()]

    async def health(self) -> HealthStatus:
        """Check gateway and sandbox health."""
        resp = await self._client.get("/api/v1/health")
        resp.raise_for_status()
        return HealthStatus.model_validate(resp.json())

    async def close(self) -> None:
        await self._client.aclose()

    async def __aenter__(self) -> SecureSandbox:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()
