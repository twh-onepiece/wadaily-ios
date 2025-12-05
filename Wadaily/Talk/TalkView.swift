//
//  TalkView.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/02.
//

import SwiftUI

struct TalkView: View {
    @StateObject private var viewModel = TalkViewModel()
    let channelName: String
    let partnerName: String
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 相手のアイコン
                VStack(spacing: 20) {
                    Image("guest1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                    
                    Text(partnerName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // 通話状態テキスト
                    Text(stateText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // コントロールボタン
                if viewModel.state == .Talking {
                    HStack(spacing: 60) {
                        // ミュートボタン
                        Button(action: {
                            viewModel.toggleMute()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(viewModel.isMuted ? Color.red.opacity(0.8) : Color.white.opacity(0.3))
                                    .clipShape(Circle())
                                
                                Text(viewModel.isMuted ? "ミュート中" : "ミュート")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 通話終了ボタン
                        Button(action: {
                            viewModel.leaveChannel()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                                
                                Text("終了")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, 50)
                } else {
                    // 通話開始ボタン
                    Button(action: {
                        viewModel.joinChannel(channelName: channelName)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }
                
                Spacer()
            }
        }
    }
    
    private var stateText: String {
        switch viewModel.state {
        case .Before:
            return "通話前"
        case .Waiting:
            return "呼び出し中..."
        case .Talking:
            return "通話中"
        case .Talked:
            return "通話終了"
        }
    }
}

#Preview {
    TalkView(channelName: "test", partnerName: "Sample User")
}
