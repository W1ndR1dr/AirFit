import Foundation

extension Double {
    var kilogramsToPounds: Double { self * 2.20462 }
    var poundsToKilograms: Double { self / 2.20462 }
    
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
