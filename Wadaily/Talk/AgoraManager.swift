//
//  Agora.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/02.
//

import SwiftUI
import AgoraRtcKit
import Combine

// コールバック(delegate)を定義するインターフェース(protocol)
// 理由: 直接ViewModelにAgoraRtcEngineDelegateが適用できないため、Coordinatorを挟んでいる。
protocol AgoraEngineCoordinatorDelegate: AnyObject {
    func didJoined(uid: UInt)
    func didPartnerJoined(uid: UInt)
    func didPartnerLeave(uid: UInt)
    func didLeaveChannel()
    func didOccurError()
    func didReceiveAudioFrame(_ frame: AgoraAudioFrame)
}

// MARK: - Agora Manager
class AgoraManager: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    private let tokenRepository: AgoraTokenRepositoryProtocol
    
    init(delegate: AgoraRtcEngineDelegate, audioFrameDelegate: AgoraAudioFrameDelegate, tokenRepository: AgoraTokenRepositoryProtocol = AgoraTokenRepository()) {
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
        
        // オーディオフレームデリゲートを設定
        agoraKit.setAudioFrameDelegate(audioFrameDelegate)
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

class AgoraEngineCoordinator: NSObject, AgoraRtcEngineDelegate, AgoraAudioFrameDelegate {
    weak var delegate: AgoraEngineCoordinatorDelegate?
    
    init(delegate: AgoraEngineCoordinatorDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    // MARK: - AgoraAudioFrameDelegate
    func onRecordAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        // ローカルマイクからの音声フレームは使用しない
        return true
    }
    
    func onPlaybackAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        // リモートユーザーからの音声フレーム(再生前) - これをテキスト変換APIに流す
        delegate?.didReceiveAudioFrame(frame)
        return true
    }
    
    func onMixedAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        // ミックスされた音声フレームは使用しない
        return true
    }
    
    func onEarMonitoringAudioFrame(_ frame: AgoraAudioFrame) -> Bool {
        // イヤモニタリングの音声フレームは使用しない
        return true
    }
    
    func onPlaybackAudioFrame(beforeMixing frame: AgoraAudioFrame, channelId: String, uid: UInt) -> Bool {
        // 特定ユーザーからの音声フレーム(ミックス前)は使用しない
        return true
    }
    
    func getObservedAudioFramePosition() -> AgoraAudioFramePosition {
        // リモートユーザーの音声のみを取得
        return .playback
    }
    
    func getRecordAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams()
        params.sampleRate = 48000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 1024
        return params
    }
    
    func getPlaybackAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams()
        params.sampleRate = 48000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 1024
        return params
    }
    
    func getMixedAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams()
        params.sampleRate = 48000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 1024
        return params
    }
    
    func getEarMonitoringAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams()
        params.sampleRate = 48000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 1024
        return params
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        delegate?.didJoined(uid: uid)
        print("Successfully joined channel: \(channel) with uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        delegate?.didPartnerJoined(uid: uid)
        print("User joined with uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        delegate?.didPartnerLeave(uid: uid)
        print("User offline with uid: \(uid), reason: \(reason.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        delegate?.didLeaveChannel()
        print("Left channel")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        delegate?.didOccurError()
        
        // エラーコードの詳細を表示
        let errorDescription: String
        switch errorCode.rawValue {
        case 110:
            errorDescription = "ERR_OPEN_CHANNEL_TIMEOUT (110): チャンネルへの接続がタイムアウトしました。ネットワーク接続を確認してください。"
        case 101:
            errorDescription = "ERR_INVALID_APP_ID (101): App IDが無効です。"
        case 109:
            errorDescription = "ERR_TOKEN_EXPIRED (109): トークンの有効期限が切れています。"
        case 2:
            errorDescription = "ERR_INVALID_ARGUMENT (2): 無効な引数が渡されました。"
        case 17:
            errorDescription = "ERR_NOT_INITIALIZED (17): SDKが初期化されていません。"
        default:
            errorDescription = "Unknown error"
        }
        
        print("❌ Agora Error occurred: \(errorCode.rawValue) - \(errorDescription)")
    }
}
