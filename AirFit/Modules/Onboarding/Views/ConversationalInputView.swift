import SwiftUI

struct ConversationalInputView: View {
    let inputType: InputType
    let onSubmit: (ResponseValue) -> Void
    
    @State private var animateIn = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            switch inputType {
            case .text(let minLength, let maxLength, let placeholder):
                TextInputView(
                    minLength: minLength,
                    maxLength: maxLength,
                    placeholder: placeholder,
                    onSubmit: { text in
                        onSubmit(.text(text))
                    }
                )
                
            case .voice(let maxDuration):
                VoiceInputView(
                    maxDuration: maxDuration,
                    onSubmit: { transcription, audioData in
                        onSubmit(.voice(transcription: transcription, audioData: audioData))
                    }
                )
                
            case .singleChoice(let options):
                ChoiceCardsView(
                    options: options,
                    multiSelect: false,
                    onSubmit: { selected in
                        if let choice = selected.first {
                            onSubmit(.choice(choice))
                        }
                    }
                )
                
            case .multiChoice(let options, let minSelections, let maxSelections):
                ChoiceCardsView(
                    options: options,
                    multiSelect: true,
                    minSelections: minSelections,
                    maxSelections: maxSelections,
                    onSubmit: { selected in
                        onSubmit(.multiChoice(selected))
                    }
                )
                
            case .slider(let min, let max, let step, let labels):
                ContextualSlider(
                    min: min,
                    max: max,
                    step: step,
                    labels: labels,
                    onSubmit: { value in
                        onSubmit(.slider(value))
                    }
                )
                
            case .hybrid(let primary, let secondary):
                // For hybrid inputs, show primary by default
                // Secondary input can be accessed via a toggle or gesture
                ConversationalInputView(
                    inputType: primary,
                    onSubmit: onSubmit
                )
            }
        }
        .animation(.spring(duration: 0.5), value: inputType)
        .onAppear {
            withAnimation(.spring(duration: 0.6).delay(0.1)) {
                animateIn = true
            }
        }
    }
}