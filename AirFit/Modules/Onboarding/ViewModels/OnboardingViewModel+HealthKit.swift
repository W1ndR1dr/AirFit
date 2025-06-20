import Foundation

// MARK: - HealthKit Integration
extension OnboardingViewModel {
    
    func requestHealthKitAuthorization() async {
        // First try the new HealthKitProvider
        if let provider = healthPrefillProvider as? HealthKitProvider {
            do {
                let granted = try await provider.requestAuthorization()
                healthKitAuthorizationStatus = granted ? .authorized : .denied
                
                if granted {
                    await fetchHealthKitData()
                }
            } catch {
                AppLogger.error("HealthKit authorization failed", error: error, category: .health)
                healthKitAuthorizationStatus = .denied
            }
        } else {
            // Fallback to existing auth manager
            let granted = await healthKitAuthManager.requestAuthorizationIfNeeded()
            healthKitAuthorizationStatus = healthKitAuthManager.authorizationStatus
            
            if granted {
                await fetchHealthKitData()
            }
        }
        
        // Track health kit authorization
        // await analytics.trackEvent(.stateTransition, properties: ["type": "healthKitAuthorization", "granted": healthKitAuthorizationStatus == .authorized])
    }
    
    func fetchHealthKitData() async {
        guard let provider = healthPrefillProvider else { return }
        
        do {
            // Fetch all health data
            if let healthProvider = provider as? HealthKitProvider {
                let snapshot = try await healthProvider.fetchHealthSnapshot()
                
                // Update all relevant fields
                self.healthKitData = snapshot
                self.currentWeight = snapshot.weight
                
                // Update sleep window if available
                if let sleepSchedule = snapshot.sleepSchedule {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    sleepWindow.bedTime = formatter.string(from: sleepSchedule.bedtime)
                    sleepWindow.wakeTime = formatter.string(from: sleepSchedule.waketime)
                }
            } else {
                // Fallback to basic fetching
                if let weight = try await provider.fetchCurrentWeight() {
                    currentWeight = weight
                }
                
                if let sleepData = try await provider.fetchTypicalSleepWindow() {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    sleepWindow.bedTime = formatter.string(from: sleepData.bed)
                    sleepWindow.wakeTime = formatter.string(from: sleepData.wake)
                }
                
                healthKitData = HealthKitSnapshot(
                    weight: currentWeight,
                    height: nil,
                    age: nil,
                    sleepSchedule: nil,
                    activityMetrics: nil
                )
            }
        } catch {
            AppLogger.error("Failed to fetch HealthKit data", error: error, category: .health)
        }
    }
}