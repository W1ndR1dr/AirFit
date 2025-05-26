@testable import AirFit
import Foundation

final class MockHealthKitPrefillProvider: HealthKitPrefillProviding {
    var result: Result<(bed: Date, wake: Date)?, Error> = .success(nil)

    func fetchTypicalSleepWindow() async throws -> (bed: Date, wake: Date)? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
