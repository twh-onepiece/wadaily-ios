//
//  TopicSuggestionViewPreview.swift
//  Wadaily
//
//  Created on 2025/12/13.
//

import SwiftUI

/// 話題提案UIのテスト用プレビュー画面（実際のTalkViewを使用）
struct TopicSuggestionViewPreview: View {
    let me = DummyCallPartner.previewMe
    let partner = DummyCallPartner.partners.last!
    
    var body: some View {
        let viewModel = TalkViewModel(me: me, partner: partner)
        
        TalkView(me: me, partner: partner, viewModel: viewModel)
            .onAppear {
                // テスト用の話題を設定
                #if DEBUG
                viewModel.setTestTopics([
                    "🎬 最近見た映画は？",
                    "🍕 好きな食べ物",
                    "🌍 行ってみたい旅行先",
                    "⚽️ 趣味について"
                ])
                viewModel.setTestState(.talking)
                #endif
            }
    }
}

#Preview("話題提案あり") {
    TopicSuggestionViewPreview()
}

#Preview("通話前") {
    TalkView(me: DummyCallPartner.previewMe, partner: DummyCallPartner.partners.last!)
}
