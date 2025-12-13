//
//  TopicService.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

// MARK: - TopicWebSocketService Implementation

class TopicWebSocketService: TopicWebSocketServiceProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private var sessionId: String?
    private var callback: TopicReceivedCallback?
    private let baseURL: String
    private let sessionURL: String
    
    // ユーザープロファイル
    private var meProfile: UserProfile?
    private var partnerProfile: UserProfile?
    
    init(baseURL: String = "https://app-253151b9-60c4-47f1-b33f-7c028738cde8.ingress.apprun.sakura.ne.jp") {
        self.baseURL = baseURL
        self.sessionURL = "\(baseURL)/sessions"
    }
    
    /// ユーザープロファイルを設定
    func setUserProfiles(me: UserProfile, partner: UserProfile) {
        self.meProfile = me
        self.partnerProfile = partner
    }
    
    // MARK: - Public Methods
    func startSession(callback: @escaping TopicReceivedCallback) async throws {
        self.callback = callback
        
        // まずHTTP APIでセッションを作成
        let sessionId = try await createSession()
        self.sessionId = sessionId
        
        // WebSocket接続を確立
        try await connectWebSocket(sessionId: sessionId)
        
        // メッセージ受信を開始
        await startReceiving()
    }
    
    func pushMessages(_ messages: [ConversationMessage]) async throws {
        guard webSocketTask != nil else {
            throw TopicServiceError.notConnected
        }
        
        let request = WebSocketConversationsRequest(conversations: messages)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        
        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask?.send(message)
        
        print("📤 Sent \(messages.count) messages to server")
    }
    
    func endSession() async {
        // WebSocket接続を切断
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        // セッション削除（オプション）
        if let sessionId = sessionId {
            await deleteSession(sessionId: sessionId)
        }
        
        sessionId = nil
        callback = nil
        print("🔌 WebSocket session ended")
    }
    
    // MARK: - Private Methods
    
    /// HTTP APIでセッションを作成
    private func createSession() async throws -> String {
        // プロファイルが設定されているか確認
        guard let meProfile = meProfile, let partnerProfile = partnerProfile else {
            throw TopicServiceError.profilesNotSet
        }
        
        let request = CreateSessionRequest(speaker: meProfile, listener: partnerProfile)
        
        guard let url = URL(string: sessionURL) else {
            throw TopicServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TopicServiceError.sessionCreationFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let sessionResponse = try decoder.decode(CreateSessionResponse.self, from: data)
        
        print("✅ Session created: \(sessionResponse.sessionId)")
        
        // 初期提案をコールバック
        let initialTopics = sessionResponse.initialSuggestions.map { $0.text }
        callback?(initialTopics)
        
        return sessionResponse.sessionId
    }
    
    /// WebSocket接続を確立
    private func connectWebSocket(sessionId: String) async throws {
        // HTTPSのURLをwssに変換
        let wsBaseURL = baseURL.replacingOccurrences(of: "https://", with: "wss://")
                                .replacingOccurrences(of: "http://", with: "ws://")
        
        guard let url = URL(string: "\(wsBaseURL)/sessions/\(sessionId)/topics") else {
            throw TopicServiceError.invalidURL
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        print("🔌 WebSocket connected to \(url)")
    }
    
    /// メッセージ受信を開始
    private func startReceiving() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let message = try await webSocketTask.receive()
            
            switch message {
            case .data(let data):
                handleReceivedData(data)
            case .string(let string):
                if let data = string.data(using: .utf8) {
                    handleReceivedData(data)
                }
            @unknown default:
                print("⚠️ Unknown message type received")
            }
            
            // 次のメッセージを受信するために再帰呼び出し
            await startReceiving()
            
        } catch {
            print("❌ WebSocket receive error: \(error)")
            // エラーが発生した場合は接続を終了
            await endSession()
        }
    }
    
    /// 受信データを処理
    private func handleReceivedData(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // まずエラーレスポンスかチェック
        if let errorResponse = try? decoder.decode(WebSocketErrorResponse.self, from: data) {
            print("❌ Server error: \(errorResponse.error)")
            return
        }
        
        // 通常のレスポンスをデコード
        if let response = try? decoder.decode(WebSocketTopicResponse.self, from: data) {
            let topics = response.suggestions.map { $0.text }
            print("📥 Received \(topics.count) topics: \(topics)")
            callback?(topics)
        } else {
            print("⚠️ Failed to decode response")
        }
    }
    
    /// セッション削除（オプション）
    private func deleteSession(sessionId: String) async {
        guard let url = URL(string: "\(sessionURL)/\(sessionId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("✅ Session deleted: \(sessionId)")
            }
        } catch {
            print("⚠️ Failed to delete session: \(error)")
        }
    }
}

// MARK: - Error Types

enum TopicServiceError: Error {
    case invalidURL
    case notConnected
    case sessionCreationFailed
    case decodingFailed
    case profilesNotSet
}
