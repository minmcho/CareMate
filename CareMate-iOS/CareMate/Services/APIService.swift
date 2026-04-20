import Foundation
import Combine

enum APIError: LocalizedError {
    case badURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL:               return "Invalid URL"
        case .networkError(let e):  return e.localizedDescription
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .serverError(let c, let m): return "Server error \(c): \(m)"
        case .unknown:              return "Unknown error"
        }
    }
}

class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        baseURL = APIConfig.baseURL
        session = URLSession.shared
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Generic request

    func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.badURL }
        let (data, response) = try await session.data(from: url)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: req)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    func patch<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: req)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    func delete(_ path: String) async throws {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: req)
        try validate(response)
    }

    // MARK: - Helpers

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode, HTTPURLResponse.localizedString(forStatusCode: http.statusCode))
        }
    }
}

// MARK: - Config

enum APIConfig {
    static let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8080"
}
