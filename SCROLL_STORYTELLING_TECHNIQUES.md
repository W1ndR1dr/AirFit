# Scroll-Based Storytelling Animation Techniques for iOS/SwiftUI

This document provides a comprehensive technical reference for implementing premium scroll-driven animations in iOS fitness apps using SwiftUI. These techniques are inspired by Apple's product pages, Nike Training Club, and modern web scroll storytelling patterns.

## Table of Contents
1. [Core SwiftUI Scroll Animation Techniques](#core-swiftui-scroll-animation-techniques)
2. [Premium Animation Patterns](#premium-animation-patterns)
3. [Advanced Effects](#advanced-effects)
4. [Performance Optimization](#performance-optimization)
5. [Fitness App Implementation Suggestions](#fitness-app-implementation-suggestions)

---

## Core SwiftUI Scroll Animation Techniques

### 1. scrollTransition Modifier (iOS 17+)

The `.scrollTransition()` modifier is the foundation of modern SwiftUI scroll animations. It applies transitions as views appear/disappear in scroll containers.

**Key Concepts:**
- **ScrollTransitionPhase**: Represents view states during scroll
  - `.topLeading` (value: -1): View entering from top/leading edge
  - `.identity` (value: 0): View fully visible on screen
  - `.bottomTrailing` (value: 1): View exiting at bottom/trailing edge

**Basic Pattern:**
```swift
ScrollView {
    ForEach(items) { item in
        ItemView(item)
            .scrollTransition { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0)
                    .scaleEffect(phase.isIdentity ? 1 : 0.75)
            }
    }
}
```

**Configuration Types:**
- `.identity`: No animation, instant transitions
- `.animated`: Standard animated transitions
- `.interactive`: Smooth, gesture-driven transitions (best for scroll)

**Advanced Usage with phase.value:**
```swift
.scrollTransition(.interactive) { content, phase in
    content
        .opacity(1.0 - abs(phase.value))
        .scaleEffect(1.0 - (abs(phase.value) * 0.3))
        .blur(radius: abs(phase.value) * 5)
        .offset(y: phase.value * 20)
}
```

**Asymmetrical Transitions:**
```swift
.scrollTransition { content, phase in
    content
        .rotation3DEffect(
            .degrees(phase == .topLeading ? 15 : -15),
            axis: (x: 1, y: 0, z: 0)
        )
        .opacity(phase.isIdentity ? 1 : 0.3)
}
```

**Resources:**
- [Hacking with Swift: scrollTransition tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-views-scroll-with-a-custom-transition)
- [Create with Swift: Symmetrical and asymmetrical transitions](https://www.createwithswift.com/symmetrical-and-asymmetrical-transitions-in-swiftui-with-the-scroll-transition-modifier/)
- [Apple Developer: scrollTransition documentation](https://developer.apple.com/documentation/SwiftUI/View/scrollTransition(_:axis:transition:))

---

### 2. GeometryReader for Parallax & Offset Tracking

GeometryReader provides precise control over scroll position for custom animations.

**Tracking Scroll Offset:**
```swift
ScrollView {
    VStack {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .named("scroll")).minY

            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: minY
            )
        }
        .frame(height: 0)

        // Your content here
    }
}
.coordinateSpace(name: "scroll")
.onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
    // Use offset for animations
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

**Parallax Effect Pattern:**
```swift
GeometryReader { geometry in
    let offset = geometry.frame(in: .global).minY
    let parallaxOffset = offset * 0.5 // Moves at half speed

    Image("background")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .offset(y: parallaxOffset)
        .frame(height: 300)
}
.frame(height: 300)
.clipped()
```

**Hero Image Parallax (Apple-style):**
```swift
ScrollView {
    GeometryReader { geo in
        let minY = geo.frame(in: .global).minY
        let size = geo.size
        let progress = minY / size.height

        Image("hero")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height + max(0, minY))
            .offset(y: -minY)
            .brightness(progress * 0.2)
    }
    .frame(height: 400)

    // Rest of content
}
```

**Stretchy Header (Pull-Down Effect):**
```swift
GeometryReader { geo in
    let minY = geo.frame(in: .global).minY
    let height = max(200, 200 + minY) // Stretches when pulled

    HeaderView()
        .frame(height: height)
        .offset(y: -minY) // Sticks to top
}
.frame(height: 200)
```

**Resources:**
- [Hacking with iOS: ScrollView effects using GeometryReader](https://www.hackingwithswift.com/books/ios-swiftui/scrollview-effects-using-geometryreader)
- [Swift by Sundell: Observing ScrollView content offset](https://www.swiftbysundell.com/articles/observing-swiftui-scrollview-content-offset/)
- [DEV Community: Modern parallax effects in SwiftUI](https://dev.to/sebastienlato/how-to-build-modern-parallax-scroll-effects-in-swiftui-20n3)

---

### 3. ScrollTargetBehavior for Snapping (iOS 17+)

Create paginated carousels and snap-to-section scrolling.

**Paging Behavior (Full-screen snapping):**
```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 0) {
        ForEach(items) { item in
            FeatureCard(item)
                .containerRelativeFrame(.horizontal)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.scrollIndicators(.hidden)
```

**View-Aligned Snapping (Snap to individual items):**
```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 16) {
        ForEach(workouts) { workout in
            WorkoutCard(workout)
                .frame(width: 280)
        }
    }
    .scrollTargetLayout()
    .padding(.horizontal, 20)
}
.scrollTargetBehavior(.viewAligned)
.safeAreaPadding(.horizontal, 20) // iOS 17+
```

**Custom Snapping Points:**
```swift
struct CustomSnapBehavior: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        // Snap to nearest 100 points
        let roundedOffset = round(target.rect.minY / 100) * 100
        target.rect.origin.y = roundedOffset
    }
}

ScrollView {
    // Content
}
.scrollTargetBehavior(CustomSnapBehavior())
```

**Important Notes:**
- For horizontal paging, use `spacing: 0` in LazyHStack
- Combine with `.containerRelativeFrame()` for full-width cards
- Use `.ignoresSafeArea(.container, edges: .horizontal)` if safe area interferes
- iOS 17+ only; use fallback for earlier versions

**Resources:**
- [Hacking with Swift: ScrollView snap with paging](https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-scrollview-snap-with-paging-or-between-child-views)
- [Swift with Majid: Mastering ScrollView Target Behavior](https://swiftwithmajid.com/2023/06/20/mastering-scrollview-in-swiftui-target-behavior/)
- [Apple Developer: ScrollTargetBehavior documentation](https://developer.apple.com/documentation/swiftui/scrolltargetbehavior)

---

### 4. onScrollGeometryChange (iOS 18+)

The newest and cleanest way to track scroll position without GeometryReader hacks.

**Basic Usage:**
```swift
@State private var scrollPosition: CGFloat = 0

ScrollView {
    // Content
}
.onScrollGeometryChange(for: CGFloat.self) { geometry in
    geometry.contentOffset.y
} action: { oldValue, newValue in
    scrollPosition = newValue
}
```

**Advanced: Track Multiple Values:**
```swift
struct ScrollInfo: Equatable {
    let offset: CGFloat
    let contentSize: CGSize
    let containerSize: CGSize

    var progress: Double {
        let scrollableHeight = contentSize.height - containerSize.height
        return scrollableHeight > 0 ? offset / scrollableHeight : 0
    }
}

@State private var scrollInfo = ScrollInfo(offset: 0, contentSize: .zero, containerSize: .zero)

ScrollView {
    // Content
}
.onScrollGeometryChange(for: ScrollInfo.self) { geometry in
    ScrollInfo(
        offset: geometry.contentOffset.y,
        contentSize: geometry.contentSize,
        containerSize: geometry.containerSize
    )
} action: { oldValue, newValue in
    scrollInfo = newValue
}
```

**Resources:**
- [Donny Wals: Building a stretchy header with onScrollGeometryChange](https://www.donnywals.com/building-a-stretchy-header-view-with-swiftui-on-ios-18/)
- [Apple Developer: WWDC24 - Create custom visual effects](https://developer.apple.com/videos/play/wwdc2024/10151/)

---

## Premium Animation Patterns

### 1. Parallax Layers (Multi-Speed Scrolling)

Create depth by moving layers at different speeds.

**Three-Layer Parallax:**
```swift
ScrollView {
    ZStack(alignment: .top) {
        // Background layer (slowest)
        GeometryReader { geo in
            Image("background")
                .offset(y: geo.frame(in: .global).minY * 0.3)
        }
        .frame(height: 500)

        // Mid layer (medium speed)
        GeometryReader { geo in
            Image("midground")
                .offset(y: geo.frame(in: .global).minY * 0.6)
        }
        .frame(height: 500)

        // Foreground (normal speed)
        VStack {
            // Your content
        }
    }
}
```

**Fitness App Example - Workout Stats Reveal:**
```swift
ScrollView {
    GeometryReader { geo in
        let minY = geo.frame(in: .global).minY

        ZStack {
            // Background gradient moves slower
            LinearGradient(...)
                .offset(y: minY * 0.4)

            // Stats cards move at medium speed
            HStack {
                StatCard(...)
            }
            .offset(y: minY * 0.7)
        }
    }
    .frame(height: 300)
}
```

**Web Inspiration:**
- The New York Times "Tomato Can Blues" uses layered parallax for comic-style journalism
- Apple's product pages layer text over images at different speeds
- Nike Training Club's workout reveal uses subtle depth effects

**Resources:**
- [Webflow: What's a parallax effect?](https://webflow.com/blog/parallax-scrolling)
- [Design+Code: Parallax ScrollView handbook](https://designcode.io/swiftui-handbook-parallax-scrollview/)

---

### 2. Fade & Scale Transitions

Elements fade in and grow as they enter the viewport.

**Basic Fade-In on Scroll:**
```swift
.scrollTransition(.interactive) { content, phase in
    content
        .opacity(phase.isIdentity ? 1 : 0.3)
        .scaleEffect(phase.isIdentity ? 1 : 0.8)
}
```

**Staggered Reveal (Cards appearing one after another):**
```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemCard(item)
        .scrollTransition(.interactive) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(phase.isIdentity ? 1 : 0.9)
                .offset(y: phase.isIdentity ? 0 : 20)
        }
        .animation(.spring(duration: 0.5).delay(Double(index) * 0.1), value: phase)
}
```

**Apple-Style Feature Reveal:**
```swift
GeometryReader { geo in
    let minY = geo.frame(in: .global).minY
    let screenHeight = UIScreen.main.bounds.height
    let progress = max(0, min(1, (screenHeight - minY) / screenHeight))

    VStack {
        Text("Amazing Feature")
            .font(.system(size: 60, weight: .bold))
            .opacity(progress)
            .scaleEffect(0.8 + (progress * 0.2))
            .blur(radius: (1 - progress) * 10)
    }
}
```

**Fitness App Usage:**
- Fade in workout cards as user scrolls through program
- Scale up achievement badges when they come into view
- Reveal nutrition goal breakdown with staggered animation

---

### 3. 3D Rotation & Perspective

Add depth with rotation effects tied to scroll.

**Card Rotation on Scroll:**
```swift
.scrollTransition(.interactive) { content, phase in
    content
        .rotation3DEffect(
            .degrees(phase.value * 15),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
}
```

**Carousel with 3D Effect:**
```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 20) {
        ForEach(exercises) { exercise in
            ExerciseCard(exercise)
                .scrollTransition(.interactive) { content, phase in
                    content
                        .rotation3DEffect(
                            .degrees(phase.value * 30),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .offset(x: phase.value * -100)
                }
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
```

**Helix-Style Spinning:**
```swift
GeometryReader { geo in
    let offset = geo.frame(in: .global).minY
    let rotation = (offset / 10).truncatingRemainder(dividingBy: 360)

    Image("icon")
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 1, y: 1, z: 0)
        )
}
```

**Fitness App Usage:**
- 3D workout card flip to reveal exercise details
- Rotating nutrition charts as user scrolls
- Depth effect on progress rings

**Resources:**
- [Medium: Mastering Scroll Transitions - Rotation Effects](https://medium.com/@chaudharyyagh/mastering-scroll-transitions-in-swiftui-paging-parallax-and-rotation-effects-fb0720ff5e49)

---

### 4. Color & Background Transitions

Smooth color changes between content sections.

**Gradient Background Transition:**
```swift
@State private var scrollProgress: Double = 0

ScrollView {
    VStack(spacing: 0) {
        Section1()
            .frame(height: 800)
        Section2()
            .frame(height: 800)
    }
}
.background(
    LinearGradient(
        colors: [
            Color.blue.opacity(1 - scrollProgress),
            Color.purple.opacity(scrollProgress)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
)
.onScrollGeometryChange(for: Double.self) { geometry in
    let offset = geometry.contentOffset.y
    return min(max(offset / 800, 0), 1)
} action: { _, newValue in
    withAnimation(.easeInOut) {
        scrollProgress = newValue
    }
}
```

**Section-Based Color Changes:**
```swift
struct ColorfulScrollView: View {
    let sections = [
        ("Strength", Color.red),
        ("Cardio", Color.orange),
        ("Flexibility", Color.green)
    ]
    @State private var currentColor: Color = .red

    var body: some View {
        ScrollView {
            ForEach(sections, id: \.0) { section in
                SectionView(title: section.0)
                    .frame(height: 600)
                    .onAppear {
                        withAnimation {
                            currentColor = section.1
                        }
                    }
            }
        }
        .background(currentColor.gradient)
    }
}
```

**Fitness App Usage:**
- Different background colors for different workout types
- Gradient transitions between nutrition and exercise sections
- Theme changes based on time of day shown in insights

---

### 5. Sticky Headers with Morphing

Headers that stick, shrink, and transform as you scroll.

**Collapsible Header Pattern:**
```swift
@State private var headerHeight: CGFloat = 200
private let minHeaderHeight: CGFloat = 60

ScrollView {
    VStack(spacing: 0) {
        // Sticky header
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let progress = max(0, min(1, -minY / (200 - 60)))

            HStack {
                // Large title when expanded
                Text("Workouts")
                    .font(.system(size: 34 - (progress * 14)))
                    .opacity(1 - progress)

                Spacer()

                // Small title when collapsed
                Text("Workouts")
                    .font(.headline)
                    .opacity(progress)
            }
            .padding()
            .frame(height: 200 - (progress * 140))
            .background(.ultraThinMaterial)
        }
        .frame(height: 200)
        .zIndex(1)

        // Content
        ForEach(items) { item in
            ItemRow(item)
        }
    }
}
```

**Stretchy + Collapsible Header (iOS 18):**
```swift
ScrollView {
    VStack(spacing: 0) {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let height = max(60, 200 + minY)
            let progress = (height - 60) / 140

            ZStack {
                // Background image
                Image("header")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .opacity(progress)
                    .blur(radius: (1 - progress) * 5)

                // Title overlay
                VStack {
                    Spacer()
                    Text("Your Progress")
                        .font(.system(size: 30 + (progress * 20)))
                        .bold()
                }
                .padding()
            }
            .frame(height: height)
            .offset(y: -minY)
        }
        .frame(height: 200)

        // Scrollable content
        LazyVStack {
            ForEach(items) { item in
                ItemView(item)
            }
        }
    }
}
```

**Third-Party Library Option:**
```swift
// Using exyte/ScalingHeaderScrollView
ScalingHeaderScrollView {
    // Header content
} content: {
    // Scrollable content
}
.height(min: 60, max: 300)
.collapseProgress($progress)
```

**Fitness App Usage:**
- Profile header that shrinks to show name/avatar
- Workout detail header with large exercise image
- Stats dashboard header with key metrics

**Resources:**
- [Medium: Creating a Collapsible Animated Sticky Header in SwiftUI](https://naufaladli0406.medium.com/creating-a-collapsible-animated-sticky-header-in-swiftui-for-ios-17-0b938c055134)
- [GitHub: exyte/ScalingHeaderScrollView](https://github.com/exyte/ScalingHeaderScrollView)
- [objc.io: Sticky Headers for Scroll Views](https://talk.objc.io/episodes/S01E333-sticky-headers-for-scroll-views)

---

### 6. Text Reveal Animations

Character-by-character or word-by-word text reveals.

**TypeWriter Effect:**
```swift
struct TypewriterText: View {
    let text: String
    @State private var displayedText = ""

    var body: some View {
        Text(displayedText)
            .task {
                for character in text {
                    displayedText.append(character)
                    try? await Task.sleep(for: .milliseconds(50))
                }
            }
    }
}
```

**Scroll-Triggered Word Reveal:**
```swift
struct ScrollRevealText: View {
    let words: [String]
    @State private var visibleWords: Set<Int> = []

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .opacity(visibleWords.contains(index) ? 1 : 0)
                    .scrollTransition(.interactive) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0)
                    }
                    .onAppear {
                        withAnimation(.easeIn.delay(Double(index) * 0.1)) {
                            visibleWords.insert(index)
                        }
                    }
            }
        }
    }
}
```

**TextRenderer for Character Animation (iOS 18+):**
```swift
struct AnimatedTextRenderer: TextRenderer {
    @State var progress: Double = 0

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for (index, glyph) in run.enumerated() {
                    let charProgress = min(1, max(0, progress - (Double(index) * 0.1)))

                    context.opacity = charProgress
                    context.draw(glyph, at: glyph.position)
                }
            }
        }
    }
}

Text("Your achievement unlocked!")
    .textRenderer(AnimatedTextRenderer(progress: scrollProgress))
```

**Fitness App Usage:**
- Reveal workout instructions step-by-step
- Animate achievement text when unlocked
- Progressive reveal of nutrition tips

**Resources:**
- [SwiftUI Blog: Text animation](https://swiftui.blog/text-animation/)
- [Rudrank: TextRenderer to animate words](https://rudrank.com/exploring-swiftui-textrenderer-to-animate-words)
- [Design+Code: Text Transition with Text Renderer](https://designcode.io/swiftui-handbook-text-transition-with-text-renderer/)

---

### 7. Progress Indicators Tied to Scroll

Visual feedback showing how far through content the user has scrolled.

**Reading Progress Bar:**
```swift
@State private var scrollProgress: Double = 0

VStack(spacing: 0) {
    // Progress bar
    GeometryReader { geo in
        Rectangle()
            .fill(.blue)
            .frame(width: geo.size.width * scrollProgress)
    }
    .frame(height: 4)

    ScrollView {
        VStack {
            // Content
        }
    }
    .onScrollGeometryChange(for: Double.self) { geometry in
        let contentHeight = geometry.contentSize.height
        let containerHeight = geometry.containerSize.height
        let offset = geometry.contentOffset.y
        let scrollable = contentHeight - containerHeight

        return scrollable > 0 ? offset / scrollable : 0
    } action: { _, newValue in
        scrollProgress = max(0, min(1, newValue))
    }
}
```

**Circular Progress Indicator:**
```swift
struct ScrollProgressCircle: View {
    let progress: Double

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(Color.blue, lineWidth: 3)
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(-90))
            .animation(.linear, value: progress)
    }
}
```

**Section Progress Dots:**
```swift
struct SectionProgress: View {
    let totalSections: Int
    let currentSection: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSections, id: \.self) { index in
                Circle()
                    .fill(index <= currentSection ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentSection ? 1.3 : 1.0)
                    .animation(.spring(), value: currentSection)
            }
        }
    }
}
```

**Fitness App Usage:**
- Workout progress through exercise list
- Nutrition log completion indicator
- Onboarding flow progress
- Weekly challenge completion

**Resources:**
- [Hacking with Swift: ProgressView tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-progress-on-a-task-using-progressview)
- [Medium: Creating Smooth Progress Indicators](https://medium.com/@makbariengineer/creating-smooth-progress-indicators-in-swiftui-a-step-by-step-guide-5dd595deaaa1)

---

## Advanced Effects

### 1. Image Sequence Animation (Apple Style)

Apple's product pages often use frame-by-frame image sequences.

**Scroll-Driven Frame Animation:**
```swift
struct ImageSequenceView: View {
    let totalFrames = 60
    @State private var currentFrame = 0

    var body: some View {
        ScrollView {
            GeometryReader { geo in
                let offset = geo.frame(in: .global).minY
                let progress = max(0, min(1, -offset / 1000))
                let frame = Int(progress * Double(totalFrames - 1))

                Image("frame_\(frame)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .frame(height: 400)

            // Spacer to enable scrolling
            Color.clear.frame(height: 1400)
        }
    }
}
```

**Canvas-Based Animation:**
```swift
Canvas { context, size in
    let progress = scrollProgress
    let frameIndex = Int(progress * Double(frames.count - 1))

    if let image = frames[frameIndex] {
        context.draw(image, in: CGRect(origin: .zero, size: size))
    }
}
.frame(height: 400)
```

**When to Use:**
- Rotating 3D product views (fitness equipment)
- Animating through exercise form demonstrations
- Complex motion graphics that can't be code-generated

**Resources:**
- [CSS-Tricks: Apple Product Page Scrolling Animations](https://css-tricks.com/lets-make-one-of-those-fancy-scrolling-animations-used-on-apple-product-pages/)
- [Awwwards: Apple AirPods Pro scroll-triggered animation](https://www.awwwards.com/inspiration/product-scroll-triggered-animation-apple-airpods-pro)

---

### 2. Blur & Material Effects

Dynamic blur that changes with scroll position.

**Progressive Blur:**
```swift
.scrollTransition(.interactive) { content, phase in
    content
        .blur(radius: abs(phase.value) * 10)
}
```

**Background Blur on Scroll:**
```swift
GeometryReader { geo in
    let minY = geo.frame(in: .global).minY
    let blurAmount = max(0, min(20, -minY / 10))

    Image("background")
        .blur(radius: blurAmount)
}
```

**Material Intensity Changes:**
```swift
.background(
    .ultraThinMaterial
        .opacity(scrollProgress)
)
```

**Fitness App Usage:**
- Blur background as modal slides up
- Frosted glass effect on floating stats
- Depth of field on workout previews

---

### 3. Offset & Translation

Horizontal/vertical movement tied to scroll.

**Horizontal Reveal on Vertical Scroll:**
```swift
.scrollTransition(.interactive) { content, phase in
    content
        .offset(x: phase.value * -100)
}
```

**Diagonal Movement:**
```swift
.offset(
    x: phase.value * 50,
    y: phase.value * -30
)
```

**Staggered Offsets:**
```swift
ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    ItemView(item)
        .scrollTransition { content, phase in
            content
                .offset(x: phase.value * CGFloat(index % 2 == 0 ? -50 : 50))
        }
}
```

---

### 4. Chapter/Section Transitions

Full-screen section changes with dramatic transitions.

**Full-Screen Section Snapping:**
```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(chapters) { chapter in
            ChapterView(chapter)
                .containerRelativeFrame([.horizontal, .vertical])
                .scrollTransition { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.95)
                        .opacity(phase.isIdentity ? 1 : 0.5)
                }
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.ignoresSafeArea()
```

**Chapter Progress Indicator:**
```swift
@State private var currentChapter = 0

VStack {
    HStack {
        ForEach(0..<chapters.count, id: \.self) { index in
            Rectangle()
                .fill(index == currentChapter ? Color.white : Color.white.opacity(0.3))
                .frame(height: 2)
        }
    }
    .padding()

    ScrollView {
        // Chapters
    }
    .onScrollGeometryChange(for: Int.self) { geometry in
        Int(geometry.contentOffset.y / geometry.containerSize.height)
    } action: { _, newValue in
        currentChapter = newValue
    }
}
```

**Fitness App Usage:**
- Workout program overview (one chapter per week)
- Nutrition guide sections
- Tutorial/onboarding flow

---

### 5. Metal Shaders & Custom Effects (iOS 17+)

SwiftUI Shaders unlock performance and creativity.

**Wave Distortion:**
```swift
.visualEffect { content, proxy in
    content
        .distortionEffect(
            ShaderLibrary.wave(
                .float(scrollProgress * 10)
            ),
            maxSampleOffset: .zero
        )
}
```

**Color Grading Based on Scroll:**
```swift
.colorEffect(
    ShaderLibrary.colorGrade(
        .float(scrollProgress)
    )
)
```

**Custom Shader Example:**
```metal
// Wave.metal
[[ stitchable ]] half4 wave(float2 position, half4 color, float time) {
    float2 uv = position / float2(375, 812);
    float wave = sin(uv.y * 10.0 + time) * 0.1;
    float2 offset = float2(wave, 0);
    return color;
}
```

**When to Use:**
- High-performance custom effects
- Unique brand-specific animations
- Complex visual transformations

**Resources:**
- [Apple Developer: WWDC24 - Create custom visual effects](https://developer.apple.com/videos/play/wwdc2024/10151/)

---

## Performance Optimization

### 1. Use Lazy Stacks

**Do This:**
```swift
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemView(item)
        }
    }
}
```

**Not This:**
```swift
ScrollView {
    VStack { // Renders ALL items immediately
        ForEach(items) { item in
            ItemView(item)
        }
    }
}
```

**Why:** LazyVStack/LazyHStack only render visible views, crucial for performance with many items.

---

### 2. Minimize GeometryReader Usage

**Avoid:**
```swift
// GeometryReader on every item
ForEach(items) { item in
    GeometryReader { geo in
        ItemView(item, offset: geo.frame(in: .global).minY)
    }
}
```

**Better:**
```swift
// Single GeometryReader with PreferenceKey
ScrollView {
    ForEach(items) { item in
        ItemView(item)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: OffsetPreferenceKey.self,
                        value: [item.id: geo.frame(in: .global).minY]
                    )
                }
            )
    }
}
.onPreferenceChange(OffsetPreferenceKey.self) { offsets in
    // Use offsets for all items
}
```

---

### 3. Use .drawingGroup() Sparingly

**When to Use:**
- Complex animations with many overlapping views
- Heavy use of blend modes or CoreImage filters
- Proven performance issues (profile first!)

**When NOT to Use:**
- Simple lists or grids
- Text-heavy content
- Already-performant views

**Example:**
```swift
ComplexAnimatedView()
    .drawingGroup() // Flattens to GPU texture
```

**Cost:** Uploading to GPU has overhead. Only use when it actually helps.

---

### 4. Optimize State Updates

**Avoid:**
```swift
// Updates on every scroll pixel
.onScrollGeometryChange(for: CGFloat.self) { geo in
    geo.contentOffset.y
} action: { _, newValue in
    scrollOffset = newValue // Triggers view update constantly
}
```

**Better:**
```swift
// Update only when crossing thresholds
.onScrollGeometryChange(for: Int.self) { geo in
    Int(geo.contentOffset.y / 100) // Only updates every 100 points
} action: { _, newValue in
    scrollSection = newValue
}
```

---

### 5. Profile with Instruments

**Key Instruments:**
- **Time Profiler**: Find CPU bottlenecks
- **Core Animation**: Track frame rate and hitches
- **View Body**: See which views rebuild most often
- **Hangs**: Detect main thread blocking

**Target Metrics:**
- **60 FPS** on standard displays (16.67ms per frame)
- **120 FPS** on ProMotion displays (8.33ms per frame)
- **Hitch Time Ratio**: < 5ms per second

**How to Profile:**
1. Run your app in Release mode
2. Open Instruments (Cmd+I in Xcode)
3. Select Time Profiler or Core Animation
4. Record while scrolling through your UI
5. Look for expensive operations in the call tree

---

### 6. Reduce Motion Accessibility

**Respect User Preferences:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    ItemView()
        .scrollTransition(.interactive) { content, phase in
            if reduceMotion {
                content // No animation
            } else {
                content
                    .opacity(phase.isIdentity ? 1 : 0)
                    .scaleEffect(phase.isIdentity ? 1 : 0.8)
            }
        }
}
```

**Why:** Some users experience motion sickness or vestibular disorders from animations.

---

### 7. Image Optimization

**Best Practices:**
- Use `.resizable()` and `.aspectRatio(contentMode:)` to prevent layout issues
- Cache images with `AsyncImage` for remote content
- Use asset catalogs for automatic size variants
- Compress images appropriately (don't load 4K images for thumbnails)

**Example:**
```swift
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        PlaceholderView()
    case .empty:
        ProgressView()
    @unknown default:
        EmptyView()
    }
}
.frame(width: 200, height: 200)
```

---

### 8. Animation Performance Tips

**Use Hardware-Accelerated Modifiers:**
- `.scaleEffect()` - GPU accelerated
- `.opacity()` - GPU accelerated
- `.rotation3DEffect()` - GPU accelerated

**Avoid:**
- `.frame()` changes - Layout is expensive
- `.offset()` by large amounts repeatedly
- Animating `.font()` size directly

**Smooth Animations:**
```swift
.animation(.spring(duration: 0.5, bounce: 0.3), value: someState)
```

**Resources:**
- [Medium: Optimizing SwiftUI Performance](https://medium.com/@garejakirit/optimizing-swiftui-performance-best-practices-93b9cc91c623)
- [Apple Developer: Explore UI animation hitches](https://developer.apple.com/videos/play/tech-talks/10855/)
- [SwiftUI 120FPS Challenge](https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps)

---

## Fitness App Implementation Suggestions

### 1. Workout Program Overview

**Effect:** Chapter-based full-screen scrolling with progress indicator

**Implementation:**
- `.scrollTargetBehavior(.paging)` for full-screen weeks
- Circular progress ring showing week completion
- Hero images for each week with parallax
- Fade-in exercise previews as user scrolls

**Code Pattern:**
```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(weeks) { week in
            WeekView(week)
                .containerRelativeFrame([.horizontal, .vertical])
                .scrollTransition { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.9)
                        .blur(radius: phase.isIdentity ? 0 : 5)
                }
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.overlay(alignment: .top) {
    ProgressIndicator(current: currentWeek, total: weeks.count)
}
```

---

### 2. Exercise Detail Page

**Effect:** Stretchy header with exercise video/image, collapsing to small navbar

**Implementation:**
- GeometryReader-based stretchy header
- Video or GIF showing exercise form
- Instructions fade in as header collapses
- Sticky section headers for sets/reps

**Code Pattern:**
```swift
ScrollView {
    VStack(spacing: 0) {
        // Stretchy header
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let height = max(80, 300 + minY)

            ExerciseVideoPlayer()
                .frame(height: height)
                .offset(y: -minY)
        }
        .frame(height: 300)

        // Instructions
        LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
            Section {
                InstructionsView()
            } header: {
                Text("How to Perform")
                    .headerStyle()
            }

            Section {
                SetsView()
            } header: {
                Text("Your Sets")
                    .headerStyle()
            }
        }
    }
}
```

---

### 3. Nutrition Log Timeline

**Effect:** Parallax meal cards with staggered reveal, progress bar at top

**Implementation:**
- Scroll progress bar showing daily calorie progress
- Meal cards fade in with slight scale
- Background gradient transitions through day (morning blue → evening purple)
- Macro rings animate as they enter viewport

**Code Pattern:**
```swift
VStack(spacing: 0) {
    // Progress bar
    CalorieProgressBar(current: consumed, goal: goal)

    ScrollView {
        LazyVStack(spacing: 20) {
            ForEach(meals) { meal in
                MealCard(meal)
                    .scrollTransition(.interactive) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.3)
                            .scaleEffect(phase.isIdentity ? 1 : 0.95)
                            .offset(y: phase.isIdentity ? 0 : 20)
                    }
            }
        }
        .padding()
    }
}
.background(
    timeBasedGradient(progress: scrollProgress)
)
```

---

### 4. Achievement Showcase

**Effect:** 3D carousel of achievement badges with rotation

**Implementation:**
- Horizontal scroll with `.viewAligned` snapping
- Centered badge has scale effect
- 3D rotation as badges move in/out of center
- Confetti animation when badge is unlocked

**Code Pattern:**
```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 30) {
        ForEach(achievements) { achievement in
            AchievementBadge(achievement)
                .frame(width: 200, height: 250)
                .scrollTransition(.interactive) { content, phase in
                    content
                        .scaleEffect(1 - (abs(phase.value) * 0.3))
                        .rotation3DEffect(
                            .degrees(phase.value * 30),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(1 - (abs(phase.value) * 0.5))
                }
        }
    }
    .scrollTargetLayout()
    .padding(.horizontal, 100)
}
.scrollTargetBehavior(.viewAligned)
.frame(height: 300)
```

---

### 5. Insights/Analytics Dashboard

**Effect:** Stats reveal with staggered fade-in, parallax chart layers

**Implementation:**
- Top summary cards fade in from bottom
- Chart layers move at different speeds (parallax)
- Text stats count up as they enter view
- Color transitions based on trend (green for improvement, red for decline)

**Code Pattern:**
```swift
ScrollView {
    LazyVStack(spacing: 30) {
        // Summary cards
        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                StatCard(stat)
                    .scrollTransition(.interactive) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0)
                            .offset(y: phase.isIdentity ? 0 : 30)
                    }
                    .animation(
                        .spring().delay(Double(index) * 0.05),
                        value: phase
                    )
            }
        }

        // Chart with parallax
        ZStack {
            // Background layer
            ChartBackground()
                .offset(y: scrollOffset * 0.3)

            // Data layer
            LineChart(data: workoutData)
                .offset(y: scrollOffset * 0.6)
        }
        .frame(height: 300)
    }
    .padding()
}
```

---

### 6. Onboarding Flow

**Effect:** Full-screen slides with chapter progress, smooth transitions

**Implementation:**
- Paging scroll behavior
- Progress dots at bottom
- Text reveals character-by-character
- Background image parallax on each slide

**Code Pattern:**
```swift
TabView(selection: $currentPage) {
    ForEach(Array(onboardingSteps.enumerated()), id: \.element.id) { index, step in
        OnboardingSlide(step)
            .tag(index)
    }
}
.tabViewStyle(.page(indexDisplayMode: .never))
.overlay(alignment: .bottom) {
    PageIndicator(current: currentPage, total: onboardingSteps.count)
        .padding(.bottom, 40)
}
```

---

### 7. Workout History Feed

**Effect:** Vertical scroll with card reveals, pull-to-refresh with animation

**Implementation:**
- Cards slide in from right/left alternating
- Date headers stick to top
- Swipe actions reveal with spring animation
- Workout metrics fade in after card

**Code Pattern:**
```swift
ScrollView {
    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
        ForEach(groupedWorkouts) { group in
            Section {
                ForEach(Array(group.workouts.enumerated()), id: \.element.id) { index, workout in
                    WorkoutCard(workout)
                        .scrollTransition(.interactive) { content, phase in
                            content
                                .offset(x: phase.value * (index % 2 == 0 ? 100 : -100))
                                .opacity(phase.isIdentity ? 1 : 0)
                        }
                }
            } header: {
                DateHeader(group.date)
            }
        }
    }
}
.refreshable {
    await refreshWorkouts()
}
```

---

## Summary: Best Practices

1. **Start Simple**: Use `.scrollTransition()` for most effects (iOS 17+)
2. **Use Lazy Stacks**: LazyVStack/LazyHStack for performance
3. **Prefer Native APIs**: `onScrollGeometryChange` (iOS 18) > GeometryReader hacks
4. **Profile First**: Don't optimize prematurely; use Instruments to find real bottlenecks
5. **Respect Accessibility**: Check `reduceMotion` environment variable
6. **Test on Device**: Simulator performance doesn't reflect real-world usage
7. **Progressive Enhancement**: Build basic functionality first, add animations after
8. **Smooth Transitions**: Use `.spring()` animations for natural feel
9. **Consistency**: Establish animation language and stick to it throughout app
10. **Purposeful Motion**: Every animation should serve UX, not just look cool

---

## Additional Resources

### Official Apple Resources
- [WWDC24: Create custom visual effects with SwiftUI](https://developer.apple.com/videos/play/wwdc2024/10151/)
- [WWDC23: Wind your way through advanced animations in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10157/)
- [Creating performant scrollable stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks)

### Web Design Inspiration
- [Webflow Blog: Parallax Scrolling Examples](https://webflow.com/blog/parallax-scrolling)
- [Creative Bloq: 14 Parallax Scrolling Websites](https://www.creativebloq.com/web-design/parallax-scrolling-1131762)
- [Framer: 10 Parallax Scrolling Examples](https://www.framer.com/blog/parallax-scrolling-examples/)

### iOS App Examples
- [Nike Training Club on Mobbin](https://mobbin.com/flows/f23f1c29-1c18-4bdf-8c87-574a4dedb894)
- [60fps.design: Nike Training Club animations](https://60fps.design/apps/nike-training-club)

### Community Tutorials
- [Hacking with Swift: SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)
- [Design+Code: SwiftUI iOS 17 Course](https://designcode.io/swiftui-ios17-scroll-transition/)
- [Swift with Majid Blog](https://swiftwithmajid.com/)

### Performance
- [SwiftUI Scroll Performance: The 120FPS Challenge](https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps)
- [Medium: Optimizing SwiftUI Performance](https://medium.com/@garejakirit/optimizing-swiftui-performance-best-practices-93b9cc91c623)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-13
**iOS Compatibility:** iOS 17+ (some features require iOS 18+)
**SwiftUI Version:** SwiftUI 5+
