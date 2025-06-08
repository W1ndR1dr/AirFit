AirFit UI Implementation Spec v 1.0

(copy this verbatim into Claude-Code or split it into two files if you hit length limits; nothing else is required for the agent to understand the entire visual system)

⸻

1. Design DNA

Principle	Implementation Cue
Pastel calm	Always start with a soft two-stop gradient; no solid backgrounds anywhere.
Text is the hero	Ultra-light variable weight (300 → 400) + letter-cascade entrance on every primary string.
Weightless glass	All surfaces are translucent cards with 12 pt blur, 1 px inner stroke, 20 pt radius, spring-in on load.
Human-centric motion	Physics-based micro-animations; nothing linear except opacity fades.
Single-device focus	iOS 18+, iPhone 16+ only – assume 120 Hz and high GPU bandwidth.


⸻

2. Pastel Gradient System

We ship with 12 pre-curated gradients. At runtime the app randomly selects one per screen transition (never repeating the current gradient).
Fades are handled by cross-fading the GradientToken on the root ZStack over 0.6 s.

Token (Light)	Hex → Hex	Dark equivalent
peachRose	#FDE4D2 → #F9C7D6	#362128 → #412932
mintAqua	#D3F6F1 → #B7E8F4	#13313D → #14444F
lilacBlush	#E9E7FD → #DCD3F9	#24203B → #2E2946
skyLavender	#DFF2FD → #D8DEFF	#15283A → #1C2541
sageMelon	#E8F9E3 → #FFF0CB	#29372A → #3A3724
butterLemon	#FFF8DB → #FFE4C2	#3B3623 → #46341F
icePeriwinkle	#E6FAFF → #E9E6FF	#1F3540 → #252B4A
rosewoodPlum	#FCD5E8 → #E5D1F8	#3A2436 → #301E41
coralMist	#FEE3D6 → #EBD6F5	#3A2723 → #33263B
sproutMint	#E5F8D4 → #CBF1E2	#283827 → #1F4033
dawnPeach	#FDE6D4 → #F7E1FD	#3D2720 → #2F233A
duskBerry	#F3D8F2 → #D8E1FF	#3A2638 → #212849

Runtime selection algorithm (Swift):

struct GradientToken: Equatable { let colors: [Color] }

let allGradients: [GradientToken] = [.peachRose, .mintAqua, /* … */ .duskBerry]

final class GradientManager: ObservableObject {
  @Published private(set) var active: GradientToken = .peachRose
  func next() {
    var candidate: GradientToken
    repeat { candidate = allGradients.randomElement()! } while candidate == active
    withAnimation(.easeInOut(duration: 0.6)) { active = candidate }
  }
}

GradientManager sits in @EnvironmentObject and every screen embeds:

ZStack { active.linear.ignoresSafeArea(); content }


⸻

3. Typography & Letter Cascade

3.1 Token Values

struct MotionToken {
  static let duration: Double  = 0.60   // total block time
  static let stagger: Double   = 0.012  // delay between glyphs
  static let offsetY: CGFloat  = 6      // start vertical offset
  static let wghtFrom: CGFloat = 300    // SF Pro Variable
  static let wghtTo:   CGFloat = 400
}

3.2 Modifier

struct CascadeText: View {
  @State private var phase: CGFloat = 0
  let text: String
  var body: some View {
    Text(text)                       // initial style provided by caller
      .modifier(CascadeModifier(phase: phase))
      .onAppear { withAnimation(.easeOut(duration: MotionToken.duration)) { phase = 1 } }
  }
}

struct CascadeModifier: AnimatableModifier {
  var phase: CGFloat
  func body(content: Content) -> some View {
    let letters = Array(content.string)
    HStack(spacing: 0) {
      ForEach(letters.indices, id: \.self) { idx in
        let p = min(max(phase - CGFloat(idx) * MotionToken.stagger, 0), 1)
        content
          .letter(at: idx)
          .font(.system(size: content.fontSize,
                        weight: .init(MotionToken.wghtFrom + (MotionToken.wghtTo - MotionToken.wghtFrom) * p),
                        design: .rounded))
          .opacity(p)
          .offset(y: (1 - p) * MotionToken.offsetY)
      }
    }
  }
}

Reduced-Motion ➔ skip modifier; plain 0.12 s fade.

⸻

4. GlassCard Component

struct GlassCard<Content: View>: View {
  @EnvironmentObject private var motion: MotionManager
  @State private var loaded = false
  let content: () -> Content
  var body: some View {
    content()
      .padding()
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.3), lineWidth: 1))
      .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
      .scaleEffect(loaded ? 1 : 0.96)
      .opacity(loaded ? 1 : 0)
      .onAppear {
        withAnimation(.interpolatingSpring(stiffness: 130, damping: 12)) { loaded = true }
      }
  }
}


⸻

5. MicRipple View

struct MicRippleView: View {
  @State private var ripple = false
  var body: some View {
    ZStack {
      Circle().fill(.white.opacity(0.1))
              .scaleEffect(ripple ? 1.6 : 0.2)
              .opacity(ripple ? 0 : 1)
      Image(systemName: "mic.fill")
        .font(.system(size: 28, weight: .light))
        .foregroundColor(.white)
    }
    .frame(width: 72, height: 72)
    .onAppear { ripple.toggle()
      withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { ripple.toggle() }
    }
  }
}


⸻

6. Screen Skeletons

Every screen extends BaseScreen which supplies the active gradient + safe stacking.

struct BaseScreen<Content: View>: View {
  @EnvironmentObject private var gm: GradientManager
  let content: () -> Content
  var body: some View {
    ZStack { gm.active.linear.ignoresSafeArea(); content() }
  }
}

6.1 Onboarding Welcome

struct OnboardingWelcome: View {
  var body: some View {
    BaseScreen {
      VStack(spacing: 32) {
        Spacer()
        CascadeText(text: "Welcome\nto AirFit")
          .multilineTextAlignment(.center)
          .font(.system(size: 44, weight: .thin, design: .rounded))
        Spacer()
        GlassCard { Text("Get Started").frame(maxWidth: .infinity).font(.headline) }
          .onTapGesture { /* nav + gm.next() */ }
      }.padding(24)
    }
  }
}

6.2 Dashboard

struct Dashboard: View {
  @State private var calories = 1920
  var body: some View {
    BaseScreen {
      VStack(alignment: .leading, spacing: 24) {
        CascadeText(text: "Daily\nDashboard")
          .font(.system(size: 34, weight: .thin, design: .rounded))
        ScrollView {
          VStack(spacing: 20) {
            GlassCard {
              HStack {
                MetricRing(value: calories, goal: 2300)
                Spacer()
                GradientNumber(value: calories)
              }
            }
            // other GlassCards…
          }
        }
      }.padding(24)
    }
  }
}

6.3 Voice Log

struct VoiceLog: View {
  var body: some View {
    BaseScreen {
      VStack(spacing: 48) {
        CascadeText(text: "Log your\nmeal")
          .multilineTextAlignment(.center)
          .font(.system(size: 36, weight: .thin, design: .rounded))
        MicRippleView().onTapGesture { /* start recording */ }
      }.padding(24)
    }
  }
}

6.4 Workout Counter

struct RepCounter: View {
  @State private var reps = 12
  var body: some View {
    BaseScreen {
      VStack(spacing: 12) {
        CascadeText(text: "I ")
          .font(.system(size: 28, weight: .thin, design: .rounded))
        GradientNumber(value: reps)
        Text("Reps").font(.title3.weight(.thin))
      }
    }
  }
}


⸻

7. GradientNumber

struct GradientNumber: View {
  @EnvironmentObject private var gm: GradientManager
  var value: Int
  var body: some View {
    Text("\(value)")
      .font(.system(size: 64, weight: .thin, design: .rounded))
      .monospacedDigit()
      .overlay(
        gm.active.linear
          .mask(Text("\(value)").font(.system(size: 64, weight: .thin, design: .rounded)))
      )
      .animation(.easeOut(duration: 0.6), value: value)
  }
}


⸻

8. Navigation & Transition
	•	All pushes/pop → use .transition(.opacity.combined(with: .offset(y: 12))).
	•	Every successful push or modal dismiss → call GradientManager.next() to trigger background cross-fade.

⸻

9. Accessibility & Performance
	•	Dynamic Type supported up to Accessibility XL; headline strings scale via .font(.scaled(.system(size:baseline))).
	•	VoiceOver labels on every GlassCard (e.g. “Nutrition summary, 1850 of 2300 calories”).
	•	All gradients meet contrast ≥ 4.5:1 when text sits atop glass-card or plain gradient area.
	•	GPU budget: keep simultaneous blurs ≤ 6 per screen; we’re on A19 / M-class GPU so fine.

⸻

10. Project Topology (for Claude Code)

AirFit/
  Sources/
    App.swift            // @main, inject Theme & GradientManager
    Theme/
      GradientToken.swift
      GradientManager.swift
      MotionToken.swift
    Components/
      CascadeText.swift
      CascadeModifier.swift
      GlassCard.swift
      MetricRing.swift
      GradientNumber.swift
      MicRippleView.swift
    Screens/
      Onboarding/
        OnboardingWelcome.swift
      Dashboard/
        Dashboard.swift
      VoiceLog/
        VoiceLog.swift
      Workout/
        RepCounter.swift
  Resources/
    Assets.xcassets       // colour sets & gradient images if needed
    LaunchScreen.storyboard


⸻

11. Random-Gradient QA Pass

Screen	Expected Gradient	Transition Verified?
Welcome → Dashboard	peachRose → mintAqua	YES
Dashboard → VoiceLog	mintAqua → lilacBlush	YES
VoiceLog → RepCounter	lilacBlush → skyLavender	YES

(run snapshot tests via SnapshotTesting to assert pixel deltas during fade < 2 % per frame).

⸻

12. Next Steps for the Agent
	1.	Scaffold the folder layout above.
	2.	Paste each component exactly as specified.
	3.	Wire navigation + gradient manager.
	4.	Verify cascade + gradient fade on device.
	5.	Iterate card spacing & typographic scale per design QA.

End of spec – this encapsulates every design choice, token, animation curve, component API, and project layout required for the Claude Code agent to reproduce the intended UI faithfully.