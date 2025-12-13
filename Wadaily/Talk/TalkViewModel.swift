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
    @Published var recognizedText: String = ""
    
    // リモートユーザーのPCMデータストリーム
    private var pcmDataBuffer = Data()
    private let bufferSizeThreshold = 48000 * 2 // 1秒分のデータ (48kHz * 2 bytes per sample)
    
    private let me: Caller
    private let partner: Caller
    
    private var agoraManager: AgoraManager?
    private var coordinator: AgoraEngineCoordinator?
    private let speechToTextRepository: SpeechToTextRepositoryProtocol

    init(
        me: Caller,
        partner: Caller,
        speechToTextRepository: SpeechToTextRepositoryProtocol = MockSpeechToTextRepository()
    ) {
        self.me = me
        self.partner = partner
        self.speechToTextRepository = speechToTextRepository
        coordinator = AgoraEngineCoordinator(delegate: self)
        if let coordinator = coordinator {
            agoraManager = AgoraManager(delegate: coordinator, audioFrameDelegate: coordinator)
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
}

extension TalkViewModel: AgoraEngineCoordinatorDelegate {
    func didJoined(uid: UInt) {
        guard (uid == me.talkId) else { return }
        state = .channelJoined
        print("I joined with uid: \(uid)")
    }
    
    func didPartnerJoined(uid: UInt) {
        state = .talking
        print("Partner joined with uid: \(uid)")
    }
    
    func didPartnerLeave(uid: UInt) {
        state = .callEnded
        print("Partner lefted with uid: \(uid)")
    }
    
    func didLeaveChannel() {
        state = .callEnded
        print("Left channel")
    }
    
    func didOccurError() {
    }
    
    func didReceiveAudioFrame(_ frame: AgoraAudioFrame) {
        // リモートユーザーのPCMデータのみを処理
        guard let buffer = frame.buffer else { return }
        
        // PCMデータを抽出 (16-bit samples)
        let byteCount = Int(frame.samplesPerChannel * frame.channels * 2)
        let pcmData = Data(bytes: buffer, count: byteCount)
        
        // バッファに追加
        pcmDataBuffer.append(pcmData)
        
        // バッファが一定サイズに達したらテキスト変換APIに送信
        if pcmDataBuffer.count >= bufferSizeThreshold {
            let dataToSend = pcmDataBuffer
            pcmDataBuffer.removeAll()
            
            // テキスト変換APIに送信
            Task {
                do {
                    let text = try await speechToTextRepository.convertToText(
                        pcmData: dataToSend,
                        sampleRate: 48000,
                        channels: 1
                    )
                    
                    await MainActor.run {
                        self.recognizedText += text + " "
                    }
                    
                    print("📤 Sent PCM data to API - Size: \(dataToSend.count) bytes")
                    print("📝 Recognized text: \(text)")
                } catch {
                    print("❌ Speech to text conversion failed: \(error)")
                }
            }
        }
    }
}           
