**Modular Sub-Document 11: Settings Module (UI & Logic)**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
- Completion of Module 1: Core Project Setup & Configuration
- Completion of Module 2: Data Layer (SwiftData Schema & Managers)
- Completion of Module 9: Notifications & Engagement Engine
- Completion of Module 10: Services Layer - AI API Client
**Date:** May 25, 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To provide users with a premium, intuitive settings experience for complete control over their AI coach, privacy, data management, and app preferences using iOS 18's latest design patterns and security features.
*   **Responsibilities:**
    *   AI coach persona customization with live preview
    *   Secure API key management with biometric protection
    *   Multi-provider LLM configuration
    *   Granular notification preferences
    *   Unit preference management (imperial/metric)
    *   Data export with privacy controls
    *   Account management and security
    *   Debug tools (dev builds only)
    *   App information and support links
*   **Key Components:**
    *   `SettingsCoordinator.swift` - Navigation and flow management
    *   `SettingsViewModel.swift` - Business logic and state
    *   `SettingsListView.swift` - Main navigation hub
    *   `AISettingsView.swift` - AI persona and provider config
    *   `PrivacySecurityView.swift` - Privacy and security settings
    *   `DataManagementView.swift` - Export and backup options
    *   `APIKeyManagementView.swift` - Secure key management
    *   `NotificationPreferencesView.swift` - Notification controls
    *   `AppearanceSettingsView.swift` - Theme and display options

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Core utilities, theme system
    *   Module 2: User and profile models
    *   Module 9: Notification management
    *   Module 10: API key manager, AI providers
    *   System settings integration
*   **Outputs:**
    *   Persisted user preferences
    *   Configured AI services
    *   Exported user data
    *   Security configurations

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 11.0: Settings Infrastructure**

**Agent Task 11.0.1: Create Settings Coordinator**
- File: `AirFit/Modules/Settings/SettingsCoordinator.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import Observation
  
  @MainActor
  @Observable
  final class SettingsCoordinator {
      // MARK: - Navigation State
      var navigationPath = NavigationPath()
      var activeSheet: SettingsSheet?
      var activeAlert: SettingsAlert?
      
      // MARK: - Sheet Types
      enum SettingsSheet: Identifiable {
          case personaRefinement
          case apiKeyEntry(provider: AIProvider)
          case dataExport
          case deleteAccount
          
          var id: String {
              switch self {
              case .personaRefinement: return "persona"
              case .apiKeyEntry(let provider): return "apikey_\(provider.rawValue)"
              case .dataExport: return "export"
              case .deleteAccount: return "delete"
              }
          }
      }
      
      // MARK: - Alert Types
      enum SettingsAlert: Identifiable {
          case confirmDelete(action: () -> Void)
          case exportSuccess(url: URL)
          case apiKeyInvalid
          case error(message: String)
          
          var id: String {
              switch self {
              case .confirmDelete: return "delete"
              case .exportSuccess: return "export"
              case .apiKeyInvalid: return "apikey"
              case .error: return "error"
              }
          }
      }
      
      // MARK: - Navigation Methods
      func navigateTo(_ destination: SettingsDestination) {
          navigationPath.append(destination)
      }
      
      func navigateBack() {
          if !navigationPath.isEmpty {
              navigationPath.removeLast()
          }
      }
      
      func navigateToRoot() {
          navigationPath.removeLast(navigationPath.count)
      }
      
      func showSheet(_ sheet: SettingsSheet) {
          activeSheet = sheet
      }
      
      func showAlert(_ alert: SettingsAlert) {
          activeAlert = alert
      }
      
      func dismiss() {
          activeSheet = nil
          activeAlert = nil
      }
  }
  
  // MARK: - Navigation Destinations
  enum SettingsDestination: Hashable {
      case aiPersona
      case apiConfiguration
      case notifications
      case privacy
      case appearance
      case units
      case dataManagement
      case about
      case debug
  }
  ```

**Agent Task 11.0.2: Create Settings View Model**
- File: `AirFit/Modules/Settings/ViewModels/SettingsViewModel.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  import Observation
  
  @MainActor
  @Observable
  final class SettingsViewModel {
      // MARK: - Dependencies
      private let modelContext: ModelContext
      private let user: User
      private let apiKeyManager: APIKeyManager
      private let aiService: AIServiceProtocol
      private let notificationManager: NotificationManager
      private let coordinator: SettingsCoordinator
      
      // MARK: - Published State
      private(set) var isLoading = false
      private(set) var error: Error?
      
      // User Preferences
      var preferredUnits: MeasurementSystem
      var appearanceMode: AppearanceMode
      var hapticFeedback: Bool
      var analyticsEnabled: Bool
      
      // AI Configuration
      var selectedProvider: AIProvider
      var selectedModel: String
      var availableProviders: [AIProvider] = []
      var installedAPIKeys: Set<AIProvider> = []
      
      // Communication Preferences
      var notificationPreferences: NotificationPreferences
      var quietHours: QuietHours
      
      // Privacy & Security
      var biometricLockEnabled: Bool
      var exportHistory: [DataExport] = []
      
      // MARK: - Initialization
      init(
          modelContext: ModelContext,
          user: User,
          apiKeyManager: APIKeyManager,
          aiService: AIServiceProtocol,
          notificationManager: NotificationManager,
          coordinator: SettingsCoordinator
      ) {
          self.modelContext = modelContext
          self.user = user
          self.apiKeyManager = apiKeyManager
          self.aiService = aiService
          self.notificationManager = notificationManager
          self.coordinator = coordinator
          
          // Initialize with user's current preferences
          self.preferredUnits = user.preferredUnits
          self.appearanceMode = user.appearanceMode ?? .system
          self.hapticFeedback = user.hapticFeedbackEnabled
          self.analyticsEnabled = user.analyticsEnabled
          self.selectedProvider = user.selectedAIProvider ?? .openAI
          self.selectedModel = user.selectedAIModel ?? "gpt-4"
          self.notificationPreferences = user.notificationPreferences ?? NotificationPreferences()
          self.quietHours = user.quietHours ?? QuietHours()
          self.biometricLockEnabled = user.biometricLockEnabled
      }
      
      // MARK: - Data Loading
      func loadSettings() async {
          isLoading = true
          defer { isLoading = false }
          
          do {
              // Load available providers
              availableProviders = AIProvider.allCases
              
              // Check which providers have API keys
              installedAPIKeys = Set(
                  availableProviders.filter { provider in
                      apiKeyManager.hasKey(for: provider)
                  }
              )
              
              // Load notification status
              let authStatus = await notificationManager.getAuthorizationStatus()
              notificationPreferences.systemEnabled = authStatus == .authorized
              
              // Load export history
              exportHistory = try await loadExportHistory()
              
          } catch {
              self.error = error
              AppLogger.error("Failed to load settings", error: error, category: .settings)
          }
      }
      
      // MARK: - Preference Updates
      func updateUnits(_ units: MeasurementSystem) async throws {
          preferredUnits = units
          user.preferredUnits = units
          try modelContext.save()
          
          // Post notification for UI updates
          NotificationCenter.default.post(
              name: .unitsChanged,
              object: nil,
              userInfo: ["units": units]
          )
      }
      
      func updateAppearance(_ mode: AppearanceMode) async throws {
          appearanceMode = mode
          user.appearanceMode = mode
          try modelContext.save()
          
          // Update app appearance
          await MainActor.run {
              switch mode {
              case .light:
                  UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
              case .dark:
                  UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
              case .system:
                  UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
              }
          }
      }
      
      func updateHaptics(_ enabled: Bool) async throws {
          hapticFeedback = enabled
          user.hapticFeedbackEnabled = enabled
          try modelContext.save()
      }
      
      func updateAnalytics(_ enabled: Bool) async throws {
          analyticsEnabled = enabled
          user.analyticsEnabled = enabled
          try modelContext.save()
          
          // Update analytics service
          if enabled {
              // Analytics.shared.enable()
          } else {
              // Analytics.shared.disable()
          }
      }
      
      // MARK: - AI Configuration
      func updateAIProvider(_ provider: AIProvider, model: String) async throws {
          // Verify API key exists
          guard apiKeyManager.hasKey(for: provider) else {
              throw SettingsError.missingAPIKey(provider)
          }
          
          // Update selection
          selectedProvider = provider
          selectedModel = model
          user.selectedAIProvider = provider
          user.selectedAIModel = model
          try modelContext.save()
          
          // Configure AI service
          let apiKey = try apiKeyManager.getAPIKey(for: provider)
          try await aiService.configure(
              provider: provider,
              apiKey: apiKey,
              model: model
          )
          
          AppLogger.info("AI provider updated to \(provider.displayName)", category: .settings)
      }
      
      func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
          // Validate key format
          guard isValidAPIKey(key, for: provider) else {
              throw SettingsError.invalidAPIKey
          }
          
          // Test key with provider
          let isValid = try await testAPIKey(key, provider: provider)
          guard isValid else {
              throw SettingsError.apiKeyTestFailed
          }
          
          // Save to keychain
          try apiKeyManager.saveAPIKey(key, for: provider)
          installedAPIKeys.insert(provider)
          
          // If this is the selected provider, reconfigure
          if provider == selectedProvider {
              try await aiService.configure(
                  provider: provider,
                  apiKey: key,
                  model: selectedModel
              )
          }
      }
      
      func deleteAPIKey(for provider: AIProvider) async throws {
          try apiKeyManager.deleteAPIKey(for: provider)
          installedAPIKeys.remove(provider)
          
          // If deleting current provider's key, switch to another
          if provider == selectedProvider {
              if let alternativeProvider = installedAPIKeys.first {
                  try await updateAIProvider(alternativeProvider, model: "default")
              }
          }
      }
      
      // MARK: - Notification Preferences
      func updateNotificationPreferences(_ prefs: NotificationPreferences) async throws {
          notificationPreferences = prefs
          user.notificationPreferences = prefs
          try modelContext.save()
          
          // Update notification manager
          await notificationManager.updatePreferences(prefs)
      }
      
      func updateQuietHours(_ hours: QuietHours) async throws {
          quietHours = hours
          user.quietHours = hours
          try modelContext.save()
          
          // Reschedule notifications
          await notificationManager.rescheduleWithQuietHours(hours)
      }
      
      func openSystemNotificationSettings() {
          guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
          UIApplication.shared.open(url)
      }
      
      // MARK: - Privacy & Security
      func updateBiometricLock(_ enabled: Bool) async throws {
          // Verify biometric availability
          if enabled {
              let biometricManager = BiometricAuthManager()
              guard biometricManager.canUseBiometrics else {
                  throw SettingsError.biometricsNotAvailable
              }
          }
          
          biometricLockEnabled = enabled
          user.biometricLockEnabled = enabled
          try modelContext.save()
      }
      
      // MARK: - Data Management
      func exportUserData() async throws -> URL {
          isLoading = true
          defer { isLoading = false }
          
          let exporter = UserDataExporter(modelContext: modelContext)
          let exportURL = try await exporter.exportAllData(for: user)
          
          // Record export
          let export = DataExport(
              date: Date(),
              size: try FileManager.default.attributesOfItem(atPath: exportURL.path)[.size] as? Int64 ?? 0,
              format: .json
          )
          user.dataExports.append(export)
          try modelContext.save()
          
          return exportURL
      }
      
      func deleteAllData() async throws {
          // Show confirmation first
          coordinator.showAlert(.confirmDelete {
              Task {
                  try await self.performDataDeletion()
              }
          })
      }
      
      private func performDataDeletion() async throws {
          // Delete all user data
          // This would typically involve:
          // 1. Deleting all related entities
          // 2. Clearing keychain
          // 3. Resetting user defaults
          // 4. Signing out
          
          AppLogger.info("User data deletion requested", category: .settings)
      }
      
      // MARK: - Helper Methods
      private func isValidAPIKey(_ key: String, for provider: AIProvider) -> Bool {
          switch provider {
          case .openAI:
              return key.hasPrefix("sk-") && key.count > 20
          case .anthropic:
              return key.hasPrefix("sk-ant-") && key.count > 20
          case .ollama:
              return !key.isEmpty // Local, any non-empty value
          case .custom:
              return !key.isEmpty
          }
      }
      
      private func testAPIKey(_ key: String, provider: AIProvider) async throws -> Bool {
          // Create temporary service to test key
          let testService = AIServiceFactory.createService(for: provider)
          return try await testService.testConnection(apiKey: key)
      }
      
      private func loadExportHistory() async throws -> [DataExport] {
          // Load from user's export history
          return user.dataExports.sorted { $0.date > $1.date }
      }
  }
  
  // MARK: - Supporting Types
  enum SettingsError: LocalizedError {
      case missingAPIKey(AIProvider)
      case invalidAPIKey
      case apiKeyTestFailed
      case biometricsNotAvailable
      case exportFailed(String)
      
      var errorDescription: String? {
          switch self {
          case .missingAPIKey(let provider):
              return "Please add an API key for \(provider.displayName)"
          case .invalidAPIKey:
              return "Invalid API key format"
          case .apiKeyTestFailed:
              return "API key validation failed. Please check your key."
          case .biometricsNotAvailable:
              return "Biometric authentication is not available on this device"
          case .exportFailed(let reason):
              return "Export failed: \(reason)"
          }
      }
  }
  
  // MARK: - Notification Names
  extension Notification.Name {
      static let unitsChanged = Notification.Name("unitsChanged")
      static let themeChanged = Notification.Name("themeChanged")
  }
  ```

---

**Task 11.1: Main Settings View**

**Agent Task 11.1.1: Create Settings List View**
- File: `AirFit/Modules/Settings/Views/SettingsListView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct SettingsListView: View {
      @Environment(\.dismiss) private var dismiss
      @StateObject private var viewModel: SettingsViewModel
      @StateObject private var coordinator: SettingsCoordinator
      
      init(user: User, modelContext: ModelContext) {
          let coordinator = SettingsCoordinator()
          let viewModel = SettingsViewModel(
              modelContext: modelContext,
              user: user,
              apiKeyManager: APIKeyManager.shared,
              aiService: AIServiceManager.shared,
              notificationManager: NotificationManager.shared,
              coordinator: coordinator
          )
          
          _viewModel = StateObject(wrappedValue: viewModel)
          _coordinator = StateObject(wrappedValue: coordinator)
      }
      
      var body: some View {
          NavigationStack(path: $coordinator.navigationPath) {
              List {
                  aiSection
                  preferencesSection
                  privacySection
                  dataSection
                  supportSection
                  
                  if AppConstants.isDevelopment {
                      debugSection
                  }
              }
              .listStyle(.insetGrouped)
              .navigationTitle("Settings")
              .navigationBarTitleDisplayMode(.large)
              .toolbar {
                  ToolbarItem(placement: .navigationBarTrailing) {
                      Button("Done") { dismiss() }
                  }
              }
              .navigationDestination(for: SettingsDestination.self) { destination in
                  destinationView(for: destination)
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
          }
      }
      
      // MARK: - Sections
      private var aiSection: some View {
          Section {
              NavigationLink(value: SettingsDestination.aiPersona) {
                  Label {
                      VStack(alignment: .leading, spacing: 4) {
                          Text("AI Coach Persona")
                          Text("Customize your coach's style")
                              .font(.caption)
                              .foregroundStyle(.secondary)
                      }
                  } icon: {
                      Image(systemName: "figure.wave")
                          .foregroundStyle(.tint)
                  }
              }
              
              NavigationLink(value: SettingsDestination.apiConfiguration) {
                  Label {
                      VStack(alignment: .leading, spacing: 4) {
                          Text("AI Provider")
                          Text(viewModel.selectedProvider.displayName)
                              .font(.caption)
                              .foregroundStyle(.secondary)
                      }
                  } icon: {
                      Image(systemName: "cpu")
                          .foregroundStyle(.tint)
                  }
              }
          } header: {
              Text("AI Configuration")
          }
      }
      
      private var preferencesSection: some View {
          Section("Preferences") {
              NavigationLink(value: SettingsDestination.units) {
                  Label {
                      HStack {
                          Text("Units")
                          Spacer()
                          Text(viewModel.preferredUnits.displayName)
                              .foregroundStyle(.secondary)
                      }
                  } icon: {
                      Image(systemName: "ruler")
                          .foregroundStyle(.tint)
                  }
              }
              
              NavigationLink(value: SettingsDestination.appearance) {
                  Label {
                      HStack {
                          Text("Appearance")
                          Spacer()
                          Text(viewModel.appearanceMode.displayName)
                              .foregroundStyle(.secondary)
                      }
                  } icon: {
                      Image(systemName: "paintbrush")
                          .foregroundStyle(.tint)
                  }
              }
              
              NavigationLink(value: SettingsDestination.notifications) {
                  Label {
                      HStack {
                          Text("Notifications")
                          Spacer()
                          if viewModel.notificationPreferences.systemEnabled {
                              Image(systemName: "bell.fill")
                                  .font(.caption)
                                  .foregroundStyle(.secondary)
                          }
                      }
                  } icon: {
                      Image(systemName: "bell")
                          .foregroundStyle(.tint)
                  }
              }
              
              Toggle(isOn: $viewModel.hapticFeedback) {
                  Label("Haptic Feedback", systemImage: "hand.tap")
              }
              .onChange(of: viewModel.hapticFeedback) { _, newValue in
                  Task {
                      try await viewModel.updateHaptics(newValue)
                  }
              }
          }
      }
      
      private var privacySection: some View {
          Section("Privacy & Security") {
              NavigationLink(value: SettingsDestination.privacy) {
                  Label("Privacy Settings", systemImage: "lock.shield")
              }
              
              Toggle(isOn: $viewModel.biometricLockEnabled) {
                  Label("Require Face ID", systemImage: "faceid")
              }
              .onChange(of: viewModel.biometricLockEnabled) { _, newValue in
                  Task {
                      try await viewModel.updateBiometricLock(newValue)
                  }
              }
              
              Toggle(isOn: $viewModel.analyticsEnabled) {
                  Label("Share Analytics", systemImage: "chart.line.uptrend.xyaxis")
              }
              .onChange(of: viewModel.analyticsEnabled) { _, newValue in
                  Task {
                      try await viewModel.updateAnalytics(newValue)
                  }
              }
          }
      }
      
      private var dataSection: some View {
          Section("Data Management") {
              NavigationLink(value: SettingsDestination.dataManagement) {
                  Label {
                      VStack(alignment: .leading, spacing: 4) {
                          Text("Export Data")
                          if let lastExport = viewModel.exportHistory.first {
                              Text("Last export: \(lastExport.date.formatted(.relative(presentation: .named)))")
                                  .font(.caption)
                                  .foregroundStyle(.secondary)
                          }
                      }
                  } icon: {
                      Image(systemName: "square.and.arrow.up")
                          .foregroundStyle(.tint)
                  }
              }
              
              Button(role: .destructive) {
                  Task {
                      try await viewModel.deleteAllData()
                  }
              } label: {
                  Label("Delete All Data", systemImage: "trash")
                      .foregroundStyle(.red)
              }
          }
      }
      
      private var supportSection: some View {
          Section("Support") {
              NavigationLink(value: SettingsDestination.about) {
                  Label {
                      HStack {
                          Text("About")
                          Spacer()
                          Text("v\(AppConstants.appVersion)")
                              .font(.caption)
                              .foregroundStyle(.secondary)
                      }
                  } icon: {
                      Image(systemName: "info.circle")
                          .foregroundStyle(.tint)
                  }
              }
              
              Link(destination: URL(string: AppConstants.privacyPolicyURL)!) {
                  Label("Privacy Policy", systemImage: "hand.raised")
              }
              
              Link(destination: URL(string: AppConstants.termsOfServiceURL)!) {
                  Label("Terms of Service", systemImage: "doc.text")
              }
              
              Link(destination: URL(string: "mailto:\(AppConstants.supportEmail)")!) {
                  Label("Contact Support", systemImage: "envelope")
              }
          }
      }
      
      private var debugSection: some View {
          Section("Developer") {
              NavigationLink(value: SettingsDestination.debug) {
                  Label("Debug Tools", systemImage: "hammer")
              }
          }
      }
      
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
              PersonaRefinementFlow(user: viewModel.user)
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
          case .exportSuccess(let url):
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
          }
      }
  }
  ```

---

**Task 11.2: AI Configuration Views**

**Agent Task 11.2.1: Create AI Persona Settings**
- File: `AirFit/Modules/Settings/Views/AIPersonaSettingsView.swift`
- Implementation:
  ```swift
  import SwiftUI
  import Charts
  
  struct AIPersonaSettingsView: View {
      @ObservedObject var viewModel: SettingsViewModel
      @State private var showPersonaRefinement = false
      @State private var previewText = "Let's crush today's workout! I see you're feeling energized - perfect timing for that strength session we planned."
      
      var body: some View {
          ScrollView {
              VStack(spacing: AppSpacing.xl) {
                  personaOverview
                  coachingStyleChart
                  communicationPreferences
                  personaActions
              }
              .padding()
          }
          .navigationTitle("AI Coach Persona")
          .navigationBarTitleDisplayMode(.large)
          .sheet(isPresented: $showPersonaRefinement) {
              PersonaRefinementFlow(user: viewModel.user)
          }
      }
      
      private var personaOverview: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Current Persona", icon: "person.fill")
              
              Card {
                  VStack(alignment: .leading, spacing: AppSpacing.md) {
                      // Coaching blend summary
                      if let profile = viewModel.user.onboardingProfile?.personaProfile {
                          PersonaBlendView(blend: profile.coachingStyle.blend ?? StyleBlend())
                      }
                      
                      Divider()
                      
                      // Preview
                      VStack(alignment: .leading, spacing: AppSpacing.sm) {
                          Label("Preview", systemImage: "quote.bubble")
                              .font(.subheadline)
                              .foregroundStyle(.secondary)
                          
                          Text(previewText)
                              .font(.callout)
                              .italic()
                              .padding()
                              .background(Color.secondaryBackground)
                              .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                      }
                  }
              }
          }
      }
      
      private var coachingStyleChart: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Coaching Style Blend", icon: "chart.pie.fill")
              
              Card {
                  if let blend = viewModel.user.onboardingProfile?.personaProfile?.coachingStyle.blend {
                      Chart {
                          if let authoritative = blend.authoritativeDirect {
                              SectorMark(
                                  angle: .value("Style", authoritative),
                                  innerRadius: .ratio(0.5),
                                  angularInset: 2
                              )
                              .foregroundStyle(Color.red.gradient)
                              .annotation(position: .overlay) {
                                  Text("\(Int(authoritative))%")
                                      .font(.caption2)
                                      .bold()
                              }
                          }
                          
                          if let encouraging = blend.encouragingEmpathetic {
                              SectorMark(
                                  angle: .value("Style", encouraging),
                                  innerRadius: .ratio(0.5),
                                  angularInset: 2
                              )
                              .foregroundStyle(Color.green.gradient)
                          }
                          
                          if let analytical = blend.analyticalInsightful {
                              SectorMark(
                                  angle: .value("Style", analytical),
                                  innerRadius: .ratio(0.5),
                                  angularInset: 2
                              )
                              .foregroundStyle(Color.blue.gradient)
                          }
                          
                          if let playful = blend.playfullyProvocative {
                              SectorMark(
                                  angle: .value("Style", playful),
                                  innerRadius: .ratio(0.5),
                                  angularInset: 2
                              )
                              .foregroundStyle(Color.purple.gradient)
                          }
                      }
                      .frame(height: 200)
                      
                      // Legend
                      VStack(alignment: .leading, spacing: AppSpacing.xs) {
                          StyleLegendItem(color: .red, title: "Authoritative & Direct")
                          StyleLegendItem(color: .green, title: "Encouraging & Empathetic")
                          StyleLegendItem(color: .blue, title: "Analytical & Insightful")
                          StyleLegendItem(color: .purple, title: "Playfully Provocative")
                      }
                      .padding(.top)
                  }
              }
          }
      }
      
      private var communicationPreferences: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Communication Style", icon: "bubble.left.and.bubble.right.fill")
              
              Card {
                  VStack(spacing: AppSpacing.md) {
                      if let prefs = viewModel.user.onboardingProfile?.communicationPreferences {
                          PreferenceRow(
                              title: "Update Frequency",
                              value: prefs.updateFrequency ?? "Moderate",
                              icon: "clock"
                          )
                          
                          PreferenceRow(
                              title: "Celebration Style",
                              value: prefs.celebrationStyle ?? "Balanced",
                              icon: "party.popper"
                          )
                          
                          PreferenceRow(
                              title: "Absence Response",
                              value: prefs.absenceResponse ?? "Gentle nudge",
                              icon: "bell.slash"
                          )
                          
                          PreferenceRow(
                              title: "Language Style",
                              value: prefs.languageComplexity ?? "Conversational",
                              icon: "text.quote"
                          )
                      }
                  }
              }
          }
      }
      
      private var personaActions: some View {
          VStack(spacing: AppSpacing.md) {
              Button(action: { showPersonaRefinement = true }) {
                  Label("Refine Coach Persona", systemImage: "wand.and.stars")
                      .frame(maxWidth: .infinity)
              }
              .buttonStyle(.primaryProminent)
              
              Button(action: generateNewPreview) {
                  Label("Generate New Preview", systemImage: "arrow.clockwise")
                      .frame(maxWidth: .infinity)
              }
              .buttonStyle(.secondary)
          }
      }
      
      private func generateNewPreview() {
          // Simulate generating a new preview based on persona
          let previews = [
              "Great job today! Your consistency is really showing in your performance metrics.",
              "Time to push those limits! I've noticed you're ready for the next level.",
              "Remember, recovery is just as important as training. How are you feeling today?",
              "Your heart rate data shows excellent cardiovascular improvements. Keep it up!",
              "I see you missed yesterday's workout. No worries - let's make today count!"
          ]
          
          withAnimation {
              previewText = previews.randomElement() ?? previewText
          }
          
          HapticManager.impact(.light)
      }
  }
  
  // MARK: - Supporting Views
  struct PersonaBlendView: View {
      let blend: StyleBlend
      
      var body: some View {
          HStack(spacing: AppSpacing.sm) {
              if let primary = primaryStyle {
                  Tag(primary.name, color: primary.color)
              }
              
              if let secondary = secondaryStyle {
                  Tag(secondary.name, color: secondary.color, style: .secondary)
              }
          }
      }
      
      private var primaryStyle: (name: String, color: Color)? {
          let styles = [
              (blend.authoritativeDirect ?? 0, "Authoritative", Color.red),
              (blend.encouragingEmpathetic ?? 0, "Encouraging", Color.green),
              (blend.analyticalInsightful ?? 0, "Analytical", Color.blue),
              (blend.playfullyProvocative ?? 0, "Playful", Color.purple)
          ].sorted { $0.0 > $1.0 }
          
          guard let first = styles.first, first.0 > 0 else { return nil }
          return (first.1, first.2)
      }
      
      private var secondaryStyle: (name: String, color: Color)? {
          let styles = [
              (blend.authoritativeDirect ?? 0, "Authoritative", Color.red),
              (blend.encouragingEmpathetic ?? 0, "Encouraging", Color.green),
              (blend.analyticalInsightful ?? 0, "Analytical", Color.blue),
              (blend.playfullyProvocative ?? 0, "Playful", Color.purple)
          ].sorted { $0.0 > $1.0 }
          
          guard styles.count > 1, styles[1].0 > 20 else { return nil }
          return (styles[1].1, styles[1].2)
      }
  }
  
  struct StyleLegendItem: View {
      let color: Color
      let title: String
      
      var body: some View {
          HStack(spacing: AppSpacing.xs) {
              Circle()
                  .fill(color.gradient)
                  .frame(width: 12, height: 12)
              
              Text(title)
                  .font(.caption)
                  .foregroundStyle(.secondary)
          }
      }
  }
  
  struct PreferenceRow: View {
      let title: String
      let value: String
      let icon: String
      
      var body: some View {
          HStack {
              Label(title, systemImage: icon)
                  .foregroundStyle(.primary)
              
              Spacer()
              
              Text(value)
                  .foregroundStyle(.secondary)
          }
      }
  }
  ```

**Agent Task 11.2.2: Create API Configuration View**
- File: `AirFit/Modules/Settings/Views/APIConfigurationView.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct APIConfigurationView: View {
      @ObservedObject var viewModel: SettingsViewModel
      @Environment(\.dismiss) private var dismiss
      @State private var selectedProvider: AIProvider
      @State private var selectedModel: String
      @State private var showAPIKeyEntry = false
      @State private var providerToAddKey: AIProvider?
      
      init(viewModel: SettingsViewModel) {
          self.viewModel = viewModel
          _selectedProvider = State(initialValue: viewModel.selectedProvider)
          _selectedModel = State(initialValue: viewModel.selectedModel)
      }
      
      var body: some View {
          ScrollView {
              VStack(spacing: AppSpacing.xl) {
                  currentConfiguration
                  providerSelection
                  apiKeyManagement
                  saveButton
              }
              .padding()
          }
          .navigationTitle("AI Provider")
          .navigationBarTitleDisplayMode(.large)
          .sheet(isPresented: $showAPIKeyEntry) {
              if let provider = providerToAddKey {
                  APIKeyEntryView(provider: provider, viewModel: viewModel)
              }
          }
      }
      
      private var currentConfiguration: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Current Configuration", icon: "cpu")
              
              Card {
                  VStack(spacing: AppSpacing.md) {
                      ConfigRow(
                          title: "Provider",
                          value: viewModel.selectedProvider.displayName,
                          icon: viewModel.selectedProvider.icon
                      )
                      
                      ConfigRow(
                          title: "Model",
                          value: viewModel.selectedModel,
                          icon: "brain"
                      )
                      
                      ConfigRow(
                          title: "Status",
                          value: viewModel.installedAPIKeys.contains(viewModel.selectedProvider) ? "Active" : "No API Key",
                          icon: "checkmark.seal.fill",
                          valueColor: viewModel.installedAPIKeys.contains(viewModel.selectedProvider) ? .green : .orange
                      )
                  }
              }
          }
      }
      
      private var providerSelection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Select Provider", icon: "rectangle.stack")
              
              Card {
                  VStack(spacing: 0) {
                      ForEach(AIProvider.allCases) { provider in
                          ProviderRow(
                              provider: provider,
                              isSelected: selectedProvider == provider,
                              hasAPIKey: viewModel.installedAPIKeys.contains(provider),
                              models: provider.availableModels
                          ) {
                              withAnimation {
                                  selectedProvider = provider
                                  selectedModel = provider.defaultModel
                              }
                              HapticManager.selection()
                          }
                          
                          if provider != AIProvider.allCases.last {
                              Divider()
                                  .padding(.vertical, AppSpacing.xs)
                          }
                      }
                  }
              }
          }
      }
      
      private var apiKeyManagement: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "API Keys", icon: "key.fill")
              
              Card {
                  VStack(spacing: AppSpacing.md) {
                      ForEach(AIProvider.allCases) { provider in
                          APIKeyRow(
                              provider: provider,
                              hasKey: viewModel.installedAPIKeys.contains(provider),
                              onAdd: {
                                  providerToAddKey = provider
                                  showAPIKeyEntry = true
                              },
                              onDelete: {
                                  Task {
                                      try await viewModel.deleteAPIKey(for: provider)
                                  }
                              }
                          )
                      }
                  }
              }
              
              Text("API keys are stored securely in your device's keychain")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .padding(.horizontal)
          }
      }
      
      private var saveButton: some View {
          Button(action: saveConfiguration) {
              Label("Save Configuration", systemImage: "checkmark.circle.fill")
                  .frame(maxWidth: .infinity)
          }
          .buttonStyle(.primaryProminent)
          .disabled(!viewModel.installedAPIKeys.contains(selectedProvider))
      }
      
      private func saveConfiguration() {
          Task {
              do {
                  try await viewModel.updateAIProvider(selectedProvider, model: selectedModel)
                  dismiss()
              } catch {
                  // Handle error
                  AppLogger.error("Failed to save AI configuration", error: error, category: .settings)
              }
          }
      }
  }
  
  // MARK: - Supporting Views
  struct ProviderRow: View {
      let provider: AIProvider
      let isSelected: Bool
      let hasAPIKey: Bool
      let models: [String]
      let onSelect: () -> Void
      
      var body: some View {
          Button(action: onSelect) {
              HStack(spacing: AppSpacing.md) {
                  Image(systemName: provider.icon)
                      .font(.title2)
                      .foregroundStyle(isSelected ? .white : .primary)
                      .frame(width: 44, height: 44)
                      .background(isSelected ? Color.accentColor : Color.secondaryBackground)
                      .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSm))
                  
                  VStack(alignment: .leading, spacing: AppSpacing.xs) {
                      Text(provider.displayName)
                          .font(.headline)
                      
                      Text("\(models.count) models available")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
                  
                  Spacer()
                  
                  if hasAPIKey {
                      Image(systemName: "key.fill")
                          .font(.caption)
                          .foregroundStyle(.green)
                  }
                  
                  if isSelected {
                      Image(systemName: "checkmark")
                          .foregroundStyle(.accentColor)
                  }
              }
              .padding(.vertical, AppSpacing.xs)
          }
          .buttonStyle(.plain)
      }
  }
  
  struct APIKeyRow: View {
      let provider: AIProvider
      let hasKey: Bool
      let onAdd: () -> Void
      let onDelete: () -> Void
      
      var body: some View {
          HStack {
              Label(provider.displayName, systemImage: provider.icon)
              
              Spacer()
              
              if hasKey {
                  Button("Remove", systemImage: "trash", action: onDelete)
                      .buttonStyle(.destructive)
                      .controlSize(.small)
              } else {
                  Button("Add Key", systemImage: "plus.circle", action: onAdd)
                      .buttonStyle(.borderedProminent)
                      .controlSize(.small)
              }
          }
      }
  }
  
  struct ConfigRow: View {
      let title: String
      let value: String
      let icon: String
      var valueColor: Color = .primary
      
      var body: some View {
          HStack {
              Label(title, systemImage: icon)
              Spacer()
              Text(value)
                  .foregroundStyle(valueColor)
                  .fontWeight(.medium)
          }
      }
  }
  ```

---

**Task 11.3: Additional Settings Views**

**Agent Task 11.3.1: Create Units Settings View**
- File: `AirFit/Modules/Settings/Views/UnitsSettingsView.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct UnitsSettingsView: View {
      @ObservedObject var viewModel: SettingsViewModel
      @Environment(\.dismiss) private var dismiss
      @State private var selectedUnits: MeasurementSystem
      
      init(viewModel: SettingsViewModel) {
          self.viewModel = viewModel
          _selectedUnits = State(initialValue: viewModel.preferredUnits)
      }
      
      var body: some View {
          ScrollView {
              VStack(spacing: AppSpacing.xl) {
                  unitSelection
                  examples
                  saveButton
              }
              .padding()
          }
          .navigationTitle("Units")
          .navigationBarTitleDisplayMode(.inline)
      }
      
      private var unitSelection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Measurement System", icon: "ruler")
              
              Card {
                  VStack(spacing: 0) {
                      ForEach(MeasurementSystem.allCases) { system in
                          UnitSystemRow(
                              system: system,
                              isSelected: selectedUnits == system
                          ) {
                              withAnimation {
                                  selectedUnits = system
                              }
                              HapticManager.selection()
                          }
                          
                          if system != MeasurementSystem.allCases.last {
                              Divider()
                          }
                      }
                  }
              }
          }
      }
      
      private var examples: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Examples", icon: "info.circle")
              
              Card {
                  VStack(spacing: AppSpacing.md) {
                      ExampleRow(
                          label: "Weight",
                          imperial: "150 lbs",
                          metric: "68 kg",
                          selectedSystem: selectedUnits
                      )
                      
                      Divider()
                      
                      ExampleRow(
                          label: "Height",
                          imperial: "5'10\"",
                          metric: "178 cm",
                          selectedSystem: selectedUnits
                      )
                      
                      Divider()
                      
                      ExampleRow(
                          label: "Distance",
                          imperial: "3 miles",
                          metric: "5 km",
                          selectedSystem: selectedUnits
                      )
                      
                      Divider()
                      
                      ExampleRow(
                          label: "Temperature",
                          imperial: "72°F",
                          metric: "22°C",
                          selectedSystem: selectedUnits
                      )
                  }
              }
          }
      }
      
      private var saveButton: some View {
          Button(action: saveUnits) {
              Label("Save Units", systemImage: "checkmark.circle.fill")
                  .frame(maxWidth: .infinity)
          }
          .buttonStyle(.primaryProminent)
          .disabled(selectedUnits == viewModel.preferredUnits)
      }
      
      private func saveUnits() {
          Task {
              try await viewModel.updateUnits(selectedUnits)
              dismiss()
          }
      }
  }
  
  // MARK: - Supporting Views
  struct UnitSystemRow: View {
      let system: MeasurementSystem
      let isSelected: Bool
      let onSelect: () -> Void
      
      var body: some View {
          Button(action: onSelect) {
              HStack {
                  VStack(alignment: .leading, spacing: AppSpacing.xs) {
                      Text(system.displayName)
                          .font(.headline)
                      
                      Text(system.description)
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
                  
                  Spacer()
                  
                  if isSelected {
                      Image(systemName: "checkmark.circle.fill")
                          .foregroundStyle(.accentColor)
                  } else {
                      Image(systemName: "circle")
                          .foregroundStyle(.quaternary)
                  }
              }
              .padding(.vertical, AppSpacing.sm)
          }
          .buttonStyle(.plain)
      }
  }
  
  struct ExampleRow: View {
      let label: String
      let imperial: String
      let metric: String
      let selectedSystem: MeasurementSystem
      
      var body: some View {
          HStack {
              Text(label)
                  .foregroundStyle(.secondary)
              
              Spacer()
              
              Text(selectedSystem == .imperial ? imperial : metric)
                  .fontWeight(.medium)
                  .animation(.easeInOut(duration: 0.2), value: selectedSystem)
          }
      }
  }
  ```

**Agent Task 11.3.2: Create Data Management View**
- File: `AirFit/Modules/Settings/Views/DataManagementView.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct DataManagementView: View {
      @ObservedObject var viewModel: SettingsViewModel
      @State private var showExportProgress = false
      @State private var exportURL: URL?
      
      var body: some View {
          ScrollView {
              VStack(spacing: AppSpacing.xl) {
                  exportSection
                  exportHistory
                  deleteSection
              }
              .padding()
          }
          .navigationTitle("Data Management")
          .navigationBarTitleDisplayMode(.large)
          .sheet(isPresented: $showExportProgress) {
              DataExportProgressView(viewModel: viewModel)
          }
          .sheet(item: $exportURL) { url in
              ShareSheet(items: [url])
          }
      }
      
      private var exportSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Export Your Data", icon: "square.and.arrow.up")
              
              Card {
                  VStack(alignment: .leading, spacing: AppSpacing.md) {
                      Text("Export all your AirFit data including workouts, meals, and health metrics in a portable JSON format.")
                          .font(.callout)
                          .foregroundStyle(.secondary)
                      
                      Button(action: startExport) {
                          Label("Export All Data", systemImage: "square.and.arrow.up")
                              .frame(maxWidth: .infinity)
                      }
                      .buttonStyle(.borderedProminent)
                  }
              }
          }
      }
      
      private var exportHistory: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Export History", icon: "clock.arrow.circlepath")
              
              if viewModel.exportHistory.isEmpty {
                  Card {
                      Text("No previous exports")
                          .font(.callout)
                          .foregroundStyle(.secondary)
                          .frame(maxWidth: .infinity, minHeight: 60)
                  }
              } else {
                  ForEach(viewModel.exportHistory) { export in
                      Card {
                          HStack {
                              VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                  Text(export.date.formatted(date: .abbreviated, time: .shortened))
                                      .font(.callout)
                                  
                                  Text(ByteCountFormatter().string(fromByteCount: export.size))
                                      .font(.caption)
                                      .foregroundStyle(.secondary)
                              }
                              
                              Spacer()
                              
                              Image(systemName: "doc.zipper")
                                  .foregroundStyle(.secondary)
                          }
                      }
                  }
              }
          }
      }
      
      private var deleteSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Delete Data", icon: "trash")
              
              Card(style: .destructive) {
                  VStack(alignment: .leading, spacing: AppSpacing.md) {
                      Label {
                          VStack(alignment: .leading, spacing: AppSpacing.xs) {
                              Text("Delete All Data")
                                  .font(.headline)
                                  .foregroundStyle(.red)
                              
                              Text("Permanently delete all your AirFit data. This cannot be undone.")
                                  .font(.caption)
                                  .foregroundStyle(.secondary)
                          }
                      } icon: {
                          Image(systemName: "exclamationmark.triangle.fill")
                              .foregroundStyle(.red)
                      }
                      
                      Button(role: .destructive, action: confirmDelete) {
                          Text("Delete Everything")
                              .frame(maxWidth: .infinity)
                      }
                      .buttonStyle(.borderedProminent)
                      .tint(.red)
                  }
              }
          }
      }
      
      private func startExport() {
          showExportProgress = true
          
          Task {
              do {
                  let url = try await viewModel.exportUserData()
                  await MainActor.run {
                      showExportProgress = false
                      exportURL = url
                  }
              } catch {
                  await MainActor.run {
                      showExportProgress = false
                      viewModel.coordinator.showAlert(.error(message: error.localizedDescription))
                  }
              }
          }
      }
      
      private func confirmDelete() {
          viewModel.coordinator.showAlert(.confirmDelete {
              Task {
                  try await viewModel.deleteAllData()
              }
          })
      }
  }
  ```

---

**Task 11.4: Supporting Components**

**Agent Task 11.4.1: Create API Key Entry View**
- File: `AirFit/Modules/Settings/Views/APIKeyEntryView.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct APIKeyEntryView: View {
      let provider: AIProvider
      @ObservedObject var viewModel: SettingsViewModel
      @Environment(\.dismiss) private var dismiss
      
      @State private var apiKey = ""
      @State private var isValidating = false
      @State private var showKey = false
      @FocusState private var isKeyFieldFocused: Bool
      
      var body: some View {
          NavigationStack {
              ScrollView {
                  VStack(spacing: AppSpacing.xl) {
                      providerInfo
                      keyInput
                      instructions
                  }
                  .padding()
              }
              .navigationTitle("Add API Key")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Cancel") { dismiss() }
                  }
                  
                  ToolbarItem(placement: .confirmationAction) {
                      Button("Save") { saveKey() }
                          .disabled(apiKey.isEmpty || isValidating)
                  }
              }
              .interactiveDismissDisabled(isValidating)
          }
      }
      
      private var providerInfo: some View {
          Card {
              HStack(spacing: AppSpacing.md) {
                  Image(systemName: provider.icon)
                      .font(.largeTitle)
                      .foregroundStyle(.tint)
                  
                  VStack(alignment: .leading, spacing: AppSpacing.xs) {
                      Text(provider.displayName)
                          .font(.headline)
                      
                      Text("API Key Required")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
                  
                  Spacer()
              }
          }
      }
      
      private var keyInput: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "API Key", icon: "key.fill")
              
              Card {
                  VStack(alignment: .leading, spacing: AppSpacing.sm) {
                      HStack {
                          if showKey {
                              TextField("Enter your API key", text: $apiKey)
                                  .textFieldStyle(.plain)
                                  .focused($isKeyFieldFocused)
                                  .autocorrectionDisabled()
                                  .textInputAutocapitalization(.never)
                          } else {
                              SecureField("Enter your API key", text: $apiKey)
                                  .textFieldStyle(.plain)
                                  .focused($isKeyFieldFocused)
                          }
                          
                          Button(action: { showKey.toggle() }) {
                              Image(systemName: showKey ? "eye.slash" : "eye")
                                  .foregroundStyle(.secondary)
                          }
                      }
                      
                      if isValidating {
                          HStack(spacing: AppSpacing.sm) {
                              ProgressView()
                                  .controlSize(.small)
                              Text("Validating key...")
                                  .font(.caption)
                                  .foregroundStyle(.secondary)
                          }
                      }
                  }
                  .padding(.vertical, AppSpacing.xs)
              }
              .onAppear {
                  isKeyFieldFocused = true
              }
          }
      }
      
      private var instructions: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Instructions", icon: "info.circle")
              
              Card {
                  VStack(alignment: .leading, spacing: AppSpacing.md) {
                      ForEach(provider.keyInstructions, id: \.self) { instruction in
                          Label {
                              Text(instruction)
                                  .font(.callout)
                          } icon: {
                              Text("•")
                                  .foregroundStyle(.secondary)
                          }
                      }
                      
                      if let url = provider.apiKeyURL {
                          Link(destination: url) {
                              Label("Get API Key", systemImage: "arrow.up.forward.square")
                                  .font(.callout)
                          }
                      }
                  }
              }
          }
      }
      
      private func saveKey() {
          isValidating = true
          
          Task {
              do {
                  try await viewModel.saveAPIKey(apiKey, for: provider)
                  await MainActor.run {
                      dismiss()
                  }
              } catch {
                  await MainActor.run {
                      isValidating = false
                      viewModel.coordinator.showAlert(.apiKeyInvalid)
                  }
              }
          }
      }
  }
  ```

**Agent Task 11.4.2: Create App Constants Extension**
- File: `AirFit/Core/Constants/AppConstants+Settings.swift`
- Implementation:
  ```swift
  extension AppConstants {
      // MARK: - App Information
      static var appVersion: String {
          Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
      }
      
      static var buildNumber: String {
          Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
      }
      
      static var appVersionString: String {
          "\(appVersion) (\(buildNumber))"
      }
      
      // MARK: - URLs
      static let privacyPolicyURL = "https://airfit.app/privacy"
      static let termsOfServiceURL = "https://airfit.app/terms"
      static let supportEmail = "support@airfit.app"
      
      // MARK: - Development
      static var isDevelopment: Bool {
          #if DEBUG
          return true
          #else
          return false
          #endif
      }
  }
  ```

---

**Task 11.5: Testing**

**Agent Task 11.5.1: Create Settings View Model Tests**
- File: `AirFitTests/Settings/SettingsViewModelTests.swift`
- Test Implementation:
  ```swift
  @MainActor
  final class SettingsViewModelTests: XCTestCase {
      var sut: SettingsViewModel!
      var mockAPIKeyManager: MockAPIKeyManager!
      var mockAIService: MockAIService!
      var modelContext: ModelContext!
      var testUser: User!
      
      override func setUp() async throws {
          try await super.setUp()
          
          // Setup test context
          modelContext = try SwiftDataTestHelper.createTestContext(
              for: User.self, OnboardingProfile.self
          )
          
          // Create test user
          testUser = User(name: "Test User")
          modelContext.insert(testUser)
          try modelContext.save()
          
          // Setup mocks
          mockAPIKeyManager = MockAPIKeyManager()
          mockAIService = MockAIService()
          
          // Create SUT
          sut = SettingsViewModel(
              modelContext: modelContext,
              user: testUser,
              apiKeyManager: mockAPIKeyManager,
              aiService: mockAIService,
              notificationManager: MockNotificationManager(),
              coordinator: SettingsCoordinator()
          )
      }
      
      func test_loadSettings_shouldPopulateAvailableProviders() async {
          // Act
          await sut.loadSettings()
          
          // Assert
          XCTAssertEqual(sut.availableProviders.count, AIProvider.allCases.count)
          XCTAssertTrue(sut.availableProviders.contains(.openAI))
          XCTAssertTrue(sut.availableProviders.contains(.anthropic))
      }
      
      func test_saveAPIKey_withValidKey_shouldStoreAndConfigureService() async throws {
          // Arrange
          let testKey = "sk-test1234567890"
          mockAPIKeyManager.testKeys[.openAI] = true
          
          // Act
          try await sut.saveAPIKey(testKey, for: .openAI)
          
          // Assert
          XCTAssertTrue(mockAPIKeyManager.savedKeys.contains { $0.provider == .openAI })
          XCTAssertTrue(sut.installedAPIKeys.contains(.openAI))
          XCTAssertTrue(mockAIService.isConfigured)
      }
      
      func test_updateUnits_shouldSaveAndPostNotification() async throws {
          // Arrange
          let expectation = expectation(forNotification: .unitsChanged, object: nil)
          
          // Act
          try await sut.updateUnits(.metric)
          
          // Assert
          XCTAssertEqual(sut.preferredUnits, .metric)
          XCTAssertEqual(testUser.preferredUnits, .metric)
          wait(for: [expectation], timeout: 1.0)
      }
      
      func test_deleteAPIKey_forActiveProvider_shouldSwitchToAlternative() async throws {
          // Arrange
          sut.selectedProvider = .openAI
          sut.installedAPIKeys = [.openAI, .anthropic]
          mockAPIKeyManager.testKeys[.anthropic] = true
          
          // Act
          try await sut.deleteAPIKey(for: .openAI)
          
          // Assert
          XCTAssertFalse(sut.installedAPIKeys.contains(.openAI))
          XCTAssertEqual(sut.selectedProvider, .anthropic)
      }
  }
  ```

---

**5. Acceptance Criteria for Module Completion**

- ✅ Complete settings navigation with all major sections
- ✅ AI persona customization with visual preview
- ✅ Secure API key management with validation
- ✅ Multi-provider LLM configuration
- ✅ Unit preference management with examples
- ✅ Granular notification controls
- ✅ Data export functionality
- ✅ Privacy and security settings
- ✅ Biometric lock option
- ✅ All settings persisted correctly
- ✅ Proper error handling and user feedback
- ✅ Accessibility support throughout
- ✅ Performance: Settings load < 500ms
- ✅ Test coverage ≥ 80%

**6. Module Dependencies**

- **Requires Completion Of:** Modules 1, 2, 9, 10
- **Must Be Completed Before:** Final app assembly
- **Can Run In Parallel With:** Module 12 (Chat Interface)

**7. Performance Requirements**

- Settings load time: < 500ms
- API key validation: < 2 seconds
- Data export: < 10 seconds for typical user
- Navigation transitions: 60fps
- Memory usage: < 30MB

---
