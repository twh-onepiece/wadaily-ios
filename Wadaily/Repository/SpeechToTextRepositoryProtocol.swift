//
//  SpeechToTextRepositoryProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// 音声テキスト変換APIのプロトコル
protocol SpeechToTextRepositoryProtocol {
    /// PCMデータをテキストに変換する
    /// - Parameters:
    ///   - pcmData: PCMオーディオデータ (48kHz, mono, 16-bit)
    ///   - sampleRate: サンプルレート (デフォルト: 48000)
    ///   - channels: チャンネル数 (デフォルト: 1 = モノラル)
    /// - Returns: 変換されたテキスト
    func convertToText(
        pcmData: Data,
        sampleRate: Int,
        channels: Int
    ) async throws -> String
}

/// デフォルトの実装（モック用）
class MockSpeechToTextRepository: SpeechToTextRepositoryProtocol {
    func convertToText(
        pcmData: Data,
        sampleRate: Int,
        channels: Int
    ) async throws -> String {
        // モック実装：実際のAPIが実装されるまでの仮実装
        print("📝 Mock: Received PCM data - Size: \(pcmData.count) bytes, SampleRate: \(sampleRate)Hz, Channels: \(channels)")
        
        // 実際の実装では、ここでAPIを呼び出してテキストを取得
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
        
        return "[Mock] 変換されたテキスト (データサイズ: \(pcmData.count) bytes)"
    }
}
