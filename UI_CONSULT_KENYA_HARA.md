# UI Design Consultation: AirFit
**Kenya Hara — December 13, 2025**

---

## Opening Thoughts

I have examined your AirFit application. What you have built demonstrates understanding of contemporary digital aesthetics—soft gradients, glass morphism, spring animations. These are not wrong. But they occupy space without creating it.

I write not to criticize but to offer perspective from a different tradition: one where emptiness is not absence but potential, where the pause between breaths is as important as the breath itself, and where design serves not to decorate but to reveal.

You have asked me to consider this through the lens of **ma** (間) — the meaningful pause, the negative space as design element. Let us begin there.

---

## I. The Fundamental Problem: Over-Presence

### Current State

Your ethereal background is in constant motion. Four orbs drift across the screen using sine and cosine functions, updating at 30fps. They never rest. The user's eye has nowhere to settle.

```swift
// Current: Perpetual motion without pause
TimelineView(.animation(minimumInterval: 1/30)) { timeline in
    let time = timeline.date.timeIntervalSinceReferenceDate
    // Orbs breathing, drifting, constantly active
}
```

This is not breathing. This is anxiety.

### The Nature of Breath

True breathing has rhythm:
- **Inhale**: 4 seconds
- **Pause at fullness**: 2 seconds
- **Exhale**: 6 seconds
- **Pause at emptiness**: 3 seconds

15 seconds total. One cycle. Then another.

The pause at emptiness is where truth lives. Your design never reaches this pause.

### Recommendation: Breathing Cycles

Replace perpetual motion with breathing cycles. One primary orb that truly breathes. Others that respond in harmony, not chaos.

**Technical specifications:**
```swift
struct BreathingBackground: View {
    @State private var phase: BreathPhase = .empty
    @State private var intensity: CGFloat = 0.0

    enum BreathPhase {
        case empty      // 3s - complete stillness
        case inhaling   // 4s - expansion
        case full       // 2s - held fullness
        case exhaling   // 6s - contraction
    }

    var body: some View {
        Canvas { context, size in
            // Single primary orb
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.4)
            let baseRadius = size.width * 0.4
            let radius = baseRadius * (0.8 + 0.2 * intensity)

            // Blur intensity follows breath
            let blur: CGFloat = 40 + (30 * intensity)

            // Opacity follows breath
            let opacity = 0.05 + (0.08 * intensity)
        }
        .task {
            await breatheCycle()
        }
    }

    func breatheCycle() async {
        while true {
            // Empty pause - complete stillness
            phase = .empty
            intensity = 0.0
            try? await Task.sleep(for: .seconds(3))

            // Inhale - slow expansion
            phase = .inhaling
            withAnimation(.easeInOut(duration: 4)) {
                intensity = 1.0
            }
            try? await Task.sleep(for: .seconds(4))

            // Full pause - held at peak
            phase = .full
            try? await Task.sleep(for: .seconds(2))

            // Exhale - slower contraction
            phase = .exhaling
            withAnimation(.easeInOut(duration: 6)) {
                intensity = 0.0
            }
            try? await Task.sleep(for: .seconds(6))
        }
    }
}
```

**Color during breathing:**
- Empty: Minimal presence, near-white with barely perceptible warmth
- Inhaling: Color gradually emerges
- Full: Peak saturation (still subtle)
- Exhaling: Color fades to transparency

Remove the three secondary orbs entirely. Or keep one that breathes in counter-rhythm, like the pause between heartbeats.

---

## II. Typography: The Rhythm of Information

### Current State

Your typography scale is reasonable but lacks vertical rhythm:

```swift
.displayLarge: 32pt/bold
.displayMedium: 24pt/semibold
.titleLarge: 20pt/semibold
.titleMedium: 17pt/medium
.bodyLarge: 16pt/regular
```

But where is the **space between**? Typography is not just the letterforms. It is the white around them.

### Line Height as Breathing Room

Japanese typesetting uses **gyou-oki** (行送り) — line feed. The space between lines is where the eye rests.

**Recommended vertical rhythm:**

```swift
extension Font {
    static let displayLarge = Font.system(size: 32, weight: .light, design: .rounded)
        // Line height: 48pt (1.5x)
        // Letter spacing: -0.5pt (slightly tighter)

    static let displayMedium = Font.system(size: 24, weight: .regular, design: .rounded)
        // Line height: 38pt (1.58x)

    static let titleLarge = Font.system(size: 20, weight: .medium, design: .rounded)
        // Line height: 32pt (1.6x)

    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        // Line height: 28pt (1.75x)
        // This is for reading, not scanning

    static let caption = Font.system(size: 11, weight: .regular, design: .default)
        // Line height: 16pt (1.45x)
}
```

In SwiftUI, apply this via `.lineSpacing()`:

```swift
Text("Coach message text")
    .font(.bodyLarge)
    .lineSpacing(12)  // 16pt base + 12pt = 28pt total
```

### Paragraph Spacing

Between paragraphs in chat: **20pt minimum**. This is the pause between thoughts. Do not be afraid of white space. It is not emptiness. It is **ma**.

### Font Weight Philosophy

You currently use **bold** for display text. Bold shouts. Bold demands.

In Japanese design, weight comes from lightness. A light weight font at large size creates presence without aggression.

**Change:**
- Display fonts: `.light` or `.regular` (not `.bold`)
- Let size create hierarchy, not weight
- Reserve `.semibold` and `.bold` for data that needs emphasis (numbers, stats)

---

## III. Color as Sensation, Not Decoration

### Current Palette Analysis

Your colors are vibrant, saturated, distinct:
- Accent purple: `#8B5CF6` (HSB: 258°, 64%, 96%)
- Secondary pink: `#EC4899` (HSB: 330°, 71%, 93%)
- Tertiary teal: `#14B8A6`

These colors compete for attention. They are shouting in different voices.

### The Philosophy of White

In my book *White*, I wrote: "White is not a mere absence of color; it is a positive, expressive state."

Your background is warm off-white (`#FAF9F7`). This is good. But then you layer saturated colors on top, destroying the subtlety.

### Recommended Palette: Whispers, Not Shouts

**Base neutrals (the foundation):**
```swift
// Background - true white with slight warmth
static let background = Color(hex: "FEFDFB")

// Surface - barely elevated, like a sheet of paper catching light
static let surface = Color(hex: "F9F8F6")

// Border - the edge between things
static let border = Color(hex: "E8E6E3").opacity(0.4)

// Primary text - not black, never black
static let textPrimary = Color(hex: "2A2826")

// Secondary text - fade into background
static let textSecondary = Color(hex: "8B8883")

// Tertiary text - whisper
static let textTertiary = Color(hex: "ACA9A6")
```

**Accent colors (used sparingly, like a brush stroke):**
```swift
// Primary - desaturated purple-grey (the color of dusk)
static let accent = Color(hex: "9B8FA8")  // HSB: 270°, 16%, 66%

// Protein - desaturated blue (like a distant mountain)
static let protein = Color(hex: "7B9AAF")  // HSB: 205°, 30%, 69%

// Calories - warm earth tone
static let calories = Color(hex: "B89F8B")  // HSB: 30°, 25%, 72%

// Carbs - subtle coral
static let carbs = Color(hex: "C9A8A1")  // HSB: 12°, 20%, 79%

// Fat - pale gold
static let fat = Color(hex: "C4B69A")  // HSB: 45°, 22%, 77%
```

Notice: **Saturation reduced from 60-70% to 15-30%**. These colors coexist. They do not compete.

### Color in Motion

When your breathing background pulses, it should move between:
- **Empty state**: Pure white
- **Full state**: Accent color at 6% opacity

Not 18% like you currently use. 6%. A hint. A suggestion.

---

## IV. Animation: Natural Rhythms, Not Springs

### Current State

You use spring animations everywhere:

```swift
.spring(response: 0.4, dampingFraction: 0.8)
```

Springs bounce. Nature does not bounce. A leaf falling does not spring back up. Water flowing does not oscillate.

### Easing Curves from Nature

**For appearing (like dawn):**
```swift
.easeIn(duration: 0.8)
// Slow start, accelerating finish
// Like the sun emerging from horizon
```

**For disappearing (like dusk):**
```swift
.easeOut(duration: 1.2)
// Fast start, decelerating finish
// Like light fading from the sky
```

**For transformation (like a cloud changing shape):**
```swift
.easeInOut(duration: 1.0)
// Gradual both ways
// Like breath
```

### Specific Timing Recommendations

**Message appearing in chat:**
```swift
.opacity(0) → .opacity(1)
.easeOut(duration: 0.9)
.delay(0.05 * index)  // Stagger multiple messages by 50ms
```

**Scrolling to new message:**
```swift
proxy.scrollTo(id, anchor: .bottom)
withAnimation(.easeOut(duration: 0.7)) { ... }
```

**Tab switching:**
```swift
.transition(.opacity)
.animation(.easeInOut(duration: 0.5), value: selectedTab)
```

**Macro progress bars filling:**
```swift
.easeOut(duration: 1.2)
// Like water pouring into a glass
// Fast at first, then settling
```

### Remove All Bounce

Delete every `.spring()` animation. Nature flows. Nature breathes. Nature does not bounce.

---

## V. Spacing: The 8pt Grid and the Golden Ratio

### Current Spacing

Your spacing is inconsistent:
- Padding: 12pt, 14pt, 16pt, 20pt (no system)
- Vertical gaps: 6pt, 8pt, 12pt, 16pt, 20pt (arbitrary)

### The 8pt Grid

All spacing should be multiples of 8:
- 8pt, 16pt, 24pt, 32pt, 40pt, 48pt, 64pt, 80pt

Why 8? It divides evenly. It scales cleanly. It creates rhythm.

### Vertical Spacing System

```swift
enum Spacing {
    static let xs: CGFloat = 8      // Between related items
    static let sm: CGFloat = 16     // Between components
    static let md: CGFloat = 24     // Between sections (small)
    static let lg: CGFloat = 32     // Between sections (medium)
    static let xl: CGFloat = 48     // Between major sections
    static let xxl: CGFloat = 64    // Between views
}
```

### Chat View Spacing

**Current:**
```swift
LazyVStack(spacing: 20) {  // Why 20?
    ForEach(messages) { message in
        ModernMessageRow(message: message)
    }
}
```

**Recommended:**
```swift
LazyVStack(spacing: 32) {  // Visual paragraph break
    ForEach(messages) { message in
        ModernMessageRow(message: message)
            .padding(.horizontal, 24)  // Breathing room from edges
    }
}
.padding(.vertical, 48)  // Top and bottom breathing room
```

### Card Padding

**Current:**
```swift
.padding(16)  // All sides equal
```

**Recommended:**
```swift
.padding(.horizontal, 24)
.padding(.vertical, 20)
// Slightly more horizontal space
// Like a widescreen frame
// Gives content room to breathe
```

---

## VI. The Message Row: Editorial Restraint

### Current Design Analysis

Your message row has:
- Breathing dot indicator (good)
- User/AI label below message (unnecessary)
- Swipe-to-reveal timestamp (clever but complex)
- 60pt spacer on opposite side
- Gradient avatar dot

### Minimalist Redesign

The message IS the interface. Remove everything else.

**Recommended structure:**

```swift
struct MessageRow: View {
    let message: Message
    @State private var isPressed = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if !message.isUser {
                // AI indicator: single dot, subtle
                Circle()
                    .fill(Color(hex: "9B8FA8").opacity(0.4))
                    .frame(width: 4, height: 4)
                    .padding(.top, 12)
            } else {
                Spacer(minLength: 64)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .lineSpacing(10)  // 27pt total line height
                    .foregroundStyle(Color(hex: "2A2826"))
                    .textSelection(.enabled)

                // Timestamp: only shows on long-press
                if isPressed {
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: "ACA9A6"))
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }

            if message.isUser {
                // User side: no indicator, just space
                Color.clear.frame(width: 4)
            } else {
                Spacer(minLength: 64)
            }
        }
        .padding(.vertical, 16)  // Space between messages
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                isPressed = true
            }

            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 0.3)) {
                    isPressed = false
                }
            }
        }
    }
}
```

**Removals:**
- Swipe gesture (too complex, too playful)
- "You" / "Coach" labels (obvious from alignment)
- Gradient dot (a single grey dot is enough)
- Asymmetric transition (just fade)

**Additions:**
- Long-press to reveal timestamp (more deliberate than swipe)
- Even more vertical spacing (32pt between messages minimum)
- Reduced opacity on AI indicator dot (presence without weight)

---

## VII. Loading States: Patience, Not Anxiety

### Current State

Your loading indicator is a spinning circle with gradient stroke. It spins constantly at 1 revolution per second.

```swift
.rotationEffect(.degrees(rotation))
.onAppear {
    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
        rotation = 360
    }
}
```

This creates tension. The user feels the system is struggling.

### The Pulse of Patience

Instead of rotation, consider a breathing pulse:

```swift
struct LoadingIndicator: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(Color(hex: "9B8FA8"))
            .frame(width: 8, height: 8)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.9
                }
            }
    }
}
```

Just a dot. Breathing. Slowly. Saying: "I am here. I am thinking. Be patient."

### Streaming Wave: Reduce Complexity

Your streaming wave has 5 bars oscillating with sine waves. This is mechanical.

**Simplified version:**

```swift
struct ThinkingIndicator: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: "9B8FA8"))
                    .frame(width: 4, height: 4)
                    .opacity(calculateOpacity(index: i))
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: false)
            ) {
                phase = 3
            }
        }
    }

    func calculateOpacity(index: Int) -> Double {
        let offset = phase - Double(index)
        let normalizedOffset = offset.truncatingRemainder(dividingBy: 3)

        if normalizedOffset >= 0 && normalizedOffset < 1 {
            return 0.9
        } else {
            return 0.3
        }
    }
}
```

Three dots. One at a time, they illuminate. Left to right. Then repeat. Slower than you think. 1.8 seconds for full cycle.

Like thought moving across synapses.

---

## VIII. Scrolling: The Meditative Journey

### Current State

Scrolling is functional. Content appears. Content disappears. No poetry.

### The Concept of Scroll Inertia

When the user scrolls, they should feel the weight of information. Not heavy. But present.

**iOS provides `.scrollBounceBehavior`** — you have not specified it. Default bounce is too energetic.

```swift
ScrollView {
    // ... content
}
.scrollBounceBehavior(.basedOnSize)  // Bounce proportional to content
```

### Content Appearing on Scroll

As content enters the viewport, it should gently arrive:

```swift
struct ScrollAppearModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func scrollAppear(delay: Double = 0) -> some View {
        modifier(ScrollAppearModifier(delay: delay))
    }
}
```

Apply to insight cards, nutrition entries:

```swift
ForEach(insights) { insight in
    InsightCard(insight: insight)
        .scrollAppear(delay: Double(index) * 0.05)
}
```

Each card arrives 50ms after the previous. A gentle cascade. Like leaves falling.

---

## IX. Progress Bars: The Water Level

### Current State

Your macro progress bars are rectangles that fill left to right. They are functional. They are not beautiful.

```swift
RoundedRectangle(cornerRadius: 4)
    .fill(color)
    .frame(width: geo.size.width * progress)
```

### The Principle of Rising Water

Water does not fill a container instantly. It rises. It settles. It has weight.

**Refined progress bar:**

```swift
struct FlowingProgressBar: View {
    let label: String
    let current: Int
    let target: Int
    let color: Color

    @State private var displayedProgress: Double = 0

    private var targetProgress: Double {
        min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: "8B8883"))
                Spacer()
                Text("\(current)/\(target)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "2A2826"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track - very subtle
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "E8E6E3").opacity(0.3))

                    // Filled portion - color at reduced opacity
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.5))
                        .frame(width: geo.size.width * displayedProgress)
                }
            }
            .frame(height: 4)  // Thinner than current 6pt
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                displayedProgress = targetProgress
            }
        }
        .onChange(of: current) { _, _ in
            withAnimation(.easeOut(duration: 1.0)) {
                displayedProgress = targetProgress
            }
        }
    }
}
```

**Key changes:**
- Height reduced: 6pt → 4pt (more delicate)
- Corner radius reduced: 4pt → 2pt (less playful, more refined)
- Fill color opacity: 100% → 50% (subtle presence)
- Background track: very faint, almost invisible
- Animation: 1.2s ease-out (water rising, settling)

---

## X. Input Fields: The Invitation to Speak

### Current State

Your floating input has:
- Glass morphism background (`.ultraThinMaterial`)
- Gradient border overlay
- Circular gradient send button
- Capsule shape
- Shadows with purple accent color

It tries too hard to be noticed.

### The Philosophy of the Blank Page

A text field should feel like a blank page. It invites. It does not demand.

**Redesigned input:**

```swift
struct MinimalInput: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("", text: $text, axis: .vertical)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color(hex: "2A2826"))
                .focused($isFocused)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .placeholder(when: text.isEmpty) {
                    Text("Ask your coach...")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color(hex: "ACA9A6"))
                }

            if !text.isEmpty {
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "9B8FA8"))
                }
                .padding(.trailing, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .background(Color(hex: "F9F8F6"))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    Color(hex: "E8E6E3").opacity(isFocused ? 1.0 : 0.0),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}
```

**Changes:**
- Remove `.ultraThinMaterial` (too much blur, too much effect)
- Background: solid off-white, like paper
- Border: appears only on focus, single color, no gradient
- Send button: simple arrow, no circle, no gradient, only appears when text exists
- Shadow: removed entirely
- Voice button: removed (simplify to single input method)

The input should disappear when not in use. When focused, a single line appears around it. When you type, the send arrow fades in. Minimal state changes. Maximum clarity.

---

## XI. Tab Bar: The Quiet Navigation

### Current Observation

The default iOS tab bar is used. This is acceptable. Do not over-design navigation.

However, consider:

**Selected state color:**
```swift
.tint(Color(hex: "9B8FA8"))  // Subtle purple-grey
```

**Unselected state:**
Default grey is fine. Do not force design where iOS conventions work.

The best interface is the one you do not notice.

---

## XII. Macro Numbers: The Beauty of Data

### Current Treatment

Numbers appear in various formats:
- `\(calories)` — no formatting
- Color-coded backgrounds with 100% opacity
- Pills with colored backgrounds

### Data as Poetry

Numbers are beautiful. Present them with reverence.

**Typography for numbers:**

```swift
extension Font {
    static let dataDisplay = Font.system(
        size: 28,
        weight: .regular,
        design: .rounded
    ).monospacedDigit()

    static let dataLarge = Font.system(
        size: 20,
        weight: .medium,
        design: .rounded
    ).monospacedDigit()

    static let dataSmall = Font.system(
        size: 14,
        weight: .regular,
        design: .rounded
    ).monospacedDigit()
}
```

Monospaced digits prevent layout shift when numbers change. This is respect for the user's eye.

**Macro pills redesign:**

```swift
struct MacroPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color.opacity(0.6))
            Text("\(value)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "2A2826"))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.08))  // Reduced from 0.1
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))  // Less rounded
    }
}
```

Less rounding. Less opacity. Less color. More clarity.

---

## XIII. Implementation Priority

You cannot change everything at once. Evolution, not revolution.

### Phase 1: Silence (Week 1)
1. Replace breathing background with single orb, true breath cycle
2. Change all colors to desaturated palette
3. Remove all `.spring()` animations, replace with `.easeOut()`
4. Increase vertical spacing to 8pt grid system

### Phase 2: Space (Week 2)
5. Refine message row: remove labels, add long-press timestamp
6. Update typography line heights
7. Simplify loading indicators
8. Refine progress bars (thinner, subtler)

### Phase 3: Refinement (Week 3)
9. Redesign input field (remove glass, remove gradients)
10. Add scroll-appear animations
11. Audit all padding/spacing for consistency
12. Final color pass (ensure nothing over 30% saturation)

---

## XIV. Closing Thoughts: The Virtue of Emptiness

You have built a functional application. What I offer is not criticism but invitation.

**Invitation to stillness.**
**Invitation to breath.**
**Invitation to space.**

Modern digital design fears emptiness. It fills every pixel with motion, every silence with sound. This is insecurity manifesting as pixels.

True confidence is restraint.

A blank page is not empty. It is full of potential. The pause between breaths is not absence. It is the moment before creation.

Your users are stressed. They come to this app seeking help with fitness, nutrition, health. Give them not more stimulus, but less. Give them room to think. Room to breathe.

Let the AI coach's words have space around them. Let numbers stand alone without decoration. Let animations complete before the next one begins.

White is not the absence of color.
Silence is not the absence of sound.
Emptiness is not the absence of meaning.

They are the canvas upon which meaning appears.

---

**Kenya Hara**
December 13, 2025
Tokyo

---

## Appendix: Complete Revised Theme.swift

For your implementation team, I include a complete revised `Theme.swift` incorporating these principles:

```swift
import SwiftUI

// MARK: - AirFit Design System (Kenya Hara Revision)
// Philosophy: Emptiness as potential, breath as rhythm, subtlety as strength

enum Theme {
    // MARK: - Colors (Desaturated, Harmonious)

    /// Background - true white with slight warmth
    static let background = Color(hex: "FEFDFB")

    /// Surface - barely elevated
    static let surface = Color(hex: "F9F8F6")

    /// Border - subtle demarcation
    static let border = Color(hex: "E8E6E3")

    /// Primary text - warm near-black
    static let textPrimary = Color(hex: "2A2826")

    /// Secondary text - medium grey
    static let textSecondary = Color(hex: "8B8883")

    /// Tertiary text - light grey
    static let textTertiary = Color(hex: "ACA9A6")

    // MARK: - Accent Colors (Desaturated, 15-30% saturation)

    /// Primary accent - dusk purple-grey
    static let accent = Color(hex: "9B8FA8")  // HSB: 270°, 16%, 66%

    /// Protein - mountain blue
    static let protein = Color(hex: "7B9AAF")  // HSB: 205°, 30%, 69%

    /// Calories - warm earth
    static let calories = Color(hex: "B89F8B")  // HSB: 30°, 25%, 72%

    /// Carbs - subtle coral
    static let carbs = Color(hex: "C9A8A1")  // HSB: 12°, 20%, 79%

    /// Fat - pale gold
    static let fat = Color(hex: "C4B69A")  // HSB: 45°, 22%, 77%

    // MARK: - Semantic Colors

    static let success = Color(hex: "8BA888")   // Desaturated green
    static let warning = Color(hex: "C9B088")   // Desaturated amber
    static let error = Color(hex: "C89B94")     // Desaturated red
}

// MARK: - Spacing System (8pt grid)

enum Spacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 16
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 48
    static let xxl: CGFloat = 64
}

// MARK: - Typography (Refined hierarchy with breathing room)

extension Font {
    static let displayLarge = Font.system(size: 32, weight: .light, design: .rounded)
    static let displayMedium = Font.system(size: 24, weight: .regular, design: .rounded)
    static let titleLarge = Font.system(size: 20, weight: .medium, design: .rounded)
    static let titleMedium = Font.system(size: 17, weight: .medium, design: .rounded)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .regular, design: .default)
    static let caption = Font.system(size: 11, weight: .regular, design: .default)

    // Data display (monospaced digits)
    static let dataDisplay = Font.system(size: 28, weight: .regular, design: .rounded).monospacedDigit()
    static let dataLarge = Font.system(size: 20, weight: .medium, design: .rounded).monospacedDigit()
    static let dataSmall = Font.system(size: 14, weight: .regular, design: .rounded).monospacedDigit()
}

// MARK: - Animation Durations (Natural rhythms, no bounce)

enum AnimationDuration {
    static let instant: Double = 0.2
    static let quick: Double = 0.4
    static let normal: Double = 0.6
    static let slow: Double = 0.9
    static let deliberate: Double = 1.2

    // Breathing cycle
    static let breathEmpty: Double = 3.0
    static let breathInhale: Double = 4.0
    static let breathFull: Double = 2.0
    static let breathExhale: Double = 6.0
}

// MARK: - Breathing Background (Single orb, true breath)

struct BreathingBackground: View {
    @State private var phase: BreathPhase = .empty
    @State private var intensity: CGFloat = 0.0

    enum BreathPhase {
        case empty, inhaling, full, exhaling
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.4)
                let baseRadius = size.width * 0.5
                let radius = baseRadius * (0.85 + 0.15 * intensity)

                var path = Path()
                path.addEllipse(in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))

                let blur: CGFloat = 50 + (30 * intensity)
                let opacity = 0.04 + (0.04 * intensity)

                context.addFilter(.blur(radius: blur))
                context.fill(path, with: .color(Theme.accent.opacity(opacity)))
            }
        }
        .task {
            await breathe()
        }
    }

    func breathe() async {
        while true {
            // Empty
            phase = .empty
            intensity = 0.0
            try? await Task.sleep(for: .seconds(AnimationDuration.breathEmpty))

            // Inhale
            phase = .inhaling
            withAnimation(.easeInOut(duration: AnimationDuration.breathInhale)) {
                intensity = 1.0
            }
            try? await Task.sleep(for: .seconds(AnimationDuration.breathInhale))

            // Full
            phase = .full
            try? await Task.sleep(for: .seconds(AnimationDuration.breathFull))

            // Exhale
            phase = .exhaling
            withAnimation(.easeInOut(duration: AnimationDuration.breathExhale)) {
                intensity = 0.0
            }
            try? await Task.sleep(for: .seconds(AnimationDuration.breathExhale))
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
```

This is the foundation. Build from here.

空 — Emptiness.
間 — Space between.
白 — White.

---
