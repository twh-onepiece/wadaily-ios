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
