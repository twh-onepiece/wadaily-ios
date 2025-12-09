import Foundation

protocol AuthRepositoryProtocol {
    func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async throws -> Account
    func login(userId: String, password: String) async throws -> Account
    func logout() async throws
    func getCurrentUser() async throws -> Account?
}

enum AuthError: Error {
    case invalidCredentials
    case userAlreadyExists
    case networkError
    case unknown
}

// 実際の実装は後で差し替え可能
class MockAuthRepository: AuthRepositoryProtocol {
    func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async throws -> Account {
        // TODO: 実際のAPI呼び出しに置き換える
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機してAPI呼び出しをシミュレート
        return Account(
            id: UUID(),
            userId: userId,
            name: userId,
            email: email,
            intro: profileText ?? "",
            iconUrl: "",
            backgroundUrl: ""
        )
    }
    
    func login(userId: String, password: String) async throws -> Account {
        // TODO: 実際のAPI呼び出しに置き換える
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return Account(
            id: UUID(),
            userId: userId,
            name: userId,
            email: "\(userId)@example.com",
            intro: "",
            iconUrl: "",
            backgroundUrl: ""
        )
    }
    
    func logout() async throws {
        // TODO: 実際のAPI呼び出しに置き換える
    }
    
    func getCurrentUser() async throws -> Account? {
        return nil
    }
}
