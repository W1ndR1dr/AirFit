import SwiftUI
import SwiftData
#if DEBUG
import HealthKit
#endif

// MARK: - Identifiable URL Wrapper
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Settings View with DI
struct SettingsView: View {
    let user: User
    @State private var viewModel: SettingsViewModel?
    @Environment(\.diContainer) private var container

    var body: some View {
        Group {
            if let viewModel = viewModel {
                SettingsListView(viewModel: viewModel, user: user)
            } else {
                ProgressView()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeSettingsViewModel(user: user)
                    }
            }
        }
    }
}

// MARK: - Settings List Content
struct SettingsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    @State var viewModel: SettingsViewModel
    @State private var coordinator: SettingsCoordinator
    @State private var animateIn = false
    let user: User

    init(viewModel: SettingsViewModel, user: User) {
        self._viewModel = State(initialValue: viewModel)
        self.user = user
        self._coordinator = State(initialValue: SettingsCoordinator())
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            BaseScreen {
                ScrollView {
                    VStack(spacing: 0) {
                        // Settings header
                        HStack {
                            CascadeText("Settings")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .opacity(animateIn ? 1 : 0)
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.lg)

                        // Animated sections
                        VStack(spacing: AppSpacing.md) {
                            if animateIn {
                                aiSection
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    .animation(.easeOut(duration: 0.3).delay(0.1), value: animateIn)

                                preferencesSection
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    .animation(.easeOut(duration: 0.3).delay(0.2), value: animateIn)

                                privacySection
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    .animation(.easeOut(duration: 0.3).delay(0.3), value: animateIn)

                                dataSection
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    .animation(.easeOut(duration: 0.3).delay(0.4), value: animateIn)

                                supportSection
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    .animation(.easeOut(duration: 0.3).delay(0.5), value: animateIn)

                                #if DEBUG
                                debugSection
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    .animation(.easeOut(duration: 0.3).delay(0.6), value: animateIn)
                                #endif
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            HapticService.impact(.soft)
                            dismiss()
                        }, label: {
                            Text("Done")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(
                                    gradientManager.currentGradient(for: colorScheme)
                                )
                        })
                    }
                }
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                destinationView(for: destination)
                    .advanceGradientOnAppear()
            }
            .sheet(item: $coordinator.activeSheet) { sheet in
                sheetView(for: sheet)
            }
            .alert(item: $coordinator.activeAlert) { alert in
                alertView(for: alert)
            }
            .task {
                await viewModel.loadSettings()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Sections
    private var aiSection: some View {
        VStack(spacing: AppSpacing.xs) {
            // Section header
            HStack {
                Text("AI Configuration")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)

            GlassCard {
                VStack(spacing: 0) {
                    // AI Coach Persona row
                    NavigationLink(value: SettingsDestination.aiPersona) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "figure.wave")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Coach Persona")
                                    .font(.system(.body, design: .rounded))
                                Text("Customize your coach's style")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("AI Coach Persona")
                    .accessibilityHint("Customize your coach's personality and coaching style")
                    .accessibilityAddTraits(.isButton)

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // AI Provider row
                    NavigationLink(value: SettingsDestination.apiConfiguration) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "cpu")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Provider")
                                    .font(.system(.body, design: .rounded))
                                Text(viewModel.selectedProvider.displayName)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("AI Provider")
                    .accessibilityValue("Currently using \(viewModel.selectedProvider.displayName)")
                    .accessibilityHint("Configure your AI provider and API settings")
                    .accessibilityAddTraits(.isButton)

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Demo Mode toggle
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Demo Mode")
                                .font(.system(.body, design: .rounded))
                            Text("Use sample responses without API keys")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.isDemoModeEnabled)
                            .labelsHidden()
                            .tint(Color(gradientManager.active.colors(for: colorScheme).first ?? .accentColor))
                            .onChange(of: viewModel.isDemoModeEnabled) { _, newValue in
                                HapticService.impact(.soft)
                                Task {
                                    await viewModel.setDemoMode(newValue)
                                }
                            }
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("Preferences")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)

            GlassCard {
                VStack(spacing: 0) {
                    // Units row
                    NavigationLink(value: SettingsDestination.units) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "ruler")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Units")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Text(viewModel.preferredUnits.displayName)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Nutrition row
                    NavigationLink(value: SettingsDestination.nutrition) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Nutrition Targets")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Text("\(String(format: "%.1f", user.proteinGramsPerPound))g/lb")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Voice row
                    NavigationLink(value: SettingsDestination.voice) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "waveform")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Voice Settings")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Text("Whisper")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Appearance row
                    NavigationLink(value: SettingsDestination.appearance) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "paintbrush")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Appearance")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Text(viewModel.appearanceMode.displayName)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Notifications row
                    NavigationLink(value: SettingsDestination.notifications) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Notifications")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            if viewModel.notificationPreferences.systemEnabled {
                                Image(systemName: "bell.fill")
                                    .font(.caption)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Haptic Feedback toggle
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)

                        Text("Haptic Feedback")
                            .font(.system(.body, design: .rounded))

                        Spacer()

                        Toggle("", isOn: $viewModel.hapticFeedback)
                            .labelsHidden()
                            .tint(Color(gradientManager.active.colors(for: colorScheme).first ?? .accentColor))
                            .onChange(of: viewModel.hapticFeedback) { _, newValue in
                                HapticService.impact(.soft)
                                Task {
                                    try await viewModel.updateHaptics(newValue)
                                    if newValue {
                                        HapticService.notification(.success)
                                    }
                                }
                            }
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var privacySection: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("Privacy & Security")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)

            GlassCard {
                VStack(spacing: 0) {
                    // Privacy Settings row
                    NavigationLink(value: SettingsDestination.privacy) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Privacy Settings")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Face ID toggle
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "faceid")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)

                        Text("Require Face ID")
                            .font(.system(.body, design: .rounded))

                        Spacer()

                        Toggle("", isOn: $viewModel.biometricLockEnabled)
                            .labelsHidden()
                            .tint(Color(gradientManager.active.colors(for: colorScheme).first ?? .accentColor))
                            .onChange(of: viewModel.biometricLockEnabled) { _, newValue in
                                HapticService.impact(.soft)
                                Task {
                                    do {
                                        try await viewModel.updateBiometricLock(newValue)
                                        if newValue {
                                            HapticService.notification(.success)
                                        }
                                    } catch {
                                        HapticService.notification(.error)
                                        coordinator.showAlert(.error(message: error.localizedDescription))
                                        viewModel.biometricLockEnabled = !newValue
                                    }
                                }
                            }
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Analytics toggle
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)

                        Text("Share Analytics")
                            .font(.system(.body, design: .rounded))

                        Spacer()

                        Toggle("", isOn: $viewModel.analyticsEnabled)
                            .labelsHidden()
                            .tint(Color(gradientManager.active.colors(for: colorScheme).first ?? .accentColor))
                            .onChange(of: viewModel.analyticsEnabled) { _, newValue in
                                HapticService.impact(.soft)
                                Task {
                                    try await viewModel.updateAnalytics(newValue)
                                }
                            }
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var dataSection: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("Data Management")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)

            GlassCard {
                VStack(spacing: 0) {
                    // Export Data row
                    NavigationLink(value: SettingsDestination.dataManagement) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export Data")
                                    .font(.system(.body, design: .rounded))
                                if let lastExport = viewModel.exportHistory.first {
                                    Text("Last export: \(lastExport.date.formatted(.relative(presentation: .named)))")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Delete All Data button
                    Button(role: .destructive, action: {
                        HapticService.impact(.rigid)
                        Task {
                            try await viewModel.deleteAllData()
                        }
                    }, label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                                .frame(width: 28, height: 28)

                            Text("Delete All Data")
                                .font(.system(.body, design: .rounded))

                            Spacer()
                        }
                        .foregroundStyle(.red)
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    })
                }
            }
        }
    }

    private var supportSection: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("Support")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)

            GlassCard {
                VStack(spacing: 0) {
                    // About row
                    NavigationLink(value: SettingsDestination.about) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("About")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Text("v\(AppConstants.appVersion)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Privacy Policy link
                    Link(destination: URL(string: AppConstants.privacyPolicyURL)!) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "hand.raised")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Privacy Policy")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Image(systemName: "arrow.up.forward")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Terms of Service link
                    Link(destination: URL(string: AppConstants.termsOfServiceURL)!) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Terms of Service")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Image(systemName: "arrow.up.forward")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)

                    // Contact Support link
                    Link(destination: URL(string: "mailto:\(AppConstants.supportEmail)")!) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "envelope")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text("Contact Support")
                                .font(.system(.body, design: .rounded))

                            Spacer()

                            Image(systemName: "arrow.up.forward")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
            }
        }
    }

    #if DEBUG
    private var debugSection: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("Developer")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)

            GlassCard {
                NavigationLink(value: SettingsDestination.debug) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "hammer")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)

                        Text("Debug Tools")
                            .font(.system(.body, design: .rounded))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }
    #endif

    // MARK: - Navigation
    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .aiPersona:
            AIPersonaSettingsView(viewModel: viewModel)
        case .apiConfiguration:
            APIConfigurationView(viewModel: viewModel)
        case .notifications:
            NotificationPreferencesView(viewModel: viewModel)
        case .privacy:
            PrivacySecurityView(viewModel: viewModel)
        case .appearance:
            AppearanceSettingsView(viewModel: viewModel)
        case .units:
            UnitsSettingsView(viewModel: viewModel)
        case .nutrition:
            NutritionSettingsView(user: user)
        case .voice:
            VoiceSettingsView()
        case .dataManagement:
            DataManagementView(viewModel: viewModel)
        case .about:
            AboutView()
        case .debug:
            DebugSettingsView()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: SettingsCoordinator.SettingsSheet) -> some View {
        switch sheet {
        case .personaRefinement:
            PersonaRefinementFlow(user: viewModel.currentUser)
        case .apiKeyEntry(let provider):
            APIKeyEntryView(provider: provider, viewModel: viewModel)
        case .dataExport:
            DataExportProgressView(viewModel: viewModel)
        case .deleteAccount:
            DeleteAccountView(viewModel: viewModel)
        }
    }

    private func alertView(for alert: SettingsCoordinator.SettingsAlert) -> Alert {
        switch alert {
        case .confirmDelete(let action):
            return Alert(
                title: Text("Delete All Data?"),
                message: Text("This will permanently delete all your data. This action cannot be undone."),
                primaryButton: .destructive(Text("Delete"), action: action),
                secondaryButton: .cancel()
            )
        case .exportSuccess:
            return Alert(
                title: Text("Export Complete"),
                message: Text("Your data has been exported successfully."),
                dismissButton: .default(Text("OK"))
            )
        case .apiKeyInvalid:
            return Alert(
                title: Text("Invalid API Key"),
                message: Text("The API key format is invalid. Please check and try again."),
                dismissButton: .default(Text("OK"))
            )
        case .error(let message):
            return Alert(
                title: Text("Error"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        case .demoModeEnabled:
            return Alert(
                title: Text("Demo Mode Enabled"),
                message: Text("You're now using demo mode with sample AI responses. No API keys are required. Perfect for exploring the app!"),
                dismissButton: .default(Text("Got it"))
            )
        case .demoModeDisabled:
            return Alert(
                title: Text("Demo Mode Disabled"),
                message: Text("You've switched back to live AI responses. Please ensure you have valid API keys configured."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Persona Refinement Flow
struct PersonaRefinementFlow: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var refinementText = ""
    @State private var isProcessing = false
    @State private var refinementOptions: [RefinementOption] = []
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: 3)
                    .tint(Color.accentColor)
                    .padding(.horizontal)

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        switch currentStep {
                        case 0:
                            refinementIntroView
                        case 1:
                            refinementOptionsView
                        case 2:
                            refinementSummaryView
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }

                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }, label: {
                            Text("Back")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                                .frame(minWidth: 80)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                        })
                    }

                    Spacer()

                    Button {
                        if currentStep == 2 {
                            applyRefinements()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    } label: {
                        Text(currentStep == 2 ? "Apply Changes" : "Next")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(currentStep == 1 && refinementOptions.filter(\.isSelected).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Refine Your Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .interactiveDismissDisabled(isProcessing)
        }
        .onAppear {
            loadRefinementOptions()
        }
    }

    private var refinementIntroView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Let's Refine Your Coach")
                .font(.title2.bold())

            Text("Tell us what you'd like to adjust about your coach's personality and communication style")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("What would you like to change?")
                        .font(.subheadline.bold())

                    TextField("E.g., Be more motivating, use less technical jargon...", text: $refinementText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                        .overlay(alignment: .bottomTrailing) {
                            WhisperVoiceButton(text: $refinementText)
                                .padding(8)
                        }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }

    private var refinementOptionsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Select areas to refine")
                    .font(.title3.bold())

                Text("Based on your feedback, here are some refinement options")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppSpacing.md) {
                ForEach($refinementOptions) { $option in
                    RefinementOptionCard(option: $option)
                }
            }
        }
    }

    private var refinementSummaryView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Refinement Summary")
                .font(.title2.bold())

            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("Your Request", systemImage: "text.quote")
                        .font(.subheadline.bold())

                    Text(refinementText)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Divider()

                    Label("Selected Refinements", systemImage: "checklist")
                        .font(.subheadline.bold())

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(refinementOptions.filter(\.isSelected)) { option in
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text(option.title)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            Text("Your coach will be updated with these refinements")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func loadRefinementOptions() {
        // Simulate loading refinement options based on user input
        refinementOptions = [
            RefinementOption(
                id: UUID(),
                title: "More Encouraging Tone",
                description: "Increase positive reinforcement and celebration of achievements",
                category: .communication,
                isSelected: false
            ),
            RefinementOption(
                id: UUID(),
                title: "Data-Driven Feedback",
                description: "Include more metrics and analytics in coaching feedback",
                category: .analysis,
                isSelected: false
            ),
            RefinementOption(
                id: UUID(),
                title: "Simplified Language",
                description: "Use less technical jargon and more everyday language",
                category: .communication,
                isSelected: false
            ),
            RefinementOption(
                id: UUID(),
                title: "Increased Check-ins",
                description: "More frequent progress updates and motivational messages",
                category: .engagement,
                isSelected: false
            )
        ]
    }

    private func applyRefinements() {
        isProcessing = true

        Task {
            // Simulate processing
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                HapticService.play(.success)
                dismiss()
            }
        }
    }
}

// Supporting types
struct RefinementOption: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: RefinementCategory
    var isSelected: Bool
}

enum RefinementCategory {
    case communication
    case analysis
    case engagement
    case personality
}

struct RefinementOptionCard: View {
    @Binding var option: RefinementOption

    var body: some View {
        GlassCard {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(option.title)
                        .font(.headline)

                    Text(option.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $option.isSelected)
                    .labelsHidden()
                    .tint(Color.accentColor)
            }
        }
    }
}

// MARK: - Data Export Progress View
struct DataExportProgressView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var exportProgress: Double = 0
    @State private var currentStatus = "Preparing export..."
    @State private var exportSteps: [ExportStep] = []
    @State private var exportURL: URL?
    @State private var exportError: Error?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                if let error = exportError {
                    // Error state
                    VStack(spacing: AppSpacing.xl) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)

                        Text("Export Failed")
                            .font(.title2.bold())

                        Text(error.localizedDescription)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            exportError = nil
                            startExport()
                        } label: {
                            Text("Try Again")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                } else if let url = exportURL {
                    // Success state
                    VStack(spacing: AppSpacing.xl) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("Export Complete!")
                            .font(.title2.bold())

                        VStack(spacing: AppSpacing.sm) {
                            Text("Your data has been exported successfully")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 {
                                Text(ByteCountFormatter().string(fromByteCount: fileSize))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        HStack(spacing: AppSpacing.md) {
                            Button {
                                showShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                dismiss()
                            } label: {
                                Text("Done")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 80)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                    }
                    .padding()
                    .sheet(isPresented: $showShareSheet) {
                        SettingsShareSheet(items: [url])
                    }
                } else {
                    // Progress state
                    VStack(spacing: AppSpacing.xl) {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 8)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: exportProgress)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: exportProgress)

                            Text("\(Int(exportProgress * 100))%")
                                .font(.title2.bold())
                        }

                        VStack(spacing: AppSpacing.sm) {
                            Text("Exporting Data")
                                .font(.headline)

                            Text(currentStatus)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .animation(.easeInOut, value: currentStatus)
                        }

                        // Export steps
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            ForEach(exportSteps) { step in
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                        .foregroundStyle(step.isComplete ? .green : .secondary)

                                    Text(step.name)
                                        .font(.caption)
                                        .foregroundStyle(step.isComplete ? .primary : .secondary)

                                    Spacer()

                                    if step.isActive {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Export Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(exportURL != nil)
                }
            }
            .interactiveDismissDisabled(exportURL == nil && exportError == nil)
        }
        .onAppear {
            startExport()
        }
    }

    private func startExport() {
        exportSteps = [
            ExportStep(name: "Gathering workout data", isComplete: false, isActive: true),
            ExportStep(name: "Collecting nutrition logs", isComplete: false, isActive: false),
            ExportStep(name: "Exporting health metrics", isComplete: false, isActive: false),
            ExportStep(name: "Packaging coach settings", isComplete: false, isActive: false),
            ExportStep(name: "Creating export file", isComplete: false, isActive: false)
        ]

        Task {
            do {
                // Simulate export progress
                for (index, _) in exportSteps.enumerated() {
                    await MainActor.run {
                        currentStatus = exportSteps[index].name
                        if index > 0 {
                            exportSteps[index - 1].isComplete = true
                            exportSteps[index - 1].isActive = false
                        }
                        exportSteps[index].isActive = true
                        exportProgress = Double(index + 1) / Double(exportSteps.count + 1)
                    }

                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second per step
                }

                // Finalize export
                await MainActor.run {
                    exportSteps[exportSteps.count - 1].isComplete = true
                    exportSteps[exportSteps.count - 1].isActive = false
                    currentStatus = "Finalizing export..."
                    exportProgress = 0.95
                }

                // Actually export the data
                let url = try await viewModel.exportUserData()

                await MainActor.run {
                    exportProgress = 1.0
                    exportURL = url
                    HapticService.play(.success)
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    HapticService.play(.error)
                }
            }
        }
    }
}

struct ExportStep: Identifiable {
    let id = UUID()
    let name: String
    var isComplete: Bool
    var isActive: Bool
}

// MARK: - Delete Account View
struct DeleteAccountView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var showFinalConfirmation = false
    @FocusState private var isTextFieldFocused: Bool

    private let confirmationPhrase = "DELETE ACCOUNT"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Warning header
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)

                        Text("Delete Account")
                            .font(.title.bold())

                        Text("This action is permanent and cannot be undone")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // What will be deleted
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Label("What will be deleted:", systemImage: "trash")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                deletionItem("All workout history and records")
                                deletionItem("Nutrition logs and meal data")
                                deletionItem("Health metrics and progress")
                                deletionItem("Personalized coach settings")
                                deletionItem("Account preferences and settings")
                                deletionItem("All personal information")
                            }
                        }
                    }

                    // What you can keep
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Label("Before you go:", systemImage: "square.and.arrow.down")
                                .font(.headline)

                            Text("You can export your data before deleting your account. This allows you to keep a copy of your information.")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            NavigationLink(destination: DataManagementView(viewModel: viewModel)) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export My Data")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                                .foregroundColor(.primary)
                            }
                        }
                    }

                    // Confirmation input
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("To confirm deletion, type \"\(confirmationPhrase)\" below:")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            TextField("Type here...", text: $confirmationText)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .focused($isTextFieldFocused)
                                .onChange(of: confirmationText) { _, newValue in
                                    // Force uppercase for easier matching
                                    confirmationText = newValue.uppercased()
                                }
                        }
                    }

                    // Delete button
                    Button {
                        showFinalConfirmation = true
                    } label: {
                        if isDeleting {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.5))
                                )
                        } else {
                            Text("Delete My Account")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red)
                                )
                        }
                    }
                    .disabled(confirmationText != confirmationPhrase || isDeleting)

                    // Alternative actions
                    VStack(spacing: AppSpacing.sm) {
                        Text("Having issues? We can help!")
                            .font(.callout.bold())

                        Link("Contact Support", destination: URL(string: "mailto:\(AppConstants.supportEmail)")!)
                            .font(.callout)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isDeleting)
                }
            }
            .interactiveDismissDisabled(isDeleting)
            .alert("Final Confirmation", isPresented: $showFinalConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    performDeletion()
                }
            } message: {
                Text("This is your last chance to cancel. All your data will be permanently deleted. This cannot be undone.")
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }

    private func deletionItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Text("•")
                .foregroundStyle(.red)
            Text(text)
                .font(.callout)
        }
    }

    private func performDeletion() {
        isDeleting = true

        Task {
            do {
                // Perform actual deletion
                try await viewModel.deleteAllData()

                await MainActor.run {
                    // Success - the app should handle sign out and navigation
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    viewModel.showAlert(.error(message: "Failed to delete account: \(error.localizedDescription)"))
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @State private var showAcknowledgments = false

    var body: some View {
        List {
            // App Info Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppConstants.appVersion)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(AppConstants.buildNumber)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "Unknown")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            // Team Section
            Section("Created by") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("AirFit Team")
                        .font(.headline)

                    Text("Empowering your fitness journey with AI")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, AppSpacing.xs)
            }

            // Features Section
            Section("Features") {
                FeatureRow(
                    icon: "figure.run",
                    title: "Smart Workouts",
                    description: "AI-powered workout recommendations"
                )

                FeatureRow(
                    icon: "fork.knife",
                    title: "Nutrition Tracking",
                    description: "Voice-enabled food logging"
                )

                FeatureRow(
                    icon: "person.fill",
                    title: "Personalized Coach",
                    description: "Your unique AI fitness companion"
                )

                FeatureRow(
                    icon: "heart.fill",
                    title: "Health Integration",
                    description: "Seamless HealthKit sync"
                )
            }

            // Technologies Section
            Section("Built with") {
                TechRow(name: "SwiftUI", version: "5.0")
                TechRow(name: "SwiftData", version: "1.0")
                TechRow(name: "iOS", version: "18.0+")
                TechRow(name: "WhisperKit", version: "0.9.0")
            }

            // Links Section
            Section {
                Link(destination: URL(string: "https://airfit.app")!) {
                    Label("Website", systemImage: "globe")
                }

                Link(destination: URL(string: "https://github.com/airfit/app")!) {
                    Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }

                Button(action: { showAcknowledgments = true }, label: {
                    Label("Acknowledgments", systemImage: "heart.text.square")
                })
            }
        }
        .navigationTitle("About AirFit")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAcknowledgments) {
            AcknowledgmentsView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

struct TechRow: View {
    let name: String
    let version: String

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(version)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

struct AcknowledgmentsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Open Source Libraries") {
                    AcknowledgmentRow(
                        name: "WhisperKit",
                        author: "Argmax Inc.",
                        license: "MIT License"
                    )
                }

                Section("Special Thanks") {
                    Text("To our beta testers and early adopters who helped shape AirFit")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, AppSpacing.sm)
                }
            }
            .navigationTitle("Acknowledgments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AcknowledgmentRow: View {
    let name: String
    let author: String
    let license: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(name)
                .font(.headline)
            Text("by \(author)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(license)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Debug Settings View
struct DebugSettingsView: View {
    @State private var showClearCacheAlert = false
    @State private var showResetOnboardingAlert = false
    @State private var showResetAppAlert = false
    @State private var showExportLogsSheet = false
    @State private var exportedLogsURL: IdentifiableURL?
    @State private var isProcessing = false
    @State private var statusMessage = ""
    @Environment(\.diContainer) private var container
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("Cache Management") {
                Button(action: { showClearCacheAlert = true }, label: {
                    Label("Clear Cache", systemImage: "trash")
                })
                .disabled(isProcessing)

                HStack {
                    Text("Cache Size")
                    Spacer()
                    Text(getCacheSize())
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Section("Development Tools") {
                Button(action: { showResetAppAlert = true }, label: {
                    Label("Reset App (Clear All Data)", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                })
                .disabled(isProcessing)

                Button(action: { showResetOnboardingAlert = true }, label: {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                })
                .disabled(isProcessing)

                Button(action: exportLogs, label: {
                    Label("Export Debug Logs", systemImage: "doc.text.magnifyingglass")
                })
                .disabled(isProcessing)

                NavigationLink(destination: FeatureFlagsView()) {
                    Label("Feature Flags", systemImage: "flag")
                }
            }

            Section("HealthKit Test Data") {
                Button(action: generateHealthKitTestData, label: {
                    Label("Generate Today's Data", systemImage: "heart.text.square")
                })
                .disabled(isProcessing)

                Button(action: { generateHealthKitHistoricalData(days: 7) }, label: {
                    Label("Generate 7 Days History", systemImage: "calendar")
                })
                .disabled(isProcessing)

                Button(action: { generateHealthKitHistoricalData(days: 30) }, label: {
                    Label("Generate 30 Days History", systemImage: "calendar.badge.clock")
                })
                .disabled(isProcessing)

                NavigationLink(destination: HealthKitTestDataDetailView()) {
                    Label("Custom Data Generator", systemImage: "slider.horizontal.3")
                }
            }

            Section("Test Actions") {
                Button("Trigger Test Notification") {
                    triggerTestNotification()
                }

                Button("Simulate Memory Warning") {
                    simulateMemoryWarning()
                }

                Button("Force Crash") {
                    fatalError("Debug crash triggered")
                }
                .foregroundStyle(.red)
            }

            if !statusMessage.isEmpty {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Debug Tools")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Cache?", isPresented: $showClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear all cached data including AI responses and images.")
        }
        .alert("Reset Onboarding?", isPresented: $showResetOnboardingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetOnboarding()
            }
        } message: {
            Text("This will reset your onboarding status and coach persona. You'll need to go through setup again.")
        }
        .alert("Reset App?", isPresented: $showResetAppAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("This will delete ALL user data and reset the app completely. This action cannot be undone.")
        }
        .sheet(item: $exportedLogsURL) { identifiableURL in
            SettingsShareSheet(items: [identifiableURL.url])
        }
    }

    private func getCacheSize() -> String {
        // Calculate actual cache size
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let size = try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey])
            .reduce(0) { total, url in
                let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
                return total + (fileSize ?? 0)
            }

        return ByteCountFormatter().string(fromByteCount: Int64(size ?? 0))
    }

    private func clearCache() {
        isProcessing = true
        statusMessage = "Clearing cache..."

        Task {
            // Clear caches
            URLCache.shared.removeAllCachedResponses()

            // Clear custom cache directories
            let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            try? FileManager.default.removeItem(at: cacheURL)
            try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)

            await MainActor.run {
                isProcessing = false
                statusMessage = "Cache cleared successfully"
                HapticService.play(.success)
                // Clear status after delay
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    statusMessage = ""
                }
            }
        }
    }

    private func resetApp() {
        isProcessing = true
        statusMessage = "Resetting app..."

        Task {
            do {
                // Delete all users
                let userDescriptor = FetchDescriptor<User>()
                let users = try modelContext.fetch(userDescriptor)
                for user in users {
                    modelContext.delete(user)
                }
                try modelContext.save()

                AppLogger.info("App reset - all user data cleared", category: .app)

                // Post notification to trigger app reload
                await MainActor.run {
                    NotificationCenter.default.post(name: .appResetForTesting, object: nil)
                    isProcessing = false
                    statusMessage = "App reset complete"
                }
            } catch {
                AppLogger.error("Failed to reset app", error: error, category: .app)
                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Reset failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func resetOnboarding() {
        isProcessing = true
        statusMessage = "Resetting onboarding..."

        Task {
            // Reset user defaults
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(nil, forKey: "coachPersonaData")

            await MainActor.run {
                isProcessing = false
                statusMessage = "Onboarding reset. Please restart the app."
                HapticService.play(.warning)
            }
        }
    }

    private func exportLogs() {
        isProcessing = true
        statusMessage = "Exporting logs..."

        Task {
            // For now, create a placeholder log file since AppLogger.exportLogs() returns nil
            let logContent = """
            AirFit Debug Log Export
            Date: \(Date())

            Log export functionality not yet implemented.
            This is a placeholder file.
            """

            let fileName = "airfit_debug_logs_\(Date().timeIntervalSince1970).txt"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            try? logContent.write(to: tempURL, atomically: true, encoding: .utf8)

            await MainActor.run {
                isProcessing = false
                exportedLogsURL = IdentifiableURL(url: tempURL)
                statusMessage = "Logs exported"
                HapticService.play(.success)
            }
        }
    }

    private func triggerTestNotification() {
        Task {
            let content = UNMutableNotificationContent()
            content.title = "Test Notification"
            content.body = "This is a test notification from debug settings"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: "debug_test", content: content, trigger: trigger)

            try? await UNUserNotificationCenter.current().add(request)

            await MainActor.run {
                statusMessage = "Test notification scheduled"
            }
        }
    }

    private func simulateMemoryWarning() {
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        statusMessage = "Memory warning simulated"
    }

    // MARK: - HealthKit Test Data Methods

    private func generateHealthKitTestData() {
        isProcessing = true
        statusMessage = "Generating HealthKit test data..."

        Task {
            do {
                // Get HealthKit manager from DI container
                let healthKitManager = try await container.resolve(HealthKitManaging.self)

                // Request authorization if needed
                if let manager = healthKitManager as? HealthKitManager,
                   manager.authorizationStatus != .authorized {
                    try await manager.requestAuthorization()
                }

                // Generate test data
                let generator = HealthKitTestDataGenerator(healthStore: HKHealthStore())
                try await generator.generateTestDataForToday()

                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Successfully generated today's test data"
                    HapticService.play(.success)

                    // Clear status after delay
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        statusMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Failed to generate test data: \(error.localizedDescription)"
                    HapticService.play(.error)
                }
            }
        }
    }

    private func generateHealthKitHistoricalData(days: Int) {
        isProcessing = true
        statusMessage = "Generating \(days) days of HealthKit test data..."

        Task {
            do {
                // Get HealthKit manager from DI container
                let healthKitManager = try await container.resolve(HealthKitManaging.self)

                // Request authorization if needed
                if let manager = healthKitManager as? HealthKitManager,
                   manager.authorizationStatus != .authorized {
                    try await manager.requestAuthorization()
                }

                // Generate test data
                let generator = HealthKitTestDataGenerator(healthStore: HKHealthStore())
                try await generator.generateHistoricalData(days: days)

                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Successfully generated \(days) days of test data"
                    HapticService.play(.success)

                    // Clear status after delay
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        statusMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Failed to generate test data: \(error.localizedDescription)"
                    HapticService.play(.error)
                }
            }
        }
    }
}

struct FeatureFlagsView: View {
    @AppStorage("debug.verboseLogging") private var verboseLogging = false
    @AppStorage("debug.mockAIResponses") private var mockAIResponses = false
    @AppStorage("debug.forceOfflineMode") private var forceOfflineMode = false
    @AppStorage("debug.showPerformanceOverlay") private var showPerformanceOverlay = false

    var body: some View {
        List {
            Section("Logging") {
                Toggle("Verbose Logging", isOn: $verboseLogging)
                Toggle("Performance Overlay", isOn: $showPerformanceOverlay)
            }

            Section("Network") {
                Toggle("Force Offline Mode", isOn: $forceOfflineMode)
                Toggle("Mock AI Responses", isOn: $mockAIResponses)
            }
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Extensions
extension Notification.Name {
    static let appResetForTesting = Notification.Name("appResetForTesting")
}

// MARK: - Share Sheet
private struct SettingsShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
