//
//  AccountView.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/28.
//

import SwiftUI

struct AccountView: View {
    // サンプルデータ
    let me: Account
    @ObservedObject var authViewModel: AuthViewModel
    
    // 通話履歴のサンプルデータ
    let callHistory = DummyCallHistory.histories
    
    init(me: Account, authViewModel: AuthViewModel) {
        self.me = me
        self.authViewModel = authViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // プロフィールヘッダー
            ZStack {
                // 背景画像
                VStack {
                    Image(me.backgroundUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .opacity(0.8)
                        .clipped()
                    
                    Spacer()
                }
                
                VStack {
                    // アイコン
                    Image(me.iconUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                    
                    Text(me.name)
                        .font(.title)
                        .bold()
                        .shadow(radius: 5)
                    
                    Text("@\(me.userId)")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                        .shadow(radius: 3)
                }
                .padding(.top, 80)
            }
            .frame(height: 240)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("はじめまして！ プロフィールを見てくれてありがとうございます！こういうアプリを使うのは初めてですが、良い出会いがあればと思って登録しました！！  同じように食べることが好きな人と出会えたら嬉しいです。 よろしくお願いします！！笑笑")
                    .font(Font.caption)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            
            HStack {
                Button(action: {
                    
                }) {
                    Text("Edit profile")
                        .foregroundStyle(.white)
                        .font(.callout)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                        .background(.gray)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                }
                Button(action: {
                    
                }) {
                    Text("Share profile")
                        .foregroundStyle(.white)
                        .font(.callout)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                        .background(.gray)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await authViewModel.logout()
                    }
                }) {
                    Text("Logout")
                        .foregroundStyle(.white)
                        .font(.callout)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                        .background(.red)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading) {
                    Text("History")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)
                    Text("最近話した友達")
                        .font(.callout)
                        .padding(.horizontal)
                }
                
                ScrollView {
                    ForEach(callHistory) { history in
                        CallHistoryCell(history: history)
                            .shadow(radius: 3)
                            .padding(8)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .ignoresSafeArea(edges: .top)
    }
}

extension AccountView {
    private func CallHistoryCell(history: CallHistory) -> some View {
        ZStack {
            // 背景
            if !history.partner.backgroundImageUrl.isEmpty {
                Image(history.partner.backgroundImageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .opacity(0.2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 36)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .blue]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(0.3)
                    }
            } else {
                Image("hotel")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .opacity(0.2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 36)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .blue]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(0.3)
                    }
            }
            
            HStack {
                // プロフィール画像
                Image(history.partner.imageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(history.partner.name)
                        .font(.headline)
                        .bold()
                    
                    Text(history.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 36)
                .stroke(Color.white, lineWidth: 10)
        )
        .cornerRadius(36)
    }
}

#Preview {
    AccountView(me: DummyAccount.urassh, authViewModel: AuthViewModel(authRepository: MockAuthRepository()))
}

