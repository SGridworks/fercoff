# FERCoff Examples

Jupyter notebooks demonstrating common AI analytics workflows on grid data. These examples use **synthetic data** to show the workflow -- in production, the same code runs on your real CEII-protected data inside the air-gapped sandbox.

## Prerequisites

- Python 3.10+
- Ollama running locally with `qwen2.5:3b` pulled
- Python packages: `requests`, `pandas`, `matplotlib`

```bash
pip install requests pandas matplotlib
curl http://localhost:11434/api/tags
```

## Notebooks

| Notebook | Description |
|----------|-------------|
| [01-transformer-anomaly-detection](01-transformer-anomaly-detection.ipynb) | Detect and explain anomalies in transformer load data using synthetic SCADA readings |
| [02-maintenance-log-query](02-maintenance-log-query.ipynb) | Natural language queries over maintenance records |
| [03-grid-event-summary](03-grid-event-summary.ipynb) | Automated daily operations briefing from grid event logs |

## How It Works

Each notebook follows the same pattern:

1. **Generate synthetic data** -- realistic SCADA/maintenance/event data created inline
2. **Analyze with pandas** -- filtering, aggregation, statistical detection
3. **Query Ollama** -- send context + question to the local LLM for natural language explanation
4. **Present results** -- structured output suitable for engineering decisions

## Running in the Sandbox

In production on Mini B, the only difference is the data source:

```python
# Instead of synthetic data, use your actual historian connection
# df = pd.read_sql("SELECT * FROM scada_readings WHERE ...", historian_conn)
```

## Notes

- These notebooks call Ollama at `http://localhost:11434`. On Mini B, Ollama binds to `10.0.5.2:11434`.
- Response quality depends on the model. Use `qwen2.5:3b` for speed, `qwen2.5:7b` for complex reasoning.
- All synthetic data is intentionally realistic but contains no actual grid information.
