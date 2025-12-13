//
//  ConversationMessage.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// 会話メッセージ（WebSocket送信用）
public struct ConversationMessage: Codable {
    let userId: String
    let text: String
    let timestamp: Int64
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case text
        case timestamp
    }
    
    /// UIntのuserIdとDateからConversationMessageを作成
    init(userId: UInt, text: String, timestamp: Date) {
        self.userId = String(userId)
        self.text = text
        self.timestamp = Int64(timestamp.timeIntervalSince1970 * 1000) // ミリ秒に変換
    }
    
    /// 直接値を指定するイニシャライザ
    init(userId: String, text: String, timestamp: Int64) {
        self.userId = userId
        self.text = text
        self.timestamp = timestamp
    }
}
