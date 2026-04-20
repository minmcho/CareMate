//
//  GraphQLClient.swift
//  Minimal GraphQL-over-HTTP client with retry + circuit breaker.
//

import Foundation

enum GraphQLError: Error {
    case transport(Error)
    case serverError(statusCode: Int)
    case decoding(Error)
    case unauthenticated
    case circuitOpen
}

actor CircuitBreaker {
    enum State { case closed, open, halfOpen }

    private(set) var state: State = .closed
    private var failures = 0
    private let threshold = 5
    private let openDuration: TimeInterval = 20
    private var openedAt: Date?

    func allow() -> Bool {
        if state == .open, let openedAt {
            if Date().timeIntervalSince(openedAt) > openDuration {
                state = .halfOpen
                return true
            }
            return false
        }
        return true
    }

    func recordSuccess() {
        state = .closed
        failures = 0
        openedAt = nil
    }

    func recordFailure() {
        failures += 1
        if failures >= threshold || state == .halfOpen {
            state = .open
            openedAt = Date()
        }
    }
}

final class GraphQLClient {
    let endpoint: URL
    let session: URLSession
    let breaker = CircuitBreaker()

    init(endpoint: URL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func perform<T: Decodable>(
        query: String,
        variables: [String: Any] = [:],
        token: String?
    ) async throws -> T {
        guard await breaker.allow() else { throw GraphQLError.circuitOpen }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = ["query": query, "variables": variables]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let delays: [UInt64] = [0, 1_000_000_000, 2_000_000_000, 4_000_000_000]
        var lastError: Error?

        for delay in delays {
            if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    lastError = GraphQLError.serverError(statusCode: -1)
                    continue
                }
                switch http.statusCode {
                case 200..<300:
                    await breaker.recordSuccess()
                    do {
                        let envelope = try JSONDecoder().decode(Envelope<T>.self, from: data)
                        if let data = envelope.data { return data }
                        throw GraphQLError.serverError(statusCode: http.statusCode)
                    } catch {
                        throw GraphQLError.decoding(error)
                    }
                case 401:
                    throw GraphQLError.unauthenticated
                default:
                    lastError = GraphQLError.serverError(statusCode: http.statusCode)
                }
            } catch {
                lastError = GraphQLError.transport(error)
            }
        }

        await breaker.recordFailure()
        throw lastError ?? GraphQLError.serverError(statusCode: -1)
    }

    private struct Envelope<T: Decodable>: Decodable {
        let data: T?
    }
}
