//
//  TalkViewModel.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/03.
//

import Combine
import AgoraRtcKit

enum TalkViewState {
    case Before
    case Waiting
    case Talking
    case Talked
}

protocol AgoraEngineCoordinatorDelegate: AnyObject {
    func didLeaveChannel()
    func didOccurError()
    func didMyJoined(uid: UInt)
    func didPartnerJoined(uid: UInt)
    func didUserOffline(uid: UInt)
}

class TalkViewModel: ObservableObject {
    @Published var state: TalkViewState = .Before
    @Published var isMuted: Bool = false
    @Published var myUserId: UInt = 0
    @Published var partnerUserId: UInt?
    
    private var agoraManager: AgoraManager?
    private var coordinator: AgoraEngineCoordinator?
    
    init() {
        coordinator = AgoraEngineCoordinator(delegate: self)
        if let coordinator = coordinator {
            agoraManager = AgoraManager(delegate: coordinator)
        }
    }
    
    func joinChannel(channelName: String, uid: UInt = 0) {
        Task {
            do {
                try await agoraManager?.joinChannel(channelName: channelName, uid: uid)
                state = .Waiting
            } catch {
                state = .Before
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
    func didMyJoined(uid: UInt) {
        myUserId = uid
        state = .Waiting
        print("I joined with uid: \(uid)")
    }
    
    func didPartnerJoined(uid: UInt) {
        partnerUserId = uid
        state = .Talking
        print("Partner joined with uid: \(uid)")
    }
    
    func didUserOffline(uid: UInt) {
        if uid == partnerUserId {
            partnerUserId = nil
            print("Partner left with uid: \(uid)")
        }
        state = .Talked
    }
    
    func didLeaveChannel() {
        state = .Talked
        print("Left channel")
    }
    
    func didOccurError() {
        state = .Before
        print("Error occurred")
    }
}

class AgoraEngineCoordinator: NSObject, AgoraRtcEngineDelegate {
    weak var delegate: AgoraEngineCoordinatorDelegate?
    
    init(delegate: AgoraEngineCoordinatorDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        delegate?.didMyJoined(uid: uid)
        print("Successfully joined channel: \(channel) with uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        delegate?.didPartnerJoined(uid: uid)
        print("User joined with uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        delegate?.didUserOffline(uid: uid)
        print("User offline with uid: \(uid), reason: \(reason.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        delegate?.didLeaveChannel()
        print("Left channel")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        delegate?.didOccurError()
        print("Error occurred: \(errorCode.rawValue)")
    }
}
