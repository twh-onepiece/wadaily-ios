//
//  SpeechToTextServiceProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// 音声テキスト変換の結果を受け取るコールバック
typealias SpeechToTextCallback = (Result<String, Error>) -> Void

/// 音声テキスト変換サービスのプロトコル
protocol SpeechToTextServiceProtocol {
    /// WebSocket接続を開始し、変換結果を受け取るコールバックを設定
    /// - Parameters:
    ///   - sampleRate: サンプルレート (例: 24000)
    ///   - channels: チャンネル数 (1 = モノラル)
    ///   - callback: 変換結果を受け取るコールバック
    func startSession(
        sampleRate: Int,
        channels: Int,
        callback: @escaping SpeechToTextCallback
    ) async throws
    
    /// PCMデータをWebSocket経由で送信
    /// - Parameter pcmData: PCMオーディオデータ (24kHz, mono, 16-bit)
    func sendAudioData(_ pcmData: Data) async throws
    
    /// WebSocket接続を終了
    func endSession() async
}

/// デフォルトの実装（モック用）
class MockSpeechToTextService: SpeechToTextServiceProtocol {
    private var callback: SpeechToTextCallback?
    private var isSessionActive = false
    
    func startSession(
        sampleRate: Int,
        channels: Int,
        callback: @escaping SpeechToTextCallback
    ) async throws {
        print("📝 Mock: Starting session - SampleRate: \(sampleRate)Hz, Channels: \(channels)")
        self.callback = callback
        self.isSessionActive = true
    }
    
    func sendAudioData(_ pcmData: Data) async throws {
        guard isSessionActive else {
            throw NSError(domain: "MockSpeechToTextService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session not active"])
        }
        
        print("📝 Mock: Received PCM data - Size: \(pcmData.count) bytes")
        
        // モック実装: 非同期でコールバックを呼び出し
        Task {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
            let mockText = "[Mock] 変換されたテキスト (データサイズ: \(pcmData.count) bytes)"
            callback?(.success(mockText))
        }
    }
    
    func endSession() async {
        print("📝 Mock: Ending session")
        isSessionActive = false
        callback = nil
    }
}

 class SpeechToTextService: SpeechToTextServiceProtocol {
     private var webSocketTask: URLSessionWebSocketTask?
     private var callback: SpeechToTextCallback?
     private var sessionId: String = ""
    
     func startSession(
         sampleRate: Int,
         channels: Int,
         callback: @escaping SpeechToTextCallback
     ) async throws {
         sessionId = UUID().uuidString.prefix(8).description
         print("🔌 [STT-\(sessionId)] Starting session - SampleRate: \(sampleRate)Hz, Channels: \(channels)")
         
         self.callback = callback
        
         // WebSocket接続の実装
         // TODO: 正しいWebSocketエンドポイントURLを設定してください
         // 現在のURLはテスト用です。実際のサーバーURLに置き換える必要があります。
         let websocketURLString = "wss://app-253151b9-60c4-47f1-b33f-7c028738cde8.ingress.apprun.sakura.ne.jp/transcript/connect"
         
         guard let url = URL(string: websocketURLString) else {
             print("❌ [STT-\(sessionId)] Invalid WebSocket URL: \(websocketURLString)")
             throw NSError(domain: "SpeechToTextService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
         }
        
         // URLスキームの検証
         guard url.scheme == "wss" || url.scheme == "ws" else {
             print("❌ [STT-\(sessionId)] Invalid URL scheme: \(url.scheme ?? "nil"). Expected 'wss' or 'ws'")
             throw NSError(domain: "SpeechToTextService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL scheme. Expected WebSocket (wss:// or ws://)"])
         }
        
         print("🔌 [STT-\(sessionId)] Connecting to: \(url.absoluteString)")
         print("🔌 [STT-\(sessionId)] URL scheme: \(url.scheme ?? "nil"), host: \(url.host ?? "nil"), path: \(url.path)")
         
         // URLSessionの設定を改善
         let configuration = URLSessionConfiguration.default
         configuration.timeoutIntervalForRequest = 30
         configuration.timeoutIntervalForResource = 30
         configuration.waitsForConnectivity = true
         
         let session = URLSession(configuration: configuration)
         webSocketTask = session.webSocketTask(with: url)
         
         print("🔌 [STT-\(sessionId)] WebSocket task created, resuming connection...")
         webSocketTask?.resume()
         print("🔌 [STT-\(sessionId)] WebSocket task resumed")
        
         print("✅ [STT-\(sessionId)] WebSocket connection initiated")
         
         // メッセージ受信の開始
         receiveMessage()
     }
    
     func sendAudioData(_ pcmData: Data) async throws {
         guard let webSocketTask = webSocketTask else {
             print("❌ [STT-\(sessionId)] Cannot send audio: WebSocket not connected")
             throw NSError(domain: "SpeechToTextService", code: 2, userInfo: [NSLocalizedDescriptionKey: "WebSocket not connected"])
         }
        
         print("📤 [STT-\(sessionId)] Sending PCM data: \(pcmData.count) bytes")
         
         // バグ修正: 生のバイナリデータを送信 (base64エンコードは不要)
         try await webSocketTask.send(.data(pcmData))
         
         print("✅ [STT-\(sessionId)] PCM data sent successfully")
     }
    
     func endSession() async {
         print("🔌 [STT-\(sessionId)] Ending session...")
         webSocketTask?.cancel(with: .goingAway, reason: nil)
         webSocketTask = nil
         callback = nil
         print("✅ [STT-\(sessionId)] Session ended")
     }
    
     private func receiveMessage() {
         webSocketTask?.receive { [weak self] result in
             guard let self = self else { return }
             
             switch result {
             case .success(let message):
                 print("📥 [STT-\(self.sessionId)] Received WebSocket message")
                 
                 switch message {
                 case .string(let text):
                     print("📝 [STT-\(self.sessionId)] Received text message: \(text)")
                     // テキストメッセージとして変換結果を受信
                     self.callback?(.success(text))
                     
                 case .data(let data):
                     print("📝 [STT-\(self.sessionId)] Received data message: \(data.count) bytes")
                     // データとして受信した場合、UTF-8文字列に変換
                     if let text = String(data: data, encoding: .utf8) {
                         print("📝 [STT-\(self.sessionId)] Decoded text: \(text)")
                         self.callback?(.success(text))
                     } else {
                         print("❌ [STT-\(self.sessionId)] Failed to decode data as UTF-8")
                     }
                     
                 @unknown default:
                     print("⚠️ [STT-\(self.sessionId)] Received unknown message type")
                     break
                 }
                
                 // 次のメッセージを受信
                 self.receiveMessage()
                
             case .failure(let error):
                 print("❌ [STT-\(self.sessionId)] WebSocket error: \(error.localizedDescription)")
                 self.callback?(.failure(error))
             }
         }
     }
 }
