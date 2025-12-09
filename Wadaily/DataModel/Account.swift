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
}
