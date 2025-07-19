//
//  NetworkClient.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case httpError(Int)
    case networkError(Error)
    case offlineMode(localData: [Transaction])
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Нет данных"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Ошибка кодирования: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP ошибка: \(code)"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .offlineMode:
            return "Работа в офлайн режиме"
        }
    }
}

// MARK: - NetworkClient
final class NetworkClient {
    private let baseURL: String
    private let token: String
    private let session: URLSession
    
    init(baseURL: String = "https://shmr-finance.ru", token: String) {
        self.baseURL = baseURL
        self.token = token
        self.session = URLSession.shared
    }
    
    func request<U: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        responseType: U.Type
    ) async throws -> U {
        
        return try await performRequestWithoutBody(endpoint: endpoint, method: method, responseType: responseType)
    }
    
    func request<T: Encodable, U: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        
        return try await performRequestWithBody(endpoint: endpoint, method: method, body: body, responseType: responseType)
    }
    
    private func performRequestWithoutBody<U: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        responseType: U.Type
    ) async throws -> U {
        
        let fullURL = baseURL + endpoint
        print("🔗 NetworkClient: формируем URL: \(fullURL)")
        guard let url = URL(string: fullURL) else {
            print("❌ NetworkClient: неверный URL: \(fullURL)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("🔐 NetworkClient: Authorization header: Bearer \(token.prefix(10))...")
        print("📋 NetworkClient: HTTP Method: \(method.rawValue)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 NetworkClient: HTTP Status: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorJsonString = String(data: data, encoding: .utf8) {
                        print("❌ NetworkClient: Error response body: \(errorJsonString)")
                    }
                    print("📋 NetworkClient: Response headers: \(httpResponse.allHeaderFields)")
                    throw NetworkError.httpError(httpResponse.statusCode)
                } else {
                    if let successJsonString = String(data: data, encoding: .utf8) {
                        print("✅ NetworkClient: Success response body: \(successJsonString)")
                    }
                }
            }
            
            if data.isEmpty && method == .DELETE {
                if let emptyResponse = EmptyResponse() as? U {
                    return emptyResponse
                }
            }
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            return try await Task.detached(priority: .background) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(responseType, from: data)
            }.value
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    private func performRequestWithBody<T: Encodable, U: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encodedBody: Data
        do {
            encodedBody = try await Task.detached(priority: .background) {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                return try encoder.encode(body)
            }.value
            
            // Отладочная информация о теле запроса
            if let requestJsonString = String(data: encodedBody, encoding: .utf8) {
                print("📤 NetworkClient: Request body: \(requestJsonString)")
            }
        } catch {
            throw NetworkError.encodingError(error)
        }
        
        request.httpBody = encodedBody
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 NetworkClient: HTTP Status: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorJsonString = String(data: data, encoding: .utf8) {
                        print("❌ NetworkClient: Error response body: \(errorJsonString)")
                    }
                    print("📋 NetworkClient: Response headers: \(httpResponse.allHeaderFields)")
                    throw NetworkError.httpError(httpResponse.statusCode)
                } else {
                    if let successJsonString = String(data: data, encoding: .utf8) {
                        print("✅ NetworkClient: Success response body: \(successJsonString)")
                    }
                }
            }
            
            if data.isEmpty && method == .DELETE {
                if let emptyResponse = EmptyResponse() as? U {
                    return emptyResponse
                }
            }
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            return try await Task.detached(priority: .background) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(responseType, from: data)
            }.value
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}

// MARK: - Empty Response for DELETE operations
struct EmptyResponse: Codable {
    init() {}
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

