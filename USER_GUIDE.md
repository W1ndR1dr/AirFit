# AirFit User Guide
### *Your AI Fitness Coach That Actually Gets You*

---

## What Is This Thing?

AirFit is what happens when someone builds a fitness app for **where AI is going**, not where it is today. No cloud APIs bleeding your wallet. No generic advice. No rigid calorie-counting databases. Just a local AI coach running on a Raspberry Pi that:

- **Learns through conversation** (not forms)
- **Sees your actual data** (HealthKit, Hevy workouts, what you ate)
- **Finds patterns you'd never notice** (AI-powered insights)
- **Evolves with you** (your profile gets richer over time)

Think of it as a super-knowledgeable friend who happens to have memorized your training logs, sleep patterns, and that one time you crushed your squat PR after accidentally carb-loading on pasta.

---

## The Five Tabs

### 1. Dashboard
*Your fitness command center*

**Body Tab:**
- Weight, body fat %, and lean mass trends with fancy LOESS smoothing (statistical science, not simple averages)
- "Change Quality" gauge — measures whether you're gaining muscle or just fat when your weight changes
- Weekly compliance: are you hitting protein? Staying in your calorie range?
- Sparklines everywhere showing 7-day patterns at a glance

**Training Tab:**
- Rolling 7-day set tracker by muscle group (are you hitting 10-20 sets per muscle per week?)
- Personal records across your lifts
- Strength progression charts with estimated 1-rep max
- Recent workouts synced automatically from Hevy

---

### 2. Nutrition
*Log food like you're texting a friend*

Type naturally: **"4 eggs scrambled with cheese and some OJ"**

The AI parses it into macros instantly. No barcode scanning. No searching databases. Just... talk.

- **Day view**: Big calorie number that shrinks as you scroll (fancy scrollytelling animation), macro breakdown, real-time energy balance with TDEE prediction
- **Week/Month view**: Daily cards showing compliance, averages for days you actually logged
- **Confidence badges**: High/Medium/Low so you know when the AI is guessing
- **Corrections**: Say "that was a large portion" and it recalculates

*Training days get higher carbs automatically. Rest days get lower. The AI knows your schedule.*

---

### 3. Coach
*Your AI fitness coach that remembers everything*

This isn't ChatGPT for fitness. Before every message, the coach gets injected with:

- Your last 30 days of workouts (from Hevy)
- Your nutrition trends (7-day averages, compliance)
- Your health data (weight, sleep, HRV, heart rate)
- Your profile (goals, constraints, communication style)
- Relationship memory (inside jokes, callbacks, what motivates you)

Ask "how's my training going?" and it **answers with your actual numbers**.

Over time, the coach learns how to talk to YOU — whether you want bro energy, tough love, or analytical breakdowns. The profile builds organically through conversation, not forms.

---

### 4. Insights
*AI-generated "aha" moments*

Every 6 hours, the AI analyzes 90 days of your data and finds patterns:

- **Correlations**: "Your protein drops on high-stress days. Maybe prep meals in advance?"
- **Trends**: "Squat strength up 8 lbs/month over last quarter"
- **Anomalies**: "Sleep crashed last night but HRV stayed solid — interesting"
- **Milestones**: "Hit your 15% body fat goal!"
- **Nudges**: "You've hit protein 6 of 7 days. Keep the streak alive."

Each insight has:
- A "Tell Me More" button → opens a chat about that specific insight
- Suggested actions (with smart reminders)
- Swipe-to-dismiss (with undo!)
- Celebration animations for milestones

---

### 5. Profile
*Everything the AI has learned about you*

Your evolving profile, built through conversation:

- **Goals**: What you're working toward (with timelines)
- **Context**: What the AI has learned from chat
- **Preferences**: How you like to train and eat
- **Constraints**: Injuries, allergies, schedule chaos
- **Patterns**: Behaviors the AI has noticed
- **Communication style**: How we talk (bro energy? Analytical? Gentle?)

You can edit anything directly. The profile gets richer over time as you chat — no forms, just natural learning.

---

## The Cool Features You Might Miss

### The Breathing Background
That living, breathing mesh behind the tabs? It's a 4×4 control point grid with three frequencies of organic motion — slow breath, medium waves, fast ripples. Not random; designed to feel alive without being distracting.

### LOESS Smoothing
The charts don't use simple moving averages (which lag behind reality). They use LOESS — a statistical technique that looks backward AND forward to show the true trend. Tap any point to see raw value vs. smoothed.

### Dynamic Island
When the app is running, your Lock Screen shows:
- Calories and protein progress bars
- Training vs. rest day indicator
- Live updates as you log food

### Session Continuity
Your chat sessions persist. The AI doesn't forget what you talked about yesterday. Ask "remember when we discussed..." and it actually remembers.

### Smart Reminders
When insights suggest actions, tap the action button:
- Protein reminder → schedules for 2 hours or 6pm (whichever's sooner)
- Workout reminder → tomorrow 8am or today 4pm
- Sleep reminder → 2 hours before your typical bedtime

---

## How It Actually Works (The Nerdy Bits)

| Thing | How |
|-------|-----|
| **AI calls** | CLI tools (Claude, Gemini) via subprocess — no cloud API costs |
| **Server** | FastAPI on Raspberry Pi, auto-reloads |
| **Data** | iOS owns granular meals, server stores daily aggregates |
| **Sync** | Background tasks every 1-6 hours (insights, Hevy, memory) |
| **Privacy** | Everything on your local network, nothing leaves unless you want it to |

---

## Getting Started

1. **Launch the app** → Complete the onboarding chat (the AI interviews you naturally)
2. **Grant HealthKit permissions** → Steps, weight, sleep, heart rate
3. **Connect Hevy** (optional) → Automatic workout sync
4. **Log a meal** → Just type what you ate
5. **Chat with your coach** → Ask anything fitness-related
6. **Check Insights** → See what patterns the AI found

---

## Pro Tips

- **Be specific in chat**: "Why am I not losing weight?" works better when you've logged meals consistently
- **Check insights daily**: They regenerate every 6 hours with fresh analysis
- **Use natural corrections**: "That was actually 2 servings" is better than re-logging
- **Edit your profile**: Add constraints, update goals — the AI adapts
- **Swipe on insights**: Dismiss ones you've addressed, they won't repeat

---

## What Makes This Different

Most fitness apps are **databases with forms**. AirFit is an **AI that converses**.

| Traditional Apps | AirFit |
|------------------|--------|
| Barcode scanning | Just describe food |
| Rigid templates | Profile learns from chat |
| Generic advice | Context injected from YOUR data |
| Cloud dependency | Runs on a Raspberry Pi |
| Vendor lock-in | Swaps Claude/Gemini/Codex seamlessly |

It's built for where AI is headed, not where it is today. As models get smarter, the app gets smarter. That's the bet.

---

## Data & Privacy

**What stays on your iPhone:**
- Every individual meal you've logged (SwiftData)
- Chat message history
- HealthKit data (Apple's domain)

**What goes to your local server:**
- Daily aggregates only (~2KB/day)
- Your evolving profile
- Generated insights

**What leaves your network:**
- Nothing, unless you configure external sync

The architecture inverts the typical cloud model: your phone owns the irreplaceable granular data, the server stores only what can be regenerated.

---

## The Tech Stack

```
iOS App (SwiftUI + Swift 6 Concurrency)
    │
    │ HTTP (local network)
    │
    ▼
Python Server (FastAPI on Raspberry Pi)
    │
    │ subprocess calls
    │
    ▼
CLI Tools (claude, gemini, codex)
```

- **iOS**: SwiftUI with actors for thread safety, SwiftData for persistence
- **Server**: FastAPI with async subprocess calls, JSON file storage
- **AI**: CLI-based LLM calls with session continuity and provider fallback
- **Sync**: Background scheduler for insights, Hevy, and memory consolidation

---

## Troubleshooting

**"Server offline" banner?**
- Check that the Python server is running (`python server.py` in the server directory)
- Verify your iPhone is on the same WiFi network as the server
- Check the IP address in `APIClient.swift` matches your server

**Insights not generating?**
- The scheduler runs every 6 hours — check `/scheduler/status` endpoint
- Ensure you have at least a few days of data logged
- Manual trigger: restart the server to force a fresh insight generation

**Hevy workouts not syncing?**
- Verify `HEVY_API_KEY` is set in your environment
- Check the Hevy API is accessible from your network
- Workouts sync every hour; check `/scheduler/status` for last sync time

**Food parsing seems wrong?**
- Use the "Tell Me More" or correction feature to adjust
- More specific descriptions = higher confidence parsing
- You can always manually edit entries

---

## Philosophy

> "Skate where the puck is going."

AirFit is built on a bet: AI models will keep getting better, faster, and cheaper. So instead of over-engineering around current limitations:

- **Simple prompts** over complex parsing
- **Rich context** over pre-filtered summaries
- **Natural conversation** over rigid forms
- **Trust the model** to find what's interesting

The app improves automatically as the underlying models improve. That's the design.

---

*Built with SwiftUI, FastAPI, and an unreasonable amount of LOESS smoothing calculations.*
