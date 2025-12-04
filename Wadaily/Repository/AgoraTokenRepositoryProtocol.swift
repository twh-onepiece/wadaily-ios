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
    private let baseURL = "YOUR_API_BASE_URL" // APIのベースURLを設定してください
    
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
        // APIのレスポンス形式に応じて調整してください
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["token"] as? String {
            return token
        }
        
        throw URLError(.cannotParseResponse)
    }
}
