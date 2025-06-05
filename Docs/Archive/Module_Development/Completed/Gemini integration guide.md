Below is a practical, end-to-end integration playbook I’d hand to one of my own iOS engineers.  It assumes you want Gemini Flash 2.5 in production-level code, not a weekend toy project.

⸻

1.  Pick the right access path first (30 sec decision)

Path	When to use	Auth style	Quotas & cost notes
Gemini Developer API	Personal or single-tenant apps; quickest to prototype	One client-side API key	60 req/min, 2 M input + 250 k output tokens/day free tier; paid overage billed to Google account  ￼ ￼
Vertex AI Gemini API	Multi-tenant or enterprise scale, need VPC-SC, regional routing, custom KMS	OAuth 2 service-account token exchanged server-side	Higher burst, enterprise SLAs, regional endpoints (us-central1, europe-west4, asia-southeast1)  ￼
Firebase AI Logic SDK	You already ship Firebase and want App Check + analytics for free	Console-provisioned key stored server-side; App Check on device	Same quotas as Developer API; transparent later migration to Vertex  ￼

Everything else in this guide is identical once you have a bearer token.

⸻

2.  Add the Swift SDK (5 min)
	1.	Xcode 16.2+ ➜ File ▸ Add Package Dependencies
Package URL → https://github.com/google/generative-ai-swift
Select the GoogleGenerativeAI product.  ￼ ￼
	2.	Hide the key.
	•	For a quick prototype, store it in a plist excluded from source control.
	•	Production: fetch from your backend once, cache in Keychain, and rotate.  Never hard-code.

⸻

3.  Minimal working code (Swift 5.10, async/await)

import GoogleGenerativeAI

final class GeminiClient {
  private let model: GenerativeModel

  init(apiKey: String) {
    let config = GenerationConfig(
      maxOutputTokens: 4096,
      temperature: 0.4,
      topP: 0.95,
      thinkingBudgetTokens: 1024   // ≤ 24 576 for Flash 2.5
    )
    model = GenerativeModel(
      name: "gemini-2.5-flash-preview-05-20",   // prod GA model string will change
      apiKey: apiKey,
      generationConfig: config
    )
  }

  func chat(prompt: String) async throws -> String {
    try await model.generateContent(prompt).text
  }
}

Flash 2.5’s thinking budget is what unlocks its step-by-step reasoning; the model stops early if it finishes sooner, so start low and tune.  ￼ ￼

⸻

4.  Streaming for UX parity with ChatGPT

for try await chunk in model.generateContentStream(prompt) {
  append(chunk.text ?? "")
}

Back-pressure is handled for you; cancel the Task to abort.  Expect ≤ 100 ms token latency over Wi-Fi on the Developer API.

⸻

5. Chat sessions & memory

let session = try await model.startChat(history: [
  .init(role: .system, parts: "You are a terse surgical co-pilot.")
])
let reply = try await session.sendMessage(userText)

The SDK automatically appends messages to history so you stay under the 1 M token context window.  For long-running threads, prune older turns on device to manage cost.

⸻

6.  Multimodal input (image + text)

let imagePart = try Parts.Image(
  uiImage: photo,
  mimeType: .png            // jpeg also allowed
)
let resp = try await model.generateContent(
  "Summarize the anatomy shown, 50 words max.",
  imagePart
).text

Flash 2.5 accepts text, code, PDFs, images, audio & video inputs; outputs are text / JSON only for now.  ￼

⸻

7.  Structured / JSON output (function calling analogue)

let tools: [Tool] = [
  .codeExecution,
  .structuredOutput(schema: """
    {
      "diagnosis": "string",
      "confidence": "number (0-1)"
    }
    """)
]
let cfg = GenerationConfig(tools: tools)
let structuredModel = GenerativeModel(
  name: "gemini-2.5-flash-preview-05-20",
  apiKey: key,
  generationConfig: cfg
)
let result = try await structuredModel.generateContent(
  "Return a JSON object with the fields above describing this case."
).jsonValue   // Decodes into `Any` or your Codable struct

No brittle regex post-processing required.

⸻

8.  Vertex AI specifics (if you outgrow the free tier)
	1.	Enable Vertex AI in your Cloud project → create a service account with roles/aiplatform.user.
	2.	Generate a JSON key, store in your backend.
	3.	Exchange for an OAuth 2 access token (https://oauth2.googleapis.com/token) and hand a time-limited bearer to the device.
	4.	Endpoint format:

POST https://us-central1-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/us-central1/publishers/google/models/gemini-2.5-flash-preview:generateContent
Authorization: Bearer ACCESS_TOKEN

Body schema identical to Developer API.  ￼

Swap :generateContent for :streamGenerateContent if you want server-side streaming.

⸻

9.  Firebase AI Logic path (kills two birds)

import FirebaseAI

let generativeAI = FirebaseAI.service(provider: .geminiDeveloper)

let model = generativeAI.generativeModel(
  "gemini-2.5-flash-preview-05-20",
  config: .init(maxOutputTokens: 4096)
)

let text = try await model.generateText("Compress this operative note to 150 chars.")

Firebase handles key management, App Check and analytics, and later you can flip a console switch to Vertex without code changes.  ￼

⸻

10.  Cost & rate-limit hygiene

Unit	Flash 2.5 price (preview)	Notes
Input tokens	$0.15 / 1 M	“thinking” counts toward input
Output tokens	$0.30 / 1 M	Rounded up to nearest 256
Minimum billable	256 tokens per request	Includes empty responses

	•	Throttle: exponential back-off on 429; the SDK throws GenerativeModelError.rateLimited.
	•	Batch: one multimodal request with multiple MIME parts costs a single request.
Pricing from public preview schedule, subject to change at GA  ￼.

⸻

11.  Security checklist (Apple review will ask)
	1.	Explain data usage in App Privacy > Data Linked to You.
	2.	Route traffic over HTTPS only; ATS already enforced.
	3.	If you rely on the Developer API, implement a server-side quota proxy before TestFlight—public keys will leak.
	4.	For HIPAA-adjacent data, you must use Vertex AI with a signed BAA; Developer API is not covered.

⸻

12.  Drop-in MVVM wiring (skeleton)

@Observable
final class ChatViewModel {
  @MainActor @Published var messages: [ChatMessage] = []

  private let gemini: GeminiClient

  init(gemini: GeminiClient) { self.gemini = gemini }

  @MainActor
  func send(_ text: String) {
    messages.append(.user(text))
    Task {
      do {
        let reply = try await gemini.chat(prompt: text)
        await MainActor.run { messages.append(.assistant(reply)) }
      } catch {
        await MainActor.run { messages.append(.error(error.localizedDescription)) }
      }
    }
  }
}

Inject the same GeminiClient into other feature modules; no singletons needed.

⸻

Where to go next
	•	Gemini thinking guide – deep dive on budget tuning  ￼
	•	Google Gen AI SDK docs (if you later need cross-platform parity)  ￼
	•	Gemini model cards for exact prompt & context limits (they change between previews)  ￼

That’s the whole picture.  Plug the snippets into your current MVVM stack and you’re live with Flash 2.5 in less than an hour.