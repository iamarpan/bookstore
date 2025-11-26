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

// MARK: - API Client
class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let config: APIConfiguration
    private let keychainManager: KeychainManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // Request logging
    private var loggingEnabled = true
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.shared.requestTimeout
        configuration.timeoutIntervalForResource = APIConfiguration.shared.resourceTimeout
        
        self.session = URLSession(configuration: configuration)
        self.config = APIConfiguration.shared
        self.keychainManager = KeychainManager.shared
        
        // Configure JSON decoder for ISO8601 dates
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
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
                
            case 401:
                // Unauthorized - try to refresh token
                if retryCount < 1 {
                    do {
                        try await refreshAccessToken()
                        // Retry the request with new token
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
    
    /// Refresh access token using refresh token
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
        
        let request = RefreshRequest(refreshToken: refreshToken)
        
        do {
            let response: RefreshResponse = try await post(
                "/auth/refresh",
                body: request,
                requiresAuth: false
            )
            
            // Save new tokens
            _ = keychainManager.saveAccessToken(response.accessToken)
            _ = keychainManager.saveRefreshToken(response.refreshToken)
            
            print("✅ Access token refreshed successfully")
        } catch {
            // Clear tokens on refresh failure
            keychainManager.clearTokens()
            throw APIError.tokenExpired
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
        guard loggingEnabled else { return }
        
        print("📤 API Request")
        print("   Method: \(request.httpMethod ?? "UNKNOWN")")
        print("   URL: \(request.url?.absoluteString ?? "UNKNOWN")")
        
        if let headers = request.allHTTPHeaderFields {
            print("   Headers: \(headers)")
        }
        
        if let body = body,
           let data = try? encoder.encode(body),
           let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("   Body: \(prettyString)")
        }
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        guard loggingEnabled else { return }
        
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        let statusEmoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
        
        print("\(statusEmoji) API Response")
        print("   Status: \(httpResponse.statusCode)")
        print("   URL: \(httpResponse.url?.absoluteString ?? "UNKNOWN")")
        
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("   Body: \(prettyString)")
        }
    }
}

// MARK: - Helper Types

/// Empty response for requests that don't return data
private struct EmptyResponse: Codable {}

/// Empty body for requests that don't send data (GET, DELETE)
private struct EmptyBody: Codable {}
