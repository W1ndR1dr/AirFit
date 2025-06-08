# UI Standards for AirFit

**Last Updated**: 2025-01-08  
**Status**: Active  
**Priority**: 🎨 Critical - Defines our visual excellence

## Design DNA

Our UI embodies these core principles:

| Principle | Implementation |
|-----------|----------------|
| **Pastel calm** | Always start with soft two-stop gradients; no solid backgrounds |
| **Text is the hero** | Ultra-light variable weight (300→400) + letter-cascade entrance |
| **Weightless glass** | Translucent cards with 12pt blur, 1px stroke, 20pt radius |
| **Human-centric motion** | Physics-based micro-animations; nothing linear except opacity |
| **Single-device focus** | iOS 18+, iPhone 16+ only – assume 120Hz and high GPU |

## Gradient System

### 12 Pre-Curated Gradients

```swift
enum GradientToken: CaseIterable {
    case peachRose      // #FDE4D2 → #F9C7D6 (dark: #362128 → #412932)
    case mintAqua       // #D3F6F1 → #B7E8F4 (dark: #13313D → #14444F)
    case lilacBlush     // #E9E7FD → #DCD3F9 (dark: #24203B → #2E2946)
    case skyLavender    // #DFF2FD → #D8DEFF (dark: #15283A → #1C2541)
    case sageMelon      // #E8F9E3 → #FFF0CB (dark: #29372A → #3A3724)
    case butterLemon    // #FFF8DB → #FFE4C2 (dark: #3B3623 → #46341F)
    case icePeriwinkle  // #E6FAFF → #E9E6FF (dark: #1F3540 → #252B4A)
    case rosewoodPlum   // #FCD5E8 → #E5D1F8 (dark: #3A2436 → #301E41)
    case coralMist      // #FEE3D6 → #EBD6F5 (dark: #3A2723 → #33263B)
    case sproutMint     // #E5F8D4 → #CBF1E2 (dark: #283827 → #1F4033)
    case dawnPeach      // #FDE6D4 → #F7E1FD (dark: #3D2720 → #2F233A)
    case duskBerry      // #F3D8F2 → #D8E1FF (dark: #3A2638 → #212849)
}
```

### Gradient Manager Implementation

```swift
@MainActor
final class GradientManager: ObservableObject {
    @Published private(set) var active: GradientToken = .peachRose
    
    func next() {
        var candidate: GradientToken
        repeat { 
            candidate = GradientToken.allCases.randomElement()! 
        } while candidate == active
        
        withAnimation(.easeInOut(duration: 0.6)) { 
            active = candidate 
        }
    }
}
```

## Typography & Motion

### Motion Tokens

```swift
enum MotionToken {
    static let duration: Double = 0.60    // Total block time
    static let stagger: Double = 0.012    // Delay between glyphs
    static let offsetY: CGFloat = 6       // Start vertical offset
    static let weightFrom: CGFloat = 300  // SF Pro Variable start
    static let weightTo: CGFloat = 400    // SF Pro Variable end
}
```

### Letter Cascade Effect

Every primary text string must use the cascade entrance:

```swift
CascadeText(text: "Welcome\nto AirFit")
    .font(.system(size: 44, weight: .thin, design: .rounded))
    .multilineTextAlignment(.center)
```

## Component Architecture

### Base Screen Pattern

Every screen must extend BaseScreen:

```swift
struct MyScreen: View {
    var body: some View {
        BaseScreen {
            // Your content here
        }
    }
}
```

### Glass Card Component

All content cards use the glass morphism pattern:

```swift
GlassCard {
    // Card content
}
```

Properties:
- Ultra-thin material background
- 20pt corner radius (continuous)
- 1px white stroke at 30% opacity
- Spring-in animation on appear
- 8pt shadow with 5% opacity

### Standard Components

1. **CascadeText** - Animated text with letter cascade
2. **GlassCard** - Translucent content container
3. **GradientNumber** - Large numbers with gradient overlay
4. **MicRippleView** - Voice input with ripple animation
5. **MetricRing** - Progress visualization
6. **BaseScreen** - Screen wrapper with gradient background

## Navigation & Transitions

### Screen Transitions
```swift
.transition(.opacity.combined(with: .offset(y: 12)))
```

### Gradient Changes
- Call `GradientManager.next()` on every screen transition
- Never repeat the current gradient
- Cross-fade duration: 0.6s

## Animation Standards

### Spring Animations
```swift
.interpolatingSpring(stiffness: 130, damping: 12)
```

### Easing Functions
- Primary: `.easeOut(duration: 0.6)`
- Secondary: `.easeInOut(duration: 0.6)`
- Never use: Linear animations (except opacity)

### Durations
- Micro-interactions: 0.12s - 0.3s
- Content transitions: 0.6s
- Background gradients: 0.6s
- Letter cascade total: 0.6s

## Spacing & Layout

### Standard Spacing
```swift
enum Spacing {
    static let xs: CGFloat = 12
    static let sm: CGFloat = 20
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 48
}
```

### Padding
- Screen padding: 24pt
- Card padding: 16pt
- Component spacing: 20pt (vertical)

## Accessibility

### Dynamic Type
- Support up to Accessibility XL
- Use `.font(.scaled(.system(size: baseline)))`

### VoiceOver
- Label every interactive element
- Example: "Nutrition summary, 1850 of 2300 calories"

### Contrast
- All gradients maintain ≥ 4.5:1 contrast ratio
- Test with both light and dark variants

## Performance Guidelines

### GPU Budget
- Maximum 6 simultaneous blurs per screen
- Optimize for A19/M-class GPU capabilities
- Profile with Instruments

### Animation Performance
- Use `.drawingGroup()` for complex animations
- Prefer `opacity` over `hidden()` for transitions
- Cache gradient calculations

## Implementation Checklist

### For Every New Screen
- [ ] Extends BaseScreen
- [ ] Uses CascadeText for primary headings
- [ ] Content wrapped in GlassCard components
- [ ] Proper spacing using standard tokens
- [ ] Gradient transition on navigation
- [ ] Spring animations for element entrance
- [ ] VoiceOver labels implemented
- [ ] Dynamic Type tested

### For Every Component
- [ ] Follows glass morphism if container
- [ ] Uses standard motion tokens
- [ ] Implements proper @EnvironmentObject access
- [ ] Handles reduced motion preference
- [ ] Maintains 120Hz smoothness

## File Organization

```
AirFit/
├── Core/
│   └── Theme/
│       ├── GradientToken.swift
│       ├── GradientManager.swift
│       ├── MotionToken.swift
│       └── Spacing.swift
├── Core/
│   └── Views/
│       ├── CascadeText.swift
│       ├── GlassCard.swift
│       ├── BaseScreen.swift
│       ├── GradientNumber.swift
│       └── MicRippleView.swift
└── Modules/
    └── [Feature]/
        └── Views/
            └── [Feature]View.swift  // Uses BaseScreen
```

## Migration Guide

### From Current UI to New Standards

1. **Replace solid backgrounds**
   ```swift
   // OLD
   .background(Color.backgroundPrimary)
   
   // NEW
   BaseScreen { /* content */ }
   ```

2. **Update text animations**
   ```swift
   // OLD
   Text("Title").opacity(isVisible ? 1 : 0)
   
   // NEW
   CascadeText(text: "Title")
   ```

3. **Convert cards to glass**
   ```swift
   // OLD
   VStack { /* content */ }
       .background(Color.cardBackground)
       .cornerRadius(12)
   
   // NEW
   GlassCard { /* content */ }
   ```

## Quality Assurance

### Visual QA Checklist
- [ ] Gradients transition smoothly (< 2% pixel delta per frame)
- [ ] Letter cascade timing feels natural
- [ ] Glass cards have proper translucency
- [ ] Springs feel responsive, not bouncy
- [ ] 120Hz performance maintained

### Snapshot Testing
```swift
assertSnapshot(matching: view, as: .image(precision: 0.98))
```

## References

- Original spec: `Docs/o3 UI consult.md`
- Research report: `UI_Implementation_Analysis.md`
- Related: `CONCURRENCY_STANDARDS.md` (for @MainActor patterns)