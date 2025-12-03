import Foundation

protocol AuthRepositoryProtocol {
    func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async throws -> User
    func login(userId: String, password: String) async throws -> User
    func logout() async throws
    func getCurrentUser() async throws -> User?
}

enum AuthError: Error {
    case invalidCredentials
    case userAlreadyExists
    case networkError
    case unknown
}
