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
}

/// WebSocketエラーレスポンス
struct WebSocketErrorResponse: Codable {
    let type: String
    let error: String
    let sessionId: String?
}
