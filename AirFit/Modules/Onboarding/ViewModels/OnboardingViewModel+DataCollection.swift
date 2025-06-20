import Foundation

// MARK: - Data Collection Methods (HealthKit, Voice, Multi-Select)

extension OnboardingViewModel {
    
    // MARK: - HealthKit Data
    
    func requestHealthKitAuthorization() async {
        isHealthKitLoading = true
        
        // Request authorization
        let authorized = await healthKitAuthManager.requestAuthorizationIfNeeded()
        
        if authorized {
            healthKitAuthorizationStatus = .authorized
            
            // Fetch initial data
            await fetchHealthKitData()
        } else {
            healthKitAuthorizationStatus = .denied
        }
        
        isHealthKitLoading = false
    }
    
    func fetchHealthKitData() async {
        guard let provider = healthPrefillProvider else { return }
        
        // Create a basic health snapshot with what we can get
        async let weight = provider.fetchCurrentWeight()
        async let sleepWindow = provider.fetchTypicalSleepWindow()
        
        // Fetch all data concurrently
        let (weightValue, sleepData) = await (try? weight, try? sleepWindow)
        
        // Create sleep schedule if we have data
        var sleepSchedule: SleepSchedule?
        if let sleepData = sleepData {
            sleepSchedule = SleepSchedule(bedtime: sleepData.bed, waketime: sleepData.wake)
        }
        
        // Update the snapshot
        self.healthKitData = HealthKitSnapshot(
            weight: weightValue,
            sleepSchedule: sleepSchedule
        )
        
        // Auto-populate weight if available
        if let weight = weightValue {
            currentWeight = weight
            currentWeightText = formatWeight(weight)
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return formatter.string(from: NSNumber(value: weight)) ?? "\(Int(weight))"
    }
    
    // MARK: - Weight Text Input
    
    var isWeightValid: Bool {
        if !currentWeightText.isEmpty, let weight = Double(currentWeightText), weight > 0, weight < 1000 {
            return true
        }
        if !targetWeightText.isEmpty, let weight = Double(targetWeightText), weight > 0, weight < 1000 {
            return true
        }
        return false
    }
    
    // MARK: - Voice Input
    
    func startVoiceTranscription() {
        guard !isTranscribing else { return }
        
        speechService?.requestPermission { [weak self] granted in
            guard let self = self, granted else { return }
            
            Task { @MainActor in
                self.isTranscribing = true
                
                self.speechService?.startTranscription { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let transcription):
                            self.lifeContext = transcription
                        case .failure(let error):
                            self.handleError(AppError.unknown(message: error.localizedDescription))
                        }
                        self.isTranscribing = false
                    }
                }
            }
        }
    }
    
    func stopVoiceTranscription() {
        speechService?.stopTranscription()
        isTranscribing = false
    }
    
    // MARK: - Multi-Select Helpers
    
    func toggleBodyGoal(_ goal: BodyRecompositionGoal) {
        if bodyRecompositionGoals.contains(goal) {
            bodyRecompositionGoals.removeAll { $0 == goal }
        } else {
            bodyRecompositionGoals.append(goal)
        }
    }
    
    func toggleCommunicationStyle(_ style: CommunicationStyle) {
        if communicationStyles.contains(style) {
            communicationStyles.removeAll { $0 == style }
        } else {
            communicationStyles.append(style)
        }
    }
    
    func toggleInformationPreference(_ preference: InformationStyle) {
        if informationPreferences.contains(preference) {
            informationPreferences.removeAll { $0 == preference }
        } else {
            informationPreferences.append(preference)
        }
    }
}