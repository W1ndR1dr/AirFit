import Foundation
import SwiftUI

/// Adapter around `VoiceInputManager` providing food-specific enhancements.
@MainActor
final class FoodVoiceAdapter: ObservableObject, FoodVoiceAdapterProtocol {
    // MARK: - Dependencies
    private let voiceInputManager: VoiceInputProtocol

    // MARK: - Published State
    @Published private(set) var isRecording = false
    @Published private(set) var transcribedText = ""
    @Published private(set) var voiceWaveform: [Float] = []
    @Published private(set) var isTranscribing = false

    // MARK: - Callbacks
    var onFoodTranscription: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((VoiceInputState) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?

    // MARK: - Initialization
    init(voiceInputManager: VoiceInputProtocol = VoiceInputManager()) {
        self.voiceInputManager = voiceInputManager
        setupCallbacks()
    }

    private func setupCallbacks() {
        voiceInputManager.onTranscription = { [weak self] text in
            guard let self else { return }
            let processedText = self.postProcessForFood(text)
            self.transcribedText = processedText
            self.onFoodTranscription?(processedText)
        }

        voiceInputManager.onPartialTranscription = { [weak self] text in
            guard let self else { return }
            self.transcribedText = text
        }

        voiceInputManager.onWaveformUpdate = { [weak self] levels in
            guard let self else { return }
            self.voiceWaveform = levels
            self.onWaveformUpdate?(levels)
        }

        voiceInputManager.onError = { [weak self] error in
            guard let self else { return }
            self.onError?(error)
        }
        
        voiceInputManager.onStateChange = { [weak self] state in
            guard let self else { return }
            self.onStateChange?(state)
        }
    }

    // MARK: - Public Methods
    func initialize() async {
        await voiceInputManager.initialize()
    }
    
    func requestPermission() async throws -> Bool {
        try await voiceInputManager.requestPermission()
    }

    func startRecording() async throws {
        isRecording = true
        try await voiceInputManager.startRecording()
    }

    func stopRecording() async -> String? {
        isRecording = false
        let result = await voiceInputManager.stopRecording()
        return result.map { postProcessForFood($0) }
    }

    // MARK: - Food-Specific Post-Processing
    private func postProcessForFood(_ text: String) -> String {
        var processed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let foodCorrections: [String: String] = [
            // Quantity corrections
            "to eggs": "two eggs",
            "for slices": "four slices",
            "won cup": "one cup",
            "tree cups": "three cups",
            "ate ounces": "eight ounces",

            // Food name corrections
            "chicken breast": "chicken breast",
            "sweet potato": "sweet potato",
            "greek yogurt": "Greek yogurt",
            "peanut butter": "peanut butter",
            "olive oil": "olive oil",

            // Measurement corrections
            "table spoon": "tablespoon",
            "tea spoon": "teaspoon",
            "fluid ounce": "fl oz",
            "pounds": "lbs"
        ]

        for (pattern, replacement) in foodCorrections {
            processed = processed.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: [.caseInsensitive]
            )
        }

        return processed
    }
}

// MARK: - FoodVoiceServiceProtocol Conformance
extension FoodVoiceAdapter: FoodVoiceServiceProtocol {}

