import Foundation

extension Double {
    var kilogramsToPounds: Double { self * 2.20462 }
    var poundsToKilograms: Double { self / 2.20462 }

    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    /// Formats a distance in meters using a natural scale
    /// - Returns: Localized string representing the distance
    func formattedDistance() -> String {
        let measurement = Measurement(value: self, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter.string(from: measurement)
    }
}
