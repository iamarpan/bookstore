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
            return "https://api-book-club.zenith-techsphere.com/api/v1"
        case .production:
            return "https://api-book-club.zenith-techsphere.com/api/v1"
        }
    }
    
    var socketURL: String {
        switch self {
        case .development:
            return "ws://localhost:3001"
        case .staging:
            return "wss://socket.api-book-club.zenith-techsphere.com"
        case .production:
            return "wss://socket.api-book-club.zenith-techsphere.com"
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
    
    // Current environment - automatically determined based on build configuration
    var currentEnvironment: APIEnvironment = {
        #if DEBUG
        // In debug builds, you can change this to .development or .staging for testing
        return .production
        #else
        // In release builds, always use production
        return .production
        #endif
    }()
    
    var baseURL: String {
        currentEnvironment.baseURL
    }
    
    var socketURL: String {
        currentEnvironment.socketURL
    }
    
    // Timeouts
    // Note: Vercel serverless functions may have cold starts (2-3 seconds)
    // Increased timeout to handle this gracefully
    let requestTimeout: TimeInterval = 30
    let resourceTimeout: TimeInterval = 60
    
    // Retry configuration
    let maxRetries: Int = 3
    let retryDelay: TimeInterval = 1.0
    
    // Enable logging only in debug builds
    var loggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    private init() {}
}
