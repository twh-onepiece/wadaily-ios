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

struct DummyAccount {
    static let urassh = Account(
        id: UUID(),
        userId: "urassh",
        name: "うらっしゅ",
        email: "urassh@example.com",
        intro: "こんにちは。\n\nプログラミングが好きです。\n\n好きな言語は、swiftです。",
        iconUrl: "guest1",
        backgroundUrl: "back1")
    static let sui = Account(
        id: UUID(),
        userId: "sui",
        name: "すい",
        email: "sui@example.com",
        intro: "こんにちは。",
        iconUrl: "guest2",
        backgroundUrl: "back2")
    static let tsukasa = Account(
        id: UUID(),
        userId: "tsukasa",
        name: "つかさ",
        email: "tsukasa@example.com",
        intro: "こんにちは。",
        iconUrl: "guest3",
        backgroundUrl: "back3")
    static let toku = Account(
        id: UUID(),
        userId: "cstoku",
        name: "とく",
        email: "cstoku@example.com",
        intro: "こんにちは。",
        iconUrl: "guest4",
        backgroundUrl: "back4")
}
