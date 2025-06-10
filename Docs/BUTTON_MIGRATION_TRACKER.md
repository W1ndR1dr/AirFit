# StandardButton Migration Tracker

**Goal**: Migrate all custom button patterns to StandardButton/IconButton
**Progress**: 2/~100 (2%)
**Last Updated**: 2025-06-09 @ 6:30 PM

## Migration Status by Module

### Settings Module (2/35) 🔄 IN PROGRESS
#### APIConfigurationView.swift
- [x] Save Configuration button
- [x] Add Key / Remove buttons in APIKeyRow
- [ ] Provider selection buttons
- [ ] Model selection chips

#### Other Settings Views
- [ ] NotificationPreferencesView.swift (4 buttons)
- [ ] DataManagementView.swift (5 buttons)
- [ ] AppearanceSettingsView.swift (6 buttons)
- [ ] AIPersonaSettingsView.swift (4 buttons)
- [ ] UnitsSettingsView.swift (3 buttons)
- [ ] PrivacySecurityView.swift
- [ ] SettingsListView.swift

### FoodTracking Module (0/20)
- [ ] FoodConfirmationView.swift (5 buttons)
- [ ] FoodLoggingView.swift (meal buttons)
- [ ] WaterTrackingView.swift (water increment)
- [ ] PhotoInputView.swift

### Workouts Module (0/15)
- [ ] WorkoutBuilderView.swift (4 buttons)
- [ ] WorkoutDetailView.swift
- [ ] TemplatePickerView.swift
- [ ] WorkoutListView.swift

### Dashboard Module (0/10)
- [ ] QuickActionsCard.swift
- [ ] Various dashboard cards

### Onboarding Module (0/50)
- [ ] OnboardingNavigationButtons.swift (2 custom)
- [ ] PersonaSelectionView.swift
- [ ] ChoiceCardsView.swift
- [ ] ConversationView.swift
- [ ] EngagementPreferencesView.swift

### Chat Module (0/8)
- [ ] MessageComposer.swift
- [ ] VoiceSettingsView.swift

## Migration Patterns

### Basic Migration
```swift
// OLD
.buttonStyle(.borderedProminent)
// NEW
StandardButton(style: .primary)
```

### Icon Button Migration
```swift
// OLD
Button { } label: { Image(systemName: "icon") }
// NEW
IconButton(icon: "icon")
```

### Custom Style Migration
```swift
// OLD
.padding().background().cornerRadius()
// NEW
StandardButton with appropriate style
```

## Notes
- ModelChip in APIConfigurationView might need custom component
- Some buttons are too specialized for StandardButton
- Navigation buttons should stay as-is