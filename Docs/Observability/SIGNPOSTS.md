# Observability — Signposts & Budgets

Use these standardized OSLog categories and signpost names.

## Categories
- `ai` — Coaching pipeline
- `context` — Context assembly and caching
- `streaming` — Chat streaming lifecycle

## Names
- Pipeline: `coach.pipeline`
- Stages: `coach.parse`, `coach.context`, `coach.infer`, `coach.act`
- Streaming: `stream.start`, `stream.first_token`, `stream.delta`, `stream.complete`

## Budgets
- TTFT: < 300ms p50, < 500ms p95
- Context: < 500ms cold, < 10ms warm

Implementation helpers: `AirFit/Core/Observability/Signposts.swift` and `ChatStreamingMetricsAdapter.swift`.

