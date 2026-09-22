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

    func home() async throws -> HomeInfo {
        let url = baseURL.appendingPathComponent("api/home")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if !(200..<300).contains(http.statusCode) {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "Unknown error"
            throw APIError.http(http.statusCode, message)
        }
        do {
            return try JSONDecoder().decode(HomeInfo.self, from: data)
        } catch {
            throw APIError.decoding("\(error)")
        }
    }

    private struct ErrorBody: Decodable { let error: String }
}