# Steve Jobs on AirFit: Product Vision & Coherence

*Exploration Date: December 18, 2025*

---

## The Soul of the Product

There's something here. A spark. You've built an app that **trusts the future** instead of being trapped by today's limitations. That's rare. Most people build for the constraints of right now — slow APIs, expensive tokens, dumb models. You said "screw that, the models will get better" and built for where we're going.

The core insight is right: **AI should converse, not navigate.** No more tapping through 47 screens to log breakfast. Just talk. The machine understands. That's the promise.

But here's the brutal truth: **you haven't finished the thought.**

The product has amazing bones — the breathing backgrounds, the LOESS smoothing, the way the coach remembers your last conversation — but the narrative gets muddy. You've built five separate apps that happen to share a tab bar. Dashboard is analytical. Nutrition is conversational. Insights is proactive. Chat is reactive. Profile is reflective.

**That's not one product. That's a committee.**

---

## Where the Narrative Breaks Down

### 1. The Onboarding Sets the Wrong Expectation

You start with this beautiful conversational interview. The AI asks questions. It learns about me. I think "oh, this is going to be different."

Then I land in... a **five-tab fitness dashboard?**

The opening promise is "talk to me, I'll understand you." But the first thing I see is charts, numbers, and a tab bar. Where's the conversation? Why am I navigating when the whole pitch was that I wouldn't have to?

**The product should open to the coach.** Make that the home screen. Everything else is detail.

### 2. Five Tabs Is Four Too Many

iPhone had one button. iPod had a click wheel. The best products have a center of gravity so strong that everything else orbits around it.

Your center of gravity is the **Coach**. Everything else — the charts, the insights, the profile — those are just context for the conversation. They're not destinations. They're details.

Right now, Chat is tab 3 of 5. Hidden in the middle. That's insane. The thing that makes this product different is buried.

**Collapse the tabs.** Make the coach the main interface. Charts and insights should be *in the conversation*, not separate screens.

### 3. Data Entry Feels Like Homework

"Log food like you're texting a friend" — I love that line. But it's buried in the Nutrition tab. I have to navigate there. The input box is at the bottom. There's a giant calorie number shouting at me.

This should be **effortless**. I shouldn't navigate to log food. I should just... log food. Anywhere. Anytime.

Why isn't there a big, beautiful button floating at the bottom of every screen that says "What did you eat?" Tap it, type "3 eggs and toast", done. The AI parses it. It updates the charts. I never had to think about tabs.

### 4. Insights Are Disconnected from Action

The Insights tab is brilliant conceptually. AI finds patterns I'd never notice. Celebrates milestones. Suggests actions.

But why is it a separate tab? **Insights should interrupt the conversation.** The coach should say "Hey, I noticed your protein drops on Wednesdays. What's going on?" Right there. In the flow.

Putting insights in a separate tab makes them optional. I have to remember to check them. That's not how epiphanies work.

### 5. The Profile Is A Museum, Not A Living Thing

The Profile tab shows what the AI learned about me. That's... fine? But it's static. A changelog. I go there when I want to audit the system.

**Why isn't the profile part of the conversation?** The coach should reference it constantly. "Last month you said you wanted to hit 180 lbs by June. You're at 177. Let's talk about the final push."

Make the profile invisible until it matters. Then make it *unmissable*.

---

## What's Essential vs. What's Noise

### Essential (Keep, Amplify)

1. **The Coach's Memory** — The fact that it remembers our last conversation, knows my workout schedule, and has access to my actual data. This is the magic.

2. **Natural Food Logging** — "4 eggs and OJ" → macros. No barcode scanning. This is 10x better than MyFitnessPal.

3. **The Breathing Background** — It's alive without being distracting. Perfectly calibrated.

4. **Insight Generation** — AI finding patterns I'd never see. Gold.

5. **LOESS Smoothing** — Shows me the *trend*, not the noise. This is how you earn trust with data nerds.

6. **The Architecture** — Local AI, no cloud lock-in, model-agnostic. This is the right bet.

### Noise (Simplify, Remove, Rethink)

1. **Five Tabs** — Murder at least three of them. Merge into the conversation.

2. **Separate Nutrition View** — Why is logging food a separate experience? It should be a lightweight overlay, available everywhere.

3. **The Dashboard's Segmented Picker** — Body vs. Training. Just show me what matters *right now*. The AI should know.

4. **Manual Time Range Selection** — Why am I picking "last 7 days" vs. "last month"? The AI should show me the relevant window automatically.

5. **Multiple Input Paradigms** — Sometimes I'm tapping cards, sometimes I'm chatting, sometimes I'm swiping insights. Pick ONE primary interaction model and commit.

6. **The Settings Cog** — Settings should be *asked for*, not hunted down. "Want to change your protein target?" → inline, conversational.

---

## The "One More Thing" Moment

Here's what this product should be:

**A single, infinite conversation with a coach who has perfect recall.**

When I open the app, I see:
- The last thing we talked about
- A suggestion for what to do next (based on time of day, my schedule, recent patterns)
- A beautiful, always-present input that accepts food, questions, or goals

Everything else — the charts, the insights, the profile — gets **pulled into the conversation** when it matters.

Example flow:

```
[Morning, 7:42 AM]

Coach: "Morning! How'd you sleep?"
Me: "Pretty good, 7 hours."

Coach: "Solid. You've got upper body today, right?
Want to log breakfast before you head out?"

[Floating input appears]
Me: "3 eggs, toast, coffee"

Coach: "Got it. 420 cal, 28g protein. You're 21% to
your target. I'll check in after your workout."

[Chart card appears inline showing protein progress]

Coach: "Also — I noticed you hit your squat PR yesterday.
Want to talk about your next strength goal?"
```

That's it. One interface. One mental model. The conversation is the product.

---

## 10 Feature Ideas for Product Coherence

### 1. **Kill Four Tabs. Keep One: "Coach"**

The app opens to the conversation. Everything else is accessed *through* the coach or via contextual overlays. No more tab bar. No more navigation.

**Why:** The product's soul is the AI coach. Make it the entire interface.

---

### 2. **Floating "Log Anything" Button**

Persistent FAB (floating action button) at the bottom-right of every screen. Tap it, speak or type what you ate/did/felt. AI categorizes it automatically.

- Food → nutrition log
- Workout → training log
- "Felt tired today" → profile note
- "What's my protein at?" → immediate answer

**Why:** Remove the friction between thought and capture. No navigation tax.

---

### 3. **Conversational Insights**

Kill the Insights tab. The coach proactively brings up insights mid-conversation:

> "By the way, I noticed your sleep quality dropped 15% this week. What changed?"

Insights become dialogue prompts, not a separate destination.

**Why:** Insights should interrupt you (gently). That's how epiphanies work.

---

### 4. **"What's Next?" Home Screen**

Replace the static Dashboard with a dynamic home screen that answers ONE question: **"What should I do right now?"**

Morning? "Log breakfast."
Post-workout? "How was the session?"
Evening? "Protein check: you're 40g short today."

The AI decides what's important based on time, context, and patterns.

**Why:** Remove decision paralysis. Tell me what matters *right now*.

---

### 5. **Voice-First Interaction**

Add a Siri-style voice mode. Hold the FAB, speak your food log or question. AI responds conversationally.

Walking to the gym? "Log post-workout meal" without touching the screen.

**Why:** The best interface is no interface. Make it effortless.

---

### 6. **Inline Data Visualization**

When I ask "How's my protein this week?", don't navigate to a chart. Show the chart **inline in the conversation** as a card.

Tap it to expand. Swipe it away when done. The conversation continues.

**Why:** Keep me in flow. Don't make me context-switch to see data.

---

### 7. **"Undo That" as a Core Primitive**

Not just for dismissed insights. Everything should be undo-able conversationally:

> Me: "Actually, that was 2 servings."
> Coach: "Got it. Updated to 840 cal, 56g protein."

Or:

> Me: "Undo my last workout log."
> Coach: "Removed. Need to re-log it?"

**Why:** Mistakes happen. Make corrections feel like fixing a typo in a text message.

---

### 8. **The Profile as a Living Document**

Show profile evolution over time with a "Memory Lane" feature:

> "3 months ago, you said you wanted to lose 15 lbs.
> Today, you're down 12. Here's what changed."

Make it a **timeline visualization** showing how goals evolved, patterns emerged, and habits shifted.

**Why:** Celebrate progress as a narrative, not a spreadsheet.

---

### 9. **Proactive Reminders Based on Intent**

When the AI detects I'm struggling (e.g., missed protein 3 days in a row), it should *offer* to help:

> "Want me to remind you about protein at 6 PM? I can send a nudge."

No settings menu. Just ask. I say yes or no. It adapts.

**Why:** Settings should be conversational agreements, not buried toggles.

---

### 10. **"Teach Mode" for Edge Cases**

When the AI gets something wrong, let me correct it *and* explain why:

> Me: "That wasn't 3 eggs. It was an omelet with 3 eggs, cheese, and veggies."
> Coach: "Ah, got it. 520 cal, 35g protein. I'll remember omelets are usually bigger."

The correction becomes part of the training data for future parses.

**Why:** Let users refine the model without feeling like beta testers.

---

## Signature "Jobs" Insights

### On Simplicity
**This app has too many features masquerading as different apps.** You've built a dashboard for data nerds, a nutrition tracker for macro counters, a chat interface for conversationalists, and an insights engine for pattern seekers.

Pick one. **The conversation.** Everything else is detail. Make it ruthlessly focused.

### On Focus
**The best products do ONE thing so well that you can't imagine life without them.** Right now, AirFit does five things pretty well. That's not good enough.

The iPhone wasn't a phone + iPod + camera + browser. It was **a pocketable internet device** that happened to make calls. You need that same clarity.

AirFit should be **a fitness coach that never forgets**, not a fitness dashboard with AI features.

### On Emotional Connection
**People don't buy what you do; they buy why you do it.**

Your "why" is buried in a markdown file (CLAUDE.md). It's brilliant: "Skate where the puck is going. Trust natural language. Let the AI do the heavy lifting."

That philosophy should be **visceral** in the product. The app should *feel* like the future. Right now, it feels like a well-designed present.

### On The User Journey
**The product should tell a story from first tap to daily use.**

Act 1: "Talk to me. I'll learn about you."
Act 2: "I'm learning. Here's what I see."
Act 3: "I know you now. Let's work together."

Right now, the story is:
Act 1: "Talk to me."
Act 2: "Now navigate these five tabs."
Act 3: "...where'd you go?"

The narrative breaks after onboarding. Fix that.

### On Design Consistency
**The breathing background is perfect. The LOESS smoothing is perfect. The "Log food like texting" is perfect.**

But then you have:
- Segmented pickers
- Tab bars
- Card-based layouts
- Chat bubbles
- Swipeable insights

That's five different design languages in one app. Pick ONE visual metaphor and commit. My vote: **conversational cards in an infinite scroll.**

---

## What Makes This Product "Insanely Great"

You're *almost* there. Here's what pushes it over the edge:

### 1. **Ruthless Simplification**
One tab. One input method. One mental model. Everything else is just depth, not breadth.

### 2. **Conversational Coherence**
The product should feel like talking to one very smart friend, not navigating a fitness complex.

### 3. **Invisible Intelligence**
The AI should do 95% of the work invisibly. I should barely notice how much it's handling. Right now, I see too much machinery.

### 4. **Finish the Design Language**
The breathing background is your North Star. Make everything else feel as organic. Remove hard edges, segmented pickers, and tab bars. Lean into cards, gradients, and flowing transitions.

### 5. **Celebrate the Bet**
You're betting on AI getting smarter. That's the story. The product should feel **alive and evolving**, not static and feature-complete.

Add an "AI Confidence" indicator. Show me when the model improves. Let me see the product get smarter over time. Make the bet visible.

---

## Final Word

You've built something rare: **a product that trusts the future.**

Most fitness apps are trapped in 2015 — barcode scanners, calorie databases, generic advice. You said "the models will get better, so I'll design for that world."

That's the right instinct. But you haven't committed fully.

**Kill the tabs. Simplify the interaction model. Make the conversation the product.**

Right now, it's a very good fitness dashboard with AI features. It should be an AI coach that happens to show charts when you ask.

The soul is there. The bones are strong. The execution is 90% of the way.

But the last 10% is what separates "good" from "insanely great."

**Make it one thing. Make it unmistakable. Make it magic.**

---

*"Simplicity is the ultimate sophistication." — Leonardo da Vinci*

*"But sometimes, you need to rip out 60% of what you built to find it." — Steve Jobs*
