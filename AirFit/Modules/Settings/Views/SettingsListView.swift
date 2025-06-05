import SwiftUI
import SwiftData

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
    @State var viewModel: SettingsViewModel
    @State private var coordinator: SettingsCoordinator
    let user: User
    
    init(viewModel: SettingsViewModel, user: User) {
        self._viewModel = State(initialValue: viewModel)
        self.user = user
        self._coordinator = State(initialValue: SettingsCoordinator())
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            List {
                aiSection
                preferencesSection
                privacySection
                dataSection
                supportSection
                
                #if DEBUG
                debugSection
                #endif
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
                    if newValue {
                        HapticManager.impact(.light)
                    }
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
                    do {
                        try await viewModel.updateBiometricLock(newValue)
                    } catch {
                        // Show error alert
                        coordinator.showAlert(.error(message: error.localizedDescription))
                        // Revert toggle
                        viewModel.biometricLockEnabled = !newValue
                    }
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
    
    #if DEBUG
    private var debugSection: some View {
        Section("Developer") {
            NavigationLink(value: SettingsDestination.debug) {
                Label("Debug Tools", systemImage: "hammer")
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
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 2 ? "Apply Changes" : "Next") {
                        if currentStep == 2 {
                            applyRefinements()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
            
            Card {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("What would you like to change?")
                        .font(.subheadline.bold())
                    
                    TextField("E.g., Be more motivating, use less technical jargon...", text: $refinementText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
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
            
            Card {
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
                HapticManager.success()
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
        Card {
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
                        
                        Button("Try Again") {
                            exportError = nil
                            startExport()
                        }
                        .buttonStyle(.borderedProminent)
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
                            Button(action: { showShareSheet = true }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
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
                    HapticManager.success()
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    HapticManager.error()
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
                    Card {
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
                    Card {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Label("Before you go:", systemImage: "square.and.arrow.down")
                                .font(.headline)
                            
                            Text("You can export your data before deleting your account. This allows you to keep a copy of your information.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            
                            NavigationLink(destination: DataManagementView(viewModel: viewModel)) {
                                Label("Export My Data", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // Confirmation input
                    Card {
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
                    Button(action: { showFinalConfirmation = true }) {
                        if isDeleting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Delete My Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
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
                
                Button(action: { showAcknowledgments = true }) {
                    Label("Acknowledgments", systemImage: "heart.text.square")
                }
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
    @State private var showExportLogsSheet = false
    @State private var exportedLogsURL: IdentifiableURL?
    @State private var isProcessing = false
    @State private var statusMessage = ""
    
    var body: some View {
        List {
            Section("Cache Management") {
                Button(action: { showClearCacheAlert = true }) {
                    Label("Clear Cache", systemImage: "trash")
                }
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
                Button(action: { showResetOnboardingAlert = true }) {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                }
                .disabled(isProcessing)
                
                Button(action: exportLogs) {
                    Label("Export Debug Logs", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(isProcessing)
                
                NavigationLink(destination: FeatureFlagsView()) {
                    Label("Feature Flags", systemImage: "flag")
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
                HapticManager.success()
                
                // Clear status after delay
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    statusMessage = ""
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
                HapticManager.success()
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
                HapticManager.success()
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

// MARK: - Share Sheet
private struct SettingsShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

