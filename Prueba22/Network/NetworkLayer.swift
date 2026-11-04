//
//  NetworkLayer.swift
//  Prueba22
//
//  Created by Victor Alejandro Perez Valdez on 04/11/26.
//

import Foundation

protocol INetworkLayer {
    func fetch<T:Decodable>(path: ApiPath) async throws -> T
}

enum ApiPath: String {
    static let apiBaseURL: String = "https://api.chucknorris.io/jokes/"
    case random
}

enum NetworkError: Error {
    case invalidURL
    case serverError
    case decodingError
}

final class NetworkLayer: INetworkLayer {
    func fetch<T: Decodable>(path: ApiPath) async throws -> T {
        
        guard let url = URL(string: ApiPath.apiBaseURL + path.rawValue) else {
            throw NetworkError.invalidURL
        }
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.serverError
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
