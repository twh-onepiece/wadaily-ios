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
    private let me: Caller
    private let partner: Caller
    
    private var agoraManager: AgoraManager?
    private var coordinator: AgoraEngineCoordinator?

    init(me: Caller, partner: Caller) {
        self.me = me
        self.partner = partner
        coordinator = AgoraEngineCoordinator(delegate: self)
        if let coordinator = coordinator {
            agoraManager = AgoraManager(delegate: coordinator)
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
        guard (uid == partner.talkId) else { return }
        state = .talking
        print("Partner joined with uid: \(uid)")
    }
    
    func didPartnerLeave(uid: UInt) {
        guard (uid == partner.talkId) else { return }
        state = .callEnded
        print("Partner lefted with uid: \(uid)")
    }
    
    func didLeaveChannel() {
        state = .callEnded
        print("Left channel")
    }
    
    func didOccurError() {
        state = .disconnected
        print("Error occurred")
    }
}
