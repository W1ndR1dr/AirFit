import SwiftUI

struct ConversationProgress: View {
    let completionPercentage: Double
    let currentNodeType: ConversationNode.NodeType?
    
    @State private var animatedProgress: Double = 0
    
    private let nodeTypes: [ConversationNode.NodeType] = [
        .opening,
        .goals,
        .lifestyle,
        .personality,
        .preferences,
        .confirmation
    ]
    
    private let nodeIcons: [ConversationNode.NodeType: String] = [
        .opening: "hand.wave",
        .goals: "target",
        .lifestyle: "figure.walk",
        .personality: "person.fill",
        .preferences: "slider.horizontal.3",
        .confirmation: "checkmark.circle"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animatedProgress)
                }
            }
            .frame(height: 8)
            
            // Node indicators
            HStack(spacing: 0) {
                ForEach(nodeTypes, id: \.self) { nodeType in
                    NodeIndicator(
                        nodeType: nodeType,
                        icon: nodeIcons[nodeType] ?? "circle",
                        isActive: nodeType == currentNodeType,
                        isCompleted: isNodeCompleted(nodeType)
                    )
                    
                    if nodeType != nodeTypes.last {
                        Spacer()
                    }
                }
            }
            
            // Percentage text
            Text("\(Int(completionPercentage * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = completionPercentage
            }
        }
        .onChange(of: completionPercentage) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
    
    private func isNodeCompleted(_ nodeType: ConversationNode.NodeType) -> Bool {
        guard let currentIndex = nodeTypes.firstIndex(where: { $0 == currentNodeType }),
              let nodeIndex = nodeTypes.firstIndex(where: { $0 == nodeType }) else {
            return false
        }
        
        return nodeIndex < currentIndex
    }
}

struct NodeIndicator: View {
    let nodeType: ConversationNode.NodeType
    let icon: String
    let isActive: Bool
    let isCompleted: Bool
    
    private var scale: CGFloat {
        isActive ? 1.2 : 1.0
    }
    
    private var color: Color {
        if isActive {
            return .accentColor
        } else if isCompleted {
            return .green
        } else {
            return Color(.systemGray4)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .scaleEffect(scale)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            if isActive {
                Text(nodeType.rawValue.capitalized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(color)
                    .fixedSize()
            }
        }
        .animation(.spring(response: 0.3), value: isActive)
    }
}