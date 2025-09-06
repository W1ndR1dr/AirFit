import SwiftUI

/// View for collecting essential profile data during onboarding
struct ProfileSetupView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var birthDate = Date()
    @State private var biologicalSex: String = ""
    @State private var showingDatePicker = false

    let onComplete: (Date, String) -> Void
    let onSkip: () -> Void

    private let maxDate = Date() // Can't be born in the future
    private let minDate = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    VStack(spacing: AppSpacing.md) {
                        CascadeText("Complete Your Profile")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text("This helps us calculate accurate nutrition targets")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.xl)
                    .padding(.horizontal, AppSpacing.lg)

                    // Birth Date Section
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Text("Birth Date")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.xs)

                        GlassCard {
                            Button {
                                showingDatePicker.toggle()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Date of Birth")
                                            .font(.system(size: 17, design: .rounded))
                                            .foregroundStyle(.primary)
                                        Text("Required for accurate BMR calculation")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(birthDate, style: .date)
                                        .font(.system(size: 17, design: .rounded))
                                        .foregroundStyle(.secondary)

                                    Image(systemName: "calendar")
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: gradientManager.active.colors(for: colorScheme),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .padding(AppSpacing.md)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Biological Sex Section
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Text("Biological Sex")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.xs)

                        HStack(spacing: AppSpacing.md) {
                            sexButton(label: "Male", value: "male", icon: "figure.stand")
                            sexButton(label: "Female", value: "female", icon: "figure.stand.dress")
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Info Card
                    GlassCard {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Why we need this")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                Text("Your age and biological sex affect your basal metabolic rate (BMR), which determines your daily calorie needs.")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: AppSpacing.xl)
                }
            }

            // Bottom Actions
            VStack(spacing: AppSpacing.md) {
                Button {
                    if !biologicalSex.isEmpty {
                        onComplete(birthDate, biologicalSex)
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(biologicalSex.isEmpty ? .secondary : Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            biologicalSex.isEmpty ? Color.white.opacity(0.2) : Color.white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(biologicalSex.isEmpty)

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Birth Date",
                    selection: $birthDate,
                    in: minDate...maxDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .navigationTitle("Select Birth Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func sexButton(label: String, value: String, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                biologicalSex = value
            }
        } label: {
            GlassCard {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(
                            biologicalSex == value ?
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : LinearGradient(colors: [.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )

                    Text(label)
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(biologicalSex == value ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            biologicalSex == value ?
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ProfileSetupView(
        onComplete: { date, sex in
            AppLogger.debug("Profile setup completed - Date: \(date), Sex: \(sex)", category: .onboarding)
        },
        onSkip: {
            AppLogger.debug("Profile setup skipped", category: .onboarding)
        }
    )
    .environmentObject(GradientManager())
}
