import SwiftUI
import WidgetKit

/// Main entry point for all AirFit watchOS complications.
/// Registers all available complications with the system.
@main
struct AirFitWatchComplicationsBundle: WidgetBundle {
    var body: some Widget {
        MacroComplication()
        ReadinessComplication()
        VolumeComplication()
        HRRComplication()
    }
}
