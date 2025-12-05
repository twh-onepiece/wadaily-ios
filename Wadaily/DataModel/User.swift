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
    
    /// Agora用の32ビット符号付き整数のUserIDを生成
    /// userIdのハッシュ値から生成（衝突の可能性はあるが、実用上は問題ない）
    var agoraUserId: UInt {
        let hash = abs(userId.hashValue)
        return UInt(hash & 0x7FFFFFFF) // 31ビットに制限（正の値のみ）
    }
}

enum AuthState {
    case authenticated(User)
    case unauthenticated
    case loading
}
