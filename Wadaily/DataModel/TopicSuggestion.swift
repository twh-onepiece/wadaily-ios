//
//  TopicSuggestion.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

/// 話題の提案
struct TopicSuggestion: Codable, Identifiable {
    let id: Int
    let text: String
    let type: String
    let score: Double
}
