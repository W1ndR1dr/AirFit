import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func standardPadding() -> some View {
        self.padding(AppConstants.defaultPadding)
    }
    
    func cardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(AppConstants.defaultCornerRadius)
            .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    func primaryButton() -> some View {
        self
            .font(AppFonts.headline())
            .foregroundColor(AppColors.buttonText)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.buttonBackground)
            .cornerRadius(AppConstants.defaultCornerRadius)
    }
    
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(FirstAppear(action: action))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct FirstAppear: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
} 