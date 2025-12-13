import Foundation

protocol LocalStorageProtocol {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T?
    func delete(forKey key: String) throws
    func exists(forKey key: String) -> Bool
}

enum StorageError: Error {
    case encodingFailed
    case decodingFailed
    case saveFailed
    case notFound
}

// UserDefaultsを使ったシンプルな実装例
class UserDefaultsStorage: LocalStorageProtocol {
    private let userDefaults = UserDefaults.standard
    
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else {
            throw StorageError.encodingFailed
        }
        userDefaults.set(data, forKey: key)
    }
    
    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let value = try? decoder.decode(type, from: data) else {
            throw StorageError.decodingFailed
        }
        return value
    }
    
    func delete(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
    
    func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}
