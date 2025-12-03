import Foundation

struct User: Codable {
    let id: String
    let email: String
    let userId: String
    let iconImageData: Data?
    let backgroundImageData: Data?
    let profileText: String?
    
    init(id: String, email: String, userId: String, iconImageData: Data? = nil, backgroundImageData: Data? = nil, profileText: String? = nil) {
        self.id = id
        self.email = email
        self.userId = userId
        self.iconImageData = iconImageData
        self.backgroundImageData = backgroundImageData
        self.profileText = profileText
    }
}

enum AuthState {
    case authenticated(User)
    case unauthenticated
    case loading
}
