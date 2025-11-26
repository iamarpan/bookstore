import Foundation

/// Environment configuration for API endpoints
enum APIEnvironment: String {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:3000/api/v1"
        case .staging:
            return "https://staging-api.bookshare.com/api/v1"
        case .production:
            return "https://api.bookshare.com/api/v1"
        }
    }
    
    var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }
}

/// Configuration manager for API settings
class APIConfiguration {
    static let shared = APIConfiguration()
    
    // Current environment - change this or make it configurable
    var currentEnvironment: APIEnvironment = .development
    
    var baseURL: String {
        currentEnvironment.baseURL
    }
    
    // Timeouts
    let requestTimeout: TimeInterval = 30
    let resourceTimeout: TimeInterval = 60
    
    // Retry configuration
    let maxRetries: Int = 3
    let retryDelay: TimeInterval = 1.0
    
    private init() {}
}
