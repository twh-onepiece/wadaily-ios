//
//  SpeechToTextService.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

class SpeechToTextService: SpeechToTextServiceProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private var callback: SpeechToTextCallback?
    private var sessionId: String = ""
    private var isConnected = false
    
    private let WEBSOCKET_URL_STRING: String = "wss://app-253151b9-60c4-47f1-b33f-7c028738cde8.ingress.apprun.sakura.ne.jp/transcript/connect"
   
    func startSession(
        sampleRate: Int,
        channels: Int,
        callback: @escaping SpeechToTextCallback
    ) async throws {
        sessionId = UUID().uuidString.prefix(8).description
        self.callback = callback
        
        guard let url = URL(string: WEBSOCKET_URL_STRING) else {
            throw NSError(domain: "SpeechToTextService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        // URLスキームの検証
        guard url.scheme == "wss" || url.scheme == "ws" else {
            throw NSError(domain: "SpeechToTextService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL scheme. Expected WebSocket (wss:// or ws://)"])
        }
       
        print("🔌 [STT-\(sessionId)] Connecting to: \(url.absoluteString)")
        
        // URLSessionの設定
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        
        let session = URLSession(configuration: configuration)
        webSocketTask = session.webSocketTask(with: url)
        
        print("🔌 [STT-\(sessionId)] WebSocket task created, resuming connection...")
        webSocketTask?.resume()
        
        // 接続確認のためPingを送信
        try await sendPing()
        
        isConnected = true
        print("✅ [STT-\(sessionId)] WebSocket connection established")
        
        // メッセージ受信の開始（接続確立後すぐに）
        receiveMessage()
        
        // 音声設定情報をサーバーに送信（必要に応じて）
        try await sendConfigurationIfNeeded(sampleRate: sampleRate, channels: channels)
    }
    
    private func sendPing() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            webSocketTask?.sendPing { error in
                if let error = error {
                    print("❌ [STT-\(self.sessionId)] Ping failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("🏓 [STT-\(self.sessionId)] Ping successful - connection confirmed")
                    continuation.resume()
                }
            }
        }
    }
    
    private func sendConfigurationIfNeeded(sampleRate: Int, channels: Int) async throws {
        // サーバーが設定情報を期待している場合に送信
        // TODO: サーバーのAPI仕様に応じてフォーマットを調整
        let config = [
            "type": "config",
            "sampleRate": sampleRate,
            "channels": channels,
            "format": "pcm16"
        ] as [String : Any]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: config),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 [STT-\(sessionId)] Sending configuration: \(jsonString)")
            try await webSocketTask?.send(.string(jsonString))
            print("✅ [STT-\(sessionId)] Configuration sent")
            
            // 設定送信後、少し待機してサーバーの応答を確認
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        }
    }
   
    func sendAudioData(_ pcmData: Data) async throws {
        guard let webSocketTask = webSocketTask else {
            print("❌ [STT-\(sessionId)] Cannot send audio: WebSocket not connected")
            throw NSError(domain: "SpeechToTextService", code: 2, userInfo: [NSLocalizedDescriptionKey: "WebSocket not connected"])
        }
        
        guard isConnected else {
            print("❌ [STT-\(sessionId)] Cannot send audio: Connection not established")
            throw NSError(domain: "SpeechToTextService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Connection not established"])
        }
       
        print("📤 [STT-\(sessionId)] Sending PCM data: \(pcmData.count) bytes, state: \(webSocketTask.state.rawValue)")
        
        do {
            try await webSocketTask.send(.data(pcmData))
            print("✅ [STT-\(sessionId)] PCM data sent successfully")
        } catch {
            print("❌ [STT-\(sessionId)] Failed to send PCM data: \(error.localizedDescription)")
            isConnected = false
            throw error
        }
    }
   
    func endSession() async {
        print("🔌 [STT-\(sessionId)] Ending session...")
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        callback = nil
        print("✅ [STT-\(sessionId)] Session ended")
    }
   
    private func receiveMessage() {
        guard isConnected else {
            print("⚠️ [STT-\(sessionId)] receiveMessage called but not connected")
            return
        }
        
        guard let task = webSocketTask else {
            print("⚠️ [STT-\(sessionId)] receiveMessage called but webSocketTask is nil")
            return
        }
        
        print("👂 [STT-\(sessionId)] Starting to listen for messages... (Task state: \(task.state.rawValue))")
        
        task.receive { [weak self] result in
            guard let self = self else {
                print("⚠️ [STT] receiveMessage: self is nil")
                return
            }
            
            print("🔔 [STT-\(self.sessionId)] Receive callback triggered")
            
            switch result {
            case .success(let message):
                print("📥 [STT-\(self.sessionId)] Received WebSocket message")
                
                switch message {
                case .string(let text):
                    print("📝 [STT-\(self.sessionId)] Received text message (length: \(text.count)): \(text)")
                    self.callback?(.success(text))
                    
                case .data(let data):
                    print("📝 [STT-\(self.sessionId)] Received data message: \(data.count) bytes")
                    if let text = String(data: data, encoding: .utf8) {
                        print("📝 [STT-\(self.sessionId)] Decoded text (length: \(text.count)): \(text)")
                        self.callback?(.success(text))
                    } else {
                        print("❌ [STT-\(self.sessionId)] Failed to decode data as UTF-8, hex: \(data.prefix(20).map { String(format: "%02x", $0) }.joined())")
                    }
                    
                @unknown default:
                    print("⚠️ [STT-\(self.sessionId)] Received unknown message type")
                    break
                }
               
                // 次のメッセージを受信
                print("🔄 [STT-\(self.sessionId)] Setting up next receive...")
                self.receiveMessage()
               
            case .failure(let error):
                let nsError = error as NSError
                print("❌ [STT-\(self.sessionId)] WebSocket receive error: \(error.localizedDescription)")
                print("❌ [STT-\(self.sessionId)] Error domain: \(nsError.domain), code: \(nsError.code)")
                self.isConnected = false
                self.callback?(.failure(error))
            }
        }
    }
}
