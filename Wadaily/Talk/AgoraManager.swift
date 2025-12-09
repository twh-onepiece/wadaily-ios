//
//  Agora.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/02.
//

import SwiftUI
import AgoraRtcKit
import Combine

protocol AgoraEngineCoordinatorDelegate: AnyObject {
    func didMyUserJoined(uid: UInt)
    func didPartnerJoined(uid: UInt)
    func didUserOffline(uid: UInt)
    func didLeaveChannel()
    func didOccurError()
}

// MARK: - Agora Manager
class AgoraManager: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    private let tokenRepository: AgoraTokenRepositoryProtocol
    
    init(delegate: AgoraRtcEngineDelegate, tokenRepository: AgoraTokenRepositoryProtocol = AgoraTokenRepository()) {
        // Info.plistからAgoraAppIdを取得
        guard let appId = Bundle.main.object(forInfoDictionaryKey: "AgoraAppId") as? String else {
            fatalError("AgoraAppId not found in Info.plist")
        }
        
        self.tokenRepository = tokenRepository
        
        super.init()
        
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: delegate)
        
        agoraKit.enableAudio()
        agoraKit.setChannelProfile(.communication)
    }
    
    func joinChannel(channelName: String, uid: UInt = 0, role: String = "publisher") async throws {
        // トークンを取得
        let token = try await tokenRepository.getToken(
            channelName: channelName,
            uid: uid,
            role: role,
            tokenExpirationInSeconds: nil,
            privilegeExpirationInSeconds: nil
        )
        
        print("fetched token: \(token)")
        
        let option = AgoraRtcChannelMediaOptions()
        option.channelProfile = .communication
        option.clientRoleType = .broadcaster
        
        agoraKit.joinChannel(
            byToken: token,
            channelId: channelName,
            uid: uid,
            mediaOptions: option
        )
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
    }
    
    func onMute() {
        agoraKit.muteLocalAudioStream(true)
    }
    
    func offMute() {
        agoraKit.muteLocalAudioStream(false)
    }
    
    deinit {
        AgoraRtcEngineKit.destroy()
    }
}

class AgoraEngineCoordinator: NSObject, AgoraRtcEngineDelegate {
    weak var delegate: AgoraEngineCoordinatorDelegate?
    
    init(delegate: AgoraEngineCoordinatorDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        delegate?.didMyUserJoined(uid: uid)
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
