# UI Design Principles

> UX recommendations from design consultation (Jony Ive × Julie Zhuo perspective)

## The Core Tension

> "The complexity of human movement versus the simplicity required for daily use."

Most fitness apps die by a thousand checkboxes. They become graveyards of toggles and settings. We must resist this with every design decision.

---

## Foundational Principles

### 1. Don't Add Tabs

The current 5-tab structure is elegant:
- Dashboard
- Nutrition
- Coach (AI chat)
- Insights
- Profile

**Adding a 6th "Workouts" tab would:**
- Fragment attention
- Create navigation confusion (Is my workout data in Dashboard or Workouts?)
- Violate the AI-centric philosophy (the Coach should synthesize across domains)

**Instead:** Expand Dashboard's Training segment to handle all workout types.

### 2. Data Should Find Its Level

Not all workouts deserve equal screen real estate. A user who lifts 5x/week and runs once monthly should see a dramatically different interface than someone who swims daily and does occasional yoga.

**The app should observe and adapt.** This aligns with the AI-native philosophy:
> "The AI learns about the user through conversation, not forms. Profile builds organically."

The same should be true for workout types. The interface should be **earned through activity**, not configured through settings.

### 3. Unified Stream, Specialized Drill-Downs

```
Dashboard
├── Body (unchanged - weight, body fat, lean mass)
└── Training
    ├── Weekly Activity Summary (adapts based on user's activities)
    ├── Unified Activity Stream (all workout types, chronological)
    └── Tap any workout → Type-specific detail view
         ├── Strength: Sets tracker, PR charts, exercise picker
         ├── Running: Route map, pace chart, splits
         ├── Cycling: Route map, elevation, power zones
         ├── Swimming: Lap breakdown, stroke analysis
         └── Yoga: Session duration, consistency tracking
```

### 4. Simplicity Is Not the Absence of Features

**Simplicity is the presence of clarity.**

The person who lifts and runs and does yoga should feel the app understands them. The person who only cycles should feel the same.

---

## Implicit Personalization

### Usage-Based UI Adaptation

```swift
func calculateUserActivityProfile() -> [WorkoutType: ActivityPriority] {
    let recentWorkouts = healthKit.getRecentWorkouts(days: 30)
    let frequencyMap = workouts.groupedByType().mapValues { $0.count }

    // Primary: >3x in 30 days → Full visualization
    // Secondary: 1-3x in 30 days → Appears in stream, less prominence
    // Tertiary: 0x in 30 days → Hidden until used

    return frequencyMap.mapValues { count in
        switch count {
        case 4...: return .primary
        case 1...3: return .secondary
        default: return .tertiary
        }
    }
}
```

### What This Means in Practice

| User Pattern | UI Adapts To Show |
|--------------|-------------------|
| Lifts 4x/week, runs 2x/week | Set Tracker prominent, running summary below |
| Runs 5x/week, occasional yoga | Running stats prominent, yoga consistency card |
| Only cycles | Cycling-focused dashboard, no strength UI |
| Does everything | Unified stream with all types, smart prioritization |

### One Exception for Explicit Override

If a user explicitly TELLS the coach:
- "I'm training for a marathon"
- "I want to focus on strength"

This should elevate that activity type regardless of recent frequency. The AI should update the profile, which influences UI weighting.

---

## Graceful Degradation

### For Cardio-Only Users (The Brothers' Use Case)

Users who don't use Hevy and do primarily running/cycling:

1. **Set Tracker disappears** - No empty state, just gone
2. **Running/cycling takes center stage** - Primary hero metrics
3. **Simplified set counter available** - If they want to track occasional strength
4. **App feels complete** - Not missing features, just adapted

```swift
var setTrackerVisible: Bool {
    // Only show if user has Hevy connected OR has manual set data
    return isHevyConfigured || hasManualSetEntries
}

var body: some View {
    VStack {
        // Weekly activity summary (always)
        WeeklyActivitySummary(activities: allActivities)

        // Set tracker (conditional)
        if setTrackerVisible {
            SetTrackerSection()
        }

        // Activity stream (always)
        UnifiedActivityStream(activities: filteredActivities)
    }
}
```

### For Strength-Only Users

If someone only uses Hevy and never does cardio:

1. **Running/cycling PBs don't appear** - No empty "Best 5K: --:--"
2. **Set Tracker and strength metrics prominent**
3. **Activity stream shows only strength workouts**
4. **If they do one run, it appears without fanfare**

---

## Route Maps: Levels of Display

Maps are powerful but dangerous. They demand attention and can overwhelm.

**Principle: Maps are rewards, not requirements.**

### Level 1: Card View (Activity Stream)

- **NO full map** - Too heavy for lists
- Show mini route "glyph" - The shape reduced to 24×24pt
- Just distance + pace text

```
┌────────────────────────────────────────────────────┐
│  🗺  Morning Run                      2 days ago  │
│ [~]  5.2 mi • 8:42 /mi • +120 ft                  │
└────────────────────────────────────────────────────┘
   ▲
   └── Mini route glyph (24×24pt shape signature)
```

### Level 2: Workout Detail Sheet

- Route map at ~40% of screen height
- Below: splits, pace chart, HR zones
- Map is interactive but not the star

### Level 3: Full-Screen Map (Tap the Map)

- Immersive route exploration
- Color-coded by pace or heart rate
- Mile markers, start/end pins
- Photo pins (if available)

---

## Progressive Disclosure Hierarchy

### At-a-Glance: This Week Card

What a user sees when they first open Training:

```
┌─────────────────────────────────────────────────────┐
│  THIS WEEK                                          │
├─────────────────────────────────────────────────────┤
│  Activity   4 sessions  [🏋️🏋️🏃🧘]                │
│  Volume     12,400 lbs  ████████░░                  │
│  Cardio     8.5 miles   ██████░░░░                  │
│  Streak     3 weeks     🔥🔥🔥                      │
└─────────────────────────────────────────────────────┘
```

Notice:
- "Activity" shows TYPE distribution with icons, not just count
- Metrics adapt to what user actually does
- No empty/irrelevant rows

### Second-Level: Scroll Down

- Set tracker (if strength user)
- Recent cardio summary (if cardio user)
- Activity stream with hero metrics

### Drill-Down: Tap for Full Detail

- Complete specialized interface per workout type
- All the charts, maps, splits, etc.

---

## Activity Type Colors

Extend the existing Theme with semantic colors:

| Activity | Color (Light) | Color (Dark) | SF Symbol |
|----------|---------------|--------------|-----------|
| Strength | E88B7F (coral) | F4A99F | figure.strengthtraining.traditional |
| Running | 5DA5A3 (teal) | 7EBFBD | figure.run |
| Cycling | 7DB095 (sage) | 9DCAB0 | figure.outdoor.cycle |
| Swimming | 8BB4B8 (pool blue) | A8CED2 | figure.pool.swim |
| Yoga | B4A0C7 (lavender) | CFC0DC | figure.mind.and.body |
| HIIT | E9B879 (amber) | F4CFA0 | figure.highintensity.intervaltraining |

### Visual Treatment

Each activity card has a subtle left-edge color bar (2-3pt) based on type. This provides instant recognition without being garish.

```swift
struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 0) {
            // Type color accent bar
            Rectangle()
                .fill(activity.type.color)
                .frame(width: 3)

            // Card content
            HStack {
                Image(systemName: activity.type.icon)
                    .foregroundStyle(activity.type.color)
                // ... rest of card
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## The AI-Centric Fallback

For complex, cross-domain questions, the answer should come from the Coach, not a specialized UI.

### When UI Handles It
- "Show me my runs this week" → Activity stream filter
- "What was my last bench press PR?" → Strength detail view
- "How far did I run yesterday?" → Running detail view

### When Coach Handles It
- "How should I adjust my training for a half marathon next month?"
- "Is my running affecting my squat progress?"
- "What's the best day to do yoga based on my schedule?"

The Coach + Insights tabs can synthesize cross-training wisdom that no specialized UI could surface:
- "Your running volume increased 40% but your protein intake stayed flat. Consider..."
- "You've been doing yoga after heavy squat days - your HRV suggests this is working."

---

## Component Patterns to Reuse

### From Existing Codebase

| Component | Location | Reuse For |
|-----------|----------|-----------|
| `InteractiveChartView` | InteractiveChartView.swift | Pace charts, HR charts, elevation profiles |
| `StatTile` | Various | Hero metrics for all workout types |
| `MiniSparkline` | StrengthDetailView | Inline trends for any metric |
| `ChartTimeRangePicker` | StrengthDetailView | All detail views |
| `ExercisePicker` (pills) | StrengthDetailView | Route selector, activity filter |

### New Components Needed

| Component | Purpose |
|-----------|---------|
| `RouteGlyph` | Mini route shape for cards |
| `RouteMapView` | Full MapKit integration |
| `HRZoneBar` | Stacked bar showing zone distribution |
| `SplitsTable` | Running splits breakdown |
| `ConsistencyCard` | Yoga/mobility streak tracking |
| `ActivityCard` | Unified card for any workout type |
| `WeeklyActivitySummary` | Adaptive weekly overview |

---

## Animation & Transition Guidelines

### Follow Existing Patterns

The app uses spring-based animations:
- `.bloom` - 0.6s response, 0.82 damping
- `.bloomBreathing` - 8s cycle
- `.airfitMorph` - Card-level transitions

### For New Components

- Route maps should fade in, not jump
- Detail view transitions should feel like expansion, not navigation
- Activity stream should use subtle stagger when loading

---

## Summary: The Irreducible Recommendations

1. **Do not add tabs.** Expand Dashboard's Training segment.

2. **Unified activity stream.** All workout types in one chronological list with type-specific hero metrics.

3. **Specialized drill-downs.** Each workout type gets its own detail view.

4. **Implicit personalization.** The app learns from usage which activities matter.

5. **Maps as earned rewards.** Mini-route glyphs in cards, full maps only in detail views.

6. **Graceful degradation.** Cardio-only users never see Set Tracker. Strength-only users don't see running PBs.

7. **AI synthesis.** Cross-activity insights come from Coach and Insights tabs, not UI complexity.

The goal is an app that feels tailored to each user without them ever touching a settings screen.
