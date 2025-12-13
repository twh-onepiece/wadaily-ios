//
//  AgoraTokenRepositoryProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/04.
//

import Foundation

// MARK: - Agora Token Repository Protocol
protocol AgoraTokenRepositoryProtocol {
    func getToken(
        channelName: String,
        uid: UInt,
        role: String,
        tokenExpirationInSeconds: Int?,
        privilegeExpirationInSeconds: Int?
    ) async throws -> String
}

// MARK: - Agora Token Repository
class AgoraTokenRepository: AgoraTokenRepositoryProtocol {
    private let baseURL: String
    
    init() {
        self.baseURL = "https://wadaily-backend-1011560404154.asia-northeast1.run.app"
    }
    
    func getToken(
        channelName: String,
        uid: UInt,
        role: String = "publisher",
        tokenExpirationInSeconds: Int? = nil,
        privilegeExpirationInSeconds: Int? = nil
    ) async throws -> String {
        var components = URLComponents(string: "\(baseURL)/agora/token")!
        
        var queryItems = [
            URLQueryItem(name: "channel_name", value: channelName),
            URLQueryItem(name: "uid", value: String(uid)),
            URLQueryItem(name: "role", value: role)
        ]
        
        if let tokenExpiration = tokenExpirationInSeconds {
            queryItems.append(URLQueryItem(name: "token_expiration_in_seconds", value: String(tokenExpiration)))
        }
        
        if let privilegeExpiration = privilegeExpirationInSeconds {
            queryItems.append(URLQueryItem(name: "privilege_expiration_in_seconds", value: String(privilegeExpiration)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // レスポンスからトークンを取得
        struct TokenResponse: Codable {
            let token: String
            let channelName: String
            let uid: Int
            let role: String
            let expiresIn: Int
            
            enum CodingKeys: String, CodingKey {
                case token
                case channelName = "channel_name"
                case uid
                case role
                case expiresIn = "expires_in"
            }
        }
        
        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
        return tokenResponse.token
    }
}
