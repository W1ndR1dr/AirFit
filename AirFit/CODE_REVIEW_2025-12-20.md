# AirFit Code Review (Code-Only) - 2025-12-20

## The quick story (plain-English)
Think of AirFit as a two-part team. Your iPhone is the "operating room" where all the raw data lives (meals, HealthKit, workouts). A small server is the "analysis lab" that runs AI brains locally (via CLI tools) and turns those raw signals into coaching insights. The app then shows you the results in a way that feels like a smart coach who actually knows your week.

It is not a typical app that just logs and charts. The code is built around a conversation loop: data goes in, the AI thinks, and the coach answers using your actual numbers. The app also tries to keep the AI relationship consistent over time (memory markers, profile evolution). That is the big idea.

## What it does really well
- Device-first data ownership is clear in the code. Most personal data stays on the phone, with the server holding daily summaries for insight generation.
- The iOS app uses actors and async patterns consistently, which makes concurrency safer and easier to reason about.
- The server has a clean "context builder" flow that stitches together insights, weekly summaries, body comp trends, and workouts.
- The code takes the AI coaching experience seriously: it has memory, profile evolution, and a steady pipeline for turning raw data into natural responses.
- There is a thoughtful split between "fast local AI calls" (Gemini direct mode) and "server mode" (Claude via CLI). That is a good hedge against latency, privacy, and cost.

## What feels excellent
- The coaching UX is clearly prioritized: lots of context prep, tool calling, and memory markers. The structure feels like it was built by someone who uses it.
- The training data pipeline is strong. Hevy sync + exercise history + set tracker gives the app real strength coaching leverage.
- The background scheduler is practical: heavy work runs out-of-band, keeping chat snappy.

## What does not make sense (code-level friction)
- Some iOS-to-server endpoints used for memory sync and profile sync do not exist on the server. That means those features silently fail even if the UI says "synced."
- Several server tools are wired to treat Hevy workouts like dictionaries, but the Hevy API wrapper returns typed objects. Those tools will crash or always return empty values.
- There are two server endpoints with the exact same path (/profile/import). That is ambiguous and will behave unpredictably.
- Demo data seeding runs automatically if the database is mostly empty. That is great for demos, but very risky for real users unless gated.
- Gemini privacy defaults are defined but never initialized, so "privacy on by default" actually means "everything off unless you flip a toggle." That can feel broken to a new user.

## Performance and efficiency notes (non-nerdy version)
- Every chat message can trigger multiple Hevy API calls. That is like running two lab panels for every single text. It works, but it is slower and wasteful.
- File-based JSON storage on the server is simple and great for a Pi, but it can get fragile if you ever run multiple server workers or add more users.

## AGI-pilled or nah?
Short answer: Yes, it is AGI-pilled in spirit. The code is intentionally loose about rigid schemas, leans on context, and assumes models will get better. It is built to "ride the model curve" instead of fighting it. The only thing holding it back from full AGI-pilled cred is the glue: some mismatched endpoints and brittle tool wiring. The vision is there; the plumbing needs tightening.

## What needs the most work next
- Align the iOS and server APIs (especially memory/profile sync). Right now, several calls go to endpoints that do not exist.
- Fix the server tool functions so they work with the actual Hevy data types.
- Add a clear switch for demo data seeding (build flag or explicit user action).
- Reduce duplicate Hevy calls per chat by caching results inside the server context builder.
- Add a tiny smoke-test script (even just a manual checklist) so core flows do not silently break.

## Final vibe check
This is an ambitious, coherent, AI-first fitness system. The architecture is bold and forward-looking, and the code already captures many of the ideas people keep talking about but rarely ship. It just needs some "surgical closure" on API alignment, tool reliability, and a few performance leaks. The bones are excellent.
