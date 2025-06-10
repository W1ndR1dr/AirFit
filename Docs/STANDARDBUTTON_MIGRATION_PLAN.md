# StandardButton Migration Plan

## Overview
~100 buttons across the codebase need migration to StandardButton for consistency.

## Migration Priority

### Phase 1: Quick Wins (1-2 hours)
Focus on simple replacements that don't change functionality:
1. All `.buttonStyle(.borderedProminent)` → `StandardButton(style: .primary)`
2. All `.buttonStyle(.bordered)` → `StandardButton(style: .secondary)`
3. Simple icon buttons → `IconButton`

### Phase 2: Settings Module (1-2 hours)
- Most standardized module
- ~35 buttons
- Good test case for patterns

### Phase 3: Core Flows (3-4 hours)
1. FoodTracking (~20 buttons)
2. Workouts (~15 buttons)
3. Dashboard (~10 buttons)

### Phase 4: Complex Cases (3-4 hours)
1. Onboarding (~50 buttons) - has complex interactions
2. Chat (~8 buttons)
3. Custom selection components

## Migration Patterns

### Basic Button
```swift
// OLD
Button("Save") { action() }
    .buttonStyle(.borderedProminent)

// NEW
StandardButton("Save", style: .primary) { action() }
```

### Icon Button
```swift
// OLD
Button { action() } label: {
    Image(systemName: "plus")
}

// NEW
IconButton(icon: "plus") { action() }
```

### Full Width Button
```swift
// OLD
Button("Continue") { action() }
    .frame(maxWidth: .infinity)
    .buttonStyle(.borderedProminent)

// NEW
StandardButton("Continue", style: .primary, isFullWidth: true) { action() }
```

### Custom Styled Button
```swift
// OLD
Button("Cancel") { action() }
    .padding()
    .background(Color.secondary)
    .cornerRadius(8)

// NEW
StandardButton("Cancel", style: .secondary) { action() }
```

## Special Cases

### Navigation Buttons
Keep as-is when:
- In navigation bars/toolbars
- NavigationLink buttons
- System integration points

### Custom Components Needed
1. **SelectionCard** - For multi-select scenarios
2. **ToggleButton** - For on/off states
3. **NavigationButtonBar** - For consistent back/next navigation

## Success Criteria
- [ ] All button styling centralized
- [ ] Consistent haptic feedback
- [ ] Reduced code duplication
- [ ] No visual regressions
- [ ] Build succeeds

## Next Steps
1. Start with Settings module as pilot
2. Document any edge cases found
3. Create additional components as needed
4. Update UI_COMPONENT_STANDARDS.md