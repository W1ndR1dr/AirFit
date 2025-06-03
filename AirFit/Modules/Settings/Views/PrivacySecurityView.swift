import SwiftUI

struct PrivacySecurityView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xLarge) {
                biometricSection
                dataPrivacySection
                analyticsSection
                legalSection
            }
            .padding()
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariView(url: URL(string: AppConstants.privacyPolicyURL)!)
        }
        .sheet(isPresented: $showTermsOfService) {
            SafariView(url: URL(string: AppConstants.termsOfServiceURL)!)
        }
    }
    
    private var biometricSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Biometric Security", icon: "faceid")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    Toggle(isOn: $viewModel.biometricLockEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text("Require Face ID")
                                    .font(.headline)
                                Text("Add an extra layer of security")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "faceid")
                                .foregroundStyle(.tint)
                        }
                    }
                    .onChange(of: viewModel.biometricLockEnabled) { _, newValue in
                        Task {
                            do {
                                try await viewModel.updateBiometricLock(newValue)
                                if newValue {
                                    HapticManager.notification(.success)
                                }
                            } catch {
                                // Revert toggle
                                viewModel.biometricLockEnabled = !newValue
                                viewModel.showAlert(.error(message: error.localizedDescription))
                            }
                        }
                    }
                    
                    if viewModel.biometricLockEnabled {
                        Divider()
                        
                        Label {
                            Text("Face ID will be required when opening the app")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Data Privacy", icon: "lock.shield")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    PrivacyRow(
                        title: "Health Data",
                        description: "Your health data is stored locally and never shared",
                        icon: "heart.text.square",
                        status: .secure
                    )
                    
                    Divider()
                    
                    PrivacyRow(
                        title: "AI Conversations",
                        description: "Chat history is encrypted and stored on device",
                        icon: "bubble.left.and.bubble.right",
                        status: .secure
                    )
                    
                    Divider()
                    
                    PrivacyRow(
                        title: "API Keys",
                        description: "Stored securely in device keychain",
                        icon: "key.fill",
                        status: .secure
                    )
                    
                    Divider()
                    
                    PrivacyRow(
                        title: "Location Data",
                        description: "Not collected or used",
                        icon: "location.slash",
                        status: .notCollected
                    )
                }
            }
        }
    }
    
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Analytics & Improvements", icon: "chart.bar.xaxis")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    Toggle(isOn: $viewModel.analyticsEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text("Share Analytics")
                                    .font(.headline)
                                Text("Help improve AirFit by sharing anonymous usage data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.tint)
                        }
                    }
                    .onChange(of: viewModel.analyticsEnabled) { _, newValue in
                        Task {
                            try await viewModel.updateAnalytics(newValue)
                        }
                    }
                    
                    if viewModel.analyticsEnabled {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Label("What we collect:", systemImage: "info.circle")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text("• App crashes and errors")
                                Text("• Feature usage statistics")
                                Text("• Performance metrics")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            
                            Label("What we don't collect:", systemImage: "xmark.circle")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.top, AppSpacing.xSmall)
                            
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text("• Personal health data")
                                Text("• AI conversation content")
                                Text("• Location information")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Legal", icon: "doc.text")
            
            Card {
                VStack(spacing: 0) {
                    Button(action: { showPrivacyPolicy = true }) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, AppSpacing.small)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                    
                    Button(action: { showTermsOfService = true }) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, AppSpacing.small)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct PrivacyRow: View {
    let title: String
    let description: String
    let icon: String
    let status: PrivacyStatus
    
    enum PrivacyStatus {
        case secure
        case notCollected
        
        var color: Color {
            switch self {
            case .secure: return .green
            case .notCollected: return .blue
            }
        }
        
        var statusIcon: String {
            switch self {
            case .secure: return "lock.fill"
            case .notCollected: return "xmark.shield"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(.subheadline.bold())
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: status.statusIcon)
                .font(.caption)
                .foregroundStyle(status.color)
        }
    }
}

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

import SafariServices