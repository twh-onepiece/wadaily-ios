//
//  SpeechToTextRepositoryProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// 音声テキスト変換の結果を受け取るコールバック
typealias SpeechToTextCallback = (Result<String, Error>) -> Void

/// 音声テキスト変換サービスのプロトコル
protocol SpeechToTextRepositoryProtocol {
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
class MockSpeechToTextService: SpeechToTextRepositoryProtocol {
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

// class SpeechToTextService: SpeechToTextRepositoryProtocol {
//     private var webSocketTask: URLSessionWebSocketTask?
//     private var callback: SpeechToTextCallback?
    
//     func startSession(
//         sampleRate: Int,
//         channels: Int,
//         callback: @escaping SpeechToTextCallback
//     ) async throws {
//         self.callback = callback
        
//         // WebSocket接続の実装
//         // TODO: 実際のWebSocketエンドポイントURLを設定
//         guard let url = URL(string: "wss://your-api-endpoint.com/speech-to-text") else {
//             throw NSError(domain: "SpeechToTextService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
//         }
        
//         let session = URLSession(configuration: .default)
//         webSocketTask = session.webSocketTask(with: url)
//         webSocketTask?.resume()
        
//         // メッセージ受信の開始
//         receiveMessage()
        
//         // 初期化メッセージの送信 (必要に応じて)
//         let config = ["sampleRate": sampleRate, "channels": channels]
//         if let configData = try? JSONSerialization.data(withJSONObject: config) {
//             try await webSocketTask?.send(.data(configData))
//         }
//     }
    
//     func sendAudioData(_ pcmData: Data) async throws {
//         guard let webSocketTask = webSocketTask else {
//             throw NSError(domain: "SpeechToTextService", code: 2, userInfo: [NSLocalizedDescriptionKey: "WebSocket not connected"])
//         }
        
//         try await webSocketTask.send(.data(pcmData))
//     }
    
//     func endSession() async {
//         webSocketTask?.cancel(with: .goingAway, reason: nil)
//         webSocketTask = nil
//         callback = nil
//     }
    
//     private func receiveMessage() {
//         webSocketTask?.receive { [weak self] result in
//             switch result {
//             case .success(let message):
//                 switch message {
//                 case .string(let text):
//                     // テキストメッセージとして変換結果を受信
//                     self?.callback?(.success(text))
//                 case .data(let data):
//                     // データとして受信した場合、UTF-8文字列に変換
//                     if let text = String(data: data, encoding: .utf8) {
//                         self?.callback?(.success(text))
//                     }
//                 @unknown default:
//                     break
//                 }
                
//                 // 次のメッセージを受信
//                 self?.receiveMessage()
                
//             case .failure(let error):
//                 self?.callback?(.failure(error))
//             }
//         }
//     }
// }
