import SwiftUI

/// Generates the AirFit app icon programmatically
struct AppIconGenerator: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.89, blue: 0.82), // Peach
                    Color(red: 0.98, green: 0.78, blue: 0.84)  // Rose
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle radial overlay for depth
            RadialGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: size * 0.7
            )
            
            // Main icon design
            ZStack {
                // Outer ring (fitness/activity)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.06
                    )
                    .frame(width: size * 0.7, height: size * 0.7)
                
                // Inner elements
                VStack(spacing: 0) {
                    // AI brain/sparkle symbol (top)
                    Image(systemName: "brain")
                        .font(.system(size: size * 0.25, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: -size * 0.05)
                    
                    // Fitness/activity lines (bottom)
                    HStack(spacing: size * 0.03) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: size * 0.02)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.9),
                                            Color.white.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: size * 0.04,
                                    height: size * (index == 1 ? 0.12 : 0.08)
                                )
                                .offset(y: index == 1 ? -size * 0.02 : 0)
                        }
                    }
                    .offset(y: size * 0.05)
                }
                
                // Subtle floating particles for "air" effect
                ForEach(0..<6) { index in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(
                            width: size * 0.02,
                            height: size * 0.02
                        )
                        .offset(
                            x: cos(Double(index) * .pi / 3) * size * 0.25,
                            y: sin(Double(index) * .pi / 3) * size * 0.25
                        )
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

/// Alternative design with a more abstract approach
struct AppIconGeneratorAlt: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.96, blue: 0.95), // Mint
                    Color(red: 0.72, green: 0.91, blue: 0.96)  // Aqua
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Abstract "A" shape combining AI and Fitness
            ZStack {
                // Left stroke of "A"
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: size * 0.08, height: size * 0.5)
                .rotationEffect(.degrees(-20))
                .offset(x: -size * 0.12, y: size * 0.05)
                
                // Right stroke of "A"
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: size * 0.08, height: size * 0.5)
                .rotationEffect(.degrees(20))
                .offset(x: size * 0.12, y: size * 0.05)
                
                // Horizontal bar with pulse effect
                HStack(spacing: size * 0.02) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(Color.white.opacity(0.8 - Double(abs(index - 2)) * 0.2))
                            .frame(width: size * 0.06, height: size * 0.06)
                    }
                }
                
                // AI sparkle at top
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.15, weight: .medium))
                    .foregroundColor(.white)
                    .offset(y: -size * 0.25)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

/// Preview helper to see different sizes
struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("AirFit App Icons")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Design 1: Brain + Activity")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        AppIconGenerator(size: 180)
                        AppIconGenerator(size: 120)
                        AppIconGenerator(size: 60)
                    }
                }
                
                VStack {
                    Text("Design 2: Abstract 'A'")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        AppIconGeneratorAlt(size: 180)
                        AppIconGeneratorAlt(size: 120)
                        AppIconGeneratorAlt(size: 60)
                    }
                }
            }
            
            // Export instructions
            VStack(alignment: .leading, spacing: 10) {
                Text("To export icons:")
                    .font(.headline)
                Text("1. Run this in Xcode Preview")
                Text("2. Right-click on the icon you like")
                Text("3. Select 'Export...'")
                Text("4. Save as PNG at different sizes")
                Text("5. Replace the existing icon files in Assets.xcassets")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    AppIconPreview()
}