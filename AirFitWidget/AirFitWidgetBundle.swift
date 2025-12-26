import SwiftUI
import WidgetKit

@main
struct AirFitWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Live Activity
        NutritionLiveActivity()

        // Lock Screen / Control Center
        QuickLogWidget()
        CameraLogWidget()
        QuickLogAccessoryWidget()
        ProteinCounterWidget()
        ReadinessWidget()

        // Home Screen
        InsightTickerWidget()
        EnergyBalanceWidget()
        MorningBriefWidget()
        StrengthTrackerWidget()
        WeeklyRhythmWidget()
        ContextualActionWidget()

        // Control Center Toggle
        TrainingDayToggleWidget()
    }
}
