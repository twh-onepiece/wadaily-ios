//
//  TalkViewModel.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/03.
//

import Combine
import AgoraRtcKit

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
        Task {
            await partnerSpeechToTextService.endSession()
            await mySpeechToTextService.endSession()
            await topicWebSocketService.endSession()
        }
        agoraManager?.leaveChannel()
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
        
        let toPushMessages = currentConversation
        currentConversation = []
        
        // 非同期でメッセージをプッシュ（待たない）
        Task {
            do {
                try await topicWebSocketService.pushMessages(toPushMessages)
                print("💬 Pushed \(toPushMessages.count) messages to server")
            } catch {
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
        // 自分のPCMデータを処理
        guard let buffer = frame.buffer else { return }
        
        // PCMデータを抽出 (16-bit samples)
        let byteCount = Int(frame.samplesPerChannel * frame.channels * 2)
        let pcmData = Data(bytes: buffer, count: byteCount)
        
        // テキスト変換サービスに直接送信
        Task {
            do {
                try await mySpeechToTextService.sendAudioData(pcmData)
                print("📤 Sent My PCM data to service - Size: \(pcmData.count) bytes")
            } catch {
                print("❌ Failed to send my audio data: \(error)")
            }
        }
    }
    
    func didOccurError() {
        state = .callEnded
        print("occur error")
    }
    
    //MARK: - Event from partner
    func didPartnerJoined(uid: UInt) {
        setupWebSoketSessions()
        state = .talking
        print("Partner joined with uid: \(uid)")

        Task {
            do {
                // 相手の音声用セッション開始
                try await partnerSpeechToTextService.startSession(
                    sampleRate: SAMPLING_RATE,
                    channels: 1,
                    callback: onReceivedPartnerText
                )
                print("🎤 Partner Speech-to-Text session started")
                
                // 自分の音声用セッション開始
                try await mySpeechToTextService.startSession(
                    sampleRate: SAMPLING_RATE,
                    channels: 1,
                    callback: onReceivedMyText
                )
                print("🎤 My Speech-to-Text session started")
            } catch {
                print("❌ Failed to start speech-to-text sessions: \(error)")
            }
        }
    }
    
    func didPartnerLeave(uid: UInt) {
        state = .callEnded
        print("Partner lefted with uid: \(uid)")
    }
    
    func didReceivePartnerAudioFrame(_ frame: AgoraAudioFrame) {
        // 相手のPCMデータを処理
        guard let buffer = frame.buffer else { return }
        
        // PCMデータを抽出 (16-bit samples)
        let byteCount = Int(frame.samplesPerChannel * frame.channels * 2)
        let pcmData = Data(bytes: buffer, count: byteCount)
        
        // テキスト変換サービスに直接送信
        Task {
            do {
                try await partnerSpeechToTextService.sendAudioData(pcmData)
                print("📤 Sent Partner PCM data to service - Size: \(pcmData.count) bytes")
            } catch {
                print("❌ Failed to send partner audio data: \(error)")
            }
        }
    }
}

// MARK: - Wadaily Callbacks
extension TalkViewModel {
    /// 自分の音声からテキスト変換結果を受け取るコールバック関数
    private func onReceivedMyText(_ result: Result<String, Error>) {
        switch result {
        case .success(let text):
            Task { @MainActor in
                print("📝 My recognized text: \(text)")
                let message = ConversationMessage(
                    userId: me.talkId,
                    text: text,
                    timestamp: Date()
                )
                currentConversation.append(message)
                checkAndPushMessages()
            }
        case .failure(let error):
            print("❌ My speech to text conversion failed: \(error)")
        }
    }
    
    /// 相手の音声からテキスト変換結果を受け取るコールバック関数
    private func onReceivedPartnerText(_ result: Result<String, Error>) {
        switch result {
        case .success(let text):
            Task { @MainActor in
                print("📝 Partner recognized text: \(text)")
                let message = ConversationMessage(
                    userId: partner.talkId,
                    text: text,
                    timestamp: Date()
                )
                currentConversation.append(message)
                checkAndPushMessages()
            }
        case .failure(let error):
            print("❌ Partner speech to text conversion failed: \(error)")
        }
    }
    
    /// WebSocketから話題提案を受け取るコールバック関数
    private func onReceivedTopics(_ topics: [String]) {
        Task { @MainActor in
            print("💡 Received topics: \(topics)")
            suggestedTopics = topics
        }
    }
}           
