import Foundation
import SwiftUI
import Combine

enum AuthState {
    case loading
    case authenticated(Account)
    case unauthenticated
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var errorMessage: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let accountManager = AccountManager.shared
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
        checkAuthState()
    }
    
    func checkAuthState() {
        authState = .loading
        Task {
            if let account = accountManager.currentAccount {
                authState = .authenticated(account)
            } else {
                authState = .unauthenticated
            }
        }
    }
    
    var currentAccount: Account? {
        accountManager.currentAccount
    }
    
    func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async {
        authState = .loading
        errorMessage = nil
        
        do {
            let account = try await authRepository.register(
                email: email,
                password: password,
                userId: userId,
                iconImageData: iconImageData,
                backgroundImageData: backgroundImageData,
                profileText: profileText
            )
            accountManager.saveAccount(account)
            authState = .authenticated(account)
        } catch {
            errorMessage = error.localizedDescription
            authState = .unauthenticated
        }
    }
    
    func login(userId: String, password: String) async {
        authState = .loading
        errorMessage = nil
        
        do {
            let account = try await authRepository.login(userId: userId, password: password)
            accountManager.saveAccount(account)
            authState = .authenticated(account)
        } catch {
            errorMessage = error.localizedDescription
            authState = .unauthenticated
        }
    }
    
    func logout() async {
        do {
            try await authRepository.logout()
            accountManager.logout()
            authState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
