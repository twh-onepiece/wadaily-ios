//
//  CallPartner.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/28.
//

import Foundation

struct CallPartner: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let imageUrl: String?
    let backgroundImageUrl: String?
    let status: String
    let topics: [Topic]
    
    var isOnline: Bool {
        status == "online"
    }
    
    static func == (lhs: CallPartner, rhs: CallPartner) -> Bool {
        lhs.id == rhs.id
    }
}
