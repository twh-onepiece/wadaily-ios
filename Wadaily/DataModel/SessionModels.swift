//
//  SessionModels.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// セッション作成リクエスト
struct CreateSessionRequest: Codable {
    let speaker: UserProfile
    let listener: UserProfile
}

/// セッション作成レスポンス
struct CreateSessionResponse: Codable {
    let sessionId: String
    let status: String
    let commonInterests: [String]
    let initialSuggestions: [TopicSuggestion]
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case status
        case commonInterests = "common_interests"
        case initialSuggestions = "initial_suggestions"
    }
}
