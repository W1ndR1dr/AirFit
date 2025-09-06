# AI Subsystem Deep-Dive

Components:
- `Services/AI/AIService.swift` (actor): Provider management, streaming, cost accounting, mode switching (production/demo/test/offline).
- Providers: `Services/AI/LLMProviders/{OpenAIProvider,GeminiProvider,AnthropicProvider}.swift` conforming to `Core/Protocols/LLMProvider`.
- Contracts: `Core/Protocols/{AIServiceProtocol, LLMProvider}.swift` (messages, structured JSON output via schema).
- Orchestration: `Modules/AI/CoachEngine.swift`, `CoachEngine+Functions.swift`, `ContextAnalyzer.swift`, `ConversationManager.swift`.
- UI/Streaming: `Modules/AI/Components/StreamingResponseHandler.swift`; Chat updates via `Notification.Name.chatStream*`.
- Persona: `Modules/AI/PersonaSynthesis/*.swift` + `Services/Persona/PersonaService.swift`.

What’s solid:
- `AIService` isolates provider logic; supports streaming and structured JSON with schemas.
- Signposted timing around requests, budgeted timeouts, token-based cost tracking.
- Persona pipeline uses staged prompts with structured responses and progress reporting; falls back to text decode.
- Mode fallback: demo/test offers graceful UX without keys; production tries configured providers by available keys.

Pain points:
- CoachEngine is a monolith (routing, orchestration, formatting, recovery) with high cognitive load and cross-cutting responsibilities.
- Streaming via notifications couples lower-level engine to UI updates; fragile over time and difficult to unit test.
- Provider duplication: request construction/response mapping logic repeats across providers, with TODOs left for tool call handling and cache metrics.
- `AIService` exposes `nonisolated(unsafe)` snapshots (config, activeProvider) to serve UI reads—must ensure writes update snapshots atomically.

Suggested target design:
- Extract a thin `AIChatPipeline` that:
  - Accepts `AIRequest` + `ConversationContext` and returns `AsyncThrowingStream<AIResponse>`.
  - Isolates streaming framing (delta aggregation, done events) and transforms to domain events (assistant message, structured payloads) without using `NotificationCenter`.
- Break `CoachEngine` into:
  - `CoachRouter` (intent classification + route), `WorkoutPlanner` / `NutritionAdvisor` / `RecoveryAdvisor` strategies.
  - `AIFormatter` (system prompts/templates), `AIParsers` (JSON decode/validation), `AIMetrics` (token/cost reporting).
- Providers: factor common encode/decode helpers and error mapping; add uniform tool call support when upstream supports.
- Testing: add provider fakes and golden JSON fixtures for parsers; snapshot structured schema prompts.

Quick wins:
- Introduce a `ChatStreamingStore` protocol with methods: `start(conversationId:)`, `appendDelta(_:)`, `finish(usage:)`; inject into ChatViewModel to remove notification reliance.
- Cap per-file length in lint for `Modules/AI/*` (soft fail initially) to gate further growth.

