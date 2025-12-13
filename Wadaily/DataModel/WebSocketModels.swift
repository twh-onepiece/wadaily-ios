//
//  WebSocketModels.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// WebSocket送信リクエスト
struct WebSocketConversationsRequest: Codable {
    let conversations: [ConversationMessage]
}

/// WebSocketレスポンス
struct WebSocketTopicResponse: Codable {
    let status: String
    let currentTopic: String
    let suggestions: [TopicSuggestion]
    
    enum CodingKeys: String, CodingKey {
        case status
        case currentTopic = "current_topic"
        case suggestions
    }
}

/// WebSocketエラーレスポンス
struct WebSocketErrorResponse: Codable {
    let type: String
    let error: String
    let sessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case type, error
        case sessionId = "session_id"
    }
}
