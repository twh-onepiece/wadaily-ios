//
//  CallPartner.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/28.
//

import Foundation

// 通話ユーザのデータモデル
struct Caller: Identifiable, Equatable, Hashable {
    let id = UUID()                 // Identifiable(一意オブジェクトを保証する用のID, ほとんど使わない。一覧表示などで活躍する)
    let userId: String              // Wadaily上で管理するUserID(通話時のchannelName解決に使われる)
    let name: String                // 通話ユーザの名前
    let imageUrl: String            // 通話ユーザの画像URL
    let backgroundImageUrl: String  // 背景画像のURL
    let status: String              // 通話可能な状態か(online, offline)
    
    var isOnline: Bool {
        status == "online"
    }
    
    // 通話用のUInt型ID（userIdのハッシュ値から生成）
    var talkId: UInt {
        let hash = userId.hashValue
        return UInt(abs(hash))
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    // チャンネル名を生成するロジック（例: 両方のuserIdを組み合わせる）
    func buildChannelName(with partner: Caller) -> String {    
        let ids = [self.userId, partner.userId].sorted()
        return ids.joined(separator: "_")
    }
    
    static func from(_ account: Account) -> Self {
        Caller(userId: account.userId, name: account.name, imageUrl: account.iconUrl, backgroundImageUrl: account.backgroundUrl, status: "online")
    }
}

enum DummyCallPartner {
    static let dummyMe = Caller(userId: "urassh", name: "うらっしゅ", imageUrl: "guest1", backgroundImageUrl: "back1", status: "online")
    
    static let partners = [
        Caller(userId: "sui", name: "Sui", imageUrl: "guest2", backgroundImageUrl: "back1", status: "online"),
        Caller(userId: "tsukasa", name: "Tsukasa", imageUrl: "guest1", backgroundImageUrl: "back2", status: "offline"),
        Caller(userId: "toku", name: "toku", imageUrl: "guest2", backgroundImageUrl: "back3", status: "online"),
    ]
}
