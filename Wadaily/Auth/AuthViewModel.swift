import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var errorMessage: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let localStorage: LocalStorageProtocol
    private let userStorageKey = "currentUser"
    
    init(authRepository: AuthRepositoryProtocol, localStorage: LocalStorageProtocol) {
        self.authRepository = authRepository
        self.localStorage = localStorage
        checkAuthState()
    }
    
    func checkAuthState() {
        authState = .loading
        Task {
            do {
                if let user = try localStorage.load(forKey: userStorageKey, as: User.self) {
                    authState = .authenticated(user)
                } else {
                    authState = .unauthenticated
                }
            } catch {
                authState = .unauthenticated
            }
        }
    }
    
    func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async {
        authState = .loading
        errorMessage = nil
        
        do {
            let user = try await authRepository.register(
                email: email,
                password: password,
                userId: userId,
                iconImageData: iconImageData,
                backgroundImageData: backgroundImageData,
                profileText: profileText
            )
            try localStorage.save(user, forKey: userStorageKey)
            authState = .authenticated(user)
        } catch {
            errorMessage = error.localizedDescription
            authState = .unauthenticated
        }
    }
    
    func login(userId: String, password: String) async {
        authState = .loading
        errorMessage = nil
        
        do {
            let user = try await authRepository.login(userId: userId, password: password)
            try localStorage.save(user, forKey: userStorageKey)
            authState = .authenticated(user)
        } catch {
            errorMessage = error.localizedDescription
            authState = .unauthenticated
        }
    }
    
    func logout() async {
        do {
            try await authRepository.logout()
            try localStorage.delete(forKey: userStorageKey)
            authState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
