import SwiftUI

struct ModelContainerErrorView: View {
    let error: Error
    let isRetrying: Bool
    let onRetry: () -> Void
    let onReset: () -> Void
    let onUseInMemory: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            
            // Error icon and title
            VStack(spacing: AppSpacing.medium) {
                Image(systemName: "exclamationmark.icloud.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.errorColor)
                
                Text("Database Error")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("We couldn't load your data")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Error details
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Error Details:")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(error.localizedDescription)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.smallCornerRadius)
                            .fill(AppColors.backgroundSecondary)
                    )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Recovery options
            VStack(spacing: AppSpacing.medium) {
                Button(action: onRetry) {
                    HStack {
                        if isRetrying {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Try Again")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                }
                .disabled(isRetrying)
                
                Button(action: onReset) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset Database")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.warningColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                }
                .disabled(isRetrying)
                
                Button(action: onUseInMemory) {
                    HStack {
                        Image(systemName: "memorychip")
                        Text("Continue Without Saving")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.backgroundSecondary)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                }
                .disabled(isRetrying)
                
                Text("'Continue Without Saving' will let you use the app, but your data won't be saved when you close it.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
    }
}