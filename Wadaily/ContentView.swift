//
//  ContentView.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        _authViewModel = StateObject(wrappedValue: authViewModel)
    }
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .authenticated:
                mainContent
            case .unauthenticated:
                LoginView(viewModel: authViewModel)
            case .loading:
                ProgressView("読み込み中...")
            }
        }
    }
    
    private var mainContent: some View {
        TabView {
            if case .authenticated(let account) = authViewModel.authState {
                DiscoverView(me: Caller.from(account))
                    .tabItem {
                        Label("Discover", systemImage: "globe")
                    }
                AccountView(me: account, authViewModel: authViewModel)
                    .tabItem {
                        Label("Account", systemImage: "person")
                    }
            }
        }
    }
}

#Preview {
    // プレビュー用のモック実装
    class MockAuthRepository: AuthRepositoryProtocol {
        func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async throws -> Account {
            return Account(
                id: UUID(),
                userId: userId,
                name: "テストユーザー",
                email: email,
                intro: "テスト用の自己紹介",
                iconUrl: "guest1",
                backgroundUrl: "back1"
            )
        }
        
        func login(userId: String, password: String) async throws -> Account {
            return Account(
                id: UUID(),
                userId: userId,
                name: "テストユーザー",
                email: "test@example.com",
                intro: "テスト用の自己紹介",
                iconUrl: "guest1",
                backgroundUrl: "back1"
            )
        }
        
        func logout() async throws {}
        
        func getCurrentUser() async throws -> Account? {
            return nil
        }
    }
    
    let mockAuthRepo = MockAuthRepository()
    let viewModel = AuthViewModel(authRepository: mockAuthRepo)
    
    return ContentView(authViewModel: viewModel)
}
