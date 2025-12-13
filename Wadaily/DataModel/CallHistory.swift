//
//  CallHistory.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/28.
//

import Foundation

// 通話履歴を管理するモデル
struct CallHistory: Identifiable {
    let id = UUID()                 // Identifiable(一意オブジェクトを保証する用のID, ほとんど使わない。一覧表示などで活躍する)
    let partner: Caller             // 通話相手
    let callDate: Date              // 通話を終了した日付
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: callDate)
    }
}

enum DummyCallHistory {
    static let histories = [
        CallHistory(partner: DummyCallPartner.partners[0], callDate: Date().addingTimeInterval(-3600)), // 1時間前
        CallHistory(partner: DummyCallPartner.partners[1], callDate: Date().addingTimeInterval(-86400)), // 1日前
        CallHistory(partner: DummyCallPartner.partners[2], callDate: Date().addingTimeInterval(-172800)), // 2日前
    ]
}
