import Foundation
import HealthKit
import Observation

/// Real-time energy tracking with observer queries for live TDEE updates
@Observable
@MainActor
final class EnergyTracker {
    private let healthStore = HKHealthStore()

    // Real-time values (updated when Apple Watch syncs)
    var todayTDEE: Int = 0
    var todayActiveCalories: Int = 0
    var todayBasalCalories: Int = 0
    var isAuthorized = false
    var lastUpdated: Date?

    private let activeEnergyType = HKQuantityType(.activeEnergyBurned)
    private let basalEnergyType = HKQuantityType(.basalEnergyBurned)

    init() {
        Task {
            await setup()
        }
    }

    private func setup() async {
        #if targetEnvironment(simulator)
        // Use mock data in simulator (no Apple Watch)
        loadMockData()
        return
        #endif

        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKObjectType> = [activeEnergyType, basalEnergyType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            await fetchTodayEnergy()
            setupObservers()
        } catch {
            print("EnergyTracker auth failed: \(error)")
        }
    }

    /// Mock data for simulator testing
    private func loadMockData() {
        isAuthorized = true
        todayActiveCalories = 487  // Morning workout + walking
        todayBasalCalories = 1680  // BMR for the day so far
        todayTDEE = todayActiveCalories + todayBasalCalories
        lastUpdated = Date()

        // Simulate periodic updates
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                // Slowly increment as day progresses
                self?.todayActiveCalories += Int.random(in: 5...15)
                self?.todayBasalCalories += Int.random(in: 10...20)
                self?.todayTDEE = (self?.todayActiveCalories ?? 0) + (self?.todayBasalCalories ?? 0)
                self?.lastUpdated = Date()
            }
        }
    }

    /// Fetch current energy totals
    func fetchTodayEnergy() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        // Fetch sequentially to avoid Swift 6 data race issues
        let active = await fetchSum(for: activeEnergyType, predicate: predicate)
        let basal = await fetchSum(for: basalEnergyType, predicate: predicate)

        todayActiveCalories = Int(active)
        todayBasalCalories = Int(basal)
        todayTDEE = todayActiveCalories + todayBasalCalories
        lastUpdated = Date()
    }

    private func fetchSum(for type: HKQuantityType, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let sum = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }
    }

    /// Set up observer queries for real-time updates from Apple Watch
    private func setupObservers() {
        // Observer for active energy (exercise calories)
        let activeQuery = HKObserverQuery(sampleType: activeEnergyType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { @MainActor in
                await self?.fetchTodayEnergy()
            }
        }
        healthStore.execute(activeQuery)

        // Observer for basal energy (resting calories)
        let basalQuery = HKObserverQuery(sampleType: basalEnergyType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { @MainActor in
                await self?.fetchTodayEnergy()
            }
        }
        healthStore.execute(basalQuery)
    }
}
