//
//  WadailyApp.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/27.
//

import SwiftUI

@main
struct WadailyApp: App {
    private let authRepository: AuthRepositoryProtocol = MockAuthRepository()
    
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        let authRepo = MockAuthRepository()
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authRepository: authRepo))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(authViewModel: authViewModel)
        }
    }
}
