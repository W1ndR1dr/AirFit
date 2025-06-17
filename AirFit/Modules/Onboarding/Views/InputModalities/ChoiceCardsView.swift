import SwiftUI

struct ChoiceCardsView: View {
    let options: [ChoiceOption]
    let multiSelect: Bool
    var minSelections: Int = 1
    var maxSelections: Int = Int.max
    let onSubmit: ([String]) -> Void
    
    @State private var selectedIds = Set<String>()
    @State private var showError = false
    
    private var isValid: Bool {
        if multiSelect {
            return selectedIds.count >= minSelections && selectedIds.count <= maxSelections
        } else {
            return !selectedIds.isEmpty
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Selection info for multi-select
            if multiSelect {
                HStack {
                    Text("Select \(minSelections) to \(maxSelections) options")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(selectedIds.count) selected")
                        .font(.subheadline)
                        .foregroundColor(showError ? .red : .secondary)
                }
                .padding(.horizontal)
            }
            
            // Options grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(options) { option in
                        ChoiceCard(
                            option: option,
                            isSelected: selectedIds.contains(option.id),
                            action: {
                                toggleSelection(option.id)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Submit button
            Button(action: submitChoices) {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValid ? Color.accentColor : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isValid)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func toggleSelection(_ optionId: String) {
        showError = false
        
        if multiSelect {
            if selectedIds.contains(optionId) {
                selectedIds.remove(optionId)
            } else if selectedIds.count < maxSelections {
                selectedIds.insert(optionId)
            }
        } else {
            // Single select - replace selection
            selectedIds = [optionId]
        }
        HapticService.play(.listSelection)
    }
    
    private func submitChoices() {
        guard isValid else {
            showError = true
            HapticService.play(.error)
            return
        }
        HapticService.play(.success)
        onSubmit(Array(selectedIds))
    }
}

struct ChoiceCard: View {
    let option: ChoiceOption
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Emoji if available
                if let emoji = option.emoji {
                    Text(emoji)
                        .font(.system(size: 40))
                }
                
                // Text
                Text(option.text)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .cardStyle()
            .shadow(
                color: isSelected ? Color.black.opacity(0.2) : Color.black.opacity(0.1),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}