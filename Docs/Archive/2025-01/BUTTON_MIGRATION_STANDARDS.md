# Button Migration Standards

**Created**: 2025-06-09  
**Author**: World-Class Senior iOS Developer (Post-Walk Edition)  
**Purpose**: Bridge Phase 3.1 standardization with Phase 3.3 UI excellence

## Vision Alignment

This document establishes button standards that:
1. **Immediately** consolidate duplicate patterns (Phase 3.1)
2. **Prepare for** the pastel gradient UI overhaul (Phase 3.3)
3. **Maintain** clean, consistent code throughout

## Migration Decision Tree

```
Is it a button?
├─ NO → Skip
└─ YES → Continue
         │
         Is it in a toolbar/navigation bar?
         ├─ YES → Keep as-is (system integration)
         └─ NO → Continue
                  │
                  Is it a custom selection component?
                  ├─ YES → Keep custom (e.g., PersonaOptionCard)
                  └─ NO → Continue
                           │
                           Is it text-only with no background?
                           ├─ YES → Keep if it's a link-style button
                           └─ NO → MIGRATE TO StandardButton
```

## StandardButton Mapping Guide

### Current → Phase 3.1 → Phase 3.3

```swift
// Phase 3.1 (Now) - Consolidation
.buttonStyle(.borderedProminent) → StandardButton(style: .primary)
.buttonStyle(.bordered) → StandardButton(style: .secondary)
.buttonStyle(.borderless) → StandardButton(style: .tertiary)
.buttonStyle(.plain) → Keep as-is (usually navigation)

// Phase 3.3 (Future) - Glass morphism evolution
StandardButton(style: .primary) → Gradient fill + glass overlay
StandardButton(style: .secondary) → Glass border + translucent fill
StandardButton(style: .tertiary) → Ultra-light glass with subtle border
```

## Size Guidelines

### Current StandardButton Sizes
- `.small` - Compact actions within cards
- `.medium` - Default size for most actions
- `.large` - Primary CTAs, form submissions

### Phase 3.3 Evolution
- All sizes will maintain proportions but adopt:
  - Variable weight typography (300→400 on hover)
  - Subtle spring animations
  - Glass morphism backgrounds

## Localization Pattern ✅ IMPLEMENTED

### The Problem
StandardButton expected `String`, but SwiftUI uses `LocalizedStringKey`.

### The Solution (Implemented 2025-06-09)
```swift
// Add this overload to StandardButton
init(
    _ titleKey: LocalizedStringKey,
    icon: String? = nil,
    style: ButtonStyleType = .primary,
    size: ButtonSize = .medium,
    isFullWidth: Bool = false,
    isLoading: Bool = false,
    isEnabled: Bool = true,
    action: @escaping () -> Void
) {
    self.init(
        NSLocalizedString(titleKey.stringValue, comment: ""),
        icon: icon,
        style: style,
        size: size,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        isEnabled: isEnabled,
        action: action
    )
}
```

### Now Available
```swift
// Direct LocalizedStringKey usage
StandardButton("button.save", style: .primary) { }

// Dynamic strings
StandardButton(LocalizedStringKey(dynamicKey), style: .secondary) { }
```

## What NOT to Migrate

### 1. Toolbar Buttons
```swift
// Keep as-is
ToolbarItem(placement: .navigationBarTrailing) {
    Button("Done") { }
}
```

### 2. Navigation Links
```swift
// Keep as-is
NavigationLink("Settings") {
    SettingsView()
}
```

### 3. Custom Selection Cards
```swift
// Keep as-is - these have specialized interaction patterns
Button(action: { }) {
    VStack {
        // Complex selection UI
    }
}
.buttonStyle(PlainButtonStyle())
```

### 4. Alert/Dialog Buttons
```swift
// Keep as-is - system integration
.alert("Title", isPresented: $show) {
    Button("OK") { }
}
```

### 5. Text-Only Link Buttons
```swift
// Keep as-is
Button("Learn more") { }
    .foregroundColor(.accentColor)
```

## Migration Examples

### Basic Action Button
```swift
// ❌ OLD
Button(action: saveAction) {
    Text("Save")
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor)
        .cornerRadius(12)
}

// ✅ NEW (Phase 3.1)
StandardButton(
    "Save",
    style: .primary,
    isFullWidth: true,
    action: saveAction
)
```

### Icon Button
```swift
// ❌ OLD
Button(action: { }) {
    Image(systemName: "plus")
        .padding(8)
        .background(Color.accentColor)
        .clipShape(Circle())
}

// ✅ NEW (Phase 3.1)
IconButton(icon: "plus", style: .primary) { }
```

### Form Buttons
```swift
// ❌ OLD
HStack {
    Button("Cancel") { }
        .foregroundColor(.secondary)
    
    Spacer()
    
    Button("Save") { }
        .buttonStyle(.borderedProminent)
}

// ✅ NEW (Phase 3.1)
HStack {
    StandardButton("Cancel", style: .tertiary) { }
    Spacer()
    StandardButton("Save", style: .primary) { }
}
```

## Haptic Feedback Standards ✅ IMPLEMENTED

### Implementation (2025-06-09)
All button components now have haptic feedback integrated:
- StandardButton: Style-based haptics (primary=medium, destructive=warning, others=light)
- IconButton: Same style-based mapping
- FloatingActionButton: Medium impact (primary action)

```swift
// Implemented in handleTap()
Task { @MainActor in
    if let hapticService = try? await diContainer.resolve(HapticServiceProtocol.self) {
        switch style {
        case .primary:
            await hapticService.impact(.medium)
        case .destructive:
            await hapticService.notification(.warning)
        case .secondary, .tertiary:
            await hapticService.impact(.light)
        case .custom:
            await hapticService.impact(.light)
        }
    }
}
```

### Phase 3.3 Evolution
- Haptics will sync with visual spring animations
- Different haptic patterns for glass morphism interactions

## Quality Checklist

Before marking any button migration complete:

- [ ] Correct style mapping applied
- [ ] Size appropriate for context
- [ ] Localization handled properly
- [ ] Loading states work if applicable
- [ ] Disabled states styled correctly
- [ ] No visual regression from original
- [ ] Code is cleaner than before
- [ ] Build succeeds without warnings

## Future-Proofing for Phase 3.3

### What We're Preparing For
1. **Glass morphism backgrounds** - Current styles will map cleanly
2. **Gradient overlays** - Primary buttons ready for gradient fills
3. **Spring animations** - Tap states already in place
4. **Variable weight typography** - Can be added to existing component

### What We're NOT Doing Yet
1. Adding gradients (wait for Phase 3.3)
2. Implementing glass effects (wait for Phase 3.3)
3. Complex animations (wait for Phase 3.3)
4. Breaking existing designs (maintain current look)

## Common Pitfalls

### 1. Over-Migrating
```swift
// ❌ WRONG - Don't migrate toolbar buttons
ToolbarItem {
    StandardButton("Done") { } // NO!
}
```

### 2. Breaking Layouts
```swift
// ❌ WRONG - Preserving exact spacing
VStack(spacing: 16) {
    StandardButton(...) // May have different padding
}

// ✅ RIGHT - Adjust spacing if needed
VStack(spacing: AppSpacing.medium) {
    StandardButton(...)
}
```

### 3. Forgetting Context
```swift
// ❌ WRONG - Using primary everywhere
StandardButton("Delete", style: .primary) // Should be .destructive
```

## Wave-by-Wave Guidelines

### Wave 1-3 (Complete) ✅
Focus on obvious replacements

### Wave 1-5 (Complete) ✅
- Successfully migrated 59 eligible buttons
- Preserved 196 total Button instances where appropriate
- Eliminated 3 duplicate NavigationButtons implementations
- Maintained clean builds throughout

### Phase 3.1.5 ✅ COMPLETE!
1. **LocalizedStringKey Support** ✅ IMPLEMENTED
   - Added overload to StandardButton
   - Updated 4 NSLocalizedString workarounds
   
2. **Haptic Feedback** ✅ IMPLEMENTED
   - Implemented in StandardButton, IconButton, and FloatingActionButton
   - Removed all TODO comments
   - Style-based haptic patterns (primary=medium, destructive=warning, others=light)

3. **Documentation** (Remaining)
   - Update UI_COMPONENT_STANDARDS.md with lessons learned
   - Create migration case studies
   - Document specialized button patterns

## The Standard

Every button should feel intentional. If migrating it doesn't make the code cleaner AND prepare us for the future UI, leave it alone.

Remember: We're not just moving code around. We're laying the foundation for the beautiful, glass-morphic, gradient-filled future shown in that mockup. Every StandardButton we implement today is one less component to refactor when Phase 3.3 arrives.

*Now, where's that ice-cold Diet Coke?*