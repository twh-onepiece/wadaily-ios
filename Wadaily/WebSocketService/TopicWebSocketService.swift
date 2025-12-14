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
    private var isConnected = false
    private let baseURL: String
    private let sessionURL: String
    private let urlSession: URLSession
    
    // ユーザープロファイル
    private var meProfile: UserProfile?
    private var partnerProfile: UserProfile?
    
    init(baseURL: String = "https://app-253151b9-60c4-47f1-b33f-7c028738cde8.ingress.apprun.sakura.ne.jp") {
        self.baseURL = baseURL
        self.sessionURL = "\(baseURL)/sessions"
        
        // URLSessionの設定
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: configuration)
    }
    
    /// ユーザープロファイルを設定
    func setUserProfiles(me: UserProfile, partner: UserProfile) {
        self.meProfile = me
        self.partnerProfile = partner
    }
    
    // MARK: - Public Methods
    func startSession(callback: @escaping TopicReceivedCallback) async throws {
        print("[TopicWebSocket] 🚀 Starting session...")
        self.callback = callback
        
        // まずHTTP APIでセッションを作成
        print("[TopicWebSocket] 📡 Step 1: Creating session via HTTPS...")
        let sessionId = try await createSession()
        self.sessionId = sessionId
        print("[TopicWebSocket] ✅ Step 1 Complete: Session ID = \(sessionId)")
        
        // WebSocket接続を確立（ping送信で接続確認済み）
        print("[TopicWebSocket] 🔌 Step 2: Establishing WebSocket connection...")
        try await connectWebSocket(sessionId: sessionId)
        
        isConnected = true
        print("[TopicWebSocket] ✅ Step 2 Complete: WebSocket connected")
        print("[TopicWebSocket] ⏱️ Waiting 100ms before starting receive loop...")
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms待機
        print("[TopicWebSocket] 📩 Step 3: Starting message receive loop...")
        
        // メッセージ受信の開始
        receiveMessage()
        print("[TopicWebSocket] ✅ All steps complete - Session ready!")
    }
    
    func pushMessages(_ messages: [ConversationMessage]) async throws {
        print("[TopicWebSocket] 📤 pushMessages called with \(messages.count) messages")
        
        guard let webSocketTask = webSocketTask else {
            print("[TopicWebSocket] ❌ WebSocketTask is nil")
            throw TopicServiceError.notConnected
        }
        
        if !isConnected {
            print("[TopicWebSocket] ⚠️ isConnected = false, but WebSocketTask exists")
            print("[TopicWebSocket] 🔧 Attempting to recover connection state...")
            // WebSocketTaskが存在する場合は、接続を回復を試みる
            isConnected = true
        }
        
        print("[TopicWebSocket] 📝 Preparing to send messages:")
        for (index, msg) in messages.enumerated() {
            print("[TopicWebSocket]   [\(index)] userId=\(msg.userId), text=\(msg.text)")
        }
        
        let request = WebSocketConversationsRequest(conversations: messages)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        
        // デバッグ: 送信するJSONを出力
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[TopicWebSocket] 📤 Sending JSON (\(data.count) bytes):")
            print("[TopicWebSocket] \(jsonString)")
        }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        
        do {
            print("[TopicWebSocket] 🚀 Sending message via WebSocket...")
            try await webSocketTask.send(message)
            print("[TopicWebSocket] ✅ Successfully sent \(messages.count) messages to server")
        } catch {
            isConnected = false
            print("[TopicWebSocket] ❌ Failed to send messages: \(error.localizedDescription)")
            throw error
        }
    }
    
    func endSession() async {
        print("[TopicWebSocket] 🛑 Ending session...")
        isConnected = false
        // WebSocket接続を切断
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        print("[TopicWebSocket] 🔌 WebSocket connection closed")
        
        // セッション削除（オプション）
        if let sessionId = sessionId {
            print("[TopicWebSocket] 🗑️ Deleting session: \(sessionId)")
            await deleteSession(sessionId: sessionId)
        }
        
        sessionId = nil
        callback = nil
        print("[TopicWebSocket] ✅ Session ended and cleaned up")
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
            if let httpResponse = response as? HTTPURLResponse {
                print("❌ Session creation failed with status: \(httpResponse.statusCode)")
            }
            throw TopicServiceError.sessionCreationFailed
        }
        
        // デバッグ: 受信したJSONを出力
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Session response JSON: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let sessionResponse = try decoder.decode(CreateSessionResponse.self, from: data)
            print("✅ Session created: \(sessionResponse.sessionId)")
            
            // 初期提案をコールバック
            let initialTopics = sessionResponse.initialSuggestions.map { $0.text }
            callback?(initialTopics)
            
            return sessionResponse.sessionId
        } catch {
            print("❌ Failed to decode session response: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Key '\(key)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    /// WebSocket接続を確立
    private func connectWebSocket(sessionId: String) async throws {
        print("[TopicWebSocket] 🔄 Original baseURL: \(baseURL)")
        
        // HTTPSのURLをwssに変換
        let wsBaseURL = baseURL.replacingOccurrences(of: "https://", with: "wss://")
                                .replacingOccurrences(of: "http://", with: "ws://")
        
        print("[TopicWebSocket] 🔄 Converted wsBaseURL: \(wsBaseURL)")
        
        let fullURL = "\(wsBaseURL)/sessions/\(sessionId)/topics"
        print("[TopicWebSocket] 🎯 Full WebSocket URL: \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            print("[TopicWebSocket] ❌ Invalid URL: \(fullURL)")
            throw TopicServiceError.invalidURL
        }
        
        print("[TopicWebSocket] ✅ Valid URL created: \(url)")
        print("[TopicWebSocket] 🔍 URL scheme: \(url.scheme ?? "none")")
        
        // WebSocketタスクを作成
        webSocketTask = urlSession.webSocketTask(with: url)
        
        print("[TopicWebSocket] ✅ WebSocketTask created")
        print("[TopicWebSocket] 🚀 Starting WebSocket connection...")
        webSocketTask?.resume()
        
        print("[TopicWebSocket] ✅ WebSocket connection initiated to \(url)")
    }
    
    /// メッセージ受信を開始
    private func receiveMessage() {
        guard isConnected else {
            print("[TopicWebSocket] ⚠️ receiveMessage: Not connected, skipping")
            return
        }
        guard let task = webSocketTask else {
            print("[TopicWebSocket] ⚠️ receiveMessage: WebSocketTask is nil")
            return
        }
        
        print("[TopicWebSocket] 👂 Waiting for next message...")
        
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("[TopicWebSocket] 📩 Received DATA message (\(data.count) bytes)")
                    self.handleReceivedData(data)
                case .string(let string):
                    print("[TopicWebSocket] 📩 Received STRING message (\(string.count) chars)")
                    print("[TopicWebSocket] Content: \(string)")
                    if let data = string.data(using: .utf8) {
                        self.handleReceivedData(data)
                    } else {
                        print("[TopicWebSocket] ❌ Failed to convert string to data")
                    }
                @unknown default:
                    print("[TopicWebSocket] ⚠️ Unknown message type received")
                }
                // 次のメッセージを受信
                print("[TopicWebSocket] 🔄 Restarting receive loop...")
                self.receiveMessage()
            case .failure(let error):
                print("[TopicWebSocket] ⚠️ WebSocket receive error: \(error.localizedDescription)")
                print("[TopicWebSocket] ⚠️ Error details: \(error)")
                
                // NSPOSIXErrorDomain Code=57 は一時的なエラーの可能性があるため、再試行
                let nsError = error as NSError
                if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
                    print("[TopicWebSocket] ⚠️ Socket not connected error - this may be temporary")
                    print("[TopicWebSocket] 🔄 Retrying receive in 1 second...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if self.isConnected {
                            self.receiveMessage()
                        }
                    }
                } else {
                    // その他の深刻なエラーの場合のみ切断
                    self.isConnected = false
                    print("[TopicWebSocket] ❌ Fatal error - marking as disconnected")
                }
            }
        }
    }
    
    /// 受信データを処理
    private func handleReceivedData(_ data: Data) {
        print("[TopicWebSocket] 🔍 Processing received data (\(data.count) bytes)")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // デバッグ: 受信したJSONを出力
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[TopicWebSocket] 📩 Received JSON:")
            print("[TopicWebSocket] \(jsonString)")
        }
        
        // まずエラーレスポンスかチェック
        if let errorResponse = try? decoder.decode(WebSocketErrorResponse.self, from: data) {
            print("[TopicWebSocket] ❌ Server returned error: \(errorResponse.error)")
            return
        }
        
        // 通常のレスポンスをデコード
        do {
            let response = try decoder.decode(WebSocketTopicResponse.self, from: data)
            let topics = response.suggestions.map { $0.text }
            print("[TopicWebSocket] ✅ Successfully decoded \(topics.count) topics:")
            for (index, topic) in topics.enumerated() {
                print("[TopicWebSocket]   [\(index)] \(topic)")
            }
            print("[TopicWebSocket] 📞 Calling callback with topics...")
            callback?(topics)
            print("[TopicWebSocket] ✅ Callback completed")
        } catch {
            print("[TopicWebSocket] ❌ Failed to decode response: \(error.localizedDescription)")
            print("[TopicWebSocket] ❌ Decode error details: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Key '\(key)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
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
