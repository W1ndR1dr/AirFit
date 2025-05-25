**Modular Sub-Document 10: Services Layer - Configurable AI API Client (v1.1 - Revised with Deep Research)**

**Version:** 1.1
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Modular Sub-Document 5: AI Persona Engine & CoachEngine – `AIRequest`, `AIResponseType`, `ChatMessage`, `AIFunctionSchema`, `AIFunctionCall` from `AIComms.swift`.
**Date:** May 24, 2025

**1. Module Overview (Remains the same)**

*   **Purpose:** To implement a configurable `AIAPIService` that can communicate with Google Gemini, OpenAI, Anthropic, and OpenRouter based on user-provided API keys and model selections.
*   **Responsibilities:** Secure API key storage, user selection of provider/model, provider-specific request construction, authentication, sending requests, processing streaming responses (text, function calls) into `AIResponseType`, and error management.
*   **Key Components:** `AIAPIService.swift`, `AIAPIServiceProtocol.swift`, `APIKeyManager.swift`, `UserSettings` (for provider/model selection).

**2. Dependencies (Remains the same)**

**3. Detailed Component Specifications & Agent Tasks (Revised with Deep Research Output)**

---

**Task 10.0: Define AI API Service Protocol & Configuration Model (No significant changes from previous, but re-verify Base URLs)**
    *   **Agent Task 10.0.1 (Review `AIAPIServiceProtocol.swift` and `AIProvider` enum):**
        *   Instruction: "Ensure `AIAPIServiceProtocol.swift` (from previous spec) and the `AIProvider` enum are correctly defined. Verify the `baseURL` for each provider in the `AIProvider` enum matches the research output."
        *   Details:
            *   `AIProvider.baseURL` switch statement should use:
                *   OpenAI: `https://api.openai.com/v1`
                *   Google Gemini: `https://generativelanguage.googleapis.com` (endpoint path is `/v1beta/models/{model}:streamGenerateContent`)
                *   Anthropic: `https://api.anthropic.com/v1`
                *   OpenRouter: `https://openrouter.ai/api/v1`
            *   Update `AppConstants.swift` with these confirmed base URLs.
        *   Acceptance Criteria: Protocol and enum are correct. Base URLs in `AppConstants.swift` are updated and accurate.

---

**Task 10.1: API Key Management (Secure Storage - Emphasize Keychain)**
    *   **Agent Task 10.1.1 (Implement `APIKeyManager.swift` with Keychain):**
        *   Instruction: "Implement `APIKeyManager.swift` in `AirFit/Services/Security/` using **Keychain** for secure API key storage and retrieval."
        *   Details:
            *   Methods: `func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws`, `func getAPIKey(forProvider provider: AIProvider) -> String?`, `func deleteAPIKey(forProvider provider: AIProvider) throws`.
            *   Use `kSecClassGenericPassword`.
            *   `kSecAttrService`: Construct a unique service name, e.g., `"com.example.airfit.apikey.\(provider.rawValue)"`.
            *   `kSecAttrAccount`: Use a consistent account name, e.g., `"userLLMAPIKey"`.
            *   Handle Keychain interaction results (e.g., `errSecSuccess`, `errSecItemNotFound`). Log errors using `AppLogger`.
            *   **No `UserDefaults` fallback should be implemented by the agent for this task.** If the agent struggles with direct Keychain implementation, this task might need to be broken down further or a well-vetted Keychain wrapper library (SPM dependency) could be suggested if you (the Vibe-Coder) approve its use.
        *   Acceptance Criteria: `APIKeyManager.swift` uses Keychain for secure API key operations.

---

**Task 10.2: `AIAPIService` Implementation Core (Revised for Provider Specifics)**
    *   **Agent Task 10.2.1 (Initialize `AIAPIService.swift`):**
        *   Instruction: "Create `AIAPIService.swift` in `AirFit/Services/AI/`, conforming to `AIAPIServiceProtocol`. Initialize properties for current provider configuration and `URLSession`."
        *   Acceptance Criteria: Basic class structure and `configure` method implemented.
    *   **Agent Task 10.2.2 (Request Preparation - Headers & Endpoint Path):**
        *   Instruction: "In `getStreamingResponse(for request: AIRequest)`, after checking configuration, determine the full `URL` and set HTTP method and common/authentication headers based on `currentProvider`."
        *   Details:
            *   HTTP Method: `POST` for all.
            *   Common Headers: `Content-Type: application/json`.
            *   **Authentication Headers (Switch on `currentProvider`):**
                *   `.openAI`: `Authorization: Bearer [currentApiKey]`
                *   `.gemini`: `X-Goog-Api-Key: [currentApiKey]` (Header preferred. Query param `?key=` is an alternative if agent finds header challenging initially, but log this deviation).
                *   `.anthropic`: `x-api-key: [currentApiKey]` AND `anthropic-version: [LATEST_STABLE_VERSION_STRING]` (e.g., "2023-06-01" or newer as per current Anthropic docs – *you, the Vibe-Coder, may need to provide the exact latest version string here or instruct agent to use a placeholder that's clearly marked for update*).
                *   `.openRouter`: `Authorization: Bearer [currentApiKey]`
            *   **Endpoint Path Construction (Switch on `currentProvider`):**
                *   `.openAI`: `baseURL` + `/chat/completions`
                *   `.gemini`: `baseURL` + `/v1beta/models/\(currentModelIdentifier ?? "gemini-1.5-pro-latest"):streamGenerateContent` (Note: `currentModelIdentifier` is part of the path. Query param `alt=sse` should be added to the URL for SSE).
                *   `.anthropic`: `baseURL` + `/messages`
                *   `.openRouter`: `baseURL` + `/chat/completions`
            *   Create `URLRequest` with the constructed URL and set `httpMethod`. Apply headers.
        *   Acceptance Criteria: `URLRequest` correctly formed with provider-specific URL and authentication headers.

---

**Task 10.3: Provider-Specific Request Body Mapping (Crucial Detail from Research)**
    *   **Agent Task 10.3.1 (OpenAI Request Body):**
        *   Instruction: "If `currentProvider` is `.openAI` in `getStreamingResponse`, construct the JSON request body conforming to OpenAI's Chat Completions API."
        *   Details:
            *   `model`: `currentModelIdentifier ?? "gpt-3.5-turbo"` (or another sensible default like "gpt-4-turbo-preview").
            *   `messages`: Map `AIRequest.conversationHistory` and `AIRequest.userMessage` to OpenAI's `messages` array. Prepend a system message: `{"role": "system", "content": AIRequest.systemPrompt}`. Handle `ChatMessage.role` mapping (e.g., internal "tool" role might map to OpenAI "function" or "tool" role depending on their latest spec if distinct).
            *   `stream: true`.
            *   `tools` (if `AIRequest.availableFunctions` is not nil): Map each `AIFunctionSchema` to OpenAI's tool format: `{"type": "function", "function": {"name": ..., "description": ..., "parameters": <JSON_SCHEMA_OBJECT>}}`. The `parameters` field is a JSON Schema object derived from `AIFunctionSchema.parameters`.
            *   `tool_choice`: Set to `"auto"` if tools are provided, or potentially a specific function if `AIRequest` indicates a forced function call (not currently in `AIRequest` spec, assume "auto").
            *   Encode to `Data` and set as `urlRequest.httpBody`.
        *   Acceptance Criteria: OpenAI request body correctly constructed, including system prompt, messages, and tool definitions.
    *   **Agent Task 10.3.2 (Google Gemini Request Body):**
        *   Instruction: "If `currentProvider` is `.gemini`, construct the JSON request body for `streamGenerateContent`."
        *   Details:
            *   `contents`: Map `AIRequest.conversationHistory` and `AIRequest.userMessage` to Gemini's `contents` array. Each item: `{"role": "user" or "model", "parts": [{"text": ...}]}`.
            *   `systemInstruction`: `{"parts": [{"text": AIRequest.systemPrompt}]}`.
            *   `tools` (if `AIRequest.availableFunctions` is not nil): `[{"functionDeclarations": [<mapped_AIFunctionSchema_to_GeminiFunctionDeclaration>]}]`. Gemini's `FunctionDeclaration` has `name`, `description`, `parameters` (JSON Schema).
            *   `generationConfig`: (Optional) Include basic config like `{"temperature": 0.7, "maxOutputTokens": 2048}`.
            *   Ensure the URL has `?alt=sse` appended for Gemini if not already part of the base path logic.
        *   Acceptance Criteria: Gemini request body correctly constructed.
    *   **Agent Task 10.3.3 (Anthropic Claude Request Body):**
        *   Instruction: "If `currentProvider` is `.anthropic`, construct the JSON request body for the `/messages` endpoint."
        *   Details:
            *   `model`: `currentModelIdentifier ?? "claude-3-sonnet-20240229"` (or newer like "claude-3.5-sonnet-latest").
            *   `system`: `AIRequest.systemPrompt`.
            *   `messages`: Map `AIRequest.conversationHistory` and `AIRequest.userMessage` to Anthropic's `messages` array (alternating "user" and "assistant" roles).
            *   `max_tokens_to_sample`: e.g., `2048`.
            *   `stream: true`.
            *   `tools` (if `AIRequest.availableFunctions` is not nil): Map each `AIFunctionSchema` to Anthropic's tool format: `{"name": ..., "description": ..., "input_schema": <JSON_SCHEMA_OBJECT>}`.
        *   Acceptance Criteria: Anthropic request body correctly constructed.
    *   **Agent Task 10.3.4 (OpenRouter Request Body):**
        *   Instruction: "If `currentProvider` is `.openRouter`, construct the JSON request body (similar to OpenAI)."
        *   Details:
            *   `model`: `currentModelIdentifier` (this MUST be prefixed, e.g., "openai/gpt-4-turbo-preview", "anthropic/claude-3.5-sonnet-latest"). The `currentModelIdentifier` stored in `AIAPIService` must already be in this format.
            *   `messages`: Same as OpenAI (system prompt as first message).
            *   `stream: true`.
            *   `tools` (or `functions`): Map `AIRequest.availableFunctions` as per OpenAI's tool format. OpenRouter handles translation.
        *   Acceptance Criteria: OpenRouter request body correctly constructed.

---

**Task 10.4: Streaming Response Handling & Parsing (Crucial Detail from Research)**
    *   **Agent Task 10.4.1 (Initiate Data Task & SSE Parsing - General Setup):**
        *   Instruction: "In `getStreamingResponse`, use `URLSession` with a delegate (`URLSessionDataDelegate`) to handle streaming data for SSE."
        *   Details:
            *   Create a `PassthroughSubject<AIResponseType, Error>` to publish parsed events.
            *   The delegate will need a buffer to accumulate `Data` from `urlSession(_:dataTask:didReceive:)`.
            *   Implement logic to parse this buffer for complete SSE messages (lines starting `event: ` (for Anthropic) and `data: `, separated by `\n\n` or `\r\n\r\n`). Each `data:` line needs to be extracted.
        *   Acceptance Criteria: SSE event framing and data extraction setup.
    *   **Agent Task 10.4.2 (OpenAI & OpenRouter SSE Response Parsing):**
        *   Instruction: "If `currentProvider` is `.openAI` or `.openRouter`, parse the `data:` JSON chunks."
        *   Details:
            *   Each `data:` line (except `data: [DONE]`) contains JSON: `{"id": ..., "object": "chat.completion.chunk", "choices": [{"index": 0, "delta": {...}, "finish_reason": ...}]}`.
            *   If `delta.role` exists: (Usually first chunk, ignore for content).
            *   If `delta.content` (string, not null): Send `.textChunk(delta.content!)`.
            *   If `delta.tool_calls` (array):
                *   Accumulate parts of `tool_calls`. Each element has `index`, `id`, `type: "function"`, `function: {"name": String?, "arguments": String?}`.
                *   `name` usually comes first, then `arguments` stream as a string.
                *   Once a complete tool call (name and full arguments string) is assembled for a given `id` or `index`, parse `arguments` string (it's JSON) into `[String: AnyCodableValue]`.
                *   Send `.functionCall(AIFunctionCall(functionName: name, arguments: parsedArgs))`.
            *   If `finish_reason` is `"stop"` or `"length"`: Send `.streamEnd`.
            *   If `finish_reason` is `"tool_calls"` (OpenAI) or `"function_call"` (older OpenAI): This signals the function call should be processed. Ensure `.streamEnd` is also sent.
            *   If `data: [DONE]` is received: Ensure `.streamEnd` has been sent, then complete the publisher (`.finished`).
        *   Acceptance Criteria: OpenAI/OpenRouter SSE parsing for text and function calls implemented.
    *   **Agent Task 10.4.3 (Google Gemini SSE Response Parsing):**
        *   Instruction: "If `currentProvider` is `.gemini` (and `alt=sse` is used), parse the `data:` JSON chunks."
        *   Details:
            *   Each `data:` line contains JSON: `{"candidates":[{"content":{"parts":[{"text": "..."}] / {"functionCall": ...} }, "finishReason": ...}]}`.
            *   If `candidates.content.parts.text` exists: Send `.textChunk(...)`.
            *   If `candidates.content.parts.functionCall` exists (object with `name`, `args`):
                *   Map `name` to `AIFunctionCall.functionName`.
                *   Map `args` (which is already an object from Gemini) to `AIFunctionCall.arguments` (using `AnyCodableValue` for each arg).
                *   Send `.functionCall(...)`.
            *   If `candidates.finishReason` is `"STOP"`, `"MAX_TOKENS"`, etc.: Send `.streamEnd`.
            *   Gemini does not use `[DONE]`. Stream ends when connection closes after final chunk.
        *   Acceptance Criteria: Gemini SSE parsing implemented.
    *   **Agent Task 10.4.4 (Anthropic Claude SSE Response Parsing):**
        *   Instruction: "If `currentProvider` is `.anthropic`, parse named SSE events (`message_start`, `content_block_delta`, `message_stop`, etc.)."
        *   Details:
            *   Parse `event: <eventName>` and `data: <jsonData>`.
            *   `event: content_block_delta`, `data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"..."}}`: Accumulate `text` and send `.textChunk(...)`.
            *   `event: content_block_delta`, `data: {"type":"content_block_delta", "index":0, "delta":{"type":"tool_use", "name":"...", "input":{...}}}` (or `input_json_delta` for partial JSON):
                *   Accumulate `input` parts if they stream.
                *   Once complete `tool_use` block is received, map `name` and `input` (args) to `AIFunctionCall`.
                *   Send `.functionCall(...)`.
            *   `event: message_delta`, `data: {"delta": {"stop_reason": "end_turn" / "tool_use" / "max_tokens"}}`: Signals why stream is ending. Send `.streamEnd`.
            *   `event: message_stop`: Final event. Ensure `.streamEnd` sent, complete publisher.
            *   `event: error`, `data: {"type": "error", "error": {...}}`: Send `.streamError(...)` via publisher.
        *   Acceptance Criteria: Anthropic named SSE parsing implemented.
    *   **Agent Task 10.4.5 (Error Handling and Stream Completion - Unified):**
        *   Instruction: "Implement unified error handling in `urlSession(_:task:didCompleteWithError:)` and end-of-stream detection for all providers."
        *   Details:
            *   If `didCompleteWithError` provides an error, send `.streamError(error)` and complete publisher.
            *   If task completes successfully without an error, and the provider-specific parsing logic hasn't already sent `.streamEnd` and completed the publisher (e.g., for Gemini which doesn't have `[DONE]`), do so here.
            *   Handle HTTP error status codes (4xx, 5xx) received in `urlSession(_:dataTask:didReceive response:completionHandler:)`. If error status, attempt to parse error JSON from body (as per research) and send `.streamError(CustomError(message: parsedMessage))`, then cancel task and complete publisher.
        *   Acceptance Criteria: Robust error handling and stream termination logic.

---

**Task 10.5: Final Review & Commit (Remains similar, focusing on the multi-provider aspect)**
    *   **Agent Task 10.5.1 (Comprehensive Review):**
        *   Instruction: "Review `AIAPIService.swift`, `APIKeyManager.swift`, and supporting structures for correct API request formatting, response parsing for ALL FOUR providers, streaming logic, error handling, and secure key management."
        *   Acceptance Criteria: The service can, based on implemented logic and the deep research, communicate correctly with all supported providers.
    *   **Agent Task 10.5.2 (Test with Mock `CoachEngine` & Provider Switching):**
        *   Instruction: "Expand test harness or unit tests. For each provider: configure `AIAPIService` with mock API key/model, send a mock `AIRequest` (one with text focus, one with function focus). Verify that the (mocked) `URLRequest` construction is correct and that the (mocked) response parsing logic for *that specific provider* is invoked."
        *   Details: This doesn't hit live APIs yet, but tests the internal switching logic and provider-specific mappers/parsers.
        *   Acceptance Criteria: Internal logic for each provider path within `AIAPIService` can be unit-tested.
    *   **Agent Task 10.5.3 (Commit):**
        *   Instruction: "Stage and commit all new and modified files for this module."
        *   Details: Commit message: "Feat: Implement multi-provider AIAPIService with detailed request/response handling".
        *   Acceptance Criteria: All changes committed. Project builds.

**Task 10.6: Add Unit Tests**
    *   **Agent Task 10.6.1 (AIAPIService Unit Tests):**
        *   Instruction: "Create `AIAPIServiceTests.swift` in `AirFitTests/` covering provider switching and request building."
        *   Details: Use protocol-based mocks and follow `TESTING_GUIDELINES.md`.
        *   Acceptance Criteria: Tests compile and pass.

**4. Acceptance Criteria for Module Completion**

*   `AIAPIService` securely manages API keys and constructs provider-specific requests.
*   Streaming responses are parsed correctly for all providers.
*   Unit tests for `AIAPIService` pass.

---

This revised Module 10 is much more specific thanks to the deep research. The Code Generation Agent will have a clearer path, but the complexity of handling four different API structures (even with OpenRouter's standardization efforts) remains high. The SSE parsing and function call translations will be the trickiest parts. Good luck to your AI agent!
