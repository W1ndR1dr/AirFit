import Foundation

public enum Validators {
    // MARK: - Nested Types
    
    // MARK: - Result Type
    enum ValidationResult: Equatable {
        case success
        case failure(String)

        var isValid: Bool {
            switch self {
            case .success: return true
            case .failure: return false
            }
        }

        var errorMessage: String? {
            switch self {
            case .success: return nil
            case .failure(let message): return message
            }
        }
    }
    
    // MARK: - Static Methods
    
    // MARK: - User Input
    static func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isBlank else {
            return .failure("Email is required")
        }
        guard email.isValidEmail else {
            return .failure("Please enter a valid email address")
        }
        return .success
    }

    static func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isBlank else {
            return .failure("Password is required")
        }
        guard password.count >= AppConstants.Validation.minPasswordLength else {
            return .failure("Password must be at least \(AppConstants.Validation.minPasswordLength) characters")
        }
        guard password.count <= AppConstants.Validation.maxPasswordLength else {
            return .failure("Password must be less than \(AppConstants.Validation.maxPasswordLength) characters")
        }
        return .success
    }

    static func validateAge(_ age: Int) -> ValidationResult {
        guard age >= AppConstants.Validation.minAge else {
            return .failure("You must be at least \(AppConstants.Validation.minAge) years old")
        }
        guard age <= AppConstants.Validation.maxAge else {
            return .failure("Please enter a valid age")
        }
        return .success
    }

    static func validateWeight(_ weight: Double) -> ValidationResult {
        guard weight >= AppConstants.Validation.minWeight else {
            return .failure("Please enter a valid weight")
        }
        guard weight <= AppConstants.Validation.maxWeight else {
            return .failure("Please enter a valid weight")
        }
        return .success
    }

    static func validateHeight(_ height: Double) -> ValidationResult {
        guard height >= AppConstants.Validation.minHeight else {
            return .failure("Please enter a valid height")
        }
        guard height <= AppConstants.Validation.maxHeight else {
            return .failure("Please enter a valid height")
        }
        return .success
    }
}
