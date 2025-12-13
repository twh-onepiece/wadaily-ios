//
//  DummyAccountSelectView.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/09.
//

import SwiftUI

struct DummyAccountSelectView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    @State private var accounts: [Account] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let accountRepository = AccountRepository()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                VStack(spacing: 20) {
                    Text("アカウントを選択")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text("ログインするアカウントを選んでください")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(accounts) { account in
                                    DummyAccountCell(account: account) {
                                        viewModel.loginWithDummyAccount(account)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .task {
                await loadAccounts()
            }
        }
    }
    
    private func loadAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            accounts = try await accountRepository.fetchAll()
        } catch {
            errorMessage = "アカウントの取得に失敗しました"
            print("Error loading accounts: \(error)")
        }
        
        isLoading = false
    }
}

extension DummyAccountSelectView {
    private func DummyAccountCell(account: Account, onTap: @escaping () -> Void) -> some View {
        ZStack {
            // 背景画像
            Image(account.backgroundUrl)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .opacity(0.3)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.3), .blue.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            
            HStack(spacing: 16) {
                // アイコン
                Image(account.iconUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text(account.userId)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(account.email)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            .padding()
        }
        .cornerRadius(20)
        .shadow(radius: 5)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    DummyAccountSelectView(viewModel: AuthViewModel(authRepository: MockAuthRepository()))
}
