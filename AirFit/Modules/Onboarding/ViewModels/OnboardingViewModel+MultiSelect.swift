import Foundation

// MARK: - Multi-Select Helpers
extension OnboardingViewModel {
    
    func toggleBodyRecompositionGoal(_ goal: BodyRecompositionGoal) {
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
    
    func toggleInformationPreference(_ pref: InformationStyle) {
        if informationPreferences.contains(pref) {
            informationPreferences.removeAll { $0 == pref }
        } else {
            informationPreferences.append(pref)
        }
    }
}