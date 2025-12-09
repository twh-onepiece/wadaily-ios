//
//  DiscoverView.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/28.
//

import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel: DiscoverViewModel
    @State private var selectedPartner: Caller?
    let me: Caller
    
    init(me: Caller) {
        self.me = me
        _viewModel = StateObject(wrappedValue: DiscoverViewModel(me: me))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                VStack {
                    Text("Wadaily")
                        .font(Font.largeTitle.bold())
                    Text("話し相手をみつけよう")
                        .font(.callout)
                    
                    if viewModel.isLoading {
                        ProgressView("読み込み中...")
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ScrollView {
                            ForEach(viewModel.partners) { partner in
                                CallPartnerCell(partner: partner)
                                    .shadow(radius: 5)
                                    .padding(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationDestination(item: $selectedPartner) { partner in
                TalkView(me: me, partner: partner)
            }
            .task {
                await viewModel.fetchPartners()
            }
        }
    }
}

extension DiscoverView {
    private func CallPartnerCell(partner: Caller) -> some View {
        ZStack {
            // 背景画像またはデフォルト背景
            Image(partner.backgroundImageUrl)
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .opacity(0.2)
                .overlay {
                    if partner.isOnline {
                        RoundedRectangle(cornerRadius: 36)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .green]), startPoint: .top, endPoint: .bottom))
                            .opacity(0.3)
                    }
                    else
                    {
                        RoundedRectangle(cornerRadius: 36)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .gray]), startPoint: .top, endPoint: .bottom))
                            .opacity(0.3)
                    }
                }
            
            HStack {
                // プロフィール画像
                Image(partner.imageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.name)
                        .font(.title2)
                        .bold()

                    Text(partner.status)
                        .font(.headline)
                        .foregroundColor(partner.isOnline ? .green : .gray)
                        .shadow(color: .white, radius: 1)
                    
                }
                
                Spacer()
                
                // 通話ボタン
                Button(action: {
                    selectedPartner = partner
                }) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(partner.isOnline ? .green : .gray)
                        .clipShape(Circle())
                }
            }
            .padding(16)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 38)
                .stroke(Color.white, lineWidth: 10)
        )
        .cornerRadius(38)
        
    }
}

#Preview {
    DiscoverView(me: DummyCallPartner.previewMe)
}
