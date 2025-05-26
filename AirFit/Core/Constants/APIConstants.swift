import Foundation

enum APIConstants {
    // MARK: - Base URLs
    static let baseURL = "https://api.airfit.com/v1"
    static let authBaseURL = "https://auth.airfit.com/v1"
    
    // MARK: - API Versions
    static let apiVersion = "v1"
    static let minimumSupportedVersion = "1.0.0"
    
    // MARK: - Headers
    enum Headers {
        static let authorization = "Authorization"
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let userAgent = "User-Agent"
        static let apiKey = "X-API-Key"
        static let sessionToken = "X-Session-Token"
    }
    
    // MARK: - Content Types
    enum ContentType {
        static let json = "application/json"
        static let formData = "multipart/form-data"
        static let urlEncoded = "application/x-www-form-urlencoded"
    }
    
    // MARK: - Endpoints
    enum Endpoints {
        // Auth
        static let login = "/auth/login"
        static let logout = "/auth/logout"
        static let refreshToken = "/auth/refresh"
        static let register = "/auth/register"
        
        // User
        static let profile = "/user/profile"
        static let updateProfile = "/user/profile/update"
        static let deleteAccount = "/user/delete"
        
        // Meals
        static let meals = "/meals"
        static let mealDetail = "/meals/%@"
        static let logMeal = "/meals/log"
        static let searchFood = "/food/search"
        
        // Workouts
        static let workouts = "/workouts"
        static let workoutDetail = "/workouts/%@"
        static let logWorkout = "/workouts/log"
        
        // Progress
        static let progress = "/progress"
        static let progressChart = "/progress/chart"
        
        // AI Coach
        static let aiChat = "/ai/chat"
        static let aiRecommendations = "/ai/recommendations"
        static let aiMealPlan = "/ai/meal-plan"
    }
    
    // MARK: - Pagination
    enum Pagination {
        static let defaultPageSize = 20
        static let maxPageSize = 100
    }
    
    // MARK: - Cache
    enum Cache {
        static let defaultExpiration: TimeInterval = 300 // 5 minutes
        static let longExpiration: TimeInterval = 3600 // 1 hour
        static let userProfileExpiration: TimeInterval = 86400 // 24 hours
    }
} 