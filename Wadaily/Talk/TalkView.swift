//
//  TalkView.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/02.
//

import SwiftUI

struct TalkView: View {
    @StateObject private var viewModel: TalkViewModel
    @State private var pulseAnimation = false
    let me: Caller
    let partner: Caller
    
    init(me: Caller, partner: Caller) {
        self.me = me
        self.partner = partner
        _viewModel = StateObject(wrappedValue: TalkViewModel(me: me, partner: partner))
    }
    
    private var stateText: String {
        switch viewModel.state {
        case .disconnected:
            return "通話を行いますか?"
        case .connecting:
            return "接続中..."
        case .channelJoined:
            return "呼び出し中..."
        case .talking:
            return "通話中"
        case .callEnded:
            return "通話終了"
        }
    }
    
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
                    ZStack {
                        // ローディング中のパルスアニメーション
                        if viewModel.state == .connecting || viewModel.state == .channelJoined {
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                .frame(width: 170, height: 170)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .opacity(pulseAnimation ? 0 : 1)
                            
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 170, height: 170)
                                .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                                .opacity(pulseAnimation ? 0 : 0.5)
                        }
                        
                        Image(partner.imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                            .opacity(viewModel.state == .connecting || viewModel.state == .channelJoined ? 0.7 : 1.0)
                    }
                    
                    Text(partner.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // 通話状態テキスト + ローディングインジケーター
                    HStack(spacing: 8) {
                        Text(stateText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if viewModel.state == .connecting || viewModel.state == .channelJoined {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                }
                
                Spacer()
                
                // コントロールボタン
                if viewModel.state == .talking {
                    talkingButtons
                        .padding(.bottom, 50)
                } else {
                    // 通話開始ボタン
                    Button(action: {
                        viewModel.joinChannel()
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
}

extension TalkView {
    private var talkingButtons: some View {
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
                        .clipShape(Circle());
                    
                    Text("終了")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    TalkView(me: DummyCallPartner.previewMe, partner: DummyCallPartner.partners.last!)
}
