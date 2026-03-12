from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class JobState(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class QueryRequest(BaseModel):
    prompt: str
    model: str = "qwen2.5:3b"
    context: str | None = None
    user: str = "anonymous"


class QueryResponse(BaseModel):
    job_id: str
    state: JobState
    content: str | None = None
    model: str | None = None
    duration_ms: int | None = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ModelInfo(BaseModel):
    name: str
    size_bytes: int | None = None
    modified_at: str | None = None


class HealthStatus(BaseModel):
    gateway: bool
    sandbox: bool
    ollama: bool
    models: list[str] = []
    timestamp: datetime = Field(default_factory=datetime.utcnow)
