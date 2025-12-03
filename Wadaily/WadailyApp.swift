//
//  WadailyApp.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/27.
//

import SwiftUI

// 実際の実装は後で差し替え可能
class MockAuthRepository: AuthRepositoryProtocol {
    func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async throws -> User {
        // TODO: 実際のAPI呼び出しに置き換える
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機してAPI呼び出しをシミュレート
        return User(id: UUID().uuidString, email: email, userId: userId, iconImageData: iconImageData, backgroundImageData: backgroundImageData, profileText: profileText)
    }
    
    func login(userId: String, password: String) async throws -> User {
        // TODO: 実際のAPI呼び出しに置き換える
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return User(id: UUID().uuidString, email: "\(userId)@example.com", userId: userId)
    }
    
    func logout() async throws {
        // TODO: 実際のAPI呼び出しに置き換える
    }
    
    func getCurrentUser() async throws -> User? {
        return nil
    }
}

@main
struct WadailyApp: App {
    private let authRepository: AuthRepositoryProtocol = MockAuthRepository()
    private let localStorage: LocalStorageProtocol = UserDefaultsStorage()
    
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        let authRepo = MockAuthRepository()
        let storage = UserDefaultsStorage()
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authRepository: authRepo, localStorage: storage))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(authViewModel: authViewModel)
        }
    }
}
