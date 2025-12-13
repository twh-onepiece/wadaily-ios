//
//  TopicServiceProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

// 話題を受け取るコールバック
typealias TopicReceivedCallback = ([String]) -> Void

protocol TopicWebSocketServiceProtocol {
    /// WebSocketセッションを開始
    func startSession(callback: @escaping TopicReceivedCallback) async throws
    
    /// 会話メッセージをサーバーにプッシュ
    func pushMessages(_ messages: [ConversationMessage]) async throws
    
    /// WebSocketセッションを終了
    func endSession() async
    
    /// ユーザプロフィール(SNSデータなど)をセット
    func setUserProfiles(me: UserProfile, partner: UserProfile)
}

// MARK: - Mock Implementation

class MockTopicWebSocketService: TopicWebSocketServiceProtocol {
    func setUserProfiles(me: UserProfile, partner: UserProfile) {
        // Mock implementation - プロファイルを保存
        print("🔧 Mock: Set profiles for \(me.userId) and \(partner.userId)")
    }
    
    private var callback: TopicReceivedCallback?
    
    func startSession(callback: @escaping TopicReceivedCallback) async throws {
        self.callback = callback
        print("🔌 Mock WebSocket session started")
    }
    
    func pushMessages(_ messages: [ConversationMessage]) async throws {
        print("📤 Mock: Pushing \(messages.count) messages to server")
        
        // モックレスポンス: 3つの話題を生成
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        let mockTopics = [
            "最近観た映画について",
            "好きな食べ物の話",
            "週末の予定は?"
        ]
        callback?(mockTopics)
    }
    
    func endSession() async {
        callback = nil
        print("🔌 Mock WebSocket session ended")
    }
}
