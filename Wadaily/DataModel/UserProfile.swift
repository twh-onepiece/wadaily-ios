//
//  UserProfile.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// ユーザー情報（speaker/listener用）
struct UserProfile: Codable {
    let userId: String
    let snsData: SNSData
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case snsData = "sns_data"
    }
}
