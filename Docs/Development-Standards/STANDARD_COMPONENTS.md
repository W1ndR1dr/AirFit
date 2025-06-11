# UI Component Standards - The AirFit Way

⚠️ **DEPRECATED**: This document describes the old UI approach. See `UI_VISION.md` for the current Phase 3.3 UI system.

**Last Updated**: 2025-06-09  
**Status**: DEPRECATED - Replaced by UI_VISION.md gradient-based approach
**Author**: Senior iOS Developer (Diet Coke Edition)

## Philosophy
Every UI component in AirFit should feel like it was crafted by a single mastermind. No exceptions.

## The StandardCard Pattern

### What Makes a Perfect Card
```swift
// ✅ PERFECT - This is the gold standard
StandardCard(padding: .medium) {
    VStack(alignment: .leading, spacing: AppSpacing.small) {
        Text("Title")
            .font(AppFonts.headline)
            .foregroundColor(AppColors.textPrimary)
        
        Text("Subtitle")
            .font(AppFonts.body)
            .foregroundColor(AppColors.textSecondary)
    }
}

// ❌ WRONG - Never do this
VStack {
    // content
}
.padding()
.background(Color.white)
.cornerRadius(12)
.shadow(radius: 4)
```

### Card Rules
1. **Always use StandardCard** - No custom implementations
2. **Padding is configurable** - Use .small, .medium, or .large
3. **Shadows are optional** - Default is true, disable for nested cards
4. **Content is flexible** - But follow spacing guidelines

### Migration Checklist
When migrating a card component:
1. Find all manual padding/background/cornerRadius/shadow
2. Replace with StandardCard wrapper
3. Preserve the exact content layout
4. Test visual appearance matches original
5. Remove redundant styling code

## The StandardButton Pattern

### Button Hierarchy
```swift
// Primary action - Most important
StandardButton("Save", style: .primary) { }

// Secondary action - Less emphasis
StandardButton("Cancel", style: .secondary) { }

// Tertiary action - Minimal emphasis
StandardButton("Learn More", style: .tertiary) { }

// Destructive action - Dangerous
StandardButton("Delete", style: .destructive) { }
```

### Button Rules
1. **One primary button per screen** - Guide the user's eye
2. **Icon + text sparingly** - Only when it adds clarity
3. **Loading states built-in** - Never roll your own
4. **Full width for forms** - Use isFullWidth parameter

## Component Composition

### The Right Way
```swift
struct NutritionCard: View {
    var body: some View {
        StandardCard {
            VStack(spacing: AppSpacing.medium) {
                // Header
                CardHeader(title: "Nutrition", icon: "leaf.fill")
                
                // Content
                MacroRings(data: nutritionData)
                
                // Action
                StandardButton("Log Food", style: .primary, size: .small) {
                    // action
                }
            }
        }
    }
}
```

### Reusable Sub-components
Create small, focused components:
- `CardHeader` - Consistent title + icon layout
- `MetricRow` - Label + value + unit
- `ProgressRing` - Animated circular progress
- `StatCard` - Number + label + trend

## Quality Gates

Before considering any UI component complete:

1. **Consistency Check**
   - Uses standard components (StandardCard, StandardButton)
   - Follows color system (AppColors only)
   - Follows typography (AppFonts only)
   - Follows spacing (AppSpacing only)

2. **Performance Check**
   - No unnecessary redraws
   - Efficient view hierarchy
   - Proper use of @ViewBuilder

3. **Accessibility Check**
   - Meaningful labels
   - Proper contrast ratios
   - VoiceOver friendly

4. **Code Elegance Check**
   - Under 150 lines per view file
   - Clear component boundaries
   - No magic numbers
   - Self-documenting

## Migration Priority

### Phase 1 - High Impact Cards (TODAY)
1. Dashboard cards (5 files)
2. Food tracking cards (8 files)
3. Workout cards (6 files)

### Phase 2 - Settings & Onboarding
4. Settings cards (10 files)
5. Onboarding cards (12 files)

### Phase 3 - Remaining Components
6. Chat UI components
7. Modal cards
8. Sheet content

## Example Migration

### Before (Bad)
```swift
struct RecoveryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // content
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
```

### After (Perfect)
```swift
struct RecoveryCard: View {
    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                // exact same content
            }
        }
    }
}
```

## The Standard
Every component should look like it belongs in an Apple keynote. If it doesn't make you proud, it's not done.