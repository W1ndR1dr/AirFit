import SwiftUI

struct ConversationView: View {
    @State var viewModel: ConversationViewModel
    @State private var animateContent = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        BaseScreen {
            NavigationStack {
                VStack(spacing: 0) {
                    progressView
                    mainContentView
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    toolbarContent
                }
            }
        }
        .overlay(processingOverlay)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateContent = true
            }
        }
        .task {
            await viewModel.start()
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        ConversationProgress(
            completionPercentage: viewModel.completionPercentage,
            currentNodeType: viewModel.currentNodeType
        )
        .background(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                questionSection
                inputSection
                skipButton
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    @ViewBuilder
    private var questionSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if animateContent {
                    CascadeText(viewModel.currentQuestion)
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if !viewModel.currentClarifications.isEmpty {
                    clarificationsView
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, AppSpacing.md)
    }
    
    @ViewBuilder
    private var clarificationsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(viewModel.currentClarifications, id: \.self) { clarification in
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    
                    Text(clarification)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.top, AppSpacing.xs)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 10)
        .animation(MotionToken.standardSpring.delay(0.1), value: animateContent)
    }
    
    @ViewBuilder
    private var inputSection: some View {
        if let inputType = viewModel.currentInputType {
            ConversationalInputView(
                inputType: inputType,
                onSubmit: { response in
                    Task {
                        await viewModel.submitResponse(response)
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(viewModel.currentNode?.id)
        }
    }
    
    @ViewBuilder
    private var skipButton: some View {
        if viewModel.showSkipOption {
            Button(action: {
                HapticService.selection()
                Task {
                    await viewModel.skipCurrentQuestion()
                }
            }) {
                Text("Skip this question")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.secondary)
            }
            .padding(.top, AppSpacing.xs)
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private var processingOverlay: some View {
        if viewModel.isLoading {
            ConversationLoadingOverlay()
        }
    }
}

// MARK: - Loading Overlay

private struct ConversationLoadingOverlay: View {
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            GlassCard {
                VStack(spacing: AppSpacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .tint(Color.primary)
                    
                    Text("Processing...")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.primary)
                }
                .padding(AppSpacing.md)
            }
            .frame(width: 150, height: 150)
        }
    }
}

// MARK: - Preview
#Preview {
    ConversationView(
        viewModel: ConversationViewModel(
            flowManager: ConversationFlowManager(
                flowDefinition: ConversationFlowData.defaultFlow(),
                modelContext: DataManager.preview.modelContext,
                responseAnalyzer: nil
            ),
            persistence: ConversationPersistence(
                modelContext: DataManager.preview.modelContext
            ),
            analytics: ConversationAnalytics(),
            userId: UUID()
        )
    )
}