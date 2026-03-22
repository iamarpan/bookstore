import Foundation

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case noData
    case tokenExpired
    case unknown
    case badRequest(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error (\(code))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received from server"
        case .tokenExpired:
            return "Session expired. Please log in again."
        case .badRequest(let message):
            return message
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Error Response from Backend
struct ErrorResponse: Codable {
    let error: String
    let message: String
    let fields: [String: String]?
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

// MARK: - Token Refresh Serialiser
// Ensures that when multiple concurrent requests get a 401 at the same time,
// only ONE refresh call is made to the server. All other callers wait for the
// in-flight refresh to finish and then reuse the new token already in Keychain.
private actor TokenRefreshActor {
    private var refreshTask: Task<Void, Error>?

    func refresh(using block: @escaping () async throws -> Void) async throws {
        // If a refresh is already in-flight, wait for it instead of firing a second one.
        if let existing = refreshTask {
            try await existing.value
            return
        }
        let task = Task { try await block() }
        refreshTask = task
        defer { refreshTask = nil }
        try await task.value
    }
}

// MARK: - API Client
class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let config: APIConfiguration
    private let keychainManager: KeychainManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let refreshActor = TokenRefreshActor()
    
    // MARK: - Shared Date Formatters (static to avoid per-call allocation)
    private static let isoWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoStandard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.shared.requestTimeout
        configuration.timeoutIntervalForResource = APIConfiguration.shared.resourceTimeout

        // Enable URLCache for image/asset responses (64 MB memory, 512 MB disk)
        let cache = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 512 * 1024 * 1024)
        configuration.urlCache = cache
        configuration.requestCachePolicy = .useProtocolCachePolicy

        self.session = URLSession(configuration: configuration)
        self.config = APIConfiguration.shared
        self.keychainManager = KeychainManager.shared

        // Configure JSON decoder — reuse static formatters instead of creating one per Date field
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = APIClient.isoWithFractional.date(from: dateString) { return date }
            if let date = APIClient.isoStandard.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        decoder.keyDecodingStrategy = .useDefaultKeys

        // Configure JSON encoder
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .useDefaultKeys
    }
    
    // MARK: - Public HTTP Methods
    
    /// Perform GET request
    func get<T: Decodable>(
        _ endpoint: String,
        queryParams: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .GET,
            queryParams: queryParams,
            body: EmptyBody?.none,
            requiresAuth: requiresAuth
        )
    }
    
    /// Perform POST request
    func post<T: Decodable, B: Encodable>(
        _ endpoint: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    /// Perform POST request without response body
    func post<B: Encodable>(
        _ endpoint: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws {
        let _: EmptyResponse = try await request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    /// Perform PUT request
    func put<T: Decodable, B: Encodable>(
        _ endpoint: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .PUT,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    /// Perform PUT request without response body
    func put<B: Encodable>(
        _ endpoint: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws {
        let _: EmptyResponse = try await request(
            endpoint: endpoint,
            method: .PUT,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    /// Perform DELETE request
    func delete<T: Decodable>(
        _ endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .DELETE,
            body: EmptyBody?.none,
            requiresAuth: requiresAuth
        )
    }
    
    /// Perform DELETE request without response body
    func delete(
        _ endpoint: String,
        requiresAuth: Bool = true
    ) async throws {
        let _: EmptyResponse = try await request(
            endpoint: endpoint,
            method: .DELETE,
            body: EmptyBody?.none,
            requiresAuth: requiresAuth
        )
    }
    
    // MARK: - Core Request Method
    
    private func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        queryParams: [String: Any]? = nil,
        body: B? = nil,
        requiresAuth: Bool,
        retryCount: Int = 0
    ) async throws -> T {
        
        // Build URL
        guard var urlComponents = URLComponents(string: config.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        // Add query parameters
        if let queryParams = queryParams {
            urlComponents.queryItems = queryParams.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authorization header
        if requiresAuth {
            if let token = keychainManager.getAccessToken() {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.unauthorized
            }
        }
        
        // Add body
        if let body = body {
            urlRequest.httpBody = try encoder.encode(body)
        }
        
        // Log request
        logRequest(urlRequest, body: body)
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            // Log response
            logResponse(response, data: data)
            
            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
                
                guard !data.isEmpty else {
                    throw APIError.noData
                }
                
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
                
            case 400:
                // Bad Request - try to decode error message
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.badRequest(errorResponse.message)
                }
                throw APIError.badRequest("Bad Request")
                
            case 401:
                // Unauthorized - try to refresh token
                // Uses TokenRefreshActor to ensure only ONE refresh fires even if
                // multiple requests get 401 concurrently (race condition fix).
                if retryCount < 1 {
                    do {
                        try await refreshActor.refresh {
                            try await self.refreshAccessToken()
                        }
                        // Retry the request with the newly saved token
                        return try await request(
                            endpoint: endpoint,
                            method: method,
                            queryParams: queryParams,
                            body: body,
                            requiresAuth: requiresAuth,
                            retryCount: retryCount + 1
                        )
                    } catch {
                        throw APIError.unauthorized
                    }
                } else {
                    throw APIError.unauthorized
                }
                
            case 403:
                throw APIError.forbidden
                
            case 404:
                throw APIError.notFound
                
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
                
            default:
                // Try to decode error response
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    print("❌ API Error: \(errorResponse.message)")
                }
                throw APIError.unknown
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Token Management
    
    /// Posted when the refresh token is rejected by the server (secret mismatch / expired / revoked).
    /// Observers should log the user out immediately.
    static let sessionExpiredNotification = Notification.Name("APIClientSessionExpired")
    
    /// Refresh access token using refresh token.
    /// Uses a raw URLSession call to avoid going through `request()`,
    /// which would recursively call this method again on a 401 response.
    private func refreshAccessToken() async throws {
        guard let refreshToken = keychainManager.getRefreshToken() else {
            throw APIError.unauthorized
        }

        struct RefreshRequest: Codable {
            let refreshToken: String
        }

        struct RefreshResponse: Codable {
            let accessToken: String
            let refreshToken: String
        }

        guard let url = URL(string: config.baseURL + "/auth/refresh") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try encoder.encode(RefreshRequest(refreshToken: refreshToken))

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                keychainManager.clearTokens()
                notifySessionExpired()
                throw APIError.tokenExpired
            }

            guard httpResponse.statusCode == 200 else {
                // Non-200 means the refresh token is invalid/expired/wrong secret — force re-login
                keychainManager.clearTokens()
                notifySessionExpired()
                throw APIError.tokenExpired
            }

            let refreshResponse = try decoder.decode(RefreshResponse.self, from: data)
            _ = keychainManager.saveAccessToken(refreshResponse.accessToken)
            _ = keychainManager.saveRefreshToken(refreshResponse.refreshToken)

            print("✅ Access token refreshed successfully")
        } catch let error as APIError {
            throw error
        } catch {
            keychainManager.clearTokens()
            notifySessionExpired()
            throw APIError.tokenExpired
        }
    }
    
    private func notifySessionExpired() {
        print("⚠️ Session expired — broadcasting sessionExpired notification")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: APIClient.sessionExpiredNotification, object: nil)
        }
    }
    
    /// Save authentication tokens
    func saveTokens(accessToken: String, refreshToken: String) {
        _ = keychainManager.saveAccessToken(accessToken)
        _ = keychainManager.saveRefreshToken(refreshToken)
    }
    
    /// Clear authentication tokens (logout)
    func clearTokens() {
        keychainManager.clearTokens()
    }
    
    /// Check if user is authenticated
    func isAuthenticated() -> Bool {
        return keychainManager.getAccessToken() != nil
    }
    
    // MARK: - Logging
    
    private func logRequest<B: Encodable>(_ request: URLRequest, body: B?) {
        #if DEBUG
        guard config.loggingEnabled else { return }

        let method = request.httpMethod ?? "UNKNOWN"
        let urlString = request.url?.absoluteString ?? "UNKNOWN"
        let headers = request.allHTTPHeaderFields

        // Move heavy JSON pretty-printing off the main thread
        Task.detached(priority: .background) { [body] in
            print("📤 API Request")
            print("   Method: \(method)")
            print("   URL: \(urlString)")
            if let headers { print("   Headers: \(headers)") }
            if let body,
               let data = try? JSONEncoder().encode(body),
               let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("   Body: \(prettyString)")
            }
        }
        #endif
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        #if DEBUG
        guard config.loggingEnabled else { return }
        guard let httpResponse = response as? HTTPURLResponse else { return }

        let statusEmoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
        let statusCode = httpResponse.statusCode
        let urlString = httpResponse.url?.absoluteString ?? "UNKNOWN"

        // Move heavy JSON pretty-printing off the main thread
        Task.detached(priority: .background) {
            print("\(statusEmoji) API Response")
            print("   Status: \(statusCode)")
            print("   URL: \(urlString)")
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("   Body: \(prettyString)")
            }
        }
        #endif
    }
}

// MARK: - Helper Types

/// Empty response for requests that don't return data
private struct EmptyResponse: Codable {}

/// Empty body for requests that don't send data (GET, DELETE)
private struct EmptyBody: Codable {}
