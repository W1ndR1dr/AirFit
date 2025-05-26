import Foundation

extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func truncated(to length: Int, addEllipsis: Bool = true) -> String {
        if self.count > length {
            let endIndex = self.index(self.startIndex, offsetBy: length)
            let truncated = self[..<endIndex]
            return addEllipsis ? "\(truncated)..." : String(truncated)
        }
        return self
    }
    
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 
