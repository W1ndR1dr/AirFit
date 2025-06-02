import SwiftUI

struct ConversationView: View {
    @State var viewModel: ConversationViewModel
    @State private var animateContent = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ConversationProgress(
                    completionPercentage: viewModel.completionPercentage,
                    currentNodeType: viewModel.currentNodeType
                )
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Question section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(viewModel.currentQuestion)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                            
                            // Clarifications if any
                            if !viewModel.currentClarifications.isEmpty {
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
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Input area
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
                        
                        // Skip option if available
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
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.currentNode) { _, _ in
            // Animate content change
            animateContent = false
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                withAnimation(.spring(duration: 0.6)) {
                    animateContent = true
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    @State private var rotation: Double = 0
    
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