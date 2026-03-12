"""Append-only audit log backed by SQLite."""

from __future__ import annotations

import hashlib
import json
import sqlite3
import time
from datetime import datetime, timezone
from pathlib import Path


class AuditLog:
    """Append-only audit trail for sandbox queries."""

    def __init__(self, db_path: Path | str = "/var/log/fercoff/audit/audit.sqlite") -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn = sqlite3.connect(str(self._db_path))
        self._init_schema()

    def _init_schema(self) -> None:
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS audit_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                user TEXT NOT NULL,
                model TEXT NOT NULL,
                query_hash TEXT NOT NULL,
                response_length INTEGER,
                duration_ms INTEGER,
                metadata TEXT
            )
        """)
        self._conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_entries(timestamp)
        """)
        self._conn.commit()

    def record(
        self,
        user: str,
        model: str,
        prompt: str,
        response_length: int,
        duration_ms: int,
        metadata: dict | None = None,
    ) -> int:
        """Record a query in the audit log. Returns the entry ID."""
        query_hash = hashlib.sha256(prompt.encode()).hexdigest()[:16]
        ts = datetime.now(timezone.utc).isoformat()

        cursor = self._conn.execute(
            """INSERT INTO audit_entries
               (timestamp, user, model, query_hash, response_length, duration_ms, metadata)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (ts, user, model, query_hash, response_length, duration_ms,
             json.dumps(metadata) if metadata else None),
        )
        self._conn.commit()
        return cursor.lastrowid  # type: ignore[return-value]

    def export_json(self, since: str | None = None) -> list[dict]:
        """Export audit entries as JSON-serializable dicts."""
        if since:
            rows = self._conn.execute(
                "SELECT * FROM audit_entries WHERE timestamp >= ? ORDER BY timestamp",
                (since,),
            ).fetchall()
        else:
            rows = self._conn.execute(
                "SELECT * FROM audit_entries ORDER BY timestamp"
            ).fetchall()

        columns = ["id", "timestamp", "user", "model", "query_hash",
                    "response_length", "duration_ms", "metadata"]
        return [dict(zip(columns, row)) for row in rows]

    def count(self) -> int:
        row = self._conn.execute("SELECT COUNT(*) FROM audit_entries").fetchone()
        return row[0] if row else 0

    def close(self) -> None:
        self._conn.close()
