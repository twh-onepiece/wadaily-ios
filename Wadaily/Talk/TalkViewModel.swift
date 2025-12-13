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

class TalkViewModel: ObservableObject {
    @Published var state: TalkViewState = .disconnected
    @Published var isMuted: Bool = false
    @Published var currentConversation: [ConversationMessage] = []
    @Published var suggestedTopics: [String] = []
    
    // 音声設定
    private let SAMPLING_RATE = 24000 // サンプルレート (Hz)
    private let MESSAGE_THRESHOLD = 10 // 話題提案を行うメッセージ数の閾値
    
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
    
    // WebSocket接続状態フラグ
    private var isMySttConnected = false
    private var isPartnerSttConnected = false
    private var isTopicWebSocketConnected = false

    init(
        me: Caller,
        partner: Caller,
        partnerSpeechToTextService: SpeechToTextServiceProtocol = SpeechToTextService(),
        mySpeechToTextService: SpeechToTextServiceProtocol = SpeechToTextService(),
        topicWebSocketService: TopicWebSocketServiceProtocol = TopicWebSocketService()
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
        
        // ユーザープロファイルをWebSocketサービスに設定
        let meProfile = UserProfile(userId: me.userId, snsData: SNSData.dummy(for: me.userId))
        let partnerProfile = UserProfile(userId: partner.userId, snsData: SNSData.dummy(for: partner.userId))
        topicWebSocketService.setUserProfiles(me: meProfile, partner: partnerProfile)
    }
    
    private func setupWebSoketSessions() {
        print("🔌 [TalkViewModel] Setting up WebSocket sessions...")
        Task {
            do {
                // 自分の音声用セッション開始
                print("🎤 [TalkViewModel] Starting My Speech-to-Text session...")
                try await mySpeechToTextService.startSession(
                    sampleRate: SAMPLING_RATE,
                    channels: 1,
                    callback: onReceivedMyText
                )
                isMySttConnected = true
                print("✅ [TalkViewModel] My Speech-to-Text session started")

                // 相手の音声用セッション開始
                print("🎤 [TalkViewModel] Starting Partner Speech-to-Text session...")
                try await partnerSpeechToTextService.startSession(
                    sampleRate: SAMPLING_RATE,
                    channels: 1,
                    callback: onReceivedPartnerText
                )
                isPartnerSttConnected = true
                print("✅ [TalkViewModel] Partner Speech-to-Text session started")
                
                // 話題提案API用セッション開始
                print("🔌 [TalkViewModel] Starting Topic WebSocket session...")
                try await topicWebSocketService.startSession(callback: onReceivedTopics)
                isTopicWebSocketConnected = true
                print("✅ [TalkViewModel] WebSocket session started for topic suggestions")
            } catch {
                print("❌ [TalkViewModel] Failed to start sessions: \(error.localizedDescription)")
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
        
        // 接続フラグをリセット
        isMySttConnected = false
        isPartnerSttConnected = false
        
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
        
        // WebSocket接続が完了していない場合は送信しない
        guard isTopicWebSocketConnected else {
            print("⏸️ Topic WebSocket not connected yet, skipping push")
            return
        }
        
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
        
        // バッファに追加して、一定サイズになったらSTT APIに送信
        bufferQueue.async { [weak self] in
            guard let self = self else { return }
            self.myAudioBuffer.append(pcmData)
            
            // 目標バッファサイズ (3秒分 = 24000 Hz * 3秒 * 2 bytes = 144,000 bytes)
            let targetBufferSize = (self.SAMPLING_RATE * self.STT_BUFFER_DURATION_MS * 2) / 1000
            
            if self.myAudioBuffer.count >= targetBufferSize {
                let dataToSend = self.myAudioBuffer
                self.myAudioBuffer.removeAll(keepingCapacity: true)
                
                // WebSocket接続が確立されている場合のみ送信
                if self.isMySttConnected {
                    // STT APIに送信（非同期・待たない）
                    Task.detached {
                        do {
                            try await self.mySpeechToTextService.sendAudioData(dataToSend)
                        } catch {
                            print("❌ Failed to send my audio data: \(error)")
                        }
                    }
                }
            }
        }
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
        // まずAgoraチャンネルから離脱
        agoraManager?.leaveChannel()
        
        // 接続フラグをリセット
        isMySttConnected = false
        isPartnerSttConnected = false
        isTopicWebSocketConnected = false
        
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
        print("Partner lefted with uid: \(uid)")
    }
    
    func didReceivePartnerAudioFrame(_ frame: AgoraAudioFrame) {
        // 相手のPCMデータを処理
        guard let buffer = frame.buffer else { return }
        
        // PCMデータを抽出 (16-bit samples)
        let byteCount = Int(frame.samplesPerChannel * frame.channels * 2)
        let pcmData = Data(bytes: buffer, count: byteCount)
        
        // バッファに追加して、一定サイズになったらSTT APIに送信
        bufferQueue.async { [weak self] in
            guard let self = self else { return }
            self.partnerAudioBuffer.append(pcmData)
            
            // 目標バッファサイズ (3秒分 = 24000 Hz * 3秒 * 2 bytes = 144,000 bytes)
            let targetBufferSize = (self.SAMPLING_RATE * self.STT_BUFFER_DURATION_MS * 2) / 1000
            
            if self.partnerAudioBuffer.count >= targetBufferSize {
                let dataToSend = self.partnerAudioBuffer
                self.partnerAudioBuffer.removeAll(keepingCapacity: true)
                
                // WebSocket接続が確立されている場合のみ送信
                if self.isPartnerSttConnected {
                    // STT APIに送信（非同期・待たない）
                    Task.detached {
                        do {
                            try await self.partnerSpeechToTextService.sendAudioData(dataToSend)
                        } catch {
                            print("❌ Failed to send partner audio data: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Wadaily Callbacks
extension TalkViewModel {
    /// 自分の音声からテキスト変換結果を受け取るコールバック関数
    private func onReceivedMyText(_ result: Result<String, Error>) {
        let textId = UUID().uuidString.prefix(8)
        print("📥 [TalkViewModel-\(textId)] Callback invoked for MY text")
        
        switch result {
        case .success(let text):
            print("📝 [TalkViewModel-\(textId)] My recognized text: \(text)")
            Task { @MainActor in
                let message = ConversationMessage(
                    userId: me.talkId,
                    text: text,
                    timestamp: Date()
                )
                currentConversation.append(message)
                checkAndPushMessages()
            }
        case .failure(let error):
            print("❌ [TalkViewModel-\(textId)] My speech to text conversion failed: \(error.localizedDescription)")
        }
    }
    
    /// 相手の音声からテキスト変換結果を受け取るコールバック関数
    private func onReceivedPartnerText(_ result: Result<String, Error>) {
        let textId = UUID().uuidString.prefix(8)
        print("📥 [TalkViewModel-\(textId)] Callback invoked for PARTNER text")
        
        switch result {
        case .success(let text):
            print("📝 [TalkViewModel-\(textId)] Partner recognized text: \(text)")
            Task { @MainActor in
                let message = ConversationMessage(
                    userId: partner.talkId,
                    text: text,
                    timestamp: Date()
                )
                currentConversation.append(message)
                checkAndPushMessages()
            }
        case .failure(let error):
            print("❌ [TalkViewModel-\(textId)] Partner speech to text conversion failed: \(error.localizedDescription)")
        }
    }
    
    /// WebSocketから話題提案を受け取るコールバック関数
    private func onReceivedTopics(_ topics: [String]) {
        Task { @MainActor in
            print("==================SUCCESS=======================")
            print("💡 Received topics: \(topics)")
            suggestedTopics = topics
        }
    }
}           
