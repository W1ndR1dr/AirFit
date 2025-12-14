# AirFit: AI-Native UI/UX Engineering Spec

## 1. The "Stream" Architecture (Server-Driven UI)

The core interaction model shifts from "Chat" to "Generative Stream". The server returns structured **UI Payloads** instead of just text.

### JSON Schema for UI Payloads

The `ChatResponse` from `server.py` will include a `ui_payload` field.

```json
{
  "response": "Here's your weekly progress.",
  "ui_payload": {
    "type": "container",
    "layout": "vertical",
    "components": [
      {
        "type": "insight_card",
        "data": {
          "title": "Protein Streak",
          "body": "You've hit your protein target 5 days in a row.",
          "category": "milestone",
          "color": "green"
        }
      },
      {
        "type": "chart",
        "data": {
          "type": "line",
          "title": "Weight Trend",
          "points": [{"x": "Mon", "y": 180}, {"x": "Tue", "y": 179.5}]
        }
      },
      {
        "type": "action_group",
        "data": {
          "actions": [
            {"label": "Log Shake (300cal)", "action_id": "log_shake_300"}
          ]
        }
      }
    ]
  }
}
```

### Swift Implementation (`UIFactory`)

A `UIFactory` ViewBuilder will map these types to SwiftUI views:
-   `insight_card` -> `InsightCard`
-   `chart` -> `SwiftCharts` View
-   `macro_gauge` -> `MacroGauge`
-   `action_group` -> `HStack { Button... }`

## 2. Generative UI Components

We will build these "Widgets" that the AI can deploy into the stream:

1.  **`MacroWidget`**: Mini version of the nutrition ring.
2.  **`WorkoutBrief`**: "Today: Chest & Back" card with a "Start" button.
3.  **`QuickLog`**: Predetermined buttons for frequent foods (e.g., "Coffee", "Eggs").
4.  **`VerificationCard`**: Result of an image upload (User uploads photo -> AI returns this card with "I see X, Y, Z. Confirm?").

## 3. Adaptive Theming (Bio-Reactive UI)

The app's `Color` assets will be wrapped in a `ThemeManager` that subscribes to `HealthKitManager`.

**States:**
1.  **Recovery (Default):** Soft Blues/Greens. (Low stress, rest days).
2.  **High Strain:** High Contrast Orange/Red. (Training days, active workout).
3.  **Fatigue:** Darker, lower contrast, "Night Shift" vibe. (Poor sleep < 6h, high RHR).

**Logic:**
```swift
var currentTheme: Theme {
    if healthContext.sleepHours < 6.0 { return .fatigue }
    if isTrainingDay { return .highEnergy }
    return .recovery
}
```

## 4. "Zero-UI" Interaction Patterns

1.  **Camera-First Input:** `InputArea` gains a camera icon.
    -   Flow: Tap Camera -> Snap -> Upload -> Server Analysis -> Stream updates with `VerificationCard`.
2.  **Mic-First Input:** `VoiceOverlay` acts as a push-to-talk.
    -   Flow: Hold Mic -> Speak -> Server STT + NLP -> Stream updates with confirmation.

## Implementation Plan

1.  **Phase 1: Stream Foundation**
    -   Refactor `Message` model to support `uiPayload`.
    -   Create `UIFactory` in SwiftUI.
    -   Update `ChatView` to render mixed Text + UI.

2.  **Phase 2: Server Payload Logic**
    -   Update `server.py` to generate sample JSON payloads for testing.
    -   Connect `insight_engine` to output UI payloads.

3.  **Phase 3: Adaptive Theme**
    -   Create `ThemeManager`.
    -   Inject HealthKit state into Theme logic.