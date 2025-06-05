import SwiftUI

struct ConversationView: View {
    @State var viewModel: ConversationViewModel
    @State private var animateContent = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
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
            withAnimation(.spring(duration: 0.6)) {
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
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                questionSection
                inputSection
                skipButton
            }
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    @ViewBuilder
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.currentQuestion)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            if !viewModel.currentClarifications.isEmpty {
                clarificationsView
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    @ViewBuilder
    private var clarificationsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.currentClarifications, id: \.self) { clarification in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(clarification)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(duration: 0.6).delay(0.1), value: animateContent)
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
                Task {
                    await viewModel.skipCurrentQuestion()
                }
            }) {
                Text("Skip this question")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
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
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
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