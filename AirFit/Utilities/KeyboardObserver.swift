import SwiftUI
import Combine

/// Observable object that tracks keyboard height for proper input positioning
@MainActor
final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                withAnimation(.easeOut(duration: 0.25)) {
                    self?.keyboardHeight = height
                }
            }
            .store(in: &cancellables)

        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    self?.keyboardHeight = 0
                }
            }
            .store(in: &cancellables)
    }
}

/// View modifier that adds keyboard-aware bottom padding
struct KeyboardAdaptive: ViewModifier {
    @StateObject private var keyboard = KeyboardObserver()
    let additionalPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboard.keyboardHeight > 0 ? keyboard.keyboardHeight - additionalPadding : 0)
    }
}

extension View {
    /// Makes the view keyboard-aware by adding bottom padding when keyboard appears
    /// - Parameter additionalPadding: Amount to subtract from keyboard height (e.g., for tab bar overlap)
    func keyboardAdaptive(subtractingTabBar: CGFloat = 70) -> some View {
        modifier(KeyboardAdaptive(additionalPadding: subtractingTabBar))
    }
}
