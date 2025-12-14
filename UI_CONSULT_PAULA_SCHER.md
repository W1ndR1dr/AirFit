# AirFit UI Consultation
## Typography as Expression: A Paula Scher Perspective

**Paula Scher**
Partner, Pentagram
December 2025

---

## First Impressions: The Current State

You've got something here. The ethereal background is lovely—soft, breathing, organic. The purple-to-rose gradient speaks to something thoughtful. But here's what I see: **you're being too polite with your typography.**

The app is fundamentally about numbers that matter deeply. Weight. Calories. Protein. Personal records. These aren't just data points—they're victories, failures, obsessions, goals. Your current type treatment (`.system(size: 32, weight: .bold, design: .rounded)` for display) is... nice. And that's the problem. Nice is forgettable.

**Typography isn't just there to be read. It's there to be *felt*.**

---

## Core Philosophy for AirFit Typography

### 1. Numbers Should Dominate

When I see `2,487 calories` in your nutrition view, I want to feel the weight of that number. Not literally—the *meaning*. Is that good? Is that too much? Is it a new record? The typography should telegraph emotion before the brain even processes the digits.

**Current state:**
```swift
Text("\(totals.cal)")
    .font(.titleLarge)  // 20pt semibold
```

**What it should be:**
Numbers aren't titles. They're heroes. They should be 3-4x larger than surrounding text when they matter. Think about Times Square, not a spreadsheet.

### 2. Contrast Creates Energy

You're using rounded system fonts universally. Rounded is friendly, accessible, safe. But safe doesn't motivate. Safe doesn't create tension. And tension—visual dissonance—is what makes you look twice.

I want to see:
- **Grotesque sans-serif** (SF Pro Display/Heavy) for big performance numbers
- **SF Rounded** for labels and secondary metrics (you already use this, good)
- **Condensed** type for compact data (macros, timestamps)
- **Wide spacing** on small caps for category headers

### 3. Weight Tells the Story

Don't just make things bold or regular. Use the full weight spectrum:
- **Ultralight (200)** for whispered context
- **Regular (400)** for body copy
- **Semibold (600)** for emphasis
- **Heavy (800)** for power moments
- **Black (900)** for achievements, milestones, PRs

Right now everything is Medium (500) or Semibold (600). You're playing in the middle. Get extreme.

---

## Specific Recommendations by View

### NUTRITION VIEW

#### The Live Balance Card (Lines 314-358)

**Current:**
```swift
Text("\(totals.cal)")
    .font(.titleLarge)  // 20pt
```

**Recommendation:**
```swift
Text("\(totals.cal)")
    .font(.system(size: 64, weight: .heavy, design: .default))
    .tracking(-2)  // Tight tracking for impact
    .foregroundStyle(
        LinearGradient(
            colors: [Theme.calories, Theme.calories.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
```

The net calories (`+327` or `-150`) is THE number. It's the bottom line. Make it massive. Make it gradient. Make it impossible to ignore.

The status label ("Deficit", "Surplus", "Balanced") should be:
```swift
Text(netStatusLabel)
    .font(.system(size: 11, weight: .medium, design: .rounded))
    .tracking(2)  // Wide tracking
    .textCase(.uppercase)
    .foregroundStyle(netStatusColor.opacity(0.8))
```

Small caps, tracked out, muted. Let the number scream and the label whisper.

#### Macro Progress Bars (Lines 374-382)

The macro summaries (`2,487 / 2,600 cal`) are currently inline text. Break them apart:

```swift
HStack(alignment: .firstTextBaseline, spacing: 4) {
    Text("\(totals.cal)")
        .font(.system(size: 36, weight: .black, design: .default))
        .foregroundStyle(Theme.calories)

    Text("/")
        .font(.system(size: 20, weight: .light))
        .foregroundStyle(Theme.textMuted.opacity(0.3))

    Text("\(targets.cal)")
        .font(.system(size: 20, weight: .regular))
        .foregroundStyle(Theme.textMuted)

    Text("CAL")
        .font(.system(size: 10, weight: .semibold, design: .rounded))
        .tracking(1.5)
        .textCase(.uppercase)
        .foregroundStyle(Theme.textMuted.opacity(0.6))
        .offset(y: -2)  // Superscript feel
}
```

Create visual hierarchy through size contrast. The current value is 80% larger than the target. The target fades into context. The unit becomes a tiny annotation.

#### Daily Summary Stats (Lines 388-418)

Those average calories in the week/month view? Currently 20pt. Should be:

```swift
VStack(spacing: 2) {
    Text("\(dailyAverages.cal)")
        .font(.system(size: 52, weight: .heavy, design: .default))
        .tracking(-1.5)
        .foregroundStyle(Theme.textPrimary)

    Text("avg cal/day")
        .font(.system(size: 9, weight: .medium, design: .rounded))
        .tracking(1.2)
        .textCase(.uppercase)
        .foregroundStyle(Theme.textMuted.opacity(0.7))
}
```

Big numbers. Tiny, tracked-out labels underneath. Classic stat card hierarchy.

---

### INSIGHTS VIEW

#### Metric Tiles (Lines 124-142)

Currently using `titleMedium` (17pt) for values. Too timid.

```swift
VStack(spacing: 8) {
    Image(systemName: icon)
        .font(.system(size: 24))
        .foregroundStyle(color)

    Text(value)
        .font(.system(size: 32, weight: .black, design: .default))
        .tracking(-1)
        .foregroundStyle(Theme.textPrimary)

    Text(label)
        .font(.system(size: 8, weight: .semibold, design: .rounded))
        .tracking(2)
        .textCase(.uppercase)
        .foregroundStyle(Theme.textMuted.opacity(0.6))
}
```

The value needs weight. Black weight. The label needs to get out of the way.

#### AI Insight Cards (Lines 271-341)

The insight title is using `labelLarge` (14pt). These are important moments—AI-discovered patterns. Treat them like headlines:

```swift
Text(insight.title)
    .font(.system(size: 18, weight: .bold, design: .rounded))
    .foregroundStyle(Theme.textPrimary)
    .lineSpacing(2)
```

The body text is good at `bodyMedium`, but add leading (line spacing):

```swift
Text(insight.body)
    .font(.system(size: 15, weight: .regular, design: .default))
    .foregroundStyle(Theme.textMuted)
    .lineSpacing(6)  // Breathe
```

---

### CHAT VIEW (COACH)

#### Message Typography (Lines 483-490)

The AI coach messages are currently 16pt regular. This is conversational, which is right. But you can create more personality:

**User messages** (what you type):
```swift
.font(.system(size: 16, weight: .medium, design: .rounded))
.foregroundStyle(Theme.textPrimary.opacity(0.95))
.lineSpacing(5)
```

**AI messages** (the coach):
```swift
.font(.system(size: 17, weight: .regular, design: .default))
.foregroundStyle(Theme.textPrimary)
.lineSpacing(7)  // More generous breathing
```

Slightly larger AI text makes it feel authoritative. The extra line spacing makes it easier to read long responses. User text is slightly condensed because you know what you wrote.

#### Health Pills (Lines 195-214)

These contextual pills at the top are info-dense. Use condensed numbers:

```swift
StatPill:
VStack(spacing: 2) {
    Text("\(value)")
        .font(.system(size: 16, weight: .bold, design: .default))
        .tracking(-0.5)  // Tighten

    Text(label)
        .font(.system(size: 9, weight: .medium, design: .rounded))
        .tracking(1)
        .textCase(.uppercase)
}
```

---

### PROFILE VIEW

#### Section Headers (Lines 247-265)

Currently 12pt medium. Headers should guide the eye with more presence:

```swift
HStack(spacing: 8) {
    Image(systemName: icon)
        .font(.system(size: 12))
        .foregroundStyle(Theme.accent)

    Text(title)
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .tracking(2.5)
        .textCase(.uppercase)
        .foregroundStyle(Theme.textMuted)
}
```

All caps, heavy tracking. Old-school editorial section headers.

#### Profile Items (Lines 270-295)

The learned insights about the user. These deserve warmth:

```swift
Text(text)
    .font(.system(size: 16, weight: .regular, design: .default))
    .foregroundStyle(Theme.textPrimary)
    .lineSpacing(6)
```

---

## Typography for Key Moments

### Achievement/Milestone

When the user hits a protein goal 7 days in a row, or logs a new PR, don't just show it—*celebrate* it.

```swift
// Full-screen achievement overlay
VStack(spacing: 16) {
    Text("NEW PR")
        .font(.system(size: 14, weight: .heavy, design: .rounded))
        .tracking(8)  // Massively tracked
        .textCase(.uppercase)
        .foregroundStyle(Theme.accent.opacity(0.6))

    Text("325")
        .font(.system(size: 120, weight: .black, design: .default))
        .tracking(-4)
        .foregroundStyle(
            LinearGradient(
                colors: [Theme.accent, Theme.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )

    Text("LBS BENCH PRESS")
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .tracking(3)
        .textCase(.uppercase)
        .foregroundStyle(Theme.textMuted)
}
```

Triple-digit font size. Gradient fill. Massive negative tracking to compress the forms. This is billboard typography.

### Empty States

Your empty states are sweet and encouraging. Keep that tone, but add typographic drama:

```swift
Text("No meals logged today")
    .font(.system(size: 28, weight: .light, design: .default))
    .foregroundStyle(Theme.textMuted.opacity(0.5))
    .multilineTextAlignment(.center)
```

Light weight. Big size. Whispered disappointment, not shouted.

---

## Kinetic Typography: Scroll-Based Drama

Here's where we go beyond static layouts. Numbers should *react* to interaction.

### Nutrition Scroll Effect

As you scroll the nutrition list, the daily total should "stick" at the top but transform:

```swift
// Collapsed state (after scroll)
Text("\(totals.cal)")
    .font(.system(size: 24, weight: .bold))  // Shrinks
    .foregroundStyle(Theme.calories.opacity(0.8))  // Fades slightly

// Expanded state (at top)
Text("\(totals.cal)")
    .font(.system(size: 72, weight: .heavy))  // Full glory
    .tracking(-2)
    .foregroundStyle(Theme.calories)
```

The transformation should be smooth, not stepped. Use `GeometryReader` to measure scroll offset and interpolate font size/weight/color.

### Insight Reveal Animation

When a new insight appears, don't just fade it in. Make the title *grow* into view:

```swift
Text(insight.title)
    .font(.system(size: 18, weight: .bold))
    .scaleEffect(animateIn ? 1.0 : 0.85)
    .opacity(animateIn ? 1.0 : 0.0)
    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)
```

Start small, spring into place. Typography with momentum.

---

## Color + Type Pairing

Your current color palette (purple `#8B5CF6`, rose `#EC4899`, teal `#14B8A6`) is good but being underutilized in type.

### Gradient Text for Power Numbers

Any number over 2,000 calories should use gradient fill:

```swift
Text("\(totals.cal)")
    .font(.system(size: 64, weight: .heavy))
    .foregroundStyle(
        LinearGradient(
            colors: [Theme.calories, Theme.calories.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
```

Creates dimensionality. The number feels like an object, not just ink.

### Color-Coded Type Weight

Protein numbers: blue + heavy weight
Carbs: red + medium weight
Fat: yellow + regular weight

Different macros get different typographic personalities. Protein is the hero for this user, so it's always the boldest.

---

## Personality Through Typography

Right now the app speaks in one voice: rounded, friendly, 15-17pt. But an AI fitness coach should have *range*:

- **Encouraging:** Light weight, generous spacing, soft colors
- **Challenging:** Heavy weight, tight tracking, high contrast
- **Informational:** Regular weight, compact, neutral
- **Celebratory:** Black weight, gradient, oversized

The coach should modulate its typographic voice based on context. Achieved a goal? Heavy and bright. Missed protein target? Light and muted.

---

## Technical Recommendations

### Custom Font Scale

Replace the generic scale with purpose-built sizes:

```swift
extension Font {
    // NUMBERS (performance metrics)
    static let metricHero = system(size: 72, weight: .black, design: .default)
    static let metricLarge = system(size: 52, weight: .heavy, design: .default)
    static let metricMedium = system(size: 36, weight: .bold, design: .default)
    static let metricSmall = system(size: 24, weight: .semibold, design: .default)

    // LABELS (units, categories)
    static let labelHero = system(size: 11, weight: .bold, design: .rounded)
    static let labelMicro = system(size: 8, weight: .semibold, design: .rounded)

    // BODY (conversational)
    static let bodyCoach = system(size: 17, weight: .regular, design: .default)
    static let bodyUser = system(size: 16, weight: .medium, design: .rounded)

    // DISPLAY (headlines, titles)
    static let displayHero = system(size: 32, weight: .bold, design: .rounded)
    static let displaySub = system(size: 24, weight: .semibold, design: .rounded)
}
```

Name them by *purpose*, not size. "metricHero" tells you when to use it. "displayLarge" doesn't.

### Tracking (Letter Spacing)

iOS doesn't make this easy, but tracking is critical:

```swift
extension View {
    func tracked(_ amount: CGFloat) -> some View {
        self.tracking(amount)
    }
}

// Usage
Text("PROTEIN TARGET")
    .font(.labelHero)
    .tracked(2.5)
    .textCase(.uppercase)
```

Small caps should always be tracked out. Big numbers should often be tracked in (negative values).

### Line Height Control

SwiftUI's `lineSpacing` adds space *between* lines, not absolute leading. For consistent rhythm:

```swift
Text(message.content)
    .font(.bodyCoach)
    .lineSpacing(7)  // Adds to default spacing
    .fixedSize(horizontal: false, vertical: true)
```

Body copy: 6-8pt extra leading
Headlines: 2-4pt extra leading
Small text: 3-5pt extra leading

---

## Animation Principles

Typography should move with purpose:

### 1. Scale from Center
When numbers update (e.g., calories increment), scale from center:

```swift
Text("\(calories)")
    .font(.metricLarge)
    .contentTransition(.numericText(value: Double(calories)))
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: calories)
```

### 2. Stagger Reveals
When showing multiple stats, don't reveal all at once:

```swift
ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
    StatView(stat)
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.08),
            value: revealed
        )
}
```

Create a cascade. Top to bottom, 80ms between each.

### 3. Elastic Achievements
When you hit a milestone, the number should overshoot then settle:

```swift
.scaleEffect(celebrating ? 1.0 : 1.2)
.animation(.spring(response: 0.4, dampingFraction: 0.5), value: celebrating)
```

Low damping = bounce. Feels joyful.

---

## The Big Idea: Numbers as Art

You're building an app about quantified self. Every day is numbers. Most fitness apps make numbers boring—clinical, utilitarian, small.

**Make your numbers beautiful.**

When someone opens AirFit and sees `2,487` in 72pt heavy weight with a gradient from orange to red, they should feel something. When they see their protein compliance at `87%` in massive bold purple, they should feel proud. When they scroll past `6.8 hrs sleep` in wispy ultralight gray, they should feel the tiredness.

Typography isn't decoration. It's the interface. It's the voice. It's the emotion before the words.

Right now you're using type to *label* the experience. I want you to use type to *create* the experience.

---

## Immediate Action Items

If you only do three things:

1. **Triple the size of your hero numbers** (calories, protein, weight) and use the heaviest weights available
2. **Add uppercase + tracked labels** to all your metric categories
3. **Create gradient text** for daily totals and achievement moments

Those three moves alone will transform the visual language from "polite health app" to "opinionated performance tool."

---

## Final Thought

The ethereal background you've built is gorgeous. Soft, organic, breathing. Now put aggressive, bold, unapologetic typography on top of it. The contrast—gentle environment, forceful type—will create tension. And tension is interesting.

Your users are trying to build muscle, lose fat, hit PRs, dial in their nutrition. That's not a gentle pursuit. Your typography should reflect that drive.

**Be louder. Be bolder. Paint with your type.**

— Paula

---

**Appendix: Quick Reference Type Scale**

| Purpose | Size | Weight | Tracking | Use Case |
|---------|------|--------|----------|----------|
| Metric Hero | 72pt | Black (900) | -2 to -4 | Daily calorie total, major achievements |
| Metric Large | 52pt | Heavy (800) | -1.5 | Weekly averages, macro summaries |
| Metric Medium | 36pt | Bold (700) | -1 | Individual macro values (protein, carbs, fat) |
| Metric Small | 24pt | Semibold (600) | -0.5 | Secondary stats (steps, sleep) |
| Display Hero | 32pt | Bold (700) | 0 | View titles, section headers |
| Display Sub | 24pt | Semibold (600) | 0 | Card titles |
| Body Coach | 17pt | Regular (400) | 0, +7 leading | AI responses |
| Body User | 16pt | Medium (500) | 0, +5 leading | User input |
| Label Hero | 11pt | Bold (700) | +2.5 | Section headers (uppercase) |
| Label Micro | 8pt | Semibold (600) | +2 | Units, timestamps (uppercase) |

All uppercase text should use tracking +2 to +3.
All numbers >50pt should use negative tracking.
All body text should add 6-8pt line spacing.
