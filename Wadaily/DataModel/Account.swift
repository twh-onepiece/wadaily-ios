//
//  Account.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/30.
//

import Foundation

// ログインしているアカウント
struct Account: Identifiable, Codable {
    let id: UUID               // Identifiable(一意オブジェクトを保証する用のID, ほとんど使わない。一覧表示などで活躍する)
    let userId: String         // Wadaily上で管理するUserID(通話時のchannelName解決に使われる)
    let name: String           // アカウント名
    let email: String          // メールアドレス
    let intro: String          // 自己紹介用のテキスト
    let iconUrl: String        // アイコンのURL
    let backgroundUrl: String  // 背景画像のURL
    let status: String         // オンライン状態 (online/offline)
    
    var isOnline: Bool {
        status == "online"
    }
    
    enum CodingKeys: String, CodingKey {
        case name, email, intro, status
        case userId = "user_id"
        case iconUrl = "icon_url"
        case backgroundUrl = "background_url"
    }
    
    // デコード時にidがなければ自動生成
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.userId = try container.decode(String.self, forKey: .userId)
        self.name = try container.decode(String.self, forKey: .name)
        self.email = try container.decode(String.self, forKey: .email)
        self.intro = try container.decode(String.self, forKey: .intro)
        self.iconUrl = try container.decode(String.self, forKey: .iconUrl)
        self.backgroundUrl = try container.decode(String.self, forKey: .backgroundUrl)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "offline"
    }
    
    // 通常のイニシャライザ
    init(id: UUID = UUID(), userId: String, name: String, email: String, intro: String, iconUrl: String, backgroundUrl: String, status: String = "offline") {
        self.id = id
        self.userId = userId
        self.name = name
        self.email = email
        self.intro = intro
        self.iconUrl = iconUrl
        self.backgroundUrl = backgroundUrl
        self.status = status
    }
}
