# AirFit Next Steps - AI-Native Roadmap

## Philosophy Reminder
**"Skate where the puck is going."** Build for where AI is headed, not where it is today.

---

## Theme 1: Voice-First Experience

### The Vision
Text input is a legacy interaction pattern. Future AI interfaces will be voice-first, with text as fallback. iOS 26 will likely bring major Siri/voice improvements.

### Current State
- `VoiceMicButton` exists but has threading crash (disabled in NutritionView)
- Speech recognition is manual start/stop
- No voice output

### Next Steps

**1.1 Fix Voice Input**
- Debug and fix the threading crash in `SpeechRecognizer`
- Ensure Swift 6 concurrency compliance (actors, Sendable)
- Test on device (simulator speech recognition is limited)

**1.2 Always-Listening Mode (Future)**
- Wake word detection: "Hey Coach" or custom phrase
- Background audio session for hands-free logging
- This anticipates iOS 26's likely voice improvements

**1.3 Voice Output (Text-to-Speech)**
- Read AI responses aloud (opt-in)
- Use AVSpeechSynthesizer or iOS 26's improved voice synthesis
- Makes the coach feel like a real conversation partner

**1.4 Conversational Food Logging**
- Instead of typing "chipotle bowl", speak it
- Natural corrections: "Actually that was two scoops of rice"
- Stream-of-consciousness input: "I had eggs for breakfast, then a protein shake around 10..."

---

## Theme 2: Ambient Intelligence

### The Vision
The best AI disappears into the background. It knows things without being told. It surfaces insights at the right moment, not when you ask.

### Current State
- Background scheduler runs insight generation every 6 hours
- Insights are pulled on-demand in InsightsView
- No proactive notifications

### Next Steps

**2.1 Smart Notifications**
- Push notifications for actionable insights
- "You're 40g short on protein with 3 hours left - want suggestions?"
- "Great sleep last night (8.2h) - good day for intensity"
- Timing: Morning briefing, post-workout, evening check-in

**2.2 Live Activities / Dynamic Island**
- Show today's macro progress as Live Activity
- Update in real-time as food is logged
- "1,847 / 2,600 cal • 142g protein"

**2.3 Widget Intelligence**
- Home screen widget with daily status
- Complication for Apple Watch
- Glanceable: "On track" / "Need protein" / "Rest day"

**2.4 Contextual Awareness**
- Detect workout completion (HealthKit workout end) → prompt for nutrition
- Detect location (gym, home, restaurant) → adjust suggestions
- Detect time patterns → "You usually eat around now"

**2.5 StandBy Mode (iOS 17+)**
- Bedside display showing tomorrow's plan
- Morning: "Training day - 2,600 cal target"
- Evening: "175g protein to go"

---

## Theme 3: Multimodal Input

### The Vision
Text and voice aren't the only inputs. Future models excel at images, structured data, and sensor fusion. Build the pipes now.

### Current State
- Food input is text-only
- No image support
- Health data is pulled but not deeply analyzed

### Next Steps

**3.1 Photo Food Logging**
- Snap a picture of your meal
- Send image to server → AI describes and estimates macros
- "Looks like a grilled chicken salad with ranch - ~450 cal, 38g protein"
- Store image with entry for review/correction

**3.2 Receipt/Menu Scanning**
- OCR restaurant menus or receipts
- "I see you ordered the Salmon Bowl from Sweetgreen..."
- Parse known restaurant menus for accuracy

**3.3 Barcode Scanning**
- Scan packaged foods
- Pull from nutrition database (OpenFoodFacts, etc.)
- Fallback to AI if unknown

**3.4 Apple Watch Sensor Fusion**
- Real-time HR during workouts
- HRV trends for recovery recommendations
- Wrist temperature for sleep quality
- Blood oxygen correlation with performance

**3.5 Workout Video Analysis (Future)**
- Record a set, AI analyzes form
- "Your depth looks good, but watch elbow flare on the press"
- Requires on-device or fast cloud vision model

---

## Theme 4: Agentic Capabilities

### The Vision
AI that takes action, not just answers questions. Future models will be more capable of multi-step reasoning and tool use.

### Current State
- AI is reactive (responds to messages)
- Background insight generation is a basic agent pattern
- No ability to "do things" for the user

### Next Steps

**4.1 Proactive Coach Check-ins**
- AI initiates conversation based on context
- "I noticed you haven't logged anything today - busy day?"
- "Your weight has been trending down nicely - 2lbs this week"
- Balance: helpful not annoying (user controls frequency)

**4.2 Automated Data Sync**
- Auto-sync HealthKit data on schedule
- Auto-sync Hevy workouts
- No manual "sync" button needed

**4.3 Smart Reminders**
- AI sets reminders based on conversation
- "Remind me to log my post-workout shake" → iOS reminder
- "Check in with me tomorrow about that craving"

**4.4 Meal Planning Agent (Future)**
- "Plan my meals for tomorrow to hit 175g protein"
- AI generates meal plan, user approves
- Integrates with grocery list

**4.5 Workout Programming Agent (Future)**
- AI generates/adjusts training program
- Based on recovery data, progress, schedule
- "Your HRV is low - let's swap today's heavy session for mobility"

---

## Theme 5: Deep Personalization

### The Vision
The profile isn't static data - it's a living understanding of who you are. Every interaction makes it better.

### Current State
- Rich profile system with onboarding
- Personality synthesis works well
- Profile extracts from conversation

### Next Steps

**5.1 Confidence Scoring**
- Track confidence in profile fields
- "I'm 90% sure your protein target is 175g"
- "I'm guessing you prefer morning workouts - correct?"
- Display uncertainty, ask for confirmation

**5.2 Temporal Patterns**
- Learn weekly rhythms (training days, meal timing)
- Seasonal adjustments (ski season, summer cut)
- Life event awareness (travel, holidays, work stress)

**5.3 Preference Learning**
- Track what user responds to positively
- "You engage more when I explain the science"
- "Short responses work better for you in mornings"

**5.4 Goal Evolution**
- Detect when goals shift (user mentions new target)
- Proactively ask: "Sounds like your focus is shifting to maintenance?"
- Phase transitions: cut → maintain → bulk

**5.5 Relationship Memory**
- Remember specific conversations
- "Last week you mentioned that wedding in May..."
- Build genuine relationship over time

---

## Theme 6: iOS 26 Native Features

### The Vision
iOS 26 will bring new capabilities. Position the app to adopt them immediately.

### Anticipated Features (Speculative)

**6.1 Apple Intelligence Integration**
- On-device summarization of chat history
- Siri shortcuts: "Hey Siri, log my lunch"
- System-wide AI that can interact with AirFit

**6.2 Enhanced HealthKit**
- More granular workout data
- Nutrition logging in HealthKit (write, not just read)
- Mental health metrics (stress, mood)

**6.3 Spatial/Immersive UI**
- Depth effects, parallax
- AR food visualization (portion size estimation)
- VisionOS compatibility preparation

**6.4 Advanced Widgets**
- Interactive widgets (log food directly from widget)
- Widget suggestions based on context
- Stack intelligence

**6.5 Improved Privacy Framework**
- On-device processing indicators
- Clearer data flow visualization
- User control over AI learning

---

## Theme 7: Infrastructure Evolution

### The Vision
The server architecture should get simpler over time, not more complex. As on-device models improve, shift processing to the edge.

### Current State
- Python FastAPI server wrapping CLI tools
- All AI processing server-side
- iOS sends raw data, receives responses

### Next Steps

**7.1 Hybrid Architecture**
- Simple tasks on-device (food parsing, quick responses)
- Complex tasks to server (insight generation, deep analysis)
- Graceful offline mode

**7.2 Response Streaming**
- Stream AI responses token-by-token
- Better perceived latency
- Interrupt capability ("stop, let me clarify")

**7.3 Multi-Model Routing**
- Use faster/cheaper models for simple tasks
- Reserve powerful models for complex reasoning
- Automatic routing based on query complexity

**7.4 Local LLM Option**
- iOS 26 may enable larger on-device models
- CoreML models for basic coaching
- Full offline capability for privacy-conscious users

**7.5 Server Simplification**
- As models improve, remove parsing/formatting code
- Trust the model to handle edge cases
- Less code = fewer bugs = easier maintenance

---

## Priority Ordering

### Immediate (High Impact, Low Effort)
1. Fix voice input threading crash
2. Smart notifications for protein/calorie gaps
3. Live Activity for daily progress
4. Automated HealthKit/Hevy sync

### Near-Term (High Impact, Medium Effort)
1. Photo food logging
2. Voice output (TTS)
3. Proactive coach check-ins
4. Widget with daily status

### Medium-Term (Medium Impact, Higher Effort)
1. Always-listening voice mode
2. Response streaming
3. Temporal pattern learning
4. Barcode scanning

### Future (Prepare Architecture Now)
1. On-device inference
2. Workout video analysis
3. AR portion estimation
4. Full offline mode

---

## Implementation Notes

### AI-Native Principles to Maintain
- **Don't over-specify**: Let AI figure out intent from natural language
- **Rich context always**: More data to the model = better responses
- **Graceful degradation**: When AI fails, fail gracefully
- **Trust evolution**: As models improve, remove guardrails
- **Conversation over forms**: Never add a settings page when a question works

### Code Hygiene
- Maintain Swift 6 strict concurrency
- Keep server endpoints RESTful and simple
- JSON in, JSON out (or plain text when appropriate)
- No complex state machines - let conversation be the state

### Testing Philosophy
- Integration tests > unit tests for AI features
- Test the full flow (iOS → Server → CLI → Response)
- Expect AI outputs to vary - test for reasonableness, not exact match
