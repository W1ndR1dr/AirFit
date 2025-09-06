# AI Provider Behavior Audit

Providers:
- OpenAI: `Services/AI/LLMProviders/OpenAIProvider.swift:1`
- Gemini: `Services/AI/LLMProviders/GeminiProvider.swift:1`
- Anthropic: likely similar pattern (not sampled in full here)

Common contract: `Core/Protocols/LLMProvider.swift:1` defines `LLMRequest/Response`, streaming chunk, and `StructuredOutputSchema`.

OpenAI highlights:
- Uses `/v1/chat/completions`; sets bearer per request.
- Streaming reads bytes and emits chunks on `data:` lines, computes basic usage by estimating prompt tokens from request and completion tokens by content length — approximate.
- Structured JSON: supports OpenAI’s `response_format: json_schema` when `LLMRequest.responseFormat = .structuredJson(schema)`. Schema mapping converts pre-encoded JSON to OpenAI schema type.
- Tool calls: parsed but not executed; TODO notes left where `LLMResponse` lacks tool call support.
- Error mapping: 401 -> invalidAPIKey; 429 -> rateLimitExceeded; >=400 -> serverError with parsed message; others -> networkError.

Gemini highlights:
- Supports response schema when provided; maps Gemini-specific finish reasons and usage (TODO for cache metrics extraction).
- Similar streaming; maps chunks to `LLMStreamChunk`.

AIService interplay:
- Actor `AIService` builds `LLMRequest` from `AIRequest`, selects effective provider/model based on active provider and per-request model override.
- Streaming path yields `.textDelta`, `.structuredData`, `.done` events; tracks cost by known model cost table.
- Timeout: uses `withThrowingTaskGroup` to race operation with sleep; truncated snippet suggests error mapping on timeout to `AppError.s…` (verify implementation end-to-end).

Risks/Recommendations:
- Usage accounting is approximate on OpenAI streaming; consider server-provided `prompt_tokens_details` when available (TODO in code) and carry through to `LLMResponse`.
- Tool calls are appended as text markers; add structured field in `LLMResponse` and handler in Chat pipeline to actually execute tools or ignore deterministically.
- Provider shared code: factor shared JSON schema conversion, error mapping, and streaming parsing to reduce drift.
- Timeouts: ensure cancellation propagates to underlying URLSession tasks; confirm that the timeout task cancels the in-flight provider task to avoid work leaks.

