//
//  TalkViewModel.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/03.
//

import Combine
import AgoraRtcKit

// MARK: - Performance Logger
class PerformanceLogger {
    private static var startTimes: [String: Date] = [:]
    
    static func start(_ label: String) {
        let timestamp = Date()
        startTimes[label] = timestamp
        print("⏱️ [START] \(label) at \(formatTime(timestamp))")
    }
    
    static func end(_ label: String) {
        let endTime = Date()
        if let startTime = startTimes[label] {
            let duration = endTime.timeIntervalSince(startTime) * 1000 // ミリ秒
            print("⏱️ [END] \(label) - Duration: \(String(format: "%.2f", duration))ms")
            startTimes.removeValue(forKey: label)
        } else {
            print("⏱️ [END] \(label) at \(formatTime(endTime)) (no start time)")
        }
    }
    
    static func log(_ message: String) {
        print("⏱️ [LOG] \(message) at \(formatTime(Date()))")
    }
    
    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

enum TalkViewState {
    case disconnected      // 未接続
    case connecting        // 接続中
    case channelJoined     // チャンネル joined
    case talking           // 通話中
    case callEnded         // 通話終了
}

struct ConversationMessage: Identifiable {
    let id = UUID()
    let userId: UInt
    let text: String
    let timestamp: Date
}

class TalkViewModel: ObservableObject {
    @Published var state: TalkViewState = .disconnected
    @Published var isMuted: Bool = false
    @Published var currentConversation: [ConversationMessage] = []
    @Published var suggestedTopics: [String] = []
    
    // 音声設定
    private let SAMPLING_RATE = 24000 // サンプルレート (Hz)
    private let MESSAGE_THRESHOLD = 5 // 話題提案を行うメッセージ数の閾値
    
    // STT APIリクエスト用バッファ設定
    private let STT_BUFFER_DURATION_MS = 3000 // STT APIに送信する音声の長さ (3秒)
    private var myAudioBuffer = Data() // 自分の音声バッファ
    private var partnerAudioBuffer = Data() // 相手の音声バッファ
    private let bufferQueue = DispatchQueue(label: "com.wadaily.audiobuffer", qos: .userInteractive)
    
    private let me: Caller
    private let partner: Caller
    
    private var agoraManager: AgoraManager?
    private var coordinator: AgoraEngineCoordinator?
    private let partnerSpeechToTextService: SpeechToTextServiceProtocol // 相手用のSpeech-to-Textサービス
    private let mySpeechToTextService: SpeechToTextServiceProtocol      // 自分用のSpeech-to-Textサービス
    private let topicWebSocketService: TopicWebSocketServiceProtocol    // 話題提案用のWebSocketサービス
    private var lastPushedMessageCount = 0

    init(
        me: Caller,
        partner: Caller,
        partnerSpeechToTextService: SpeechToTextServiceProtocol = MockSpeechToTextService(),
        mySpeechToTextService: SpeechToTextServiceProtocol = MockSpeechToTextService(),
        topicWebSocketService: TopicWebSocketServiceProtocol = MockTopicWebSocketService()
    ) {
        self.me = me
        self.partner = partner
        self.partnerSpeechToTextService = partnerSpeechToTextService
        self.mySpeechToTextService = mySpeechToTextService
        self.topicWebSocketService = topicWebSocketService
        coordinator = AgoraEngineCoordinator(delegate: self)
        if let coordinator = coordinator {
            agoraManager = AgoraManager(delegate: coordinator, audioFrameDelegate: coordinator)
        }
    }
    
    private func setupWebSoketSessions() {
        Task {
            do {
                // 自分の音声用セッション開始
                try await mySpeechToTextService.startSession(
                    sampleRate: SAMPLING_RATE,
                    channels: 1,
                    callback: onReceivedMyText
                )
                print("🎤 My Speech-to-Text session started")

                // 相手の音声用セッション開始
                try await partnerSpeechToTextService.startSession(
                    sampleRate: SAMPLING_RATE,
                    channels: 1,
                    callback: onReceivedPartnerText
                )
                print("🎤 Partner Speech-to-Text session started")
                
                // 話題提案API用セッション開始
                try await topicWebSocketService.startSession(callback: onReceivedTopics)
                print("🔌 WebSocket session started for topic suggestions")
            } catch {
                print("❌ Failed to start sessions: \(error)")
            }
        }
    }
    
    func joinChannel() {
        state = .connecting
        Task {
            do {
                try await agoraManager?.joinChannel(channelName: partner.buildChannelName(with: me), uid: me.talkId)
            } catch {
                state = .disconnected
                print("Failed to join channel: \(error)")
            }
        }
    }

    func leaveChannel() {
        // まずAgoraチャンネルから離脱
        agoraManager?.leaveChannel()
        
        // バッファをクリア
        bufferQueue.async { [weak self] in
            self?.myAudioBuffer.removeAll()
            self?.partnerAudioBuffer.removeAll()
        }
        
        // その後、WebSocketセッションをクリーンアップ
        Task {
            await partnerSpeechToTextService.endSession()
            await mySpeechToTextService.endSession()
            await topicWebSocketService.endSession()
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            agoraManager?.onMute()
        } else {
            agoraManager?.offMute()
        }
    }
    
    /// メッセージ数をチェックし、5件溜まったらサーバーにプッシュ
    private func checkAndPushMessages() {
        guard currentConversation.count >= MESSAGE_THRESHOLD else { return }
        
        let pushId = UUID().uuidString.prefix(8)
        PerformanceLogger.start("PushMessages-\(pushId)")
        PerformanceLogger.log("PushMessages-\(pushId): Pushing \(currentConversation.count) messages")
        
        let toPushMessages = currentConversation
        currentConversation = []
        
        // 非同期でメッセージをプッシュ（待たない）
        Task {
            do {
                try await topicWebSocketService.pushMessages(toPushMessages)
                PerformanceLogger.end("PushMessages-\(pushId)")
                print("💬 Pushed \(toPushMessages.count) messages to server")
            } catch {
                PerformanceLogger.end("PushMessages-\(pushId)")
                print("❌ Failed to push messages: \(error)")
            }
        }
    }
}

// MARK: - Agora Delegates
extension TalkViewModel: AgoraEngineCoordinatorDelegate {
    //MARK: - Event from me
    func didJoined(uid: UInt) {
        guard (uid == me.talkId) else { return }
        state = .channelJoined
        print("I joined with uid: \(uid)")
    }
    
    func didLeaveChannel() {
        state = .callEnded
        print("Left channel")
    }
    
    func didReceiveMyAudioFrame(_ frame: AgoraAudioFrame) {
        let frameId = UUID().uuidString.prefix(8)
        PerformanceLogger.start("MyAudioFrame-\(frameId)")
        
        // 自分のPCMデータを処理
        guard let buffer = frame.buffer else { 
            PerformanceLogger.log("MyAudioFrame-\(frameId): buffer is nil")
            return 
        }
        
        // PCMデータを抽出 (16-bit samples)
        let byteCount = Int(frame.samplesPerChannel * frame.channels * 2)
        let pcmData = Data(bytes: buffer, count: byteCount)
        PerformanceLogger.log("MyAudioFrame-\(frameId): PCM data extracted (\(pcmData.count) bytes)")
        
        // バッファに追加して、一定サイズになったらSTT APIに送信
        bufferQueue.async { [weak self] in
            guard let self = self else { return }
            self.myAudioBuffer.append(pcmData)
            
            // 目標バッファサイズ (3秒分 = 24000 Hz * 3秒 * 2 bytes = 144,000 bytes)
            let targetBufferSize = (self.SAMPLING_RATE * self.STT_BUFFER_DURATION_MS * 2) / 1000
            
            if self.myAudioBuffer.count >= targetBufferSize {
                let dataToSend = self.myAudioBuffer
                self.myAudioBuffer.removeAll(keepingCapacity: true)
                
                // STT APIに送信（非同期・待たない）
                Task.detached {
                    PerformanceLogger.start("MyAudioSend-\(frameId)")
                    do {
                        try await self.mySpeechToTextService.sendAudioData(dataToSend)
                        PerformanceLogger.end("MyAudioSend-\(frameId)")
                        print("📤 Sent My buffered PCM data to STT API - Size: \(dataToSend.count) bytes (\(self.STT_BUFFER_DURATION_MS)ms)")
                    } catch {
                        PerformanceLogger.end("MyAudioSend-\(frameId)")
                        print("❌ Failed to send my audio data: \(error)")
                    }
                }
            }
        }
        PerformanceLogger.end("MyAudioFrame-\(frameId)")
    }
    
    func didOccurError() {
        state = .callEnded
        print("occur error")
    }
    
    //MARK: - Event from partner
    func didPartnerJoined(uid: UInt) {
        state = .talking
        print("Partner joined with uid: \(uid)")
        
        // WebSocketセッションを非同期で開始（待たない）
        // 音声処理をブロックしないため、バックグラウンドで実行
        setupWebSoketSessions()
    }
    
    func didPartnerLeave(uid: UInt) {
        state = .callEnded
        print("Partner lefted with uid: \(uid)")
    }
    
    func didReceivePartnerAudioFrame(_ frame: AgoraAudioFrame) {
        let frameId = UUID().uuidString.prefix(8)
        PerformanceLogger.start("PartnerAudioFrame-\(frameId)")
        
        // 相手のPCMデータを処理
        guard let buffer = frame.buffer else { 
            PerformanceLogger.log("PartnerAudioFrame-\(frameId): buffer is nil")
            return 
        }
        
        // PCMデータを抽出 (16-bit samples)
        let byteCount = Int(frame.samplesPerChannel * frame.channels * 2)
        let pcmData = Data(bytes: buffer, count: byteCount)
        PerformanceLogger.log("PartnerAudioFrame-\(frameId): PCM data extracted (\(pcmData.count) bytes)")
        
        // バッファに追加して、一定サイズになったらSTT APIに送信
        bufferQueue.async { [weak self] in
            guard let self = self else { return }
            self.partnerAudioBuffer.append(pcmData)
            
            // 目標バッファサイズ (3秒分 = 24000 Hz * 3秒 * 2 bytes = 144,000 bytes)
            let targetBufferSize = (self.SAMPLING_RATE * self.STT_BUFFER_DURATION_MS * 2) / 1000
            
            if self.partnerAudioBuffer.count >= targetBufferSize {
                let dataToSend = self.partnerAudioBuffer
                self.partnerAudioBuffer.removeAll(keepingCapacity: true)
                
                // STT APIに送信（非同期・待たない）
                Task.detached {
                    PerformanceLogger.start("PartnerAudioSend-\(frameId)")
                    do {
                        try await self.partnerSpeechToTextService.sendAudioData(dataToSend)
                        PerformanceLogger.end("PartnerAudioSend-\(frameId)")
                        print("📤 Sent Partner buffered PCM data to STT API - Size: \(dataToSend.count) bytes (\(self.STT_BUFFER_DURATION_MS)ms)")
                    } catch {
                        PerformanceLogger.end("PartnerAudioSend-\(frameId)")
                        print("❌ Failed to send partner audio data: \(error)")
                    }
                }
            }
        }
        PerformanceLogger.end("PartnerAudioFrame-\(frameId)")
    }
}

// MARK: - Wadaily Callbacks
extension TalkViewModel {
    /// 自分の音声からテキスト変換結果を受け取るコールバック関数
    private func onReceivedMyText(_ result: Result<String, Error>) {
        let textId = UUID().uuidString.prefix(8)
        PerformanceLogger.start("MyTextReceived-\(textId)")
        
        switch result {
        case .success(let text):
            PerformanceLogger.log("MyTextReceived-\(textId): Text length \(text.count)")
            Task { @MainActor in
                PerformanceLogger.start("MyTextMainActor-\(textId)")
                print("📝 My recognized text: \(text)")
                let message = ConversationMessage(
                    userId: me.talkId,
                    text: text,
                    timestamp: Date()
                )
                currentConversation.append(message)
                checkAndPushMessages()
                PerformanceLogger.end("MyTextMainActor-\(textId)")
                PerformanceLogger.end("MyTextReceived-\(textId)")
            }
        case .failure(let error):
            PerformanceLogger.end("MyTextReceived-\(textId)")
            print("❌ My speech to text conversion failed: \(error)")
        }
    }
    
    /// 相手の音声からテキスト変換結果を受け取るコールバック関数
    private func onReceivedPartnerText(_ result: Result<String, Error>) {
        let textId = UUID().uuidString.prefix(8)
        PerformanceLogger.start("PartnerTextReceived-\(textId)")
        
        switch result {
        case .success(let text):
            PerformanceLogger.log("PartnerTextReceived-\(textId): Text length \(text.count)")
            Task { @MainActor in
                PerformanceLogger.start("PartnerTextMainActor-\(textId)")
                print("📝 Partner recognized text: \(text)")
                let message = ConversationMessage(
                    userId: partner.talkId,
                    text: text,
                    timestamp: Date()
                )
                currentConversation.append(message)
                checkAndPushMessages()
                PerformanceLogger.end("PartnerTextMainActor-\(textId)")
                PerformanceLogger.end("PartnerTextReceived-\(textId)")
            }
        case .failure(let error):
            PerformanceLogger.end("PartnerTextReceived-\(textId)")
            print("❌ Partner speech to text conversion failed: \(error)")
        }
    }
    
    /// WebSocketから話題提案を受け取るコールバック関数
    private func onReceivedTopics(_ topics: [String]) {
        let topicId = UUID().uuidString.prefix(8)
        PerformanceLogger.start("TopicsReceived-\(topicId)")
        PerformanceLogger.log("TopicsReceived-\(topicId): \(topics.count) topics")
        
        Task { @MainActor in
            PerformanceLogger.start("TopicsMainActor-\(topicId)")
            print("💡 Received topics: \(topics)")
            suggestedTopics = topics
            PerformanceLogger.end("TopicsMainActor-\(topicId)")
            PerformanceLogger.end("TopicsReceived-\(topicId)")
        }
    }
    
    // MARK: - Test Helpers
    #if DEBUG
    /// テスト用：話題を手動で設定
    func setTestTopics(_ topics: [String]) {
        suggestedTopics = topics
    }
    
    /// テスト用：状態を手動で設定
    func setTestState(_ newState: TalkViewState) {
        state = newState
    }
    #endif
}           
