# UI Component Standards for Phase 3.3

**Created**: 2025-06-10  
**Purpose**: Ensure consistent, world-class implementation of our UI vision

## Component Development Principles

### 1. Every Component Must Be Perfect
- **No shortcuts**: Each component should be production-ready
- **Performance first**: Profile everything for 120fps
- **Reusability**: Components should work in any context
- **Type safety**: Strong typing, no force unwrapping

### 2. File Organization
```swift
// Component structure
struct ComponentName: View {
    // MARK: - Properties
    private let property: Type
    @State private var state: Type
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func helperMethod() { }
}

// MARK: - Previews
#Preview("Light Mode") {
    ComponentName()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ComponentName()
        .preferredColorScheme(.dark)
}
```

### 3. Animation Standards
```swift
// Always use our standard spring via MotionToken
.animation(MotionToken.standardSpring, value: animationTrigger)
// Which equals: .interpolatingSpring(stiffness: 130, damping: 12)

// For gradients
.animation(MotionToken.gradientAnimation, value: gradientChange)
// Which equals: .easeInOut(duration: 0.6)

// For micro-interactions
.animation(MotionToken.microAnimation, value: smallChange)
// Which equals: .easeOut(duration: 0.2)
```

### 4. Performance Patterns
```swift
// Good: Drawing group for complex hierarchies
CascadeText("Title")
    .drawingGroup()

// Good: Conditional opacity
.opacity(isVisible ? 1 : 0)

// Bad: Conditional rendering
if isVisible { ComplexView() }
```

### 5. Testing Each Component
Before moving to the next component:
1. Build and run
2. Test on iPhone 16 Pro simulator
3. Verify 120fps with Instruments
4. Check memory usage
5. Test light/dark mode

## Component Implementation Order

### Phase 1: Foundation (GradientManager)
1. GradientToken enum
2. GradientManager class
3. BaseScreen wrapper
4. Test gradient transitions

### Phase 2: Core Components
1. CascadeModifier + CascadeText
2. GlassCard
3. GradientNumber
4. MicRippleView
5. MetricRing

### Phase 3: Screen Integration
Transform one screen at a time, starting with Dashboard

## Quality Checklist
- [ ] Follows naming conventions
- [ ] Includes proper documentation
- [ ] Has preview providers
- [ ] Tested on device
- [ ] Performance validated
- [ ] No warnings
- [ ] Animations smooth
- [ ] Memory efficient

## Implementation Status (as of 2025-06-10)

### ✅ Completed Components
- GradientToken & GradientManager
- BaseScreen wrapper
- MotionToken (fully aligned with specs)
- CascadeText with letter animations
- GlassCard with blur effects
- GradientNumber with gradient masking
- MicRippleView for voice input
- MetricRing for circular progress
- AppSpacing (aligned with UI Vision)

### 🚧 In Progress
- Food Tracking screens (43% complete)
  - ✅ FoodLoggingView
  - ✅ FoodVoiceInputView
  - ✅ PhotoInputView
  - ⏳ FoodConfirmationView
  - ⏳ MacroRingsView
  - ⏳ NutritionSearchView
  - ⏳ WaterTrackingView

### 📋 Remaining
- Workout screens
- Settings screens
- Advanced components (ParallaxContainer, DragDismissSheet, FlareButton)

## Code Examples

### Perfect Component Template
```swift
import SwiftUI

/// A beautifully animated component that...
struct PerfectComponent: View {
    // MARK: - Properties
    let title: String
    let value: Double
    
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        content
            .onAppear { startAnimation() }
    }
    
    // MARK: - Private Views
    private var content: some View {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func startAnimation() {
        withAnimation(.interpolatingSpring(stiffness: 130, damping: 12)) {
            isAnimating = true
        }
    }
}
```

## Consistency Checklist for Transformations

When transforming each screen, ensure:

### 1. Structure
- [ ] Wrapped in `BaseScreen` for gradient background
- [ ] Uses `NavigationStack` (not deprecated `NavigationView`)
- [ ] Proper `@EnvironmentObject` for GradientManager
- [ ] `@Environment(\.colorScheme)` for color scheme

### 2. Animations
- [ ] `@State private var animateIn = false`
- [ ] `.onAppear { withAnimation(MotionToken.standardSpring) { animateIn = true } }`
- [ ] Staggered delays: `.delay(0.1)`, `.delay(0.2)`, etc.
- [ ] Use `MotionToken` constants, not raw values

### 3. Components
- [ ] Primary titles use `CascadeText`
- [ ] Content cards use `GlassCard`
- [ ] Large numbers use `GradientNumber`
- [ ] Spacing uses `AppSpacing` tokens
- [ ] Buttons call `HapticService` on tap

### 4. Common Fixes
- [ ] Replace `.foregroundStyle(.tertiary)` with `.foregroundColor(Color.secondary.opacity(0.5))`
- [ ] Replace `gradientManager.currentGradient(for: colorScheme).colors(for: colorScheme).first` with color selection based on `gradientManager.active`
- [ ] Fix `onLongPressGesture` to use `pressing:` parameter
- [ ] Ensure proper type matching for Material vs Color

Remember: We're creating art, not just code. Every pixel matters.