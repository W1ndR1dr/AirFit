# API Features Implementation Guide

## Overview
This guide details the unique features and capabilities of each AI provider (OpenAI, Anthropic, Google Gemini) and how to implement them in AirFit.

## Function Calling Implementation

### OpenAI (Fully Supported)
OpenAI's function calling is mature and well-documented:

```swift
// Request format
{
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "log_nutrition",
        "description": "Log nutrition data for a food item",
        "parameters": {
          "type": "object",
          "properties": {
            "food_name": {"type": "string"},
            "calories": {"type": "number"},
            "protein": {"type": "number"}
          },
          "required": ["food_name", "calories"]
        }
      }
    }
  ],
  "tool_choice": "auto"
}
```

### Anthropic (Beta Support)
As of late 2024, Anthropic supports function calling in beta:

```swift
// Update AnthropicProvider capabilities
let capabilities = LLMCapabilities(
    maxContextTokens: 200_000,
    supportsJSON: true,
    supportsStreaming: true,
    supportsSystemPrompt: true,
    supportsFunctionCalling: true,  // Now supported
    supportsVision: true
)

// Request format
{
  "tools": [
    {
      "name": "log_nutrition",
      "description": "Log nutrition data",
      "input_schema": {
        "type": "object",
        "properties": {
          "food_name": {"type": "string"},
          "calories": {"type": "number"}
        },
        "required": ["food_name", "calories"]
      }
    }
  ],
  "tool_choice": {"type": "auto"}
}
```

### Google Gemini (Function Declarations)
Gemini uses a different format for function calling:

```swift
// Request format
{
  "tools": [{
    "functionDeclarations": [{
      "name": "log_nutrition",
      "description": "Log nutrition data",
      "parameters": {
        "type": "object",
        "properties": {
          "food_name": {"type": "string"},
          "calories": {"type": "number"}
        },
        "required": ["food_name", "calories"]
      }
    }]
  }]
}
```

## Unique Provider Features

### Google Gemini - Grounding with Google Search

Grounding allows Gemini to search Google for real-time information:

```swift
// Enable grounding in request
private func buildGeminiRequestBody(
    request: AIRequest,
    model: String,
    enableGrounding: Bool = false
) -> [String: Any] {
    var body: [String: Any] = [
        "contents": contents,
        "generationConfig": generationConfig
    ]
    
    if enableGrounding {
        body["tools"] = [[
            "googleSearchRetrieval": [
                "dynamicRetrievalConfig": [
                    "mode": "MODE_DYNAMIC",
                    "dynamicThreshold": 0.3
                ]
            ]
        ]]
    }
    
    return body
}
```

### Anthropic - Context Caching

Anthropic's context caching allows reusing conversation context across requests:

```swift
// Implementation for context caching
extension AnthropicProvider {
    func completeWithCache(_ request: LLMRequest, cacheKey: String?) async throws -> LLMResponse {
        var anthropicRequest = try buildAnthropicRequest(from: request)
        
        if let cacheKey = cacheKey {
            // Add cache control headers
            anthropicRequest["cache_control"] = [
                "type": "ephemeral",
                "cache_key": cacheKey
            ]
        }
        
        // Continue with normal request...
    }
}
```

### OpenAI - Real-time API & Audio

OpenAI's latest models support audio input/output:

```swift
// Audio support in request
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "text", "text": "What's in this recording?"},
        {"type": "audio", "audio": {"data": base64AudioData}}
      ]
    }
  ]
}
```

## Implementation Recommendations

### 1. Update LLMProvider Protocol
```swift
protocol LLMProvider {
    // Existing methods...
    
    // Add support for provider-specific features
    func supportsGrounding() -> Bool
    func supportsContextCaching() -> Bool
    func supportsAudioIO() -> Bool
    
    // Optional implementations
    func completeWithGrounding(_ request: LLMRequest) async throws -> LLMResponse
    func completeWithCache(_ request: LLMRequest, cacheKey: String?) async throws -> LLMResponse
}
```

### 2. Enhanced Request Builder
```swift
// Add provider-specific options
struct LLMRequest {
    // Existing properties...
    
    // Provider-specific features
    var enableGrounding: Bool = false
    var cacheKey: String? = nil
    var audioData: Data? = nil
}
```

### 3. Update UI to Show Features
```swift
// In ModelDetailsCard
if provider == .googleGemini && modelEnum.specialFeatures.contains("Grounding (Google Search)") {
    Toggle("Enable Google Search", isOn: $enableGrounding)
        .font(.caption)
}
```

## Cost Implications

### Function Calling
- **OpenAI**: No additional cost for function definitions
- **Anthropic**: Included in standard pricing
- **Gemini**: Free with standard usage

### Special Features
- **Grounding (Gemini)**: May incur additional API costs
- **Context Caching (Anthropic)**: Reduces token usage by 90% for cached content
- **Audio (OpenAI)**: Separate pricing tier for audio tokens

## Testing Recommendations

1. **Function Calling**: Test with nutrition logging and workout planning functions
2. **Grounding**: Test with current events queries (weather, news)
3. **Context Caching**: Test with long conversation sessions
4. **Audio**: Test with voice input for food logging

## Security Considerations

1. **API Keys**: Continue using Keychain storage
2. **Function Results**: Validate all function call results before execution
3. **Grounding Results**: Filter potentially sensitive search results
4. **Audio Data**: Ensure proper permissions and privacy handling

## Migration Path

1. Update provider capabilities in respective files
2. Enhance AIRequestBuilder to handle new formats
3. Update UI to expose new features
4. Add feature flags for gradual rollout
5. Monitor usage and costs for new features