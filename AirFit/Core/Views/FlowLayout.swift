import SwiftUI

/// A layout that arranges views in horizontal rows, wrapping to the next row when needed
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing,
            verticalSpacing: verticalSpacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing,
            verticalSpacing: verticalSpacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat, verticalSpacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                sizes.append(size)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Wrap to next line
                    currentX = 0
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxX = max(maxX, currentX - spacing)
            }

            self.size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

/// View modifier to create a chip-style suggestion
struct SuggestionChipStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .fontWeight(.light)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.thin, in: .capsule)
    }
}

extension View {
    func suggestionChipStyle() -> some View {
        modifier(SuggestionChipStyle())
    }
}
