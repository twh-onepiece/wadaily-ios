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
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "globe")
                }
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
    }
}

#Preview {
    // プレビュー用のモック実装
    class MockAuthRepository: AuthRepositoryProtocol {
        func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async throws -> User {
            return User(id: "1", email: email, userId: userId, iconImageData: iconImageData, backgroundImageData: backgroundImageData, profileText: profileText)
        }
        
        func login(userId: String, password: String) async throws -> User {
            return User(id: "1", email: "test@example.com", userId: userId)
        }
        
        func logout() async throws {}
        
        func getCurrentUser() async throws -> User? {
            return nil
        }
    }
    
    let mockAuthRepo = MockAuthRepository()
    let mockStorage = UserDefaultsStorage()
    let viewModel = AuthViewModel(authRepository: mockAuthRepo, localStorage: mockStorage)
    
    return ContentView(authViewModel: viewModel)
}
