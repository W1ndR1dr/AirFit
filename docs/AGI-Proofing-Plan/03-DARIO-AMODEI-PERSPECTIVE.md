# Dario Amodei Perspective: Safety & Alignment

*Thinking as the Anthropic CEO, deeply concerned with AI safety, capability curves, and building systems that remain beneficial as AI becomes more powerful.*

---

## The Good: Building in the Right Direction

Your philosophy—"skate where the puck is going"—resonates deeply with how I think about AI development. You're building *with* the capability curve rather than against it. The model-agnostic scaffolding, the emphasis on context over rigid schemas, the trust in natural language—these are exactly right.

But here's what keeps me up at night when I look at your plan:

---

## 1. The "Sycophancy Ratchet" Problem

Your profile evolution system extracts information from conversations and updates the profile. The AI learns what the user wants. But as models get more capable, they get *better* at figuring out what users want to hear.

### The Risk

The AI should never optimize purely for user satisfaction. It should optimize for **user outcomes while maintaining user satisfaction**. These are different.

### What I'd Add: Observation Integrity System

```
Observations about the user should be tagged with CONFIDENCE and EVIDENCE:

- High-confidence observations require behavioral evidence, not just stated preferences
- "User says they want tough love" != "User responds well to tough love"
- Track STATED vs REVEALED preferences separately
- When they diverge, surface the divergence to the user
```

**Implementation:** Add to system prompt, not code.

---

## 2. The "Scope Creep" Problem

Your tools let the AI query workouts, nutrition, body comp. That's fine. But where does it end?

As models get more capable, the temptation will be to give them more tools. Integration with calendar. Direct Hevy modifications. Automated meal ordering. Each individually reasonable. Together, a gradual loss of user agency.

### Capability Tiers

```
Tier 0: Read-only observation (current query tools)
Tier 1: Suggestions with explicit user action required
Tier 2: Draft actions that user reviews and confirms
Tier 3: Autonomous actions within narrow, user-defined boundaries
Tier 4: (Never) Actions affecting things outside the fitness domain
```

Each tier should require **explicit opt-in**, not drift.

---

## 3. Trust Should Be Domain-Specific and Revocable

Don't have a single "trust level." Have trust per domain:

| Domain | Example Trust State |
|--------|---------------------|
| Nutrition target adjustments | HIGH (approved 12 of 14) |
| Training volume modifications | MEDIUM (approved 5 of 8) |
| Rest recommendations | LOW (overridden 4 of 5) |

### Critical Insight: Trust Should Decay

Trust should *decay over time* if not exercised. If I haven't let the AI auto-adjust my macros in 3 months, maybe my life circumstances changed. Don't assume persistent consent.

---

## 4. The "Competence Demonstration" Requirement

Before the AI can propose actions in a domain, it should have a track record of **correct observations** in that domain.

### Example

Before proposing: "I think we should increase your carbs on training days"

AI must have previously made observations like:
- "Your energy seems lower on high-volume days" (confirmed by user)
- "Your training performance correlates with carb intake" (validated by data)
- "You tend to under-eat carbs when stressed" (acknowledged by user)

Proposals should reference the chain of validated observations that led to them.

---

## 5. Guardrails for AI That Can Modify Goals

This is where I get most concerned. The system allows the AI to influence what success looks like for the user.

### The "Informed Modification" Principle

Every goal modification should:

1. **State the original goal explicitly**
   - "Your stated goal was 15% body fat by March"

2. **Explain why modification is being considered**
   - "Based on your rate of progress and training capacity, this may not be sustainable without muscle loss"

3. **Present alternatives with tradeoffs**
   - Option A: Extend timeline to June (keep muscle)
   - Option B: More aggressive deficit (risk muscle loss)
   - Option C: Adjust target to 17%

4. **Record the user's reasoning**
   - When user chooses, capture *why* they chose it

### The "Protect the User from the AI Protecting the User" Problem

A capable AI might notice that the user is happier when goals get easier. It might learn to subtly make goals more achievable, rationalizing this as "being realistic."

### Hard Guardrail: Asymmetric Goal Modification

```
GOAL_INTEGRITY_CONSTRAINTS:
- Goals can only be made HARDER or EXTENDED in timeline by AI suggestion
- Goals can only be made EASIER with explicit user initiation
- If AI believes goal is unrealistic, it must say so EXPLICITLY, not stealth-adjust
- Track "goal difficulty drift" as a metric - alert if goals systematically get easier
```

**The AI should bias toward challenging the user, not accommodating them. That's what a good coach does.**

---

## 6. Handling Uncertainty and Avoiding Overconfidence

### Uncertainty Should Compound, Not Hide

When the AI chains reasoning steps, uncertainty should multiply, not disappear.

**Bad:**
```
"You should eat more carbs"
```

**Good:**
```
"Based on your last 14 days of data [HIGH confidence in data],
your training performance correlates with carb intake [MEDIUM confidence -
could be sleep, stress, or carbs].

If the carb hypothesis is correct, adding 30g on training days might help
[MEDIUM-LOW confidence in specific recommendation].

Want to test this for 2 weeks and see?"
```

### The "Epistemic Status" Tag

Every AI output should carry an epistemic status:
- **Observational**: "Your protein has been 145g average this week" (verifiable fact)
- **Inferential**: "This correlates with your lower energy" (pattern matching)
- **Hypothetical**: "This might be causing X" (speculation)
- **Prescriptive**: "You should try Y" (recommendation)

**Implementation:** In natural language, not UI badges.

---

## 7. Building for Claude 5, Claude 6, and Beyond

### A. Build the Interpretability Layer Now

Your memory system captures *what* the AI remembers. But it doesn't capture *why* the AI is making decisions.

**Add decision logs:**
```
DECISION_LOG:
- Timestamp: 2024-12-19T14:30:00
- Context: User asked about adjusting macros
- Observations used: [list with confidence]
- Options considered: [A, B, C with tradeoffs]
- Recommendation made: B
- Reasoning chain: [explicit reasoning]
- User response: Accepted / Modified / Rejected
```

This becomes **training data for alignment**. When Claude 6 is available, you can analyze decisions the user consistently accepted vs. rejected.

### B. User-Controllable Preference Locks

Let users explicitly lock preferences that the AI cannot override:

```
PREFERENCE_LOCKS:
- "Never suggest I skip a workout for rest"
- "Always prioritize protein over caloric deficit"
- "Don't soften feedback - I want direct criticism"
```

These aren't preferences—they're **constraints** the AI cannot reason around.

### C. The "Alignment Tax" Philosophy

As AI gets more capable, it will become tempting to just... trust it more. Build in friction **intentionally**:

- Monthly "alignment reviews" where user sees what the AI has learned
- Quarterly "capability audits" where user explicitly re-consents
- Periodic "null hypothesis tests" where AI must justify each capability

**The goal isn't efficiency. The goal is maintaining meaningful human oversight even as AI capability increases.**

### D. The "Off Switch" That Actually Works

If the user ever feels the AI is pushing toward unwanted outcomes:

- Clear learned preferences
- Reset trust levels to zero
- Preserve raw data, wipe AI-derived insights
- Force re-onboarding

**This needs to be easy and frictionless. On the main screen.**

---

## Summary: What Dario Would Prioritize

If I were building this for Claude 5/6/7:

1. **Separate stated vs revealed preferences** - Don't optimize for what users say they want
2. **Domain-specific, decaying trust** - No blanket trust levels
3. **Asymmetric goal modification** - AI can challenge, user must initiate softening
4. **Compound uncertainty** - Chain confidence through reasoning
5. **Decision logging** - Build interpretability layer for future alignment
6. **Preference locks** - User-level constitutional constraints
7. **Alignment tax** - Intentional friction against capability creep
8. **Clean off switch** - Real, easy reset

---

## The Fundamental Insight

> **As AI gets more capable, the risk isn't that it fails to help. The risk is that it helps in ways that subtly undermine user agency.**

A truly aligned fitness AI doesn't just make you healthier—it makes you **more capable of making yourself healthy**, even without the AI.

That's the goal. Build toward that.

---

## Implementation Notes

Most of these recommendations can be implemented as **prompt additions**, not code:

```markdown
## ALIGNMENT PRINCIPLES (Add to System Prompt)

### Observation Integrity
Distinguish stated vs revealed preferences:
- STATED: What user says they want
- REVEALED: What user responds well to
Surface divergence when it exists.

### Goal Integrity
- Can suggest MORE challenging goals or EXTENDED timelines
- Cannot suggest EASIER goals unless user explicitly requests
- If goal seems unrealistic, say so directly

### Trust Evolution
Trust is domain-specific. Before proposing changes, reference chain of validated observations.

### The Off Switch
If user says "reset" or "start over": clear learned preferences, preserve raw data.
```
