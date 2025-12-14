//
//  TopicSuggestionView.swift
//  Wadaily
//
//  Created on 2025/12/13.
//

import SwiftUI

struct TopicSuggestionView: View {
    let topics: [String]
    
    @State private var isVisible = false
    @State private var floatingOffsets: [CGFloat] = []
    
    var body: some View {
        if !topics.isEmpty {
            VStack(spacing: 12) {
                // ヘッダー
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                    
                    Text("おすすめの話題")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 18))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // 話題チップ（縦1列表示）
                VStack(alignment: .center, spacing: 12) {
                    ForEach(Array(topics.enumerated()), id: \.offset) { index, topic in
                        TopicChip(
                            topic: topic,
                            floatingOffset: floatingOffsets.indices.contains(index) ? floatingOffsets[index] : 0
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(
                // すりガラス風背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            )
            .padding(.horizontal, 20)
            .offset(y: isVisible ? 0 : 100)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                // 初期化：浮遊オフセット
                floatingOffsets = topics.map { _ in CGFloat.random(in: -3...3) }
                
                // 表示アニメーション
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isVisible = true
                }
                
                // 新着通知のハプティクス
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                
                // 浮遊アニメーション開始
                startFloatingAnimation()
            }
            .onChange(of: topics) { newTopics in
                // 話題更新時のアニメーション
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    floatingOffsets = newTopics.map { _ in CGFloat.random(in: -3...3) }
                }
                
                // 新着通知のハプティクス
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
    }
    
    private func startFloatingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                floatingOffsets = floatingOffsets.map { _ in
                    CGFloat.random(in: -3...3)
                }
            }
        }
    }
}

struct TopicChip: View {
    let topic: String
    let floatingOffset: CGFloat
    
    var body: some View {
        Text(topic)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // 柔らかいグラデーション
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.4)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 白枠
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            .offset(y: floatingOffset)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            TopicSuggestionView(
                topics: ["🎬 最近見た映画は？", "🍕 好きな食べ物", "🌍 行ってみたい旅行先"]
            )
            .padding(.bottom, 150)
        }
    }
}
