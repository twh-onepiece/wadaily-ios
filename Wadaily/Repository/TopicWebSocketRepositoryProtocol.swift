//
//  TopicWebSocketRepositoryProtocol.swift
//  Wadaily
//
//  Created on 2025/12/13.
//

import Foundation

typealias TopicReceivedCallback = ([String]) -> Void

protocol TopicWebSocketRepositoryProtocol {
    /// WebSocketセッションを開始
    func startSession(callback: @escaping TopicReceivedCallback) async throws
    
    /// 会話メッセージをサーバーにプッシュ
    func pushMessages(_ messages: [ConversationMessage]) async throws
    
    /// WebSocketセッションを終了
    func endSession() async
}

// MARK: - Mock Implementation

class MockTopicWebSocketService: TopicWebSocketRepositoryProtocol {
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
