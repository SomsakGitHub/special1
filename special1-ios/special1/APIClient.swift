//
//  APIClient.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case http(Int, String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server."
        case .http(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decoding(let detail):
            return "Failed to decode response: \(detail)"
        }
    }
}

struct APIClient {
    var baseURL: URL

    init(baseURL: URL = APIClient.defaultBaseURL) {
        self.baseURL = baseURL
    }

    static var defaultBaseURL: URL {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !configured.isEmpty,
           let url = URL(string: configured) {
            return url
        }
        return URL(string: "https://special1-api.js6ctz7gtj.workers.dev")!
    }

    func matches(finished: Bool? = nil, upcoming: Bool? = nil) async throws -> [Match] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/matches"), resolvingAgainstBaseURL: false)
        if let finished {
            components?.queryItems?.append(URLQueryItem(name: "finished", value: String(finished)))
        }
        if let upcoming {
            components?.queryItems?.append(URLQueryItem(name: "upcoming", value: String(upcoming)))
        }
        guard let url = components?.url else { throw APIError.invalidResponse }

        let (data, _) = try await send(url)
        struct Wrapper: Decodable { let matches: [Match] }
        return try decode(Wrapper.self, from: data).matches
    }

    func teams() async throws -> [Team] {
        let url = baseURL.appendingPathComponent("api/teams")
        let (data, _) = try await send(url)
        struct Wrapper: Decodable { let teams: [Team] }
        return try decode(Wrapper.self, from: data).teams
    }

    func standings() async throws -> [Standings] {
        let url = baseURL.appendingPathComponent("api/standings")
        let (data, _) = try await send(url)
        struct Wrapper: Decodable { let standings: [Standings] }
        return try decode(Wrapper.self, from: data).standings
    }

    private func send(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if !(200..<300).contains(http.statusCode) {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "Unknown error"
            throw APIError.http(http.statusCode, message)
        }
        return (data, http)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decoding("\(error)")
        }
    }

    private struct ErrorBody: Decodable { let error: String }
}